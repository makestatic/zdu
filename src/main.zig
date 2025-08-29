// zdu — fast disk usage scanner
// licensed under GPLv3+

const std = @import("std");

pub const VERSION = "15.2";
const usage = @embedFile("usage.txt");

/// system info
const TargetInfo = struct {
    os: []const u8,
    arch: []const u8,

    pub fn init() TargetInfo {
        const target = @import("builtin").target;

        const os = switch (target.os.tag) {
            .windows => "Windows",
            .linux => "Linux",
            .macos => "macOS",
            .freebsd => "FreeBSD",
            else => "Unknown",
        };

        const arch = switch (target.cpu.arch) {
            .x86_64 => "x86_64",
            .aarch64 => "aarch64",
            else => "Unknown",
        };

        return TargetInfo{ .os = os, .arch = arch };
    }
};

const ParsedArgs = struct {
    opts: OPTIONS,
    exclude: std.ArrayList([]const u8),
};

const OPTIONS = struct {
    verbose: bool = false,
    quiet: bool = false,
    help: bool = false,
    version: bool = false,
};

/// Parse passed arguments
fn parseArgs(args: []const []const u8, allocator: std.mem.Allocator) !ParsedArgs {
    var opts = OPTIONS{};
    var exclude = try std.ArrayList([]const u8).initCapacity(allocator, 8);
    defer exclude.deinit(allocator);

    for (args[1..]) |arg| {
        if (std.mem.startsWith(u8, arg, "-ex=")) {
            try exclude.append(allocator, arg[4..]);
            continue;
        }

        if (std.mem.eql(u8, arg, "-v") or std.mem.eql(u8, arg, "--verbose")) {
            opts.verbose = true;
        } else if (std.mem.eql(u8, arg, "-q") or std.mem.eql(u8, arg, "--quiet")) {
            opts.quiet = true;
        } else if (std.mem.eql(u8, arg, "-h") or std.mem.eql(u8, arg, "--help")) {
            opts.help = true;
        } else if (std.mem.eql(u8, arg, "--version") or std.mem.eql(u8, arg, "--v")) {
            opts.version = true;
        } else {
            if (std.mem.eql(u8, arg, args[0])) continue;
            if (std.mem.eql(u8, arg, args[1])) continue;

            return error.UnknownOption;
        }
    }

    return ParsedArgs{ .opts = opts, .exclude = exclude };
}

/// Main struct managing threads and counts
const ZDU = struct {
    allocator: std.mem.Allocator,
    pool: std.Thread.Pool = undefined,
    wg: std.Thread.WaitGroup = .{},
    dirs_count: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
    files_count: std.atomic.Value(usize) = std.atomic.Value(usize).init(0),
    size: std.atomic.Value(u64) = std.atomic.Value(u64).init(0),

    pub fn init(allocator: std.mem.Allocator) !ZDU {
        return ZDU{ .allocator = allocator };
    }

    /// Deinitialize pool
    pub fn deinit(self: *ZDU) void {
        self.pool.deinit();
    }

    /// Start directory traversal
    pub fn cycle(self: *ZDU, base_path: []const u8, exs: []const []const u8, opts: OPTIONS) !void {
        // Init thread pool
        try self.pool.init(.{
            .allocator = self.allocator,
            .n_jobs = std.Thread.getCpuCount() catch 8,
        });
        // Spawn root directory
        const root = try std.mem.Allocator.dupe(self.allocator, u8, base_path);
        self.pool.spawnWg(&self.wg, processDir, .{ self, root, exs, opts });
        // Wait for pool to finish before exiting
        self.wg.wait();
    }
};

/// Worker function; spawns recursively
fn processDir(zdu: *ZDU, path: []u8, exs: []const []const u8, opts: OPTIONS) void {
    defer zdu.allocator.free(path);

    var dir = std.fs.cwd().openDir(path, .{
        .access_sub_paths = true,
        .iterate = true,
    }) catch return;
    defer dir.close();

    var local_dirs: usize = 0;
    var local_files: usize = 0;
    var local_size: u64 = 0;
    local_dirs += 1;

    var it = dir.iterate();
    while (it.next() catch null) |entry| {
        if (entry.kind == .directory) {
            var skip = false;
            for (exs) |ex| if (std.mem.eql(u8, entry.name, ex)) {
                skip = true;
                break;
            };
            // Skip if excluded
            if (skip) continue;
            local_dirs += 1;

            const full_path = std.fs.path.join(zdu.allocator, &.{ path, entry.name }) catch continue;

            for (exs) |ex| if (std.mem.eql(u8, full_path, ex)) {
                zdu.allocator.free(full_path);
                skip = true;
                break;
            };
            // Skip if excluded; absolute path
            if (skip) continue;

            // Spawn child directory
            zdu.pool.spawnWg(&zdu.wg, processDir, .{ zdu, full_path, exs, opts });
        } else {
            // Process file
            const st = dir.statFile(entry.name) catch continue;
            local_files += 1;
            local_size += st.size;

            // Hot print if verbose
            if (opts.verbose) {
                const full_path = std.fs.path.join(zdu.allocator, &.{ path, entry.name }) catch continue;
                defer zdu.allocator.free(full_path);
                std.debug.print("{d}B {s}\n", .{ st.size, full_path });
            }
        }
    }

    // Push local counts
    _ = zdu.dirs_count.fetchAdd(local_dirs, .monotonic);
    _ = zdu.files_count.fetchAdd(local_files, .monotonic);
    _ = zdu.size.fetchAdd(local_size, .monotonic);
}

/// Main entry
pub fn main() !void {
    // Init at compile-time
    const target = TargetInfo.init();

    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer std.debug.assert(gpa.deinit() == .ok);
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("{s}", .{usage});
        std.process.exit(1);
    }

    const path = args[1];
    const parsed = parseArgs(args, allocator) catch |err| {
        std.debug.print("[ERROR]: {s}\n\n{s}", .{ @errorName(err), usage });
        std.process.exit(1);
    };
    const opts = parsed.opts;
    const exclude = parsed.exclude;

    if (opts.help) {
        std.debug.print("{s}", .{usage});
        std.process.exit(0);
    }

    if (opts.version) {
        std.debug.print("ZDU v{s} [{s}/{s}]\n", .{ VERSION, target.os, target.arch });
        std.process.exit(0);
    }

    var zdu = try ZDU.init(allocator);
    defer zdu.deinit();

    try zdu.cycle(path, exclude.items, opts);

    const size = zdu.size.load(.monotonic);

    std.debug.print(
        \\================= ZDU Report =================
        \\| Entry Path   | {s}
        \\| Directories  | {d}
        \\| Files        | {d}
        \\| Total Size   | {d} BYTES | {d} MB
        \\==============================================
    , .{
        path,
        zdu.dirs_count.load(.monotonic),
        zdu.files_count.load(.monotonic),
        size,
        size / 1024 / 1024,
    });
}
