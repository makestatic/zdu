/// Copyright (C) 2025 makestatic; 
/// Licensed under GPLv3+ <https://www.gnu.org/licenses/>

const std = @import("std");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("usage: zdu <path>\n", .{});
        std.process.exit(1);
    }

    const path = args[1];

    var zdu = ZDU.init(allocator);
    defer zdu.deinit();

    try zdu.cycle(path);

    std.debug.print(
        \\ ================= ZDU Report =================
        \\    Entry Path  : `{s}`
        \\ ----------------------------------------------
        \\    Directory   : {d}
        \\    File        : {d}
        \\    Total Size  : {d} bytes / {d} mb
        \\ ==============================================
    , .{
        path,
        zdu.dirs_count.load(.monotonic),
        zdu.files_count.load(.monotonic),
        zdu.size.load(.monotonic),
        zdu.size.load(.monotonic) / 1024 / 1024, // bytes -> mb
    });
}

const ZDU = struct {
    allocator: std.mem.Allocator,
    pool: std.Thread.Pool = undefined,
    wg: std.Thread.WaitGroup = .{},
    dirs_count: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
    files_count: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
    size: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),

    pub fn init(allocator: std.mem.Allocator) ZDU {
        return ZDU{ .allocator = allocator };
    }
    pub fn deinit(self: *ZDU) void {
        self.pool.deinit();
    }

    pub fn cycle(self: *ZDU, base_path: []const u8) !void {
        try self.pool.init(.{
            .allocator = self.allocator,
            .n_jobs = std.Thread.getCpuCount() catch 8,
        });
        // duplicate the base path and spawn the root job
        const root = try std.mem.Allocator.dupe(self.allocator, u8, base_path);
        self.pool.spawnWg(&self.wg, processDir, .{ self, root });
        // wait for all jobs to finish before exiting
        self.wg.wait();
    }
};

// Worker owns `path` and must free it.
fn processDir(zdu: *ZDU, path: []u8) void {
    defer zdu.allocator.free(path);

    // open `path` as a directory
    var dir = std.fs.cwd().openDir(path, .{
        .access_sub_paths = true,
        .iterate = true,
    }) catch return;
    defer dir.close();

    // increment the directory count
    _ = zdu.dirs_count.fetchAdd(1, .monotonic);

    // iterate over the directory
    var it = dir.iterate();
    while (it.next() catch null) |entry| {
        // if it is a directory, spawn a new job
        // if it is a file, process
        if (entry.kind == .directory) {
            // allocate a new owned path for the child job
            const full_path = std.fs.path.join(zdu.allocator, &.{ path, entry.name }) catch continue;
            // spawn a new job
            zdu.pool.spawnWg(&zdu.wg, processDir, .{ zdu, full_path });
        } else if (entry.kind == .file) {
            const st = dir.statFile(entry.name) catch continue;
            // increment the file count
            _ = zdu.files_count.fetchAdd(1, .monotonic);
            // increment the size
            _ = zdu.size.fetchAdd(st.size, .monotonic);
            {
                const full_path = std.fs.path.join(zdu.allocator, &.{ path, entry.name }) catch continue;
                defer zdu.allocator.free(full_path);
                std.debug.print("{s}\n", .{full_path});
            }
        }
    }
}
