## autoreboot.py

### Description

For reasons unknown a network connection was not always established on one of
my remote embedded systems after a power cycle. It may have been a problem
with the NIC, the driver or the ISP.

Quick log analysis and googling did not reveal the cause of the problem, but
some sort of a workaround was required ASAP.

The network did come up after a reboot (sometimes two), so a Python script was
quickly cobbled up to check for Internet access and reboot the system after
a timeout was reached.

The version here is probably the second or third. Some testing was done with
Ubuntu 14.04 (and later 16.04) minimal images, since that is what I used on the
embedded system.

### Operation

The script uses the `ping` utility (up to 30 times, by default) to test whether
a host (by default `8.8.8.8`) is available, with the delay of 10 seconds
between each invocation.

If the host is not available after testing, the script stores the current
attempt number to a file (by default `/var/opt/autoreboot/attempts`) and
reboots the system.

If the maximum number of restart attempts has been reached, the script does
nothing.

If the host is available, the script resets the attempt counter and exits.

Logging is done using the `syslog` facility.

### Requirements

1. Python 2.7
2. `ping` (preferably from the _iputils_ package) to send ICMP echo packets and
   `reboot` command for rebooting the system
3. `syslog` Unix facility for logging
3. Persistent filesystem to store the number of restart attempts
4. Superuser (or proper `sudo` config) on the target system to do the restart

### Installation

1. Place this script in a directory like `/opt`
2. Add a line to your `rc.local` script, that launches `autoreboot.py` in the
   background (something like `/opt/autoreboot.py &`)

### Options

Almost everything is customizable by adding proper command-line options.
The list of options is available by running `autoreboot.py --help`:
```
usage: autoreboot.py [-h] [-v] [-H HOST] [-r NUMBER] [-a NUMBER] [-d SECONDS]
                     [-s FILE] [-0] [-V]

Automatically reboot the system if the network is unavailable

optional arguments:
  -h, --help            show this help message and exit
  -v, --version         show program's version number and exit
  -H HOST, --host HOST  Host to ping to check if the network is available
  -r NUMBER, --reboot-attempts NUMBER
                        Maximum reboot attempts
  -a NUMBER, --ping-attempts NUMBER
                        Maximum ping attempts before rebooting
  -d SECONDS, --ping-delay SECONDS
                        Delay between ping calls
  -s FILE, --state-file FILE
                        File to store reboot count
  -0, --reset-state     Resets the reboot count to zero
  -V, --verbose         Enable verbose logging
```
