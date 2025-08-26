![ZDU](doc/assets/logo.jpg)

**ZDU** is a fast, multithreaded, cross-platform alternative to GNU `du`, written in Zig. It recursively scans directories and reports file counts, directory counts, and total disk usage.

## Installation

Download from the [pre-built static binaries](https://github.com/makestatic/zdu/releases) for Linux, macOS, and Windows.

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
$ zdu <path>
```

Example:
```bash
# current working directory
$ zdu .
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
   Entry Path  : `.`
----------------------------------------------
   Directory   : 38   
   File        : 71
   Total Size  : 226006729 bytes / 215 mb
==============================================
```

## License
ZDU is licensed under the [GNU General Public License v3 or later](https://www.gnu.org/licenses/gpl-3.0.en.html).
