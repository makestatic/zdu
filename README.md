![ZDU](doc/assets/logo.jpg)

**ZDU** is a fast, multithreaded, cross-platform alternative to `du`, written in Zig. It recursively scans directories and reports files, directories, and total disk usage.

## Performance 

### Summary
ZDU scans directories **~3.34× faster** than GNU du on this target directory, while giving a full report of files, directories, and sizes.


### Benchmark
System Information:
- CPU: 4 cores
- Memory: 4 GB
- OS: Linux 6.2.1-aarch64 GNU/Linux

Commands:
- ZDU: `zdu . -v`
- GNU du: `du -h .`
- Target Directory: `.` (home directory)


| Metric             | **ZDU**       | **GNU du**     | Notes |
|-------------------|---------------|----------------|------|
| Total Size        | 1.21 GB       | 1.2 GB         | Slight differences due to block counting |
| Directories       | 8,337         | N/A            | ZDU counts natively |
| Files             | 43,590        | N/A            | ZDU counts natively |
| **Real Time**     | 15.1 s        | 50.484 s       | ZDU ~**3.34× faster** |
| CPU Time          | 7.773 s       | 11.298 s       | ZDU uses less CPU |
| I/O Bound         | ✅            | ✅             | Most of the time spent on disk operations |
| Ease of Reporting | High          | Low            | ZDU outputs a formatted report, du needs scripting |

### Key Takeaways
- **Speed:** ZDU is significantly faster for large directory trees.
- **Information:** ZDU provides directories, file counts, and sizes out-of-the-box.
- **Reporting:** ZDU produces a clean report; GNU du is minimal and needs extra commands (e.g. `find`) for full info.
- **Use Case:** ZDU for auditing or full reports; GNU du for simple size checks or lightweight scripts.

---

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
