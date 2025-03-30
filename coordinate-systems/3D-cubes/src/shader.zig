const std = @import("std");
const builtin = @import("builtin");
const zopengl = @import("zopengl");

const print = std.debug.print;
const panic = std.debug.panic;
const gl = zopengl.wrapper;

const isDebug = builtin.mode == .Debug;
const maxShaderSize = 1000000;

pub const ShaderConstructor = struct {
    shaderProgram: gl.Program,

    pub fn deinit(self: ShaderConstructor) void {
        gl.deleteProgram(self.shaderProgram);
    }
    pub fn init(
        vertexShaderPath: [:0]const u8,
        fragmentShaderPath: [:0]const u8,
        allocator: std.mem.Allocator,
    ) ShaderConstructor {
        const vertexShaderSource = readShaderFile(
            vertexShaderPath,
            maxShaderSize,
            allocator,
        );
        defer allocator.free(vertexShaderSource);
        const fragmentShaderSource = readShaderFile(
            fragmentShaderPath,
            maxShaderSize,
            allocator,
        );
        defer allocator.free(fragmentShaderSource);

        const vertexShader = createShader(vertexShaderSource, .vertex, allocator);
        defer gl.deleteShader(vertexShader);
        const fragmentShader = createShader(fragmentShaderSource, .fragment, allocator);
        defer gl.deleteShader(fragmentShader);

        const shaderProgram = gl.createProgram();
        gl.attachShader(shaderProgram, vertexShader);
        gl.attachShader(shaderProgram, fragmentShader);
        gl.linkProgram(shaderProgram);

        if (isDebug) {
            const success = gl.getProgramiv(shaderProgram, .link_status);
            if (success == 0) {
                const buffer = allocator.alloc(u8, 512) catch |err|
                    {
                        panic("Error allocating buffer:{?}\n", .{err});
                    };
                defer allocator.free(buffer);
                const log = gl.getProgramInfoLog(shaderProgram, buffer);
                print("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{?s}\n", .{log});
            } else {
                const buffer = allocator.alloc(u8, 512) catch |err|
                    {
                        panic("Error allocating buffer:{?}\n", .{err});
                    };
                defer allocator.free(buffer);
                print("INFO::SHADER::PROGRAM::LINKING_SUCCESS\n", .{});
            }
        }
        return ShaderConstructor{ .shaderProgram = shaderProgram };
    }
    pub fn use(self: ShaderConstructor) void {
        gl.useProgram(self.shaderProgram);
    }

    //TODO:Implement

    // pub fn setBool(name: []const u8, value: bool) void {
    //     gl.uniform1i(gl.getUniformLocation(.ID, name), @intFromBool(value));
    // }
    pub fn setInt(
        slef: ShaderConstructor,
        name: []const u8,
        value: gl.Int,
        allocator: std.mem.Allocator,
    ) void {
        const sentiel_str: [:0]u8 = std.mem.Allocator.dupeZ(allocator, u8, name) catch |err| {
            panic("Error processing uniform name: {any}", .{err});
        };
        defer allocator.free(sentiel_str);
        const location = gl.getUniformLocation(slef.shaderProgram, sentiel_str) orelse {
            panic("Error accessing uniform location", .{});
        };
        gl.uniform1i(location, value);
    }
    // pub fn setFloat(name: []const u8, value: gl.Float) void {
    //     gl.uniform1i(gl.getUniformLocation(.ID, name), value);
    // }
    pub fn setMat4(
        self: ShaderConstructor,
        name: []const u8,
        value_ptr: *const [16]f32,
    ) void {
        var name_buffer = std.mem.zeroes([64]u8);
        const terminated_name = std.fmt.bufPrintZ(&name_buffer, "{s}", .{name}) catch {
            std.debug.print("Error: Uniform name '{s}' too long for buffer.\n", .{name});
            return;
        };
        const location: gl.UniformLocation = gl.getUniformLocation(
            self.shaderProgram,
            terminated_name,
        ) orelse {
            panic("Unifrom location not found'n", .{});
        };
        if (location.location == -1) {
            std.debug.print(
                \\Warning: Uniform '{s}' not found or inactive in shader program {}.
            , .{ name, self.program_id });
            return;
        }
        gl.uniformMatrix4fv(
            location,
            1,
            false,
            value_ptr,
        );
    }
};

pub fn readShaderFile(shaderPath: []const u8, maxSize: u64, allocator: std.mem.Allocator) [:0]const u8 {
    const cwd = std.fs.cwd();
    const fileStr = cwd.readFileAlloc(allocator, shaderPath, maxSize) catch |err| {
        panic("Error reading file: {?} \n", .{err});
    };
    defer allocator.free(fileStr);
    const nullTerminated = std.mem.Allocator.dupeZ(allocator, u8, fileStr) catch |err| {
        panic("Error copying file:{?} \n", .{err});
    };
    return nullTerminated;
}

fn createShader(
    shaderSource: [:0]const u8,
    shaderType: gl.ShaderType,
    allocator: std.mem.Allocator,
) gl.Shader {
    const shader = gl.createShader(shaderType);

    // Create one-element arrays for the source pointer and its length.
    const src_ptrs = &[_][*:0]const u8{shaderSource};
    const shaderSourceLen: u32 = @intCast(shaderSource.len);
    const src_lengths = &[_]u32{shaderSourceLen};

    // Set the shader source.
    gl.shaderSource(shader, src_ptrs[0..], src_lengths[0..]);

    // Compile the shader.
    gl.compileShader(shader);

    // Check for compilation errors.
    if (checkShaderError(shader, allocator)) {
        panic("Shader failed", .{});
    }

    return shader;
}

fn checkShaderError(
    shader: gl.Shader,
    allocator: std.mem.Allocator,
) bool {
    if (isDebug) {
        const success = gl.getShaderiv(shader, .compile_status);
        if (success == 0) {
            const buffer = allocator.alloc(u8, 512) catch |err|
                {
                    panic("Error:{?}\n", .{err});
                };
            defer allocator.free(buffer);
            const log = gl.getShaderInfoLog(shader, buffer);
            print("ERROR::SHADER::OPERATION_FAILED\n{?s}\n", .{log});
            return true;
        }
    }
    print("INFO::SHADER::OPERATION_SUCCESS\n", .{});
    return false;
}
