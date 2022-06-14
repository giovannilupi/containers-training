# Containers training

This repository contains an overview on containers at the operating system level, along with some code examples.

---

## Description

Containerization is the packaging into a single executable of some software code along with libraries, dependencies and all the reletaed configuration files required to run it.

The `containers_overview.pdf` file provides an analysis on the containerization process. It highlights its main differences with respect to virtualization, explains how to create a container using the appropriate Linux kernel features and explores some relevant details of the Docker architecure.

The `container-from-scratch` folder contains an example on how to create a rootless container using a few Linux kernel mechanisms.

The `docker-cgroup` folder contains an example of the interaction between Docker containers and the cgroup hierarchy.
