
<p align="center">
    <img src="" alt="ProxARMian">
</p>

<table align="center">
  <tr>
    <td align="center">
      <a href="https://www.apache.org/licenses/LICENSE-2.0">
        <img src="https://img.shields.io/badge/License-Apache%202.0-green.svg" alt="License">
      </a>
    </td>
    <td align="center">
      <img src="https://img.shields.io/badge/Version-1.0.0-blue" alt="Version">
    </td>
    <td align="center">
      <img src="https://img.shields.io/badge/Arch-ARM64-green?style=flat&labelColor=gray" alt="Architecture">
    </td>
    <td align="center">
      <img src="https://img.shields.io/badge/Author-rompelhd-red" alt="Author">
    </td>
  </tr>
</table>

<p align="center">
    <i>Experimental software. Use at your own risk.</i>
    <i>Always review the installation script before executing it.</i>
</p>

<br/>

<p align="center">
    <b>ProxARMian</b> is an open-source project that brings the Proxmox Virtual Environment management ecosystem to ARM64 devices running Debian-based Linux distributions.
</p>

<p align="center">
    By automating the installation and configuration of Proxmox VE components, ProxARMian makes it possible to experiment with ARM-based virtualization on single-board computers, mini PCs and home servers.
</p>

<br/>

## About

Proxmox VE provides official ARM64 support, but its hardware compatibility remains limited.

According to the official system requirements, supported ARM platforms primarily include NVIDIA Grace Hopper and NVIDIA Vera systems, while other UEFI-based ARM platforms receive best-effort support.

Devices relying exclusively on Device Tree boot environments, such as Raspberry Pi systems, are not officially supported.

**ProxARMian aims to bridge this gap.**

The project automates the deployment of Proxmox VE components on existing Debian-based ARM64 installations, exploring the possibility of running the Proxmox management environment on community-supported ARM hardware.

ProxARMian is an independent, community-driven project and is not affiliated with, endorsed by or officially supported by Proxmox Server Solutions GmbH.

<br/>

## Key Features

- Automated installation of Proxmox VE components on ARM64 systems.
- Automatic Proxmox package repository configuration.
- Installation of packages from official Proxmox repositories.
- Hostname and `/etc/hosts` configuration.
- Proxmox service initialization.
- SSL certificate generation and configuration.
- Designed for minimal Debian-based installations.
- Supports experimentation with ARM single-board computers and home servers.

<br/>

## Requirements

ProxARMian does not install a complete operating system.

An existing Debian-based ARM64 installation is required before running the installer.

### LXC Edition (Minimum Requirements)

Designed for lightweight deployments focused on LXC containers and low-resource ARM devices.

- ARM64 / AArch64 architecture.
- Quad-core CPU (4 cores).
- 4GB RAM.
- Fast microSD card.
- Minimal or server installation.
- Headless environment (no desktop environment required).
- Root privileges.
- Working internet connection.

### Full Edition (Recommended Requirements)

Designed for more demanding workloads, including LXC containers and virtual machines (QEMU/KVM).

- ARM64 / AArch64 architecture.
- Quad-core CPU or higher.
- 8GB RAM or more.
- eMMC storage or SSD.
- Minimal or server installation.
- Headless environment (no desktop environment required).
- Root privileges.
- Working internet connection.

**Important:** Storage performance has a significant impact on Proxmox VE. SSD or eMMC storage is strongly recommended for better performance and reliability.

Hardware compatibility depends on the device, kernel, bootloader, firmware and available virtualization capabilities. Meeting these requirements does not guarantee compatibility with every ARM64 device.

Virtual machine support also depends on the availability of hardware virtualization extensions and compatible kernel support.

**Recommended distributions:**

| Distribution | Description |
|---|---|
| [Armbian](https://www.armbian.com/) | Recommended for a wide range of ARM single-board computers. |
| [DietPi](https://dietpi.com/) | Lightweight Debian-based distribution for SBCs and home servers. |
| [Raspberry Pi OS Lite](https://www.raspberrypi.com/software/) | Minimal operating system for Raspberry Pi devices. |

**Important:** A minimal/headless installation is strongly recommended. Desktop environments are unnecessary for Proxmox VE and consume resources that are better reserved for virtual machines and containers.

Hardware compatibility depends on the device, kernel, bootloader, firmware and available virtualization capabilities.

<br/>

## Installation

For security and transparency, reviewing the installation script before execution is recommended.

Download the script:

```bash
curl -fsSL https://raw.githubusercontent.com/rompelhd/ProxARMian/refs/heads/main/proxarmian.sh -o proxarmian.sh
```

Review its contents:

```bash
less proxarmian.sh
```

Execute the installer:

```bash
bash proxarmian.sh
```

<br/>

## Tested Hardware

ProxARMian has been successfully tested on the following hardware:

### Orange Pi 3B (8GB RAM) Nice exp with ssd or emmc
### Raspberry Pi 3b (1GB RAM) Not recommended

This demonstrates that the Proxmox VE management environment can run on community ARM hardware outside the officially supported ARM platforms.

Additional hardware testing and compatibility improvements are ongoing.

<br/>

## Security & Software Sources

ProxARMian is designed to remain as close as possible to the official Proxmox VE ecosystem.

The project relies on official Proxmox VE package repositories and upstream Proxmox components instead of distributing modified or third-party replacements.

**Software sources:**

- Proxmox VE packages are downloaded from official Proxmox repositories.
- No third-party Proxmox component builds are distributed.
- No modified Proxmox VE binaries are introduced.
- Installation and configuration automation is handled by the ProxARMian shell script.

The only custom code distributed by ProxARMian is its installation and configuration script.

**Security considerations:**

Using official package repositories does not guarantee that the resulting installation is completely secure or officially supported.

The installation script is third-party code and should be reviewed before execution. Running it requires root privileges and may modify system repositories, packages, network-related configuration and system services.

Always understand the changes being made before executing the installer.

<br/>

## Limitations & Disclaimer

ProxARMian is an experimental project intended for testing, learning, homelabs and ARM-based virtualization experiments.

- It is not an official Proxmox VE ARM port.
- It does not provide official Proxmox support for unsupported hardware.
- Not every ARM64 device is guaranteed to work.
- Hardware virtualization capabilities vary between platforms.
- Kernel, bootloader and firmware compatibility may affect functionality.
- Production workloads are not recommended.

**Use ProxARMian at your own risk.**

The project is provided as-is, without warranties or guarantees of functionality. The author is not responsible for hardware failures, data loss, system instability or other incidents resulting from its use.

<br/>

## Project Status

ProxARMian is an independent community project under active experimentation.

Contributions, hardware testing, compatibility reports and suggestions are welcome.

If you successfully run Proxmox VE on additional ARM64 hardware, consider sharing your configuration to help expand the project's compatibility information.

<br/>

## License

This project is licensed under the [Apache License 2.0](https://www.apache.org/licenses/LICENSE-2.0), unless otherwise specified.

<br/>

---

<p align="center">
    <b>ProxARMian</b>
    <br/>
    <i>Bringing Proxmox VE to the ARM ecosystem.</i>
</p>
