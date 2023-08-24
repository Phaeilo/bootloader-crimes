# Bootloader Crimes
## A web-based utility for building disposable Windows VMs

[Demo Instance](https://bootloader-crimes.de) - [Talk at CCCamp23](https://media.ccc.de/v/camp2023-57222-bootloader_crimes)

This utility allows you to configure a Windows VM using a web UI, then download a tiny disk image which contains a
Linux-based stager and your configuration. If run, it will bootstrap an OS installation according to the configuration.
It will deploy Windows 11 on a MBR partition with BIOS boot, which is somewhat cursed but functional and easy to use in hypervisors.

This repo contains both the frontend code for the web application, as well as the scripts that make up the bootstrap disk image.

### Building

The disk image(s) are built by the `./utils/mkdisk.sh` script.
Besides some usual command line utilities, this script requires `guestfish`, `syslinux` and `qemu-img`.
Once finished, images are output to `./build/images`.

The web UI is kept in `./webapp` and can be built by installing dependencies with
`npm i` and then running webpack with `npm run pack`.
When deploying on a server, make sure to also add the vmdk image and its manifest to the webroot.
