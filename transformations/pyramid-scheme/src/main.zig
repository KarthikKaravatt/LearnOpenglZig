const std = @import("std");
const builtin = @import("builtin");

const glfw = @import("zglfw");
const zgl = @import("zopengl");
const zstbi = @import("zstbi");
const zm = @import("zmath");

const ShaderConstructor = @import("./shader.zig").ShaderConstructor;

const print = std.debug.print;
const panic = std.debug.panic;

const is_debug = builtin.mode == .Debug;

const gl = zgl.wrapper;
const math = std.math;

const gl_major = 4;
const gl_minor = 3;

const triangle_vertex_shader_path = "src/shaders/triangle.vs";
const triangle_fragment_shader_path = "src/shaders/triangle.fs";

pub fn main() !void {
    var debug_allocator: std.heap.DebugAllocator(.{}) = .init;
    defer if (is_debug) {
        _ = debug_allocator.deinit();
    };
    const gpa, _ = gpa: {
        if (builtin.os.tag == .wasi) break :gpa .{ std.heap.wasm_allocator, false };
        break :gpa switch (builtin.mode) {
            .Debug, .ReleaseSafe => .{ debug_allocator.allocator(), true },
            .ReleaseFast, .ReleaseSmall => .{ std.heap.smp_allocator, false },
        };
    };
    zstbi.init(gpa);
    defer zstbi.deinit();
    glfw.init() catch |err| {
        panic("Failed to initlaise zglfw: {}", .{err});
    };
    defer glfw.terminate();

    const window = glfwSetupWindow("Pyramid Scheme");
    zgl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor) catch |err| {
        panic("Failed to load opengl:{}", .{err});
    };

    const vertices = [_]f32{
        // pos           //colors       //texture coords
        -0.5,  -0.25, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
        0.0,   -0.25, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0,
        -0.25, 0.25,  0.0, 0.0, 0.0, 1.0, 0.5, 0.0,

        0.0,   -0.25, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
        0.5,   -0.25, 0.0, 0.0, 1.0, 0.0, 1.0, 1.0,
        0.25,  0.25,  0.0, 0.0, 0.0, 1.0, 0.5, 0.0,

        -0.25, 0.25,  0.0, 1.0, 0.0, 0.0, 0.0, 1.0,
        0.25,  0.25,  0.0, 0.0, 1.0, 0.0, 1.0, 1.0,
        0.0,   0.75,  0.0, 0.0, 0.0, 1.0, 0.5, 0.0,
    };

    const vertex_data_size = @sizeOf(@TypeOf(vertices));
    // Opengl works with raw bytes
    const vertices_bytes: []const u8 = std.mem.sliceAsBytes(vertices[0..]);
    const byte_ptr: ?[*]const u8 = vertices_bytes.ptr;

    var vao: gl.VertexArrayObject = .{ .name = 0 };
    var vbo: gl.Buffer = .{ .name = 0 };
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
    const vertexTextureLocation: gl.VertexAttribLocation = .{ .location = 2 };
    gl.vertexAttribPointer(
        vertexCoordLocation,
        3,
        .float,
        gl.FALSE,
        8 * @sizeOf(gl.Float),
        0,
    );
    gl.enableVertexAttribArray(vertexCoordLocation);
    gl.vertexAttribPointer(
        vertexColourLocation,
        3,
        .float,
        gl.FALSE,
        8 * @sizeOf(gl.Float),
        3 * @sizeOf((gl.Float)),
    );
    gl.enableVertexAttribArray(vertexColourLocation);

    gl.vertexAttribPointer(
        vertexTextureLocation,
        2,
        .float,
        gl.FALSE,
        8 * @sizeOf(gl.Float),
        6 * @sizeOf(gl.Float),
    );
    gl.enableVertexAttribArray(vertexTextureLocation);

    var image_1 = zstbi.Image.loadFromFile("src/textures/wall.jpg", 0) catch |err| {
        panic("Image reading failed:{any}", .{err});
    };
    var image_2 = zstbi.Image.loadFromFile("src/textures/awesomeface.png", 0) catch |err| {
        panic("Image reading failed:{any}", .{err});
    };
    defer image_1.deinit();
    defer image_2.deinit();
    var texture_1: gl.Texture = .{ .name = 0 };
    var texture_2: gl.Texture = .{ .name = 0 };
    gl.genTexture(&texture_1);
    gl.bindTexture(.texture_2d, texture_1);
    gl.texParameteri(.texture_2d, .wrap_s, gl.REPEAT);
    gl.texParameteri(.texture_2d, .wrap_t, gl.REPEAT);
    gl.texParameteri(.texture_2d, .min_filter, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(.texture_2d, .mag_filter, gl.LINEAR);
    gl.texImage2D(.{
        .target = .texture_2d,
        .level = 0,
        .internal_format = .rgb,
        .width = image_1.width,
        .height = image_1.height,
        .format = .rgb,
        .pixel_type = .unsigned_byte,
        .data = image_1.data.ptr,
    });
    gl.generateMipmap(.texture_2d);
    gl.genTexture(&texture_2);
    gl.bindTexture(.texture_2d, texture_2);
    gl.texParameteri(.texture_2d, .wrap_s, gl.REPEAT);
    gl.texParameteri(.texture_2d, .wrap_t, gl.REPEAT);
    gl.texParameteri(.texture_2d, .min_filter, gl.LINEAR_MIPMAP_LINEAR);
    gl.texParameteri(.texture_2d, .mag_filter, gl.LINEAR);
    gl.texImage2D(.{
        .target = .texture_2d,
        .level = 0,
        .internal_format = .rgb,
        .width = image_2.width,
        .height = image_2.height,
        .format = .rgba,
        .pixel_type = .unsigned_byte,
        .data = image_2.data.ptr,
    });
    gl.generateMipmap(.texture_2d);

    const shader: ShaderConstructor = ShaderConstructor.init(
        triangle_vertex_shader_path,
        triangle_fragment_shader_path,
        gpa,
    );
    defer shader.deinit();
    if (hasGlError()) return;
    shader.use();
    shader.setInt("texture1", 0, gpa);
    shader.setInt("texture2", 1, gpa);
    while (!window.shouldClose()) {
        processInput(window);
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(.{ .color = true });
        if (hasGlError()) return;
        gl.activeTexture(.texture_0);
        gl.bindTexture(.texture_2d, texture_1);
        gl.activeTexture(.texture_1);
        gl.bindTexture(.texture_2d, texture_2);

        var trans = zm.identity();
        const time: f32 = @floatCast((glfw.getTime()));
        trans = zm.mul(trans, zm.rotationZ(math.degreesToRadians(time * 0)));
        const transformLoc = gl.getUniformLocation(
            shader.shaderProgram,
            "transform",
        ) orelse {
            panic("transfrom uniform not found", .{});
        };

        gl.uniformMatrix4fv(transformLoc, 1, false, &zm.matToArr(trans));
        gl.bindVertexArray(vao);
        gl.drawArrays(.triangles, 0, 9);

        if (hasGlError()) return;
        window.swapBuffers();
        glfw.pollEvents();
        if (hasGlError()) return;
    }
}

