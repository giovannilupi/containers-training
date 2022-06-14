# Rootless container from scratch

Creating a rootless container from scratching using Linux kernel features.

## Description
The vast majority of the most popular container runtimes always create and manage containers as root. A rootless container is instead a type of container that can be created and run by an unprivileged user. In this approach, the user creating the container appears to be root inside of it, but remains unprivileged in the host machine.

The code inside this repository creates a rootless container from scratch using the appropriate Linux kernel features:
- <em>namespaces</em> : used to limit the information visible from inside the container.
- <em>chroot</em> : changes the filesystem root folder visible form the container.

### Namespaces

Namespaces are a Linux kernel mechanism for isolating the machine resources that a set of processes is aware of. The type of namespaces used by this program are:
- <em>UTS</em> : isolates hostname and domain name
- <em>Mount</em> : isolates the list of mountpoints
- <em>User</em> : isolate user and group IDs
- <em>PID</em> : isolates the PID number space

The user namespace is the core of rootless containers, as it allows a process to have a user ID of 0 inside the container and a different unprivileged ID on the host machine.

### chroot

The `chroot` command is used to change the root directory of the container to a folder containing the filesystem of Alpine Linux. This provides the container with some basic executables, as `/bin/sh`, that can be used for interacting with the container in a meaningful way. The filesystem also contains the `burner_program.sh` script, which can be executed to mimic the behavior of a cpu-intensive application.

## Directories

This project contains 4 directories:
- `alpine` : contains the Alpine Linux filesystem
- `bash` : contains some bash scripts
- `bin` : contains the rootles container executable
- `cpp` : contains the rootless container source code

## Working

Once the rootless container is running, the `container_manager` script creates a new cgroup for the container and sets a cpu consumption limit of 50%. Once this is done, it's possible to make experiments inside the container by runnning `burner_program.sh` and observing the cpu behavior. When the container is stopped, the manager script automatically performs the cleanup of the cgroup hierarchy.

---

## Instructions

First, the <em>tmux</em> and <em>inotify-tools</em> packages must be installed with the following commands:
```
sudo apt install tmux
```
```
sudo apt install inotify-tools
```

The executable for `container_example` must be present in the bin folder. This can be compiled from source and automatically copied to the bin folder using cmake.

The `container_runner.sh` script must be run inside the `bash` folder using `tmux`.
First run `tmux`:
```
tmux
```
Inside tmux, run the script **without** root privileges:
```
./container_runner.sh
``` 