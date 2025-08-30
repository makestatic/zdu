![ZDU](doc/assets/logo.jpg)

**ZDU** is a fast, multithreaded, cross-platform alternative to `du`, written in Zig. It recursively scans directories and reports files, directories, and total disk usage.

# Performance Comparison

System Information:
- CPU: 4 cores
- Memory: 4 GB
- OS: Linux 6.2.1-aarch64 GNU/Linux

Commands:
- ZDU: `zdu . -v`
- GNU du: `du -h .`
- Target Directory: `.` (home directory)

Metric                 | ZDU       | GNU du   | Relative Performance
-----------------------|-----------|----------|-------------------
Directories            | 8,475     | N/A      | -
Files                  | 43,889    | N/A      | -
Total Size             | 2.0 GB    | 1.9 GB   | -
Wall-clock Time        | 21.08 s   | 64.00 s  | ~3x faster
User CPU Time          | 0.66 s    | 0.90 s   | ~27% faster
Sys CPU Time           | 10.60 s   | 8.80 s   | ~20% slower
Total CPU Time         | 11.26 s   | 9.70 s   | ~16% slower
Overall                | 32.35 s   | 73.70 s  | ~2.28x faster


## Installation

Download from the pre-built static binaries [page](https://github.com/makestatic/zdu/releases), for Linux, FreeBSD, macOS, and Windows.

### via installation script
```bash
curl -sSL https://raw.githubusercontent.com/makestatic/zdu/master/scripts/install.sh | bash
```

### manual installation 
```bash
$ git clone https://github.com/makestatic/zdu.git
$ cd zdu
$ make
$ sudo make install
```

## Usage
```bash
zdu [path] [options]

  OPTIONS:
      -ex=<exclude>   exclude a directory (can be specified multiple times)
      -v, --verbose   verbose output (may impact performance)
      -q, --quiet     quiet output (default)
      --v,--version   print version
      -h, --help      print this help message

  EXAMPLES:
      zdu /home/user  # use defaults
      zdu /home/user -ex=build
      zdu /home/user -ex=build -ex=dist
      zdu /home/user -ex=build -ex=dist --verbose
```

Example:

`.`: zdu project directory.

```bash
$ zdu . --verbose
```

Output:
```text
                        ...
79.83 KB  ./.zig-cache/o/5d4c2eba87f5ecf2d03e319db48cd17f/zdu_zc
69.73 KB  ./.zig-cache/o/e5c723dacc4a030a4a2b852750823cad/zdu
272.25 KB ./.zig-cache/o/26283bde56878605b8de1efba924ae01/zdu_zc
21 B      ./.zig-cache/o/c7a3e02a9b0d3b08f8dc146729a2bc14/cimpor
271.00 KB ./.zig-cache/o/26283bde56878605b8de1efba924ae01/zdu.ex
13.30 KB  ./.zig-cache/o/c7a3e02a9b0d3b08f8dc146729a2bc14/cimpor
================= ZDU Report =================
| Entry Path   | .
| Directories  | 182
| Files        | 365
| Total Size   | 1,064,806,639 (1015.48 MB)
==============================================
```

## License
ZDU is licensed under the [GNU General Public License v3 or later](https://www.gnu.org/licenses/gpl-3.0.en.html).
