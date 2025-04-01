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
    gl.enable(.depth_test);

    const vertices = [_]f32{
        -0.5, -0.5, -0.5, 0.0, 0.0,
        0.5,  -0.5, -0.5, 1.0, 0.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,

        -0.5, 0.5,  -0.5, 0.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 0.0,
        -0.5, -0.5, 0.5,  0.0, 0.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,

        0.5,  0.5,  0.5,  1.0, 1.0,
        0.5,  0.5,  0.5,  1.0, 1.0,
        -0.5, 0.5,  0.5,  0.0, 1.0,
        -0.5, -0.5, 0.5,  0.0, 0.0,

        -0.5, 0.5,  0.5,  1.0, 0.0,
        -0.5, 0.5,  -0.5, 1.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,

        -0.5, -0.5, 0.5,  0.0, 0.0,
        -0.5, 0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,

        0.5,  -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, 0.5,  0.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,

        -0.5, -0.5, -0.5, 0.0, 1.0,
        0.5,  -0.5, -0.5, 1.0, 1.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,
        0.5,  -0.5, 0.5,  1.0, 0.0,

        -0.5, -0.5, 0.5,  0.0, 0.0,
        -0.5, -0.5, -0.5, 0.0, 1.0,
        -0.5, 0.5,  -0.5, 0.0, 1.0,
        0.5,  0.5,  -0.5, 1.0, 1.0,

        0.5,  0.5,  0.5,  1.0, 0.0,
        0.5,  0.5,  0.5,  1.0, 0.0,
        -0.5, 0.5,  0.5,  0.0, 0.0,
        -0.5, 0.5,  -0.5, 0.0, 1.0,
    };

    const vertex_data_size = @sizeOf(@TypeOf(vertices));
    // Opengl works with raw bytes
    const vertices_bytes: []const u8 = std.mem.sliceAsBytes(vertices[0..]);
    const vertices_byte_ptr: ?[*]const u8 = vertices_bytes.ptr;

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
        vertices_byte_ptr,
        .static_draw,
    );

    const vertexCoordLocation: gl.VertexAttribLocation = .{ .location = 0 };
    const vertexTextureLocation: gl.VertexAttribLocation = .{ .location = 1 };
    gl.vertexAttribPointer(
        vertexCoordLocation,
        3,
        .float,
        gl.FALSE,
        5 * @sizeOf(gl.Float),
        0,
    );
    gl.enableVertexAttribArray(vertexCoordLocation);

    gl.vertexAttribPointer(
        vertexTextureLocation,
        2,
        .float,
        gl.FALSE,
        5 * @sizeOf(gl.Float),
        3 * @sizeOf(gl.Float),
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
    shader.use();
    defer shader.deinit();
    if (hasGlError()) return;
    shader.setInt("texture1", 0, gpa);
    shader.setInt("texture2", 1, gpa);
    const movement_vec = zm.f32x4(0, 0, 0, 0);
    var view = zm.identity();
    var time_last = glfw.getTime();
    while (!window.shouldClose()) {
        const time_now = glfw.getTime();
        const delta_time = time_now - time_last;
        time_last = time_now;
        view = processInput(window, movement_vec, view, @floatCast(delta_time));
        gl.clearColor(0.2, 0.3, 0.3, 1.0);
        gl.clear(.{ .color = true, .depth = true });
        if (hasGlError()) return;
        gl.activeTexture(.texture_0);
        gl.bindTexture(.texture_2d, texture_1);
        gl.activeTexture(.texture_1);
        gl.bindTexture(.texture_2d, texture_2);
        shader.use();
        var projection = zm.identity();

        // view = zm.mul(view, zm.translationV(movement_vec));
        projection = zm.perspectiveFovRhGl(math.degreesToRadians(45.0), 800.0 / 600.0, 0.1, 100.0);

        const viewLoc = gl.getUniformLocation(
            shader.shaderProgram,
            "view",
        ) orelse {
            panic("view uniform not found", .{});
        };
        const porjectionLoc = gl.getUniformLocation(
            shader.shaderProgram,
            "projection",
        ) orelse {
            panic("projection uniform not found", .{});
        };

        gl.uniformMatrix4fv(viewLoc, 1, false, &zm.matToArr(view));
        gl.uniformMatrix4fv(porjectionLoc, 1, false, &zm.matToArr(projection));

        var model = zm.identity();
        gl.bindVertexArray(vao);
        const time: f32 = @floatCast(glfw.getTime());
        const current_angle = std.math.degreesToRadians(50) * (time * 0.2);
        const rotation_axis = zm.f32x4(0.0, 1.0, 0.0, 0.0);
        const rotation_matrix = zm.matFromAxisAngle(rotation_axis, current_angle);
        model = zm.mul(model, zm.translationV(zm.f32x4(0, 0, 0, 0)));
        model = zm.mul(model, rotation_matrix);
        shader.setMat4("model", &zm.matToArr(model));
        gl.drawArrays(.triangles, 0, 36);
        // }

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
    const window_height = 600;
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

pub fn processInput(window: *glfw.Window, curr_pos: zm.Vec, cur_view: zm.Mat, delta_time: f32) zm.Mat {
    var translation_vector = zm.f32x4(0, 0, 0, 0);
    var rotation_angles = zm.f32x4(0, 0, 0, 0);
    var new_view = cur_view;
    const movement_speed = 2;
    const rotation_speed = 60;

    if (window.getKey(.escape) == .press) {
        window.setShouldClose(true);
        return new_view;
    }

    // Handle translation
    if (window.getKey(.w) == .press) {
        translation_vector[2] += movement_speed;
    } else if (window.getKey(.s) == .press) {
        translation_vector[2] -= movement_speed;
    }

    if (window.getKey(.a) == .press) {
        translation_vector[0] += movement_speed;
    } else if (window.getKey(.d) == .press) {
        translation_vector[0] -= movement_speed;
    }

    if (window.getKey(.q) == .press) {
        translation_vector[1] -= movement_speed;
    } else if (window.getKey(.e) == .press) {
        translation_vector[1] += movement_speed;
    }

    // Handle rotation
    if (window.getKey(.k) == .press) {
        rotation_angles[0] += math.degreesToRadians(rotation_speed);
    } else if (window.getKey(.i) == .press) {
        rotation_angles[0] -= math.degreesToRadians(rotation_speed);
    }

    if (window.getKey(.j) == .press) {
        rotation_angles[1] -= math.degreesToRadians(rotation_speed);
    } else if (window.getKey(.l) == .press) {
        rotation_angles[1] += math.degreesToRadians(rotation_speed);
    }

    // Only update the view if there's any movement or rotation
    const total_speed = @abs(translation_vector[0]) + @abs(translation_vector[1]) + @abs(translation_vector[2]) + @abs(translation_vector[3]);
    const total_rotation_speed = @abs(rotation_angles[0]) + @abs(rotation_angles[1]);

    if (total_speed != 0 or total_rotation_speed != 0) {
        const final_pos = zm.f32x4(
            (curr_pos[0] + translation_vector[0]) * delta_time,
            (curr_pos[1] + translation_vector[1]) * delta_time,
            (curr_pos[2] + translation_vector[2]) * delta_time,
            (curr_pos[3] + translation_vector[3]) * delta_time,
        );

        // Apply transformations:  Rotation then Translation
        new_view = zm.mul(new_view, zm.rotationX(rotation_angles[0] * delta_time));
        new_view = zm.mul(new_view, zm.rotationY(rotation_angles[1] * delta_time));
        new_view = zm.mul(new_view, zm.translationV(final_pos));
    }

    return new_view;
}
