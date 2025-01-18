const std = @import("std");
const builtin = @import("builtin");
const zopengl = @import("zopengl");
const print = std.debug.print;
const panic = std.debug.panic;
const gl = zopengl.bindings;
const isDebug = builtin.mode == .Debug;
const maxShaderSize = 20_000_00;

pub const Shader = struct {
    ID: gl.Uint,

    pub fn init(
        vertexShaderPath: [:0]const u8,
        fragmentShaderPath: [:0]const u8,
        allocator: std.mem.Allocator,
    ) Shader {
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

        const vertexShader = createShader(vertexShaderSource, gl.VERTEX_SHADER);
        defer gl.deleteShader(vertexShader);
        const fragmentShader = createShader(fragmentShaderSource, gl.FRAGMENT_SHADER);
        defer gl.deleteShader(fragmentShader);

        const shaderID = gl.createProgram();
        gl.attachShader(shaderID, vertexShader);
        gl.attachShader(shaderID, fragmentShader);
        gl.linkProgram(shaderID);

        if (isDebug) {
            var success: gl.Int = 0;
            gl.getProgramiv(shaderID, gl.LINK_STATUS, &success);
            if (success == 0) {
                var infoLog: [512]u8 = undefined;
                var logSize: gl.Int = 0;
                gl.getProgramInfoLog(shaderID, 512, &logSize, &infoLog);
                const i: usize = @intCast(logSize);
                print("ERROR::SHADER::PROGRAM::LINKING_FAILED\n{s}\n", .{infoLog[0..i]});
                return panic("Shader program error", .{});
            } else {
                var infoLog: [512]u8 = undefined;
                var logSize: gl.Int = 0;
                gl.getProgramInfoLog(shaderID, 512, &logSize, &infoLog);
                const i: usize = @intCast(logSize);
                print("INFO::SHADER::PROGRAM::LINKING_SUCCESS {d}\n{s}\n", .{ i, infoLog[0..i] });
            }
        }
        return Shader{ .ID = shaderID };
    }
    pub fn use() void {
        gl.useProgram(.ID);
    }
    pub fn setBool(name: []const u8, value: bool) void {
        gl.uniform1i(gl.getUniformLocation(.ID, name), @intFromBool(value));
    }
    pub fn setInt(name: []const u8, value: gl.Int) void {
        gl.uniform1i(gl.getUniformLocation(.ID, name), value);
    }
    pub fn setFloat(name: []const u8, value: gl.Float) void {
        gl.uniform1i(gl.getUniformLocation(.ID, name), value);
    }
    pub fn deinit() void {
        gl.deleteShader(.ID);
    }
};

pub fn readShaderFile(shaderPath: []const u8, maxSize: u64, allocator: std.mem.Allocator) [:0]const u8 {
    const cwd = std.fs.cwd();
    print("{s}\n", .{shaderPath});
    const fileStr = cwd.readFileAlloc(allocator, shaderPath, maxSize) catch |err| {
        panic("Error {?} \n", .{err});
    };
    defer allocator.free(fileStr);
    const nullTerminated = std.mem.Allocator.dupeZ(allocator, u8, fileStr) catch |err| {
        panic("Error:{?} \n", .{err});
    };
    return nullTerminated;
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
