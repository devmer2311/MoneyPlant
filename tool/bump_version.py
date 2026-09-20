"""Calculate release version from pubspec. Run only in a disposable CI checkout."""
import argparse
import re
from pathlib import Path


def bump(current: str, kind: str) -> str:
    match = re.fullmatch(r"(\d+)\.(\d+)\.(\d+)\+(\d+)", current)
    if not match:
        raise ValueError("Expected MAJOR.MINOR.PATCH+BUILD in pubspec.yaml")
    major, minor, patch, build = map(int, match.groups())
    if kind == "major":
        major, minor, patch = major + 1, 0, 0
    elif kind == "minor":
        minor, patch = minor + 1, 0
    elif kind == "patch":
        patch += 1
    else:
        raise ValueError("Unknown version increment")
    return f"{major}.{minor}.{patch}+{build + 1}"


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("kind", choices=["patch", "minor", "major"])
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()
    pubspec = Path("pubspec.yaml")
    contents = pubspec.read_text()
    match = re.search(r"^version: (\S+)$", contents, re.MULTILINE)
    if not match:
        raise SystemExit("Missing pubspec version")
    version = bump(match.group(1), args.kind)
    pubspec.write_text(contents[:match.start(1)] + version + contents[match.end(1):])
    tag = "v" + version.split("+")[0]
    if args.output:
        with args.output.open("a") as output:
            output.write(f"version={version}\ntag={tag}\n")
    print(version)
