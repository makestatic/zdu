![ZDU](doc/assets/logo.jpg)

**ZDU** is a fast, multithreaded, cross-platform alternative to `du`, written in Zig. It recursively scans directories and reports files, directories, and total disk usage.

### Performance

| Metric             | ZDU           | du (GNU)     |
|-------------------|---------------|-------------|
| Command Used       | `zdu . -h`    | `du -h .`   |
| Directories        | 10,303        | implicit    |
| Files              | 37,302        | implicit    |
| Total Size         | 2.0 GB        | 1.9 GB      |
| Wall-clock Time    | 31 s          | 64 s        |
| User CPU Time      | 0.42 s        | 0.90 s      |
| Sys Time           | 7.8 s         | 8.8 s       |
| Performance        | 206% Faster   | ...         |


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
```bash
# current working directory
$ zdu . --verbose
```

Output:
```text
                        ...
./.zig-cache/o/9f7280af6858074430ef67b2128d12e3/build_zcu.o
./.zig-cache/o/aee36d8c5c7ccba1fb65caff314409d2/zdu_zcu.o
./.zig-cache/o/9f7280af6858074430ef67b2128d12e3/build
./.zig-cache/o/aee36d8c5c7ccba1fb65caff314409d2/zdu
./.zig-cache/o/bbaed4b8a94d4cfcc89cddb1634917f2/build_zcu.o
./.zig-cache/o/bbaed4b8a94d4cfcc89cddb1634917f2/build
================= ZDU Report =================
| Entry Path   | .
| Directories  | 245
| Files        | 216
| Total Size   | 610857133 BYTES | 582 MB
==============================================
```

## License
ZDU is licensed under the [GNU General Public License v3 or later](https://www.gnu.org/licenses/gpl-3.0.en.html).
