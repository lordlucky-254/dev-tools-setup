# Safe installation checklist

The installers in this repository can change your system by installing packages and tools. Review the script and package list before running it, especially on a work-managed device.

## Before running

- [ ] Read the relevant installer (`install.sh` or `install.ps1`) and confirm every package is wanted.
- [ ] Check the supported operating system and package manager in the README.
- [ ] Use a trusted network and verify the repository URL before downloading scripts.
- [ ] Prefer cloning the repository and inspecting the local script over piping a remote script directly to a shell.
- [ ] Confirm you have a backup or restore path for important configuration files.
- [ ] Do not run with administrator privileges unless the script or package manager requires them.

## After running

- [ ] Read the terminal output for skipped or failed packages.
- [ ] Verify installed tools with their version commands.
- [ ] Review any shell profile or PATH changes before opening a new terminal.
- [ ] Remove tools you do not need and report reproducible issues with your OS and package manager versions.

The scripts are convenience automation, not a security audit. They may invoke platform package managers and upstream installers; review those sources and their terms before use.
