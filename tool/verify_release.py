"""Check the compiled APK, not just its filename. Requires Android SDK aapt."""
import argparse
import re
import subprocess
from pathlib import Path

def verify_badging(text, version):
    expected, build = version.split("+")
    match = re.search(r"^package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", text, re.M)
    if not match:
        raise ValueError("aapt did not return APK package metadata")
    package, code, name = match.groups()
    if package != "app.moneyplant.money_plant" or name != expected or code != build:
        raise ValueError(f"APK mismatch: {package}, {name}+{code}; expected app.moneyplant.money_plant, {version}")
    return {"package": package, "versionName": name, "versionCode": int(code)}

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument("version")
    parser.add_argument("--aapt", default="aapt")
    args = parser.parse_args()
    output = subprocess.check_output([args.aapt, "dump", "badging", str(args.apk)], text=True)
    print(verify_badging(output, args.version))
