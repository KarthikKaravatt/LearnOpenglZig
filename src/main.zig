const std = @import("std");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");

fn frameBufferSizeCallback(_: *glfw.Window, width: i32, height: i32) callconv(.c) void {
    zopengl.bindings.viewport(0, 0, width, height);
}

fn processInput(window: *glfw.Window) void {
    if (glfw.Window.getKey(window, glfw.Key.escape) == glfw.Action.press) {
        glfw.Window.setShouldClose(window, true);
    }
}

pub fn main() !void {
    try glfw.init();
    const window_width = 800;
    const window_height = 600;
    const gl_major = 4;
    const gl_minor = 0;
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    glfw.windowHintTyped(.opengl_profile, .opengl_core_profile);
    const window = try glfw.Window.create(window_width, window_height, "LearnOpenGL", null);
    glfw.makeContextCurrent(window);
    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);
    const gl = zopengl.bindings;
    gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.4, 0.8, 1.0 });
    gl.viewport(0, 0, window_width, window_height);
    _ = window.setFramebufferSizeCallback(frameBufferSizeCallback);
    while (!glfw.Window.shouldClose(window)) {
        processInput(window);
        window.swapBuffers();
        glfw.pollEvents();
    }
    glfw.terminate();
}
