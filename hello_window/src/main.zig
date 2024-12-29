const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");
const gl = zopengl.bindings;

fn frameBufferSizeCallback(
    _: *glfw.Window,
    width: gl.Int,
    height: gl.Int,
) callconv(.C) void {
    //Set the view port
    zopengl.bindings.viewport(0, 0, width, height);
}

/// Input processing
fn processInput(window: *glfw.Window) void {
    if (glfw.Window.getKey(window, glfw.Key.escape) == glfw.Action.press) {
        glfw.Window.setShouldClose(window, true);
    }
}

pub fn main() !void {
    const window_width = 800;
    const window_height = 600;
    const gl_major = 4;
    const gl_minor = 6;

    try glfw.init();
    defer glfw.terminate();
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
    defer glfw.Window.destroy(window);
    glfw.makeContextCurrent(window);

    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);
    gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.4, 0.8, 1.0 });
    gl.viewport(0, 0, window_width, window_height);
    _ = window.setFramebufferSizeCallback(frameBufferSizeCallback);

    while (!glfw.Window.shouldClose(window)) {
        processInput(window);
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(gl.COLOR_BUFFER_BIT);
        glfw.pollEvents();
        window.swapBuffers();
    }
}
