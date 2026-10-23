#!/usr/bin/env python3
"""Sample an existing macOS process; CPU percent uses one full core as 100%."""
import argparse
import ctypes
import json
import time

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument("pid", type=int)
parser.add_argument("--interval", type=float, default=5)
parser.add_argument("--windows", type=int, default=3)
args = parser.parse_args()
if args.interval <= 0 or args.windows <= 0:
    parser.error("interval and windows must be positive")

# rusage_info_v2 from the macOS SDK's sys/resource.h (RUSAGE_INFO_V2 = 2).
fields = "user_time system_time pkg_idle_wkups interrupt_wkups pageins wired_size resident_size phys_footprint proc_start_abstime proc_exit_abstime child_user_time child_system_time child_pkg_idle_wkups child_interrupt_wkups child_pageins child_elapsed_abstime diskio_bytesread diskio_byteswritten".split()


class RUsage(ctypes.Structure):
    _fields_ = [("uuid", ctypes.c_uint8 * 16)] + [(name, ctypes.c_uint64) for name in fields]


libproc = ctypes.CDLL("/usr/lib/libproc.dylib", use_errno=True)
libproc.proc_pid_rusage.argtypes = [ctypes.c_int, ctypes.c_int, ctypes.POINTER(RUsage)]
libproc.proc_pid_rusage.restype = ctypes.c_int


class Timebase(ctypes.Structure):
    _fields_ = [("numer", ctypes.c_uint32), ("denom", ctypes.c_uint32)]


timebase = Timebase()
libsystem = ctypes.CDLL("/usr/lib/libSystem.B.dylib")
libsystem.mach_timebase_info(ctypes.byref(timebase))
seconds_per_tick = timebase.numer / timebase.denom / 1e9


def read():
    usage = RUsage()
    if libproc.proc_pid_rusage(args.pid, 2, ctypes.byref(usage)) != 0:
        raise OSError(ctypes.get_errno(), "proc_pid_rusage failed")
    return time.monotonic(), usage


rows = []
for window in range(args.windows):
    start, before = read()
    time.sleep(args.interval)
    end, after = read()
    wall = end - start
    # proc_pid_rusage CPU times use Mach ticks, unlike getrusage's timeval seconds.
    cpu = (after.user_time + after.system_time - before.user_time - before.system_time) * seconds_per_tick
    rows.append({
        "window": window + 1,
        "wall_seconds": wall,
        "cpu_seconds": cpu,
        "single_core_percent": 100 * cpu / wall,
        "package_idle_wakeups": after.pkg_idle_wkups - before.pkg_idle_wkups,
        "interrupt_wakeups": after.interrupt_wkups - before.interrupt_wkups,
        "disk_bytes_read": after.diskio_bytesread - before.diskio_bytesread,
        "disk_bytes_written": after.diskio_byteswritten - before.diskio_byteswritten,
        "resident_bytes": after.resident_size,
    })
print(json.dumps({"pid": args.pid, "mach_timebase": [timebase.numer, timebase.denom], "samples": rows}, indent=2))
