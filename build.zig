const std = @import("std");
const Builder = std.build.Builder;

pub const Executable = struct {
    output: []const u8,
    input: []const u8,
};

const executables = []Executable {
    Executable { .output = "../bin/c8dasm", .input = "src/c8dasm.zig"},
    Executable { .output = "../bin/c8run", .input = "src/c8run.zig"}
};

pub fn build(b: *Builder) !void {
    const mode = b.standardReleaseOptions();
    try b.makePath("bin");

    for (executables) |file| {
        const exe = b.addExecutable(file.output, file.input);
        exe.setBuildMode(mode);
        b.default_step.dependOn(&exe.step);
        b.installArtifact(exe);
    }
}
