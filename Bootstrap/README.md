# Bootstrap Helpers

The scripts in this directory create minimal Debian-based root file systems for use with Andronix.

## Usage

Run any bootstrap script with:

```bash
./bootstrap.sh <arch> <target-dir> [suite]
```

- `arch`: CPU architecture understood by `debootstrap` (for example `amd64`, `arm64`, `armhf`).
- `target-dir`: Destination directory where the root file system will be assembled.
- `suite` (optional): Distribution release codename. If omitted, each script falls back to its historical default (for example `bionic` for Ubuntu, `buster` for Debian).

The scripts automatically choose an appropriate mirror for native versus foreign architectures and clean up the resulting rootfs into a compressed `tar.xz` archive named after the selected architecture.

## Safety Checks

- Scripts now refuse to run without the required positional arguments.
- Unsafe targets (empty paths or `/`) are rejected before any deletion occurs.
- All filesystem operations use quoted paths to avoid accidental glob expansion.

These safeguards make it easier to iterate locally without risking damage to unrelated directories.
