#!/usr/bin/python

import os
import syslog
from argparse import ArgumentParser
from errno import EEXIST
from time import sleep

VERSION = "0.3"

# default command line options
DEFAULT_HOST = "8.8.8.8"
DEFAULT_REBOOT_ATTEMPTS = 3
DEFAULT_PING_ATTEMPTS = 30
DEFAULT_PING_DELAY = 10
DEFAULT_STATE_FILE = "/var/opt/autoreboot/attempts"

# command constants
PING_COMMAND = "ping -c 1 -w2 %s > /dev/null 2>&1"  # %s is replaced with the host
REBOOT_COMMAND = "reboot"


def __init_argparse():
    parser = ArgumentParser(description="Automatically reboot the system if the network is unavailable",
                            version=VERSION)
    parser.add_argument('-H', '--host', default=DEFAULT_HOST, help="Host to ping to check if the network is available")
    parser.add_argument('-r', '--reboot-attempts', type=int, default=DEFAULT_REBOOT_ATTEMPTS,
                        help="Maximum reboot attempts", metavar="NUMBER")
    parser.add_argument('-a', '--ping-attempts', type=int, default=DEFAULT_PING_ATTEMPTS,
                        help="Maximum ping attempts before rebooting", metavar="NUMBER")
    parser.add_argument('-d', '--ping-delay', type=int, default=DEFAULT_PING_DELAY, help="Delay between ping calls",
                        metavar="SECONDS")
    parser.add_argument('-s', '--state-file', default=DEFAULT_STATE_FILE, help="File to store reboot count",
                        metavar="FILE")
    parser.add_argument('-0', '--reset-state', action='store_true', help="Resets the reboot count to zero")
    parser.add_argument('-V', '--verbose', action='store_true', help="Enable verbose logging")
    return parser


def __init_logging(verbose):
    syslog.openlog(ident='autoreboot', logoption=syslog.LOG_PID)
    level = syslog.LOG_INFO
    if verbose:
        level = syslog.LOG_DEBUG
    syslog.setlogmask(syslog.LOG_UPTO(level))


def __log(message, severity=syslog.LOG_INFO):
    syslog.syslog(severity, message)


def __do_ping(hostname):
    command = PING_COMMAND % hostname
    response = os.system(command)
    return response == 0


def __ping(hostname, times, delay):
    for attempts in range(0, times):
        if __do_ping(hostname):
            return True
        else:
            __log("Ping unsuccessful, sleeping for %d second(s)" % delay, syslog.LOG_DEBUG)
            sleep(delay)
    return False


def __load_count(filename):
    count = 0
    if os.path.isfile(filename):
        with open(filename, 'r') as f:
            contents = f.read().strip()
            try:
                if len(contents) > 0:
                    count = int(contents)
            except ValueError:
                pass
    __log("Previous reboot attempt count is %d" % count, syslog.LOG_DEBUG)
    return count


def __store_count(filename, count):
    __log("Storing attempt count %d" % count, syslog.LOG_DEBUG)
    if not os.path.exists(os.path.dirname(filename)):
        try:
            os.makedirs(os.path.dirname(filename))
        except OSError as exc:
            if exc.errno != EEXIST:
                raise
    with open(filename, 'w') as f:
        f.write(str(count))


def __reboot():
    __log("Rebooting system")
    os.system(REBOOT_COMMAND)


def __reset_count(filename):
    __store_count(filename, 0)


def __main():
    args = __init_argparse().parse_args()
    __init_logging(args.verbose)

    state_file = args.state_file

    if args.reset_state:
        __log("Resetting the reboot count")
        __reset_count(state_file)
        return

    __log("Checking if network is available")
    if __ping(args.host, args.ping_attempts, args.ping_delay):
        __log("Network is available, exiting")
        __reset_count(state_file)
    else:
        __log("Network unavailable")
        attempts = __load_count(state_file)
        if attempts < args.reboot_attempts:
            __store_count(state_file, attempts + 1)
            __reboot()
        else:
            __log("Maximum reboot attempt number is reached, doing nothing", syslog.LOG_ERR)
            exit(2)


if __name__ == '__main__':
    __main()
