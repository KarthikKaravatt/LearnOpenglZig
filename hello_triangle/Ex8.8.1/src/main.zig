const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const print = std.debug.print;
const panic = std.debug.panic;
const gl = zopengl.bindings;
const isDebug = builtin.mode == .Debug;

fn frameBufferSizeCallback(
    _: *glfw.Window,
    width: i32,
    height: i32,
) callconv(.c) void {
    gl.viewport(0, 0, width, height);
}

fn processInput(window: *glfw.Window) void {
    if (glfw.Window.getKey(window, glfw.Key.escape) == glfw.Action.press) {
        glfw.Window.setShouldClose(window, true);
    }
}
fn checkGLError() bool {
    if (isDebug) {
        const e = gl.getError();
        if (e != gl.NO_ERROR) {
            print("OpenGL Error: {d}\n", .{e});
            return true;
        }
    }
    return false;
}

fn checkShaderError(
    shader: gl.Uint,
) bool {
    if (isDebug) {
        var success: gl.Int = 0;
        gl.getShaderiv(shader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            var infoLog: [512]u8 = undefined;
            var logLength: gl.Int = 0;
            gl.getShaderInfoLog(shader, 512, &logLength, &infoLog);
            print(
                "ERROR::SHADER::COMPILATION_FAILED\n{s}\n",
                .{
                    infoLog[0..@intCast(logLength)],
                },
            );
            return true;
        }
    }
    print("INFO::SHADER::LINKING_SUCCESS\n", .{});
    return false;
}

pub fn main() !void {
    const width = 800;
    const height = 600;
    const gl_major = 4;
    const gl_minor = 6;
    try glfw.init();
    defer glfw.terminate();
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.resizable, false);
    if (comptime builtin.mode == .Debug) {
        glfw.windowHintTyped(.opengl_debug_context, true);
    }
    if (comptime builtin.target.os.tag == .macos) {
        glfw.windowHintTyped(.opengl_forward_compat, true);
    } else {
        glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    }
    const window = try glfw.Window.create(
        width,
        height,
        "LearnOpenGL",
        null,
    );
    glfw.makeContextCurrent(window);
    _ = window.setFramebufferSizeCallback(frameBufferSizeCallback);
    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);

    var vertices = [_]gl.Float{
        // Triangle 1 (moved slightly to the left)
        -0.9, -0.5, 0.0, // Bottom left
        0.0, -0.5, 0.0, // Bottom right
        -0.45, 0.5, 0.0, // Top center
        // Triangle 2 (unchanged)
        0, -0.5, 0.0, // Bottom left
        0.9, -0.5, 0.0, // Bottom right
        0.45, 0.5, 0.0, // Top center
    };

    var VAO: gl.Uint = 0;
    var VBO: gl.Uint = 0;

    gl.genVertexArrays(1, &VAO);
    defer gl.deleteVertexArrays(1, &VAO);
    gl.genBuffers(1, &VBO);
    defer gl.deleteBuffers(1, &VBO);

    gl.bindVertexArray(VAO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);

    const verticesSize = vertices.len * @sizeOf(gl.Float);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        verticesSize,
        &vertices,
        gl.STATIC_DRAW,
    );

    const vertexSize = 3 * @sizeOf(gl.Float);
    gl.vertexAttribPointer(
        0,
        3,
        gl.FLOAT,
        gl.FALSE,
        vertexSize,
        @ptrFromInt(0),
    );
    gl.enableVertexAttribArray(0);
    defer gl.disableVertexAttribArray(0);
    if (checkGLError()) @panic("Error setting up vertex array and buffer");

    const vertexShaderSource: [:0]const u8 = @embedFile(
        "shaders/triangle.vs",
    );
    const vertexShader: gl.Uint = gl.createShader(gl.VERTEX_SHADER);
    defer gl.deleteShader(vertexShader);
    gl.shaderSource(
        vertexShader,
        1,
        &[_][*c]const u8{vertexShaderSource.ptr},
        null,
    );
    gl.compileShader(vertexShader);
    if (checkShaderError(vertexShader)) {
        panic("Vertex shader failed", .{});
    }
    const fragmentShaderSource: [:0]const u8 = @embedFile(
        "shaders/triangle.fs",
    );
    const fragmentShader: gl.Uint = gl.createShader(gl.FRAGMENT_SHADER);
    defer gl.deleteShader(fragmentShader);
    gl.shaderSource(
        fragmentShader,
        1,
        &[_][*c]const u8{fragmentShaderSource.ptr},
        null,
    );
    gl.compileShader(fragmentShader);
    if (checkShaderError(fragmentShader)) {
        panic("Fragment shader failed", .{});
    }

    const shaderProgram: gl.Uint = gl.createProgram();
    defer gl.deleteProgram(shaderProgram);
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);
    if (builtin.mode == .Debug) {
        var success: gl.Int = 0;
        gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
        if (success == 0) {
            var infoLog: [512]u8 = undefined;
            var logSize: gl.Int = 0;
            gl.getProgramInfoLog(shaderProgram, 512, &logSize, &infoLog);
            const i: usize = @intCast(logSize);
            print("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog[0..i]});
            return;
        } else {
            var infoLog: [512]u8 = undefined;
            var logSize: gl.Int = 0;
            gl.getProgramInfoLog(shaderProgram, 512, &logSize, &infoLog);
            const i: usize = @intCast(logSize);
            print("INFO::SHADER::PROGRAM::LINKING_SUCCESS {d}\n{s}\n", .{ i, infoLog[0..i] });
        }
    }
    if (checkGLError()) return panic("Shader program error", .{});

    while (!glfw.Window.shouldClose(window)) {
        processInput(window);
        gl.useProgram(shaderProgram);
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(shaderProgram);
        gl.bindVertexArray(VAO);
        gl.drawArrays(gl.TRIANGLES, 0, 6);
        if (checkGLError()) return panic("Shader program error", .{});

        window.swapBuffers();
        glfw.pollEvents();
    }
}
