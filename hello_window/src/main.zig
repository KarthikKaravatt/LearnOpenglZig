const std = @import("std");
const builtin = @import("builtin");
const glfw = @import("zglfw");
const zopengl = @import("zopengl");

/// Resize frame buffer when window size changes
// callconv specifies the calling convention of the function
// It allows the function to interface with other languages
// In this case we need to interface with c
// The opengl library is written in c so this callback needs to work with C
fn frameBufferSizeCallback(
    _: *glfw.Window,
    width: i32,
    height: i32,
) callconv(.c) void {
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
    try glfw.init();
    const window_width = 800;
    const window_height = 600;
    const gl_major = 4;
    const gl_minor = 0;
    // Window hints are settings for the window set before initialisation
    // Set the openGL version to 4.0
    glfw.windowHintTyped(.context_version_major, gl_major);
    glfw.windowHintTyped(.context_version_minor, gl_minor);
    // Must use forward compat for macos
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
    // Load function pointers for opengl
    try zopengl.loadCoreProfile(glfw.getProcAddress, gl_major, gl_minor);
    const gl = zopengl.bindings;
    gl.clearBufferfv(gl.COLOR, 0, &[_]f32{ 0.2, 0.4, 0.8, 1.0 });
    gl.viewport(0, 0, window_width, window_height);
    // Register a callback to resize the viewport when the window is resized
    _ = window.setFramebufferSizeCallback(frameBufferSizeCallback);
    while (!glfw.Window.shouldClose(window)) {
        processInput(window);
        // Choose the color for the buffer
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        // Clear the screen with a buffer bit
        gl.clear(gl.COLOR_BUFFER_BIT);
        // Check for events e.g. mouse movement or key input
        glfw.pollEvents();
        // Swap the colour buffer that is used in rendering
        // Single buffer drawing is done pixel by pixel
        // Causes flickering issues
        // Double buffering is used to fix this
        // Front buffer draws to the screen
        // All rendering commands go to the back buffer
        // We swap the back buffer and front buffer so image displayed so the
        // user does to see the incomplete drawing
        window.swapBuffers();
    }
    glfw.terminate();
}
