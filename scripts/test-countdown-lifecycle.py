#!/usr/bin/env python3
"""Run AppDelegate lifecycle tests without opening the real product data or preferences."""
import os
from pathlib import Path
import shlex
import subprocess
import tempfile

real_library = Path.home() / "Library"
fixture_home = Path(tempfile.mkdtemp(prefix="twentyguard-lifecycle-"))
profile = f'''(version 1)(allow default)
(deny mach-lookup (global-name-regex ".*cfprefsd.*"))
(deny file-read* (subpath "{real_library / 'Preferences'}"))
(deny file-write* (subpath "{real_library / 'Preferences'}"))
(deny file-write* (subpath "{real_library / 'Application Support/com.javengroup.twentyguard'}"))'''
environment = dict(os.environ, CFFIXED_USER_HOME=str(fixture_home),
                   TWENTYGUARD_LIFECYCLE_TEST_HOME=str(fixture_home))
flags = shlex.split(os.environ["SWIFT_BUILD_FLAGS"])
print("Isolated lifecycle profile:", fixture_home, flush=True)
result = subprocess.run(["sandbox-exec", "-p", profile, "swift", "test", *flags,
                         "--filter", "CountdownLifecycleTests"], env=environment)
raise SystemExit(result.returncode)