fn frameBufferSizeCallback(
    _: *glfw.Window,
    width: i32,
    height: i32,
) callconv(.c) void {
    gl.viewport(0, 0, @bitCast(width), @bitCast(height));
}

fn glfwSetupWindow(title: [:0]const u8) *glfw.Window {
    glfw.windowHint(.context_version_major, gl_major);
    glfw.windowHint(.context_version_minor, gl_minor);
    glfw.windowHint(.resizable, false);
    if (is_debug) {
        glfw.windowHint(.opengl_debug_context, true);
    }
    if (builtin.target.os.tag == .macos) {
        glfw.windowHint(.opengl_forward_compat, true);
    } else {
        glfw.windowHint(.opengl_profile, .opengl_core_profile);
    }
    const window_width = 800;
    const window_height = 700;
    const window = glfw.Window.create(
        window_width,
        window_height,
        title,
        null,
    ) catch |err| {
        panic("Window creation failed: {any}", .{err});
    };
    glfw.makeContextCurrent(window);
    _ = window.setFramebufferSizeCallback(frameBufferSizeCallback);
    return window;
}

fn hasGlError() bool {
    if (is_debug) {
        const e = gl.getError();
        if (e != gl.Error.no_error) {
            return true;
        }
    }
    return false;
}

fn processInput(window: *glfw.Window) void {
    if (window.getKey(glfw.Key.escape) == glfw.Action.press) {
        window.setShouldClose(true);
    }
}
