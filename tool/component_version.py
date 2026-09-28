"""Strict flat YAML version manifests; no third-party dependencies required."""
import argparse
import os
import re
import subprocess
from pathlib import Path

def parse_manifest(text, component):
    values = {}
    for line in text.splitlines():
        line = line.split("#", 1)[0].strip()
        if not line:
            continue
        match = re.fullmatch(r"(version|build):\s*([^\s]+)", line)
        if not match or match[1] in values:
            raise ValueError("Expected unique, unquoted version/build YAML fields")
        values[match[1]] = match[2]
    required = {"version", "build"} if component == "app" else {"version"}
    if set(values) != required or not re.fullmatch(r"(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)", values["version"]):
        raise ValueError("Use a stable MAJOR.MINOR.PATCH version")
    if component == "app" and (not re.fullmatch(r"[1-9]\d*", values["build"]) or int(values["build"]) > 2100000000):
        raise ValueError("Android build must be a positive valid versionCode")
    return values

def semver(version):
    return tuple(map(int, version.split(".")))

def changed(current, previous):
    if previous is None:
        return True
    if current == previous:
        return False
    if semver(current["version"]) <= semver(previous["version"]):
        raise ValueError("A release change must increase the semantic version")
    if "build" in current and int(current["build"]) <= int(previous["build"]):
        raise ValueError("Android build number must also increase")
    return True

def unpublished(current_version, prefix, existing):
    versions = [t[len(prefix):] for t in existing if t.startswith(prefix) and re.fullmatch(r"\d+\.\d+\.\d+", t[len(prefix):])]
    if versions and semver(current_version) < max(map(semver, versions)):
        raise ValueError("Version is below an existing release tag")
    return prefix + current_version not in existing

def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()

def manifest_at(ref, path):
    if not ref or set(ref) == {"0"}:
        return None
    # Only a missing file is a bootstrap; missing commit/history must fail.
    git("rev-parse", "--verify", ref + "^{commit}")
    if not git("ls-tree", "--name-only", ref, "--", path):
        return None
    return git("show", f"{ref}:{path}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("component", choices=["app", "site"])
    parser.add_argument("--base")
    parser.add_argument("--output", type=Path)
    parser.add_argument("--sync-pubspec", action="store_true")
    args = parser.parse_args()
    path = f"versions/{args.component}.yaml"
    current = parse_manifest(Path(path).read_text(), args.component)
    if args.component == "app":
        expected = current["version"] + "+" + current["build"]
        pubspec = Path("pubspec.yaml")
        text = pubspec.read_text()
        if args.sync_pubspec:
            text, count = re.subn(r"^version: \S+$", "version: " + expected, text, flags=re.M)
            if count != 1:
                raise ValueError("Expected one pubspec version")
            pubspec.write_text(text)
        actual = re.search(r"^version: (\S+)$", text, re.M)
        if not actual or actual[1] != expected:
            raise ValueError("pubspec differs: run python tool/component_version.py app --sync-pubspec")
    previous_text = manifest_at(args.base, path) if args.base else None
    previous = parse_manifest(previous_text, args.component) if previous_text else None
    should_build = changed(current, previous)
    prefix = "v" if args.component == "app" else "site-v"
    tag = prefix + current["version"]
    # A published version can never be reused, lowered, or moved.
    if os.environ.get("GITHUB_REF") == "refs/heads/main" and should_build:
        existing = git("tag", "--list", prefix + "*").splitlines()
        should_build = unpublished(current["version"], prefix, existing)
        if not should_build:
            print(f"{tag} already exists; no repeat publication")
    output = dict(current, tag=tag, changed=str(should_build).lower())
    if args.output:
        with args.output.open("a") as out:
            out.write("".join(f"{k}={v}\n" for k, v in output.items()))
    print(output)
