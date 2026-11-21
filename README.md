# ProxARMian
ProxARMian is an open-source project that aims to bring Proxmox Virtual Environment (VE) to ARM64 (AArch64) devices running Debian or Debian-based Linux distributions.

Why ProxARMian?

- Proxmox VE officially supports ARM64 platforms, but its hardware compatibility is limited.

According to the official Proxmox VE system requirements, ARM64 support is focused on NVIDIA Grace Hopper and NVIDIA Vera platforms, with best-effort support for other UEFI-based ARM systems.

Single-board computers that rely exclusively on Device Tree, such as the Raspberry Pi, are explicitly not supported.

ProxARMian aims to bridge this gap.

By automating the installation and configuration of Proxmox VE components on Debian-based ARM64 distributions, ProxARMian explores the possibility of bringing the Proxmox management ecosystem to community ARM hardware, including Raspberry Pi devices and other ARM-based single-board computers.

This is an independent, community-driven project and is not officially affiliated with or endorsed by Proxmox Server Solutions GmbH.

The goal is to make Proxmox more accessible to the ARM ecosystem by allowing users to turn ARM-based mini PCs, single-board computers (SBCs), home servers, and other compatible devices into virtualization platforms.

ProxARMian automates the installation and configuration of the main Proxmox VE components, handling repository setup, package installation, hostname resolution, service initialization, and SSL certificate generation.

The project aims to simplify the process of deploying a Proxmox-based environment on ARM64 hardware, opening new possibilities for home labs, lightweight servers, edge computing, and ARM-based virtualization experiments.
