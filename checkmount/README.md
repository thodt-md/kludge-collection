## checkmount.sh

### Description

Checks if the file system is mounted. If not, tries to mount. If unsuccessful,
sends an email with currently mounted filesystems (`findmnt` output to be
exact).

### Requirements

1. Configured bsd-mailx, available as `/usr/bin/mail`
2. `findmnt` and `mount` (preferably from the _util-linux_ package)
4. Superuser (or proper `sudo` config) on the target system to do the mounting

### Usage

checkmount.sh /mount/target/dir your@email.com
