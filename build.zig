const std = @import("std");
const Builder = std.build.Builder;

pub fn build(b: &Builder) void {
    const mode = b.standardReleaseOptions();
    const exe = b.addExecutable("../bin/c8dis", "src/c8d.zig");
    exe.setBuildMode(mode);

    // exe.linkSystemLibrary("winmm.dll");

    b.default_step.dependOn(&exe.step);
    b.installArtifact(exe);
}