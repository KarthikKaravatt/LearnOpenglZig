// Imports
const std = @import("std");
const builtin = @import("builtin");

const glfw = @import("zglfw");
const zgl = @import("zopengl");

const ShaderConstructor = @import("./shader.zig").ShaderConstructor;

// shorthand
const gl = zgl.wrapper;
const bgl = zgl.bindings;

// Functions
const print = std.debug.print;
const panic = std.debug.panic;

//Mode
const isDebug = builtin.mode == .Debug;

//constants
const gl_major = 4;
const gl_minor = 6;
const triangleVertexShaderPath = "src/shaders/triangle.vs";
const triangleFragmentShaderPath = "src/shaders/triangle.fs";

pub fn main() void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();
    defer {
        const deint_status = gpa.deinit();
        if (deint_status == .leak) {
            std.testing.expect(false) catch {
                panic("Memory Leak detected", .{});
            };
        }
    }
    const bytes = allocator.alloc(u8, 100) catch |err| {
        panic("Allocation failed {any}", .{err});
    };
    defer allocator.free(bytes);

    glfw.init() catch |err| {
        panic("Failed to intialise glfw: {any}", .{err});
    };
    defer glfw.terminate();

    const window = glfwSetupWindow("CrateTexture");

    zgl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor) catch |err| {
        panic("Failed to load opengl core profile: {any}", .{err});
    };
    var vertices = [_]f32{
        // pos           //colors
        -0.5, -0.5, 0.0, 1.0, 0.0, 0.0,
        0.5,  -0.5, 0.0, 0.0, 1.0, 0.0,
        0.0,  0.5,  0.0, 0.0, 0.0, 1.0,
    };

    const vertex_data_size = @sizeOf(@TypeOf(vertices));
    // Opengl works with raw bytes
    const byte_ptr: ?[*]const u8 = @ptrCast(&vertices);

    var vao: gl.VertexArrayObject = undefined;
    var vbo: gl.Buffer = undefined;
    defer gl.deleteVertexArray(&vao);
    defer gl.deleteBuffer(&vbo);

    gl.genVertexArray(&vao);
    gl.genBuffer(&vbo);

    gl.bindVertexArray(vao);
    gl.bindBuffer(.array_buffer, vbo);

    gl.bufferData(
        .array_buffer,
        vertex_data_size,
        byte_ptr,
        .static_draw,
    );
    const vertexCoordLocation: gl.VertexAttribLocation = .{ .location = 0 };
    const vertexColourLocation: gl.VertexAttribLocation = .{ .location = 1 };
    gl.vertexAttribPointer(
        vertexCoordLocation,
        3,
        .float,
        gl.FALSE,
        6 * @sizeOf(gl.Float),
        0,
    );
    gl.enableVertexAttribArray(vertexCoordLocation);
    gl.vertexAttribPointer(
        vertexColourLocation,
        3,
        .float,
        gl.FALSE,
        6 * @sizeOf(gl.Float),
        3 * @sizeOf((gl.Float)),
    );
    gl.enableVertexAttribArray(vertexColourLocation);
    const shader: ShaderConstructor = ShaderConstructor.init(
        triangleVertexShaderPath,
        triangleFragmentShaderPath,
        allocator,
    );
    defer shader.deinit();
    shader.use();
    if (hasGlError()) return;
    while (!window.shouldClose()) {
        processInput(window);
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(.{ .color = true });
        _ = hasGlError();

        gl.bindVertexArray(vao);
        gl.drawArrays(.triangles, 0, 3);
        _ = hasGlError();

        window.swapBuffers();
        glfw.pollEvents();
        _ = hasGlError();
    }
}

fn glfwSetupWindow(title: [:0]const u8) *glfw.Window {
    glfw.windowHint(.context_version_major, gl_major);
    glfw.windowHint(.context_version_minor, gl_minor);
    glfw.windowHint(.resizable, false);
    if (isDebug) {
        glfw.windowHint(.opengl_debug_context, true);
    }
    if (builtin.target.os.tag == .macos) {
        glfw.windowHint(.opengl_forward_compat, true);
    } else {
        glfw.windowHint(.opengl_profile, .opengl_core_profile);
    }
    const window_width = 800;
    const window_height = 600;
    const window = glfw.Window.create(
        window_width,
        window_height,
        title,
        null,
    ) catch |err| {
        panic("Window creation failed: {any}", .{err});
    };
    glfw.makeContextCurrent(window);
    _ = glfw.Window.setFramebufferCallback(window, frameBufferSizeCallback);
    // _ = window.setFramebufferCallback(frameBufferSizeCallback);
    return window;
}

fn hasGlError() bool {
    if (isDebug) {
        const e = gl.getError();
        if (e != gl.Error.no_error) {
            print("OpenGL Error: {s}\n", .{@tagName(e)});
            return true;
        }
    }
    return false;
}
fn frameBufferSizeCallback(
    _: *glfw.Window,
    width: i32,
    height: i32,
) callconv(.c) void {
    gl.viewport(0, 0, @bitCast(width), @bitCast(height));
}

fn processInput(window: *glfw.Window) void {
    if (window.getKey(glfw.Key.escape) == glfw.Action.press) {
        window.setShouldClose(true);
    }
}
