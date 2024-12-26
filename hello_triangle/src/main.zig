const std = @import("std");
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

pub fn main() !void {
    const window_width = 800;
    const window_height = 600;
    const gl_major = 4;
    const gl_minor = 0;

    //GLFW initialisation
    try glfw.init();
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
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
    var vertices: [9]gl.Float = [9]gl.Float{
        -0.7, -0.5, 0.0,
        0.7,  -0.5, 0.0,
        0.0,  0.7,  0.0,
    };

    // Setup vertex array object and vertex buffer object
    var VAO: gl.Uint = undefined;
    gl.genVertexArrays(1, &VAO);
    gl.bindVertexArray(VAO);
    var VBO: gl.Uint = undefined;
    gl.genBuffers(1, &VBO);
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
        null,
    );
    gl.enableVertexAttribArray(0);
    var e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("error: {d}\n", .{e});
        return;
    }

    // Compile vertex shader
    const vertexShaderSource: [:0]const u8 = @embedFile("shaders/triangle.vs");
    std.debug.print("vertexShaderSource: {s}\n", .{vertexShaderSource.ptr});
    const vertexShader: gl.Uint = gl.createShader(gl.VERTEX_SHADER);
    defer gl.deleteShader(vertexShader);
    gl.shaderSource(
        vertexShader,
        1,
        &[_][*c]const u8{vertexShaderSource.ptr},
        null,
    );
    gl.compileShader(vertexShader);
    var success: gl.Int = 0;
    gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getShaderInfoLog(vertexShader, 512, &logSize, &infoLog);
        const i: usize = @intCast(logSize);
        std.debug.print(
            "ERROR::SHADER::VERTEX::COMPILATION_FAILED\n{s}\n",
            .{infoLog[0..i]},
        );
        return;
    } else {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getShaderInfoLog(vertexShader, 512, &logSize, &infoLog);
        const i: usize = @intCast(logSize);
        std.debug.print(
            "INFO::SHADER::VERTEX::LINKING_SUCCESS\n{s}\n",
            .{infoLog[0..i]},
        );
    }

    // Compile fragment shader
    const fragmentShaderSource: [:0]const u8 =
        @embedFile("shaders/triangle.fs");
    std.debug.print(
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
    gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getShaderInfoLog(fragmentShader, 512, &logSize, &infoLog);
        const i: usize = @intCast(logSize);
        std.debug.print(
            "ERROR::SHADER::FRAGMENT::COMPILATION_FAILED\n{s}\n",
            .{infoLog[0..i]},
        );
        return;
    } else {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getShaderInfoLog(vertexShader, 512, &logSize, &infoLog);
        const i: usize = @intCast(logSize);
        std.debug.print(
            "INFO::SHADER::FRAGMENT::LINKING_SUCCESS\n{s}\n",
            .{infoLog[0..i]},
        );
    }

    // Create shader program
    const shaderProgram: gl.Uint = gl.createProgram();
    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("error: {d}\n", .{e});
        return;
    }
    gl.linkProgram(shaderProgram);
    gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
    if (success == 0) {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getProgramInfoLog(shaderProgram, 512, &logSize, &infoLog);
        const i: usize = @intCast(logSize);
        std.debug.print("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog[0..i]});
        return;
    } else {
        var infoLog: [512]u8 = undefined;
        var logSize: gl.Int = 0;
        gl.getProgramInfoLog(shaderProgram, 512, &logSize, &infoLog);
        const i: usize = @intCast(logSize);
        std.debug.print("INFO::SHADER::PROGRAM::LINKING_SUCCESS {d}\n{s}\n", .{ i, infoLog[0..i] });
    }
    e = gl.getError();
    if (e != gl.NO_ERROR) {
        std.debug.print("error: {d}\n", .{e});
        return;
    }
    std.debug.print("program set up \n", .{});

    while (!glfw.Window.shouldClose(window)) {
        processInput(window);
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        // Draw the triangle
        gl.useProgram(shaderProgram);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return;
        }
        gl.bindVertexArray(VAO);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return;
        }
        gl.drawArrays(gl.TRIANGLES, 0, 3);
        e = gl.getError();
        if (e != gl.NO_ERROR) {
            std.debug.print("error: {d}\n", .{e});
            return;
        }

        window.swapBuffers();
        glfw.pollEvents();
    }

    glfw.terminate();
}
