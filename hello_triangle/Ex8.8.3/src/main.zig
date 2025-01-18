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
fn createShader(shaderSource: [:0]const u8, shaderType: gl.Enum) gl.Uint {
    const shader: gl.Uint = gl.createShader(shaderType);
    gl.shaderSource(
        shader,
        1,
        &[_][*c]const u8{shaderSource.ptr},
        null,
    );
    gl.compileShader(shader);
    if (checkShaderError(shader)) {
        panic("Shader failed", .{});
    }
    return shader;
}
fn createShaderProgram(shaders: *const [2]c_uint) gl.Uint {
    const shaderProgram: gl.Uint = gl.createProgram();
    for (shaders) |shader| {
        gl.attachShader(shaderProgram, shader);
    }
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
            return panic("Shader program error", .{});
        } else {
            var infoLog: [512]u8 = undefined;
            var logSize: gl.Int = 0;
            gl.getProgramInfoLog(shaderProgram, 512, &logSize, &infoLog);
            const i: usize = @intCast(logSize);
            print("INFO::SHADER::PROGRAM::LINKING_SUCCESS {d}\n{s}\n", .{ i, infoLog[0..i] });
        }
    }
    return shaderProgram;
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

    var triangle_1 = [_]gl.Float{
        // Triangle 1 (moved slightly to the left)
        -0.9, -0.5, 0.0, // Bottom left
        0.0, -0.5, 0.0, // Bottom right
        -0.45, 0.5, 0.0, // Top center
    };

    var triangle_2 = [_]gl.Float{
        0, -0.5, 0.0, // Bottom left
        0.9, -0.5, 0.0, // Bottom right
        0.45, 0.5, 0.0, // Top center
    };

    var VAO_T1: gl.Uint = 0;
    var VAO_T2: gl.Uint = 0;

    gl.genVertexArrays(1, &VAO_T1);
    gl.genVertexArrays(1, &VAO_T2);

    defer gl.deleteVertexArrays(1, &VAO_T1);
    defer gl.deleteVertexArrays(1, &VAO_T2);
    var VBO_T1: gl.Uint = 0;
    var VBO_T2: gl.Uint = 0;

    gl.genBuffers(1, &VBO_T1);
    gl.genBuffers(1, &VBO_T2);
    defer gl.deleteBuffers(1, &VBO_T1);
    defer gl.deleteBuffers(1, &VBO_T2);

    gl.bindVertexArray(VAO_T1);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO_T1);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        triangle_1.len * @sizeOf(gl.Float),
        &triangle_1,
        gl.STATIC_DRAW,
    );
    gl.vertexAttribPointer(
        0,
        3,
        gl.FLOAT,
        gl.FALSE,
        3 * @sizeOf(gl.Float),
        @ptrFromInt(0),
    );
    gl.enableVertexAttribArray(0);

    gl.bindVertexArray(VAO_T2);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO_T2);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        triangle_2.len * @sizeOf(gl.Float),
        &triangle_2,
        gl.STATIC_DRAW,
    );

    gl.vertexAttribPointer(
        0,
        3,
        gl.FLOAT,
        gl.FALSE,
        3 * @sizeOf(gl.Float),
        @ptrFromInt(0),
    );

    gl.enableVertexAttribArray(0);
    if (checkGLError()) return panic("Buffer setup failed", .{});
    const vertexShaderSource: [:0]const u8 = @embedFile(
        "shaders/triangle.vs",
    );
    const fragmentShaderSource: [:0]const u8 = @embedFile(
        "shaders/triangle.fs",
    );
    const fragmentShaderSource2: [:0]const u8 = @embedFile(
        "shaders/triangle2.fs",
    );
    const vertexShader: gl.Uint = createShader(
        vertexShaderSource,
        gl.VERTEX_SHADER,
    );
    defer gl.deleteShader(vertexShader);
    const fragmentShader: gl.Uint = createShader(
        fragmentShaderSource,
        gl.FRAGMENT_SHADER,
    );
    const fragmentShader2: gl.Uint = createShader(
        fragmentShaderSource2,
        gl.FRAGMENT_SHADER,
    );
    defer gl.deleteShader(fragmentShader);
    const shaders = [_]gl.Uint{ vertexShader, fragmentShader };
    const shaderProgram: gl.Uint = createShaderProgram(&shaders);
    defer gl.deleteProgram(shaderProgram);
    const shaders2 = [_]gl.Uint{ vertexShader, fragmentShader2 };
    const shaderProgram2: gl.Uint = createShaderProgram(&shaders2);
    defer gl.deleteProgram(shaderProgram2);

    while (!glfw.Window.shouldClose(window)) {
        processInput(window);
        gl.useProgram(shaderProgram);
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);
        gl.useProgram(shaderProgram);
        gl.bindVertexArray(VAO_T1);
        gl.drawArrays(gl.TRIANGLES, 0, 3);
        gl.useProgram(shaderProgram2);
        gl.bindVertexArray(VAO_T2);
        gl.drawArrays(gl.TRIANGLES, 0, 3);
        if (checkGLError()) return panic("Shader program error", .{});

        window.swapBuffers();
        glfw.pollEvents();
    }
}
