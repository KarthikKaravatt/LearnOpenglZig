const std = @import("std");
const builtin = @import("builtin");

const glfw = @import("zglfw");
const zopengl = @import("zopengl");

fn frameBufferSizeCallback(
    _: *glfw.Window,
    width: i32,
    height: i32,
) callconv(.c) void {
    zopengl.bindings.viewport(0, 0, width, height);
}

fn processInput(window: *glfw.Window) void {
    if (glfw.Window.getKey(window, glfw.Key.escape) == glfw.Action.press) {
        glfw.Window.setShouldClose(window, true);
    }
}

pub fn main() !void {
    const window_width = 800;
    const window_height = 600;
    const gl_major = 3;
    const gl_minor = 3;
    const vertexShaderSource = &[_][*:0]const u8{
        "#version 330 core\n",
        "layout (location = 0) in vec3 aPos;\n",
        "void main()\n",
        "{\n",
        "gl_Position = vec4(aPos.x,aPos.y,aPos.z,1.0);\n",
        "}",
    };
    const fragmentShaderSource = &[_][*:0]const u8{
        "#version 330 core\n",
        "out vec4 FragColor;\n",
        "void main()\n",
        "{\n",
        "FragColor = vec4(0.1f,0.5f,0.2f,1.0f);\n",
        "}",
    };
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
    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);
    const gl = zopengl.bindings;
    _ = window.setFramebufferSizeCallback(frameBufferSizeCallback);

    const vertexShader = gl.createShader(gl.VERTEX_SHADER);

    gl.shaderSource(vertexShader, 1, vertexShaderSource, null);
    gl.compileShader(vertexShader);

    var success: i32 = 0;
    var infoLog: [512]u8 = [_]u8{0} ** 512;
    gl.getShaderiv(vertexShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        std.debug.print("Shader has not compiled\n", .{});
        gl.getShaderInfoLog(vertexShader, 512, 0, &infoLog);
        std.debug.print("{s}", .{infoLog});
    }

    const fragmentShader = gl.createShader(gl.FRAGMENT_SHADER);
    gl.shaderSource(fragmentShader, 1, fragmentShaderSource, null);
    gl.compileShader(fragmentShader);

    gl.getShaderiv(fragmentShader, gl.COMPILE_STATUS, &success);
    if (success == 0) {
        gl.getShaderInfoLog(fragmentShader, 512, 0, &infoLog);
        std.debug.print("{s}", .{infoLog});
    }

    const shaderProgram = gl.createProgram();

    gl.attachShader(shaderProgram, vertexShader);
    gl.attachShader(shaderProgram, fragmentShader);
    gl.linkProgram(shaderProgram);

    gl.getProgramiv(shaderProgram, gl.LINK_STATUS, &success);
    if (success == 0) {
        gl.getProgramInfoLog(shaderProgram, 512, 0, &infoLog);
        std.debug.print("{s}\n", .{infoLog});
    }
    gl.deleteShader(vertexShader);
    gl.deleteShader(fragmentShader);

    const vertices = [_]f32{
        -0.5, -0.5, 0,
        0.5,  -0.5, 0,
        0.0,  0.5,  0,
    };
    var VBO: c_uint = undefined;
    var VAO: c_uint = undefined;

    gl.genVertexArrays(1, &VAO);

    gl.genBuffers(1, &VBO);

    gl.bindVertexArray(VAO);

    gl.bindBuffer(gl.ARRAY_BUFFER, VBO);
    gl.bufferData(
        gl.ARRAY_BUFFER,
        @sizeOf(@TypeOf(f32)) * vertices.len,
        &vertices,
        gl.STATIC_DRAW,
    );

    gl.vertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * @sizeOf(f32), null);
    gl.enableVertexAttribArray(0);

    gl.bindBuffer(gl.ARRAY_BUFFER, 0);
    gl.bindVertexArray(0);

    while (!glfw.Window.shouldClose(window)) {
        processInput(window);
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);

        gl.useProgram(shaderProgram);
        gl.bindVertexArray(VAO);
        gl.drawArrays(gl.TRIANGLES, 0, 3);

        window.swapBuffers();
        glfw.pollEvents();
    }
    gl.deleteVertexArrays(1, &VAO);
    gl.deleteBuffers(1, &VBO);
    gl.deleteProgram(shaderProgram);

    glfw.terminate();
}
