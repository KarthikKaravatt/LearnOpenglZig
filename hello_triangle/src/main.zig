const std = @import("std");
const print = @import("std").debug.print;
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
    const gl = zopengl.bindings;
    const e = gl.getError();
    if (e != gl.NO_ERROR) {
        print("OpenGL Error: {d}\n", .{e});
        return true;
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
    // for tiling window manager
    glfw.windowHintTyped(.resizable, false);
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

    // Triangle with 3 points
    var vertices = [_]gl.Float{
        -0.5, -0.5, 0.0,
        0.5,  -0.5, 0.0,
        0.0,  0.5,  0.0,
    };

    // Setup vertex array object and vertex buffer object
    // Set to 0 as it's reserved in opengl (better than undefined)
    var VAO: gl.Uint = 0;
    var VBO: gl.Uint = 0;

    gl.genVertexArrays(1, &VAO);
    gl.genBuffers(1, &VBO);

    defer gl.deleteVertexArrays(1, &VAO);
    defer gl.deleteBuffers(1, &VBO);

    gl.bindVertexArray(VAO);
    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        vertices.len * @sizeOf(gl.Float),
        &vertices,
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
    defer gl.disableVertexAttribArray(0);

    if (builtin.mode == .Debug) {
        print("DEBUG\n", .{});
        if (hasGlError()) return;
    }

    // Compile vertex shader
    const vertexShaderSource: [:0]const u8 = @embedFile("shaders/triangle.vs");
    if (builtin.mode == .Debug)
        print("vertexShaderSource: {s}\n", .{vertexShaderSource.ptr});
    const vertexShader: gl.Uint = gl.createShader(gl.VERTEX_SHADER);
    defer gl.deleteShader(vertexShader);
    gl.shaderSource(
        vertexShader,
        1,
        &[_][*c]const u8{vertexShaderSource.ptr},
        null,
    );
    gl.compileShader(vertexShader);
    if (builtin.mode == .Debug) {
        var success: gl.Int = 0;
        gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            var infoLog: [512]u8 = undefined;
            var logSize: gl.Int = 0;
            gl.getShaderInfoLog(vertexShader, 512, &logSize, &infoLog);
            const i: usize = @intCast(logSize);
            print(
                "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n",
                .{infoLog[0..i]},
            );
            return;
        } else {
            var infoLog: [512]u8 = undefined;
            var logSize: gl.Int = 0;
            gl.getShaderInfoLog(vertexShader, 512, &logSize, &infoLog);
            const i: usize = @intCast(logSize);
            print(
                "INFO::SHADER::VERTEX::LINKING_SUCCESS\n{s}\n",
                .{infoLog[0..i]},
            );
        }
    }

    // Compile fragment shader
    const fragmentShaderSource: [:0]const u8 =
        @embedFile("shaders/triangle.fs");
    if (builtin.mode == .Debug)
        print(
            "fragmentShaderSource: {s}\n",
            .{fragmentShaderSource.ptr},
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
    if (builtin.mode == .Debug) {
        var success: gl.Int = 0;
        gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
        if (success == 0) {
            var infoLog: [512]u8 = undefined;
            var logSize: gl.Int = 0;
            gl.getShaderInfoLog(fragmentShader, 512, &logSize, &infoLog);
            const i: usize = @intCast(logSize);
            print(
                "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n",
                .{infoLog[0..i]},
            );
            return;
        } else {
            var infoLog: [512]u8 = undefined;
            var logSize: gl.Int = 0;
            gl.getShaderInfoLog(vertexShader, 512, &logSize, &infoLog);
            const i: usize = @intCast(logSize);
            print(
                "INFO::SHADER::FRAGMENT::LINKING_SUCCESS\n{s}\n",
                .{infoLog[0..i]},
            );
        }
    }

    // Create shader program
    const shaderProgram: gl.Uint = gl.createProgram();
    defer gl.deleteProgram(shaderProgram);
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    if (builtin.mode == .Debug)
        if (hasGlError()) return;
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
    if (builtin.mode == .Debug)
        if (hasGlError()) return;

    while (!glfw.Window.shouldClose(window)) {
        processInput(window);
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // Draw the triangle
        gl.useProgram(shaderProgram);
        if (builtin.mode == .Debug)
            if (hasGlError()) return;
        gl.bindVertexArray(VAO);
        if (builtin.mode == .Debug)
            if (hasGlError()) return;
        gl.drawArrays(gl.TRIANGLES, 0, 3);
        if (builtin.mode == .Debug)
            if (hasGlError()) return;

        window.swapBuffers();
        glfw.pollEvents();
    }
}
