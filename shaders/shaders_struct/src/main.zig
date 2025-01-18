const std = @import("std");
const Shader = @import("./shader.zig").Shader;
const print = @import("std").debug.print;
const panic = std.debug.panic;
const builtin = @import("builtin");

const glfw = @import("zglfw");
const zopengl = @import("zopengl");

/// Change the viewport size when window is resized
fn frameBufferSizeCallback(
    _: *glfw.Window,
    width: i32,
    height: i32,
) callconv(.c) void {
    zopengl.bindings.viewport(0, 0, width, height);
}

/// Process the input
fn processInput(window: *glfw.Window) void {
    if (glfw.Window.getKey(window, glfw.Key.escape) == glfw.Action.press) {
        glfw.Window.setShouldClose(window, true);
    }
}
/// Check for opengl error
fn hasGlError() bool {
    if (comptime builtin.mode == .Debug) {
        const gl = zopengl.bindings;
        const e = gl.getError();
        if (e != gl.NO_ERROR) {
            print("OpenGL Error: {d}\n", .{e});
            return true;
        }
    }
    return false;
}

pub fn main() !void {
    const window_width = 800;
    const window_height = 600;
    const gl_major = 4;
    const gl_minor = 6;

    //GLFW initialisation
    try glfw.init();
    defer glfw.terminate();
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.resizable, false);
    if (comptime builtin.mode == .Debug) {
        glfw.windowHintTyped(.opengl_debug_context, true);
    }
    if (comptime builtin.target.os.tag == .macos) {
        glfw.windowHintTyped(.opengl_forward_compat, .gl_true);
    } else {
        glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    }

    const window = try glfw.Window.create(
        window_width,
        window_height,
        "LearnOpenGL",
        null,
    );
    glfw.makeContextCurrent(window);
    _ = window.setFramebufferSizeCallback(frameBufferSizeCallback);

    // Load function pointers for opengl
    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);
    const gl = zopengl.bindings;
    // gl.polygonMode(gl.FRONT_AND_BACK, gl.LINE);

    // Square
    var vertices = [_]gl.Float{
        0.5,  0.5,  0.0,
        0.5,  -0.5, 0.0,
        -0.5, -0.5, 0.0,
        -0.5, 0.5,  0.0,
    };
    var indices = [_]gl.Uint{
        0, 1, 3,
        1, 2, 3,
    };
    // Initialise array object and buffers
    var VAO: gl.Uint = undefined;
    var VBO: gl.Uint = undefined;
    var EBO: gl.Uint = undefined;

    defer gl.deleteVertexArrays(1, &VAO);
    defer gl.deleteBuffers(1, &VBO);
    defer gl.deleteBuffers(1, &EBO);

    // Generate ids
    gl.genVertexArrays(1, &VAO);
    gl.genBuffers(1, &VBO);
    gl.genBuffers(1, &EBO);

    // Bind array and buffers
    gl.bindVertexArray(VAO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.bindBuffer(gl.ELEMENT_ARRAY_BUFFER, EBO);

    // Add data to the buffer
    gl.bufferData(
        gl.ARRAY_BUFFER,
        vertices.len * @sizeOf(gl.Float),
        &vertices,
        gl.STATIC_DRAW,
    );
    gl.bufferData(
        gl.ELEMENT_ARRAY_BUFFER,
        indices.len * @sizeOf(gl.Uint),
        &indices,
        gl.STATIC_DRAW,
    );

    // Set the Attribute pointers
    gl.vertexAttribPointer(
        0,
        3,
        gl.FLOAT,
        gl.FALSE,
        3 * @sizeOf(gl.Float),
        @ptrFromInt(0),
    );

    if (hasGlError()) panic("OpenGL buffer setup failed", .{});

    gl.enableVertexAttribArray(0);
    defer gl.disableVertexAttribArray(0);
    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();
    const shaderProgram: Shader = Shader.init(
        "src/shaders/triangle.vs",
        "src/shaders/triangle.fs",
        allocator,
    );
    // Compile vertex shader
    if (hasGlError()) return;

    while (!glfw.Window.shouldClose(window)) {
        processInput(window);
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // Draw the triangle
        gl.useProgram(shaderProgram.ID);
        const timeValue: f32 = @floatCast(glfw.getTime());
        const greenVale = (std.math.sin(timeValue) / 2.0) + 0.5;
        const vertexColorLocation = gl.getUniformLocation(shaderProgram.ID, "ourColor");
        if (vertexColorLocation == -1) panic("Unifrom location not found", .{});
        gl.uniform4f(vertexColorLocation, 0.0, greenVale, 0.0, 1.0);
        if (hasGlError()) return;
        gl.bindVertexArray(VAO);
        if (hasGlError()) return;
        gl.drawElements(gl.TRIANGLES, 6, gl.UNSIGNED_INT, @ptrFromInt(0));
        if (hasGlError()) return;
        gl.bindVertexArray(0);
        if (hasGlError()) return;

        window.swapBuffers();
        glfw.pollEvents();
    }
}
