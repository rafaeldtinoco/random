PREVIOUS: README-create-iso-test-livecd.txt

*** Make sure to read "PREVIOUS" README files before moving on! ***

[ Creating an Ubuntu Installer ISO ]

Previous README files showed how to create the basic infrastructure to this
part: the ISO creation tool. This tool is responsible to create an Ubuntu LIVE
Image that will be booted from a CD-ROM and/or a PENDRIVE in a machine (virtual
or not) and will install to this machine's local disk an Ubuntu Cloud Image
(contained in the generated ISO) PLUS chosen - during ISO generation - packages
(also contained in the generated ISO).

The "iso.sh" script is a tool that creates a small Ubuntu environment capable
of being run as a LIVE OS from a cd-rom. This small Ubuntu environment contains
the tool called "Curtin", responsible for provisioning anything related to
Ubuntu.

As described in the "practice" exercise, curtin is capable of doing several
different customizations during installation. In our example it uses the
configuration file provided in the "files/" directory (machine01-curtin.yaml,
for example) and installs the "booted" (w/ generated ISO) machine based on
that configuration file.

There were some requirements when developing this tool:

1) Tool must be capable of installing Ubuntu offline
   => The generated ISO is (from a CDROM and/or a PENDRIVE)

2) Tool must allow to-be-installed OS configuration
   => Curtin yaml files allow that deeply.

3) Tool must be based in images provided by Canonical (official Ubuntu ones)
   => Curtin uses a file:/// URI to specify a self-contained .txz Ubuntu Cloud
   Image downloaded during ISO generation time.

4) Tool must allow one to customize packages to be installed
   => You can specify extra packages to be installed in chosen Ubuntu Cloud
   Images. Those packages will be put, together with all their dependencies, in
   a self-contained "repository" placed inside the ISO, during ISO generation
   time.
   => All packages specified during ISO generation time will be available to
   Curtin when installing the Ubuntu OS locally.

5) Tool must provide cloud-init support
   => The Ubuntu Cloud Image is cloud-init ready.
   => Provided curtin examples show how to customize installed OS to realize,
   during its first boot, all setup needed for a "final" state.

6) Tool must allow different machine types to be installed with a single ISO
   => You can specify as many different machine types as you want. Each of them
   will contain its own Curtin yaml configuration file AND its own cloud-init
   configuration file.
   => The generated ISO contains a "menu driven" option to start curtin for a
   specific machine type. One has to basically chose options (1), (2) or (3) and
   hit enter.

Optional) ISO can be converted to PENDRIVE using "dd" tool.
Optional) ISO will display on ttyS0 and tty0 (serial or monitor)

With all the requirements and its resolution explained, its time to check the
tool command line options. Some less obvious arguments can be better explained
here:

--------

rafaeldtinoco@workstation:~/.../create-iso$ ./iso.sh -h
info: logs at /tmp/iso.log

syntax: ./iso.sh [options]

options:
        -n <hostname>           - OS hostname
        -c <ubuntu cloud img>   - https://cloud-images.ubuntu.com/releases/.../release/*-root.tar.xz
                                  * default: ubuntu-18.04-server-cloudimg-amd64-root.tar.xz *
        -d <livecd version>     - xenial/bionic/disco/eoan/focal (default: stable)
        -u <username>           - as 1000:1000 in the installed vm (default: ubuntu)
        -l <launchpad_id>       - for the ssh key import (default: rafaeldtinoco)
        -r <repo.url>           - url for the ubuntu mirror (default: us.archive)
        -o <offlinepkgs>        - format: package01,package02,package03
                                  * these pkgs be part of a local repository in livecd *

--------

    -c <ubuntu cloud img> = This is the FULL URL (HTTP URI) of the .tar.xz
    Ubuntu Cloud Image to be used in the Server Installation. You have to
    generate 1 ISO per Ubuntu Cloud Image. Usually you will have an Ubuntu Cloud
    Image for each Ubuntu Version: Bionic, Disco, Eoan, etc. Check:

      - https://cloud-images.ubuntu.com/releases/bionic/release/

    as an example. You will find a file called:

      - ubuntu-18.04-server-cloudimg-amd64-root.tar.xz

    This is the default Ubuntu Cloud Image if you don't specify this argument.

    -d <livecd version> = This is the Ubuntu version to be used in the Ubuntu
    LIVE Image only. You can specify a different (than the Ubuntu Cloud Image)
    version but if you specify extra packages, to be installed by the Installer,
    it won't work. Best advice is to use the SAME version as the Ubuntu Cloud
    Image you're setting.

    -u <username> = This is the default username (uid:1000/gid:1000) to be
    created in the installed OS.

    -l <launchpad_id> = Since you can choose to either embed your ssh key inside
     the cloud-init file, or just instruct cloud-init to import the ssh key
     using the network during the first boot, this option tells cloud-init which
     launchpad_id to use in the second case. For the first case you can change
     default.yaml file for your own ssh key to be provisioned.

    -r <repo.url> = http//archive.ubuntu.com/ubuntu is the most simple option
     you can have here. Pick a better mirror if that suites you.

    -o <offlinepkgs> = This is (4) item in requirements described earlier in
    this README file. In the following format:

        "xterm,rxvt,net-tools,bash-completion"

    It will instruct the ISO generation tool to create a repo, internal to the
    ISO, containing all specified packages PLUS all their dependencies. This
    allows end-user (of the ISO) to install those packages on top of the Ubuntu
    Cloud Image being installed in the local disks.

    The way you specify the installation of these packages is through the
    "machine type" cloud-init yaml configuration file. Machine called
    "machine01" in the default example shows how to achieve that.

    Enough explanations, let's generate our first Ubuntu Installer ISO:

--------

$ ./iso.sh -n ubuntulive -d bionic -u rafaeldtinoco -l rafaeldtinoco \
  -o xterm,x11-apps,rxvt

info: logs at /tmp/iso.log
option: hostname=ubuntulive
option: distro=bionic
option: username=rafaeldtinoco
option: launchpad_id=rafaeldtinoco
option: offlinepkgs=xterm,x11-apps,rxvt
...
info: targetdirt=/home/rafaeldtinoco/example/riband/liveboot/chroot
info: livebootdir=/home/rafaeldtinoco/example/riband/liveboot
mark: debootstraping
mark: mount {procfs,sysfs,devfs}
mark: setting hostname
mark: adjusting accounts
mark: /etc/modules
mark: /etc/apt/sources.list
mark: update and upgrade
info: cleaning up mount leftovers
info: downloading ubuntu-18.04-server-cloudimg-amd64-root.tar.xz
mark: configuring curtin and cloud-init yaml files
mark: configuring local (to live cdrom) repository
mark: creating squashfs
mark: creating grub.cfg
mark: creating UBUNTU_LIVE file
mark: configuring EFI cdrom portion
mark: configuring MBR cdrom portion
mark: creating the ISO
finished: your ISO can be found at /home/rafaeldtinoco/example/riband/liveboot/ubuntu-livecd.iso

--------

You will find logs at /tmp/iso.log during ISO generation (and debugging). After
having created the Ubuntu LIVE CD, containing everything needed for a full
server installation, its time to test it and the "livecdinstall" virtual machine
we have created previously is the perfect environment for that!

--------

rafaeldtinoco@workstation:~$ virsh destroy livecdinstallstart --console
Domain livecdinstall started
Connected to domain livecdinstall
Escape character is ^]
[    0.000000] Linux version 4.15.0-76-generic (buildd@lcy01-amd64-029) (gcc version 7.4.0 (Ubuntu 7.4.0-1ubuntu1~18.04.1)) #86-Ubuntu SMP Fri Jan 17 17:24:28 UTC 2020 (Ubuntu 4.15.0-76.86-generic 4.15.18)
[    0.000000] Command line: BOOT_IMAGE=/vmlinuz boot=live console=tty0 console=ttyS0,38400n8 apparmor=0 net.ifnames=0 elevator=noop
[    0.000000] KERNEL supported cpus:
[    0.000000]   Intel GenuineIntel
[    0.000000]   AMD AuthenticAMD
[    0.000000]   Centaur CentaurHauls
[    0.000000] random: get_random_u32 called from bsp_init_amd+0x207/0x2c0 with crng_init=0
[    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'
[    0.000000] x86/fpu: Supporting XSAVE feature 0x002: 'SSE registers'
[    0.000000] x86/fpu: Supporting XSAVE feature 0x004: 'AVX registers'
[    0.000000] x86/fpu: xstate_offset[2]:  576, xstate_sizes[2]:  256
[    0.000000] x86/fpu: Enabled xstate features 0x7, context size is 832 bytes, using 'standard' format.
[    0.000000] e820: BIOS-provided physical RAM map:
[    0.000000] BIOS-e820: [mem 0x0000000000000000-0x000000000009fbff] usable
[    0.000000] BIOS-e820: [mem 0x000000000009fc00-0x000000000009ffff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000000f0000-0x00000000000fffff] reserved
[    2.303929] async_tx: api initialized (async)
...
Begin: Running /scripts/init-premount ... done.
Begin: Mounting root file system ... [    2.371294] random: fast init done
Begin: Running /scripts/init-bottom ... done.
[    2.751297] ip_tables: (C) 2000-2006 Netfilter Core Team
[    2.759634] systemd[1]: systemd 237 running in system mode. (+PAM +AUDIT +SELINUX +IMA +APPARMOR +SMACK +SYSVINIT +UTMP +LIBCRYPTSETUP +GCRYPT +GNUTLS +ACL +XZ +LZ4 +SECCOMP +BLKID +ELFUTILS +KMOD -IDN2 +IDN -PCRE2 default-hierarchy=hybrid)
[    2.764530] systemd[1]: Detected virtualization kvm.
[    2.765781] systemd[1]: Detected architecture x86-64.

Welcome to Ubuntu 18.04.3 LTS!

[  OK  ] Started Dispatch Password Requests to Console Directory Watch.
[  OK  ] Started Forward Password Requests to Wall Directory Watch.
[  OK  ] Reached target Local Encrypted Volumes.
[  OK  ] Started Thermal Daemon Service.
...
[  OK  ] Started Lighttpd Daemon.
[  OK  ] Started Dispatcher daemon for systemd-networkd.
[  OK  ] Reached target Multi-User System.
[  OK  ] Reached target Graphical Interface.
         Starting Update UTMP about System Runlevel Changes...
[  OK  ] Started Update UTMP about System Runlevel Changes.


                    ┌──────┤ Ubuntu Live Installer ├───────┐
                    │ Select this machine type:            │
                    │                                      │
                    │    (*) 1  Machine Type 01            │
                    │    ( ) 2  Machine Type 02            │
                    │    ( ) 3  Machine Type 03            │
                    │                                      │
                    │       <Ok>           <Cancel>        │
                    │                                      │
                    └──────────────────────────────────────┘


--------

This is the menu made in shell script and dialog mentioned before. This allows
an end-user to select which machine type to install locally. It will start
the curtin installation tool with appropriate curtin yaml configuration file.

For this example all machines are the same (symbolic links) so we are choosing
"Machine Type 01". It will run the following command:

    curtin -v install -c /curtin/machine01-curtin.yaml

And machine01-curtin.yaml file places "machine01-cloud.yaml" cloud-init
configuration file in the local disk partition (to instruct the first boot how
cloud-init should behave).

So, after choosing (1) we have:

--------

curtin: Installation started. (19.1-7-g37a7a0f4-0ubuntu1~18.04.1)
Current device storage tree:
vda
|-- vda2
`-- vda1
Shutdown Plan:
{'level': 1, 'device': '/sys/class/block/vda/vda2', 'dev_type': 'partition'}
{'level': 1, 'device': '/sys/class/block/vda/vda1', 'dev_type': 'partition'}
{'level': 0, 'device': '/sys/class/block/vda', 'dev_type': 'disk'}
shutdown running on holder type: 'partition' syspath: '/sys/class/block/vda/vda2'
wiping superblock on /dev/vda2
shutdown running on holder type: 'partition' syspath: '/sys/class/block/vda/vda1'
extended partitions do not need wiping, so skipping: '/dev/vda1'
shutdown running on holder type: 'disk' syspath: '/sys/class/block/vda'
wiping superblock on /dev/vda
blockmeta: detected storage config, using mode=custom
labeling device: '/dev/vda' with 'msdos' partition table
partition 'number' key not set in config:
{
 "device": "vda",
 "id": "vda1",
 "size": "10MB",
 "type": "partition"
}
adding partition 'vda1' to disk 'vda' (ptable: 'msdos')
partition 'number' key not set in config:
{
 "device": "vda",
 "id": "vda1",
 "size": "10MB",
 "type": "partition"
}
partition 'number' key not set in config:
{
 "device": "vda",
 "id": "vda2",
 "size": "28GB",
 "type": "partition"
}
partition 'number' key not set in config:
{
 "device": "vda",
 "id": "vda1",
 "size": "10MB",
 "type": "partition"
}
adding partition 'vda2' to disk 'vda' (ptable: 'msdos')
partition 'number' key not set in config:
{
 "device": "vda",
 "id": "vda2",
 "size": "28GB",
 "type": "partition"
}
partition 'number' key not set in config:
{
 "device": "vda",
 "id": "vda2",
 "size": "28GB",
 "type": "partition"
}
Applying write_files from config.
Running curtin builtin curthooks
Configuring target system for distro: ubuntu osfamily: debian
curthooks handling apt to target /tmp/tmpjr_4l79m/target with config {'preserve_sources_list': False, 'sources_list': '# network: will be
available to target from early stage\ndeb [trusted=yes] http://127.0.0.1/ /\n', 'conf': 'Dpkg::Options {\n  "--force-confdef";\n  "--force-confold";\n};\n'}
Ign:1 http://127.0.0.1  InRelease
Ign:2 http://127.0.0.1  Release
Ign:3 http://127.0.0.1  Packages
Ign:3 http://127.0.0.1  Packages
Ign:3 http://127.0.0.1  Packages
Get:3 http://127.0.0.1  Packages [47.7 kB]
Fetched 47.7 kB in 0s (1435 kB/s)
Reading package lists...
Reading package lists...
Building dependency tree...
Reading state information...

--------

NOTE 1: Curtin is using an "apt" repository from "http://127.0.0.1". This
happens because the Ubuntu LIVE Image has a local repository being used by
Curtin to install packages (selected by -o option in iso creation tool) and its
dependencies.

NOTE 2: This installation is not installing packages provided by the -o cmdline
argument. This happens because Curtin also needs the kernel packages (and all
its dependencies) to be available during installation time. Since our installer
is working offline, it also embeds the kernel packages in this
local-to-iso-ramdisk repository.

--------

The following additional packages will be installed:
  amd64-microcode crda grub-common grub-gfxpayload-lists grub-pc grub-pc-bin
  grub2-common intel-microcode iucode-tool iw libnl-3-200 libnl-genl-3-200
  linux-firmware linux-image-4.15.0-76-generic linux-modules-4.15.0-76-generic
  linux-modules-extra-4.15.0-76-generic wireless-regdb
Suggested packages:
  multiboot-doc grub-emu xorriso desktop-base fdutils linux-doc-4.15.0
  | linux-source-4.15.0 linux-tools linux-headers-4.15.0-76-generic
Recommended packages:
  os-prober thermald
The following NEW packages will be installed:
  amd64-microcode crda grub-common grub-gfxpayload-lists grub-pc grub-pc-bin
  grub2-common intel-microcode iucode-tool iw libnl-3-200 libnl-genl-3-200
  linux-firmware linux-image-4.15.0-76-generic linux-image-generic
  linux-modules-4.15.0-76-generic linux-modules-extra-4.15.0-76-generic
  wireless-regdb
0 upgraded, 18 newly installed, 0 to remove and 6 not upgraded.
Need to get 135 MB of archives.
After this operation, 596 MB of additional disk space will be used.
Get:1 http://127.0.0.1  amd64-microcode 3.20191021.1+really3.20181128.1~ubuntu0.18.04.1 [31.6 kB]
Get:2 http://127.0.0.1  iucode-tool 2.3.1-1 [45.6 kB]
Get:3 http://127.0.0.1  intel-microcode 3.20191115.1ubuntu0.18.04.2 [2407 kB]
Get:4 http://127.0.0.1  libnl-3-200 3.2.29-0ubuntu3 [52.8 kB]
Get:5 http://127.0.0.1  libnl-genl-3-200 3.2.29-0ubuntu3 [11.2 kB]
Get:6 http://127.0.0.1  wireless-regdb 2018.05.09-0ubuntu1~18.04.1 [11.1 kB]
Get:7 http://127.0.0.1  iw 4.14-0.1 [75.4 kB]
Get:8 http://127.0.0.1  crda 3.18-1build1 [63.5 kB]
Get:9 http://127.0.0.1  grub-common 2.02-2ubuntu8.14 [1772 kB]
Get:10 http://127.0.0.1  grub2-common 2.02-2ubuntu8.14 [532 kB]
Get:11 http://127.0.0.1  grub-pc-bin 2.02-2ubuntu8.14 [899 kB]
Get:12 http://127.0.0.1  grub-pc 2.02-2ubuntu8.14 [138 kB]
Get:13 http://127.0.0.1  grub-gfxpayload-lists 0.7 [3658 B]
Get:14 http://127.0.0.1  linux-firmware 1.173.14 [75.1 MB]
Get:15 http://127.0.0.1  linux-modules-4.15.0-76-generic 4.15.0-76.86 [13.0 MB]
Get:16 http://127.0.0.1  linux-image-4.15.0-76-generic 4.15.0-76.86 [7993 kB]
Get:17 http://127.0.0.1  linux-modules-extra-4.15.0-76-generic 4.15.0-76.86 [32.7 MB]
Get:18 http://127.0.0.1  linux-image-generic 4.15.0.76.78 [2388 B]
Preconfiguring packages ...
Fetched 135 MB in 2s (60.0 MB/s)
Selecting previously unselected package amd64-microcode.
(Reading database ... 28654 files and directories currently installed.)
Preparing to unpack .../00-amd64-microcode_3.20191021.1+really3.20181128.1~ubuntu0.18.04.1_amd64.deb ...
Unpacking amd64-microcode (3.20191021.1+really3.20181128.1~ubuntu0.18.04.1) ...
Selecting previously unselected package iucode-tool.
Preparing to unpack .../01-iucode-tool_2.3.1-1_amd64.deb ...
Unpacking iucode-tool (2.3.1-1) ...
Selecting previously unselected package intel-microcode.
Preparing to unpack .../02-intel-microcode_3.20191115.1ubuntu0.18.04.2_amd64.deb ...
Unpacking intel-microcode (3.20191115.1ubuntu0.18.04.2) ...
Selecting previously unselected package libnl-3-200:amd64.
Preparing to unpack .../03-libnl-3-200_3.2.29-0ubuntu3_amd64.deb ...
Unpacking libnl-3-200:amd64 (3.2.29-0ubuntu3) ...
Selecting previously unselected package libnl-genl-3-200:amd64.
Preparing to unpack .../04-libnl-genl-3-200_3.2.29-0ubuntu3_amd64.deb ...
Unpacking libnl-genl-3-200:amd64 (3.2.29-0ubuntu3) ...
Selecting previously unselected package wireless-regdb.
Preparing to unpack .../05-wireless-regdb_2018.05.09-0ubuntu1~18.04.1_all.deb ...
Unpacking wireless-regdb (2018.05.09-0ubuntu1~18.04.1) ...
Selecting previously unselected package iw.
Preparing to unpack .../06-iw_4.14-0.1_amd64.deb ...
Unpacking iw (4.14-0.1) ...
Selecting previously unselected package crda.
Preparing to unpack .../07-crda_3.18-1build1_amd64.deb ...
Unpacking crda (3.18-1build1) ...
Selecting previously unselected package grub-common.
Preparing to unpack .../08-grub-common_2.02-2ubuntu8.14_amd64.deb ...
Unpacking grub-common (2.02-2ubuntu8.14) ...
Selecting previously unselected package grub2-common.
Preparing to unpack .../09-grub2-common_2.02-2ubuntu8.14_amd64.deb ...
Unpacking grub2-common (2.02-2ubuntu8.14) ...
Selecting previously unselected package grub-pc-bin.
Preparing to unpack .../10-grub-pc-bin_2.02-2ubuntu8.14_amd64.deb ...
Unpacking grub-pc-bin (2.02-2ubuntu8.14) ...
Selecting previously unselected package grub-pc.
Preparing to unpack .../11-grub-pc_2.02-2ubuntu8.14_amd64.deb ...
Unpacking grub-pc (2.02-2ubuntu8.14) ...
Selecting previously unselected package grub-gfxpayload-lists.
Preparing to unpack .../12-grub-gfxpayload-lists_0.7_amd64.deb ...
Unpacking grub-gfxpayload-lists (0.7) ...
Selecting previously unselected package linux-firmware.
Preparing to unpack .../13-linux-firmware_1.173.14_all.deb ...
Unpacking linux-firmware (1.173.14) ...
Selecting previously unselected package linux-modules-4.15.0-76-generic.
Preparing to unpack .../14-linux-modules-4.15.0-76-generic_4.15.0-76.86_amd64.deb ...
Unpacking linux-modules-4.15.0-76-generic (4.15.0-76.86) ...
Selecting previously unselected package linux-image-4.15.0-76-generic.
Preparing to unpack .../15-linux-image-4.15.0-76-generic_4.15.0-76.86_amd64.deb ...
Unpacking linux-image-4.15.0-76-generic (4.15.0-76.86) ...
Selecting previously unselected package linux-modules-extra-4.15.0-76-generic.
Preparing to unpack .../16-linux-modules-extra-4.15.0-76-generic_4.15.0-76.86_amd64.deb ...
Unpacking linux-modules-extra-4.15.0-76-generic (4.15.0-76.86) ...
Selecting previously unselected package linux-image-generic.
Preparing to unpack .../17-linux-image-generic_4.15.0.76.78_amd64.deb ...
Unpacking linux-image-generic (4.15.0.76.78) ...
Setting up linux-modules-4.15.0-76-generic (4.15.0-76.86) ...
Setting up wireless-regdb (2018.05.09-0ubuntu1~18.04.1) ...
Setting up linux-image-4.15.0-76-generic (4.15.0-76.86) ...
Setting up grub-common (2.02-2ubuntu8.14) ...
Running in chroot, ignoring request.
invoke-rc.d: policy-rc.d denied execution of start.
Setting up libnl-3-200:amd64 (3.2.29-0ubuntu3) ...
Setting up amd64-microcode (3.20191021.1+really3.20181128.1~ubuntu0.18.04.1) ...
update-initramfs: deferring update (trigger activated)
amd64-microcode: microcode will be updated at next boot
Setting up linux-firmware (1.173.14) ...
Setting up intel-microcode (3.20191115.1ubuntu0.18.04.2) ...
update-initramfs: deferring update (trigger activated)
intel-microcode: microcode will be updated at next boot
Setting up grub-pc-bin (2.02-2ubuntu8.14) ...
Setting up grub2-common (2.02-2ubuntu8.14) ...
Setting up libnl-genl-3-200:amd64 (3.2.29-0ubuntu3) ...
Setting up iw (4.14-0.1) ...
Setting up crda (3.18-1build1) ...
Setting up linux-modules-extra-4.15.0-76-generic (4.15.0-76.86) ...
Setting up linux-image-generic (4.15.0.76.78) ...
Setting up grub-gfxpayload-lists (0.7) ...
Setting up grub-pc (2.02-2ubuntu8.14) ...
Creating config file /etc/default/grub with new version
Processing triggers for libc-bin (2.27-3ubuntu1) ...
Processing triggers for systemd (237-3ubuntu10.33) ...
Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
Processing triggers for ureadahead (0.100.0-21) ...
Processing triggers for install-info (6.5.0.dfsg.1-2) ...
Processing triggers for linux-image-4.15.0-76-generic (4.15.0-76.86) ...
/etc/kernel/postinst.d/initramfs-tools:
update-initramfs: Generating /boot/initrd.img-4.15.0-76-generic
Processing triggers for initramfs-tools (0.130ubuntu3.9) ...
update-initramfs: Generating /boot/initrd.img-4.15.0-76-generic
Setting up swapspace version 1, size = 3.9 GiB (4135579648 bytes)
no label, UUID=b159c8b8-16aa-4685-95ce-047a6ffa8f46
applying network_config
Checking cloud-init in target [/tmp/tmpjr_4l79m/target] for network configuration passthrough support.
Passing network configuration through to target: /tmp/tmpjr_4l79m/target
Writing network config to etc/cloud/cloud.cfg.d/50-curtin-networking.cfg: /tmp/tmpjr_4l79m/target/etc/cloud/cloud.cfg.d/50-curtin-networking.cfg
Failed to find legacy network conf file /tmp/tmpjr_4l79m/target/etc/network/interfaces.d/eth0.cfg
Removing ipv6 privacy extension config file: /tmp/tmpjr_4l79m/target/etc/sysctl.d/10-ipv6-privacy.conf
Injecting fix for ipv6 mtu settings: /tmp/tmpjr_4l79m/target/etc/network/if-pre-up.d/mtuipv6
Injecting fix for ipv6 mtu settings: /tmp/tmpjr_4l79m/target/etc/network/if-up.d/mtuipv6
Ign:1 http://127.0.0.1  InRelease
Ign:2 http://127.0.0.1  Release
Ign:3 http://127.0.0.1  Packages
Ign:4 http://127.0.0.1  Translation-en
Ign:3 http://127.0.0.1  Packages
Ign:4 http://127.0.0.1  Translation-en
Ign:3 http://127.0.0.1  Packages
Ign:4 http://127.0.0.1  Translation-en
Hit:3 http://127.0.0.1  Packages
Ign:4 http://127.0.0.1  Translation-en
Ign:4 http://127.0.0.1  Translation-en
Ign:4 http://127.0.0.1  Translation-en
Ign:4 http://127.0.0.1  Translation-en
Reading package lists...
Reading package lists...
Building dependency tree...
Reading state information...

--------

Now Curtin tool is following the rule:

  94_install_pkgs: ["curtin", "in-target", "--", "sh", "-c","DEBIAN_FRONTEND=noninteractive apt-get install -y --assume-yes xterm rxvt x11-apps"]

and using the local-to-ramdisk repository to install those:

--------


The following additional packages will be installed:
  fontconfig-config fonts-dejavu-core libfontconfig1 libgdk-pixbuf2.0-0
  libgdk-pixbuf2.0-common libice6 libjbig0 libjpeg-turbo8 libjpeg8 libsm6
  libstartup-notification0 libtiff5 libx11-xcb1 libxaw7 libxcb-util1
  libxcursor1 libxfixes3 libxft2 libxinerama1 libxkbfile1 libxmu6 libxpm4
  libxrender1 libxt6 rxvt-unicode x11-common xbitmaps
Suggested packages:
  mesa-utils xfonts-cyrillic
Recommended packages:
  libgdk-pixbuf2.0-bin fonts-dejavu fonts-vlgothic | fonts-japanese-gothic
  x11-utils
The following NEW packages will be installed:
  fontconfig-config fonts-dejavu-core libfontconfig1 libgdk-pixbuf2.0-0
  libgdk-pixbuf2.0-common libice6 libjbig0 libjpeg-turbo8 libjpeg8 libsm6
  libstartup-notification0 libtiff5 libx11-xcb1 libxaw7 libxcb-util1
  libxcursor1 libxfixes3 libxft2 libxinerama1 libxkbfile1 libxmu6 libxpm4
  libxrender1 libxt6 rxvt rxvt-unicode x11-apps x11-common xbitmaps xterm
0 upgraded, 30 newly installed, 0 to remove and 6 not upgraded.
Need to get 4459 kB of archives.
After this operation, 16.1 MB of additional disk space will be used.
Get:1 http://127.0.0.1  libjpeg-turbo8 1.5.2-0ubuntu5.18.04.3 [110 kB]
Get:2 http://127.0.0.1  x11-common 1:7.7+19ubuntu7.1 [22.5 kB]
Get:3 http://127.0.0.1  libice6 2:1.0.9-2 [40.2 kB]
Get:4 http://127.0.0.1  libsm6 2:1.2.2-1 [15.8 kB]
Get:5 http://127.0.0.1  fonts-dejavu-core 2.37-1 [1041 kB]
Get:6 http://127.0.0.1  fontconfig-config 2.12.6-0ubuntu2 [55.8 kB]
Get:7 http://127.0.0.1  libfontconfig1 2.12.6-0ubuntu2 [137 kB]
Get:8 http://127.0.0.1  libxrender1 1:0.9.10-1 [18.7 kB]
Get:9 http://127.0.0.1  libxft2 2.3.2-1 [36.1 kB]
Get:10 http://127.0.0.1  libxinerama1 2:1.1.3-1 [7908 B]
Get:11 http://127.0.0.1  libjpeg8 8c-2ubuntu8 [2194 B]
Get:12 http://127.0.0.1  libjbig0 2.1-3.1build1 [26.7 kB]
Get:13 http://127.0.0.1  libtiff5 4.0.9-5ubuntu0.3 [153 kB]
Get:14 http://127.0.0.1  libgdk-pixbuf2.0-common 2.36.11-2 [4536 B]
Get:15 http://127.0.0.1  libgdk-pixbuf2.0-0 2.36.11-2 [165 kB]
Get:16 http://127.0.0.1  libx11-xcb1 2:1.6.4-3ubuntu0.2 [9376 B]
Get:17 http://127.0.0.1  libxcb-util1 0.4.0-0ubuntu3 [11.2 kB]
Get:18 http://127.0.0.1  libstartup-notification0 0.12-5 [18.9 kB]
Get:19 http://127.0.0.1  libxt6 1:1.1.5-1 [160 kB]
Get:20 http://127.0.0.1  libxmu6 2:1.1.2-2 [46.0 kB]
Get:21 http://127.0.0.1  libxpm4 1:3.5.12-1 [34.0 kB]
Get:22 http://127.0.0.1  libxaw7 2:1.0.13-1 [173 kB]
Get:23 http://127.0.0.1  libxfixes3 1:5.0.3-1 [10.8 kB]
Get:24 http://127.0.0.1  libxcursor1 1:1.1.15-1 [19.8 kB]
Get:25 http://127.0.0.1  libxkbfile1 1:1.0.9-2 [64.6 kB]
Get:26 http://127.0.0.1  rxvt-unicode 9.22-3 [729 kB]
Get:27 http://127.0.0.1  rxvt 1:2.7.10-7.1+urxvt9.22-3 [4152 B]
Get:28 http://127.0.0.1  x11-apps 7.7+6ubuntu1 [653 kB]
Get:29 http://127.0.0.1  xbitmaps 1.1.1-2 [28.1 kB]
Get:30 http://127.0.0.1  xterm 330-1ubuntu2 [661 kB]
Fetched 4459 kB in 0s (43.8 MB/s)
E: Can not write log (Is /dev/pts mounted?) - posix_openpt (19: No such device)
Selecting previously unselected package libjpeg-turbo8:amd64.
(Reading database ... 37609 files and directories currently installed.)
Preparing to unpack .../00-libjpeg-turbo8_1.5.2-0ubuntu5.18.04.3_amd64.deb ...
Unpacking libjpeg-turbo8:amd64 (1.5.2-0ubuntu5.18.04.3) ...
Selecting previously unselected package x11-common.
Preparing to unpack .../01-x11-common_1%3a7.7+19ubuntu7.1_all.deb ...
dpkg-query: no packages found matching nux-tools
Unpacking x11-common (1:7.7+19ubuntu7.1) ...
Selecting previously unselected package libice6:amd64.
Preparing to unpack .../02-libice6_2%3a1.0.9-2_amd64.deb ...
Unpacking libice6:amd64 (2:1.0.9-2) ...
Selecting previously unselected package libsm6:amd64.
Preparing to unpack .../03-libsm6_2%3a1.2.2-1_amd64.deb ...
Unpacking libsm6:amd64 (2:1.2.2-1) ...
Selecting previously unselected package fonts-dejavu-core.
Preparing to unpack .../04-fonts-dejavu-core_2.37-1_all.deb ...
Unpacking fonts-dejavu-core (2.37-1) ...
Selecting previously unselected package fontconfig-config.
Preparing to unpack .../05-fontconfig-config_2.12.6-0ubuntu2_all.deb ...
Unpacking fontconfig-config (2.12.6-0ubuntu2) ...
Selecting previously unselected package libfontconfig1:amd64.
Preparing to unpack .../06-libfontconfig1_2.12.6-0ubuntu2_amd64.deb ...
Unpacking libfontconfig1:amd64 (2.12.6-0ubuntu2) ...
Selecting previously unselected package libxrender1:amd64.
Preparing to unpack .../07-libxrender1_1%3a0.9.10-1_amd64.deb ...
Unpacking libxrender1:amd64 (1:0.9.10-1) ...
Selecting previously unselected package libxft2:amd64.
Preparing to unpack .../08-libxft2_2.3.2-1_amd64.deb ...
Unpacking libxft2:amd64 (2.3.2-1) ...
Selecting previously unselected package libxinerama1:amd64.
Preparing to unpack .../09-libxinerama1_2%3a1.1.3-1_amd64.deb ...
Unpacking libxinerama1:amd64 (2:1.1.3-1) ...
Selecting previously unselected package libjpeg8:amd64.
Preparing to unpack .../10-libjpeg8_8c-2ubuntu8_amd64.deb ...
Unpacking libjpeg8:amd64 (8c-2ubuntu8) ...
Selecting previously unselected package libjbig0:amd64.
Preparing to unpack .../11-libjbig0_2.1-3.1build1_amd64.deb ...
Unpacking libjbig0:amd64 (2.1-3.1build1) ...
Selecting previously unselected package libtiff5:amd64.
Preparing to unpack .../12-libtiff5_4.0.9-5ubuntu0.3_amd64.deb ...
Unpacking libtiff5:amd64 (4.0.9-5ubuntu0.3) ...
Selecting previously unselected package libgdk-pixbuf2.0-common.
Preparing to unpack .../13-libgdk-pixbuf2.0-common_2.36.11-2_all.deb ...
Unpacking libgdk-pixbuf2.0-common (2.36.11-2) ...
Selecting previously unselected package libgdk-pixbuf2.0-0:amd64.
Preparing to unpack .../14-libgdk-pixbuf2.0-0_2.36.11-2_amd64.deb ...
Unpacking libgdk-pixbuf2.0-0:amd64 (2.36.11-2) ...
Selecting previously unselected package libx11-xcb1:amd64.
Preparing to unpack .../15-libx11-xcb1_2%3a1.6.4-3ubuntu0.2_amd64.deb ...
Unpacking libx11-xcb1:amd64 (2:1.6.4-3ubuntu0.2) ...
Selecting previously unselected package libxcb-util1:amd64.
Preparing to unpack .../16-libxcb-util1_0.4.0-0ubuntu3_amd64.deb ...
Unpacking libxcb-util1:amd64 (0.4.0-0ubuntu3) ...
Selecting previously unselected package libstartup-notification0:amd64.
Preparing to unpack .../17-libstartup-notification0_0.12-5_amd64.deb ...
Unpacking libstartup-notification0:amd64 (0.12-5) ...
Selecting previously unselected package libxt6:amd64.
Preparing to unpack .../18-libxt6_1%3a1.1.5-1_amd64.deb ...
Unpacking libxt6:amd64 (1:1.1.5-1) ...
Selecting previously unselected package libxmu6:amd64.
Preparing to unpack .../19-libxmu6_2%3a1.1.2-2_amd64.deb ...
Unpacking libxmu6:amd64 (2:1.1.2-2) ...
Selecting previously unselected package libxpm4:amd64.
Preparing to unpack .../20-libxpm4_1%3a3.5.12-1_amd64.deb ...
Unpacking libxpm4:amd64 (1:3.5.12-1) ...
Selecting previously unselected package libxaw7:amd64.
Preparing to unpack .../21-libxaw7_2%3a1.0.13-1_amd64.deb ...
Unpacking libxaw7:amd64 (2:1.0.13-1) ...
Selecting previously unselected package libxfixes3:amd64.
Preparing to unpack .../22-libxfixes3_1%3a5.0.3-1_amd64.deb ...
Unpacking libxfixes3:amd64 (1:5.0.3-1) ...
Selecting previously unselected package libxcursor1:amd64.
Preparing to unpack .../23-libxcursor1_1%3a1.1.15-1_amd64.deb ...
Unpacking libxcursor1:amd64 (1:1.1.15-1) ...
Selecting previously unselected package libxkbfile1:amd64.
Preparing to unpack .../24-libxkbfile1_1%3a1.0.9-2_amd64.deb ...
Unpacking libxkbfile1:amd64 (1:1.0.9-2) ...
Selecting previously unselected package rxvt-unicode.
Preparing to unpack .../25-rxvt-unicode_9.22-3_amd64.deb ...
update-alternatives: error: no alternatives for rxvt
Unpacking rxvt-unicode (9.22-3) ...
Selecting previously unselected package rxvt.
Preparing to unpack .../26-rxvt_1%3a2.7.10-7.1+urxvt9.22-3_all.deb ...
Unpacking rxvt (1:2.7.10-7.1+urxvt9.22-3) ...
Selecting previously unselected package x11-apps.
Preparing to unpack .../27-x11-apps_7.7+6ubuntu1_amd64.deb ...
Unpacking x11-apps (7.7+6ubuntu1) ...
Selecting previously unselected package xbitmaps.
Preparing to unpack .../28-xbitmaps_1.1.1-2_all.deb ...
Unpacking xbitmaps (1.1.1-2) ...
Selecting previously unselected package xterm.
Preparing to unpack .../29-xterm_330-1ubuntu2_amd64.deb ...
Unpacking xterm (330-1ubuntu2) ...
Setting up libxkbfile1:amd64 (1:1.0.9-2) ...
Setting up libxinerama1:amd64 (2:1.1.3-1) ...
Setting up libxfixes3:amd64 (1:5.0.3-1) ...
Setting up libjbig0:amd64 (2.1-3.1build1) ...
Setting up fonts-dejavu-core (2.37-1) ...
Setting up xbitmaps (1.1.1-2) ...
Setting up libgdk-pixbuf2.0-common (2.36.11-2) ...
Setting up libjpeg-turbo8:amd64 (1.5.2-0ubuntu5.18.04.3) ...
Setting up libxcb-util1:amd64 (0.4.0-0ubuntu3) ...
Setting up libx11-xcb1:amd64 (2:1.6.4-3ubuntu0.2) ...
Setting up libxpm4:amd64 (1:3.5.12-1) ...
Setting up libxrender1:amd64 (1:0.9.10-1) ...
Setting up x11-common (1:7.7+19ubuntu7.1) ...
Setting up libjpeg8:amd64 (8c-2ubuntu8) ...
Setting up fontconfig-config (2.12.6-0ubuntu2) ...
Setting up libtiff5:amd64 (4.0.9-5ubuntu0.3) ...
Setting up libstartup-notification0:amd64 (0.12-5) ...
Setting up libxcursor1:amd64 (1:1.1.15-1) ...
Setting up libice6:amd64 (2:1.0.9-2) ...
Setting up libfontconfig1:amd64 (2.12.6-0ubuntu2) ...
Setting up libsm6:amd64 (2:1.2.2-1) ...
Setting up libgdk-pixbuf2.0-0:amd64 (2.36.11-2) ...
Setting up libxt6:amd64 (1:1.1.5-1) ...
Setting up libxft2:amd64 (2.3.2-1) ...
Setting up rxvt-unicode (9.22-3) ...
Setting up rxvt (1:2.7.10-7.1+urxvt9.22-3) ...
Setting up libxmu6:amd64 (2:1.1.2-2) ...
Setting up libxaw7:amd64 (2:1.0.13-1) ...
Setting up xterm (330-1ubuntu2) ...
Setting up x11-apps (7.7+6ubuntu1) ...
Processing triggers for ureadahead (0.100.0-21) ...
Processing triggers for libc-bin (2.27-3ubuntu1) ...
Processing triggers for systemd (237-3ubuntu10.33) ...
Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
Processing triggers for mime-support (3.60ubuntu1) ...
Reading package lists...
Building dependency tree...
Reading state information...
The following packages will be REMOVED:
  unattended-upgrades*
0 upgraded, 0 newly installed, 1 to remove and 6 not upgraded.
After this operation, 418 kB disk space will be freed.
E: Can not write log (Is /dev/pts mounted?) - posix_openpt (19: No such device)
(Reading database ... 38218 files and directories currently installed.)
Removing unattended-upgrades (1.1ubuntu1.18.04.13) ...
Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
(Reading database ... 38191 files and directories currently installed.)
Purging configuration files for unattended-upgrades (1.1ubuntu1.18.04.13) ...
Processing triggers for systemd (237-3ubuntu10.33) ...
Processing triggers for ureadahead (0.100.0-21) ...
{instance-id: 1806584f-f426-44d8-b9d6-40156d08968a}
curtin: Installation finished.
Press any key to halt ...

--------

At this point we finished installing "our server" (livecdinstall virtual
machine). Remember that the virtual machine XML is telling it to always boot
from the cdrom first. We have to change it:

--------

rafaeldtinoco@workstation:~$ virsh destroy livecdinstall
Domain livecdinstall destroyed

rafaeldtinoco@workstation:~$ virsh edit livecdinstall
Domain livecdinstall XML configuration edited.

--------

Make sure to change:

--------

  <os>
    <type arch='x86_64' machine='pc-i440fx-4.0'>hvm</type>
    <boot dev='cdrom'/>
    <boot dev='hd'/>
  </os>

--------

to:

--------

  <os>
    <type arch='x86_64' machine='pc-i440fx-4.0'>hvm</type>
    <boot dev='hd'/>
    <boot dev='cdrom'/>
  </os>

--------

Okay, now the server is "installed". Lets suppose the installed server was
pre-installed and shipped. End-customer plugs the server into the network
and powers it up. Cloud-Init will do the rest of the job based on the
"machine01-cloud.yaml" file since during the installation the installer chose
option (1).

Let's see... (and sorry, this next output is extended but its a real output from
the first boot of a just-installed, by this tool, virtual machine. I wanted it
to be full so you can follow all configuration made in cloud-init file).

--------

rafaeldtinoco@workstation:~$ virsh start --console livecdinstall
Domain livecdinstall started
Connected to domain livecdinstall
Escape character is ^]
[    0.000000] Linux version 4.15.0-76-generic (buildd@lcy01-amd64-029) (gcc version 7.4.0 (Ubuntu 7.4.0-1ubuntu1~18.04.1)) #86-Ubuntu SMP
 Fri Jan 17 17:24:28 UTC 2020 (Ubuntu 4.15.0-76.86-generic 4.15.18)
[    0.000000] Command line: BOOT_IMAGE=/boot/vmlinuz-4.15.0-76-generic root=UUID=cb3c594d-2432-47eb-a114-09fea1c13716 ro console=tty0 con
sole=ttyS0,38400n8
[    0.000000] KERNEL supported cpus:
[    0.000000]   Intel GenuineIntel
[    0.000000]   AMD AuthenticAMD
[    0.000000]   Centaur CentaurHauls
[    0.000000] random: get_random_u32 called from bsp_init_amd+0x207/0x2c0 with crng_init=0
[    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'
[    0.000000] x86/fpu: Supporting XSAVE feature 0x002: 'SSE registers'
[    0.000000] x86/fpu: Supporting XSAVE feature 0x004: 'AVX registers'
[    0.000000] x86/fpu: xstate_offset[2]:  576, xstate_sizes[2]:  256
[    0.000000] x86/fpu: Enabled xstate features 0x7, context size is 832 bytes, using 'standard' format.
[    0.000000] e820: BIOS-provided physical RAM map:
[    0.000000] BIOS-e820: [mem 0x0000000000000000-0x000000000009fbff] usable
[    0.000000] BIOS-e820: [mem 0x000000000009fc00-0x000000000009ffff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000000f0000-0x00000000000fffff] reserved
[    0.000000] BIOS-e820: [mem 0x0000000000100000-0x00000000bffdbfff] usable
[    0.000000] BIOS-e820: [mem 0x00000000bffdc000-0x00000000bfffffff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000feffc000-0x00000000feffffff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000fffc0000-0x00000000ffffffff] reserved
[    0.000000] BIOS-e820: [mem 0x0000000100000000-0x000000013fffffff] usable
[    0.000000] NX (Execute Disable) protection: active
[    0.000000] SMBIOS 2.8 present.
[    0.000000] DMI: QEMU Standard PC (i440FX + PIIX, 1996), BIOS 1.12.0-1 04/01/2014
[    0.000000] Hypervisor detected: KVM
[    0.000000] AGP: No AGP bridge found
[    0.000000] e820: last_pfn = 0x140000 max_arch_pfn = 0x400000000
[    0.000000] x86/PAT: Configuration [0-7]: WB  WC  UC- UC  WB  WP  UC- WT
[    0.000000] e820: last_pfn = 0xbffdc max_arch_pfn = 0x400000000
[    0.000000] found SMP MP-table at [mem 0x000f5a40-0x000f5a4f]
[    0.000000] Scanning 1 areas for low memory corruption
[    0.000000] Using GB pages for direct mapping
[    0.000000] RAMDISK: [mem 0x3117d000-0x348b5fff]
[    0.000000] ACPI: Early table checksum verification disabled
[    0.000000] ACPI: RSDP 0x00000000000F5A00 000014 (v00 BOCHS )
[    0.000000] ACPI: RSDT 0x00000000BFFE13B8 000030 (v01 BOCHS  BXPCRSDT 00000001 BXPC 00000001)
[    0.000000] ACPI: FACP 0x00000000BFFE127C 000074 (v01 BOCHS  BXPCFACP 00000001 BXPC 00000001)
[    0.000000] ACPI: DSDT 0x00000000BFFDFDC0 0014BC (v01 BOCHS  BXPCDSDT 00000001 BXPC 00000001)
[    0.000000] ACPI: FACS 0x00000000BFFDFD80 000040
[    0.000000] ACPI: APIC 0x00000000BFFE12F0 000090 (v01 BOCHS  BXPCAPIC 00000001 BXPC 00000001)
[    0.000000] ACPI: HPET 0x00000000BFFE1380 000038 (v01 BOCHS  BXPCHPET 00000001 BXPC 00000001)
[    0.000000] No NUMA configuration found
[    0.000000] Faking a node at [mem 0x0000000000000000-0x000000013fffffff]
[    0.000000] NODE_DATA(0) allocated [mem 0x13ffd3000-0x13fffdfff]
[    0.000000] kvm-clock: cpu 0, msr 1:3ff52001, primary cpu clock
[    0.000000] kvm-clock: Using msrs 4b564d01 and 4b564d00
[    0.000000] kvm-clock: using sched offset of 2013499044 cycles
[    0.000000] clocksource: kvm-clock: mask: 0xffffffffffffffff max_cycles: 0x1cd42e4dffb, max_idle_ns: 881590591483 ns
[    0.000000] Zone ranges:
[    0.000000]   DMA      [mem 0x0000000000001000-0x0000000000ffffff]
[    0.000000]   DMA32    [mem 0x0000000001000000-0x00000000ffffffff]
[    0.000000]   Normal   [mem 0x0000000100000000-0x000000013fffffff]
[    0.000000]   Device   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000000001000-0x000000000009efff]
[    0.000000]   node   0: [mem 0x0000000000100000-0x00000000bffdbfff]
[    0.000000]   node   0: [mem 0x0000000100000000-0x000000013fffffff]
[    0.000000] Reserved but unavailable: 98 pages
[    0.000000] Initmem setup node 0 [mem 0x0000000000001000-0x000000013fffffff]
[    0.000000] ACPI: PM-Timer IO Port: 0x608
[    0.000000] ACPI: LAPIC_NMI (acpi_id[0xff] dfl dfl lint[0x1])
[    0.000000] IOAPIC[0]: apic_id 0, version 17, address 0xfec00000, GSI 0-23
[    0.000000] ACPI: INT_SRC_OVR (bus 0 bus_irq 0 global_irq 2 dfl dfl)
[    0.000000] ACPI: INT_SRC_OVR (bus 0 bus_irq 5 global_irq 5 high level)
[    0.000000] ACPI: INT_SRC_OVR (bus 0 bus_irq 9 global_irq 9 high level)
[    0.000000] ACPI: INT_SRC_OVR (bus 0 bus_irq 10 global_irq 10 high level)
[    0.000000] ACPI: INT_SRC_OVR (bus 0 bus_irq 11 global_irq 11 high level)
[    0.000000] Using ACPI (MADT) for SMP configuration information
[    0.000000] ACPI: HPET id: 0x8086a201 base: 0xfed00000
[    0.000000] smpboot: Allowing 4 CPUs, 0 hotplug CPUs
[    0.000000] PM: Registered nosave memory: [mem 0x00000000-0x00000fff]
[    0.000000] PM: Registered nosave memory: [mem 0x0009f000-0x0009ffff]
[    0.000000] PM: Registered nosave memory: [mem 0x000a0000-0x000effff]
[    0.000000] PM: Registered nosave memory: [mem 0x000f0000-0x000fffff]
[    0.000000] PM: Registered nosave memory: [mem 0xbffdc000-0xbfffffff]
[    0.000000] PM: Registered nosave memory: [mem 0xc0000000-0xfeffbfff]
[    0.000000] PM: Registered nosave memory: [mem 0xfeffc000-0xfeffffff]
[    0.000000] PM: Registered nosave memory: [mem 0xff000000-0xfffbffff]
[    0.000000] PM: Registered nosave memory: [mem 0xfffc0000-0xffffffff]
[    0.000000] e820: [mem 0xc0000000-0xfeffbfff] available for PCI devices
[    0.000000] Booting paravirtualized kernel on KVM
[    0.000000] clocksource: refined-jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645519600211568 ns
[    0.000000] setup_percpu: NR_CPUS:8192 nr_cpumask_bits:4 nr_cpu_ids:4 nr_node_ids:1
[    0.000000] percpu: Embedded 45 pages/cpu s147456 r8192 d28672 u524288
[    0.000000] KVM setup async PF for cpu 0
[    0.000000] kvm-stealtime: cpu 0, msr 13fc23040
[    0.000000] PV qspinlock hash table entries: 256 (order: 0, 4096 bytes)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 1032037
[    0.000000] Policy zone: Normal
[    0.000000] Kernel command line: BOOT_IMAGE=/boot/vmlinuz-4.15.0-76-generic root=UUID=cb3c594d-2432-47eb-a114-09fea1c13716 ro console=t
ty0 console=ttyS0,38400n8
[    0.000000] AGP: Checking aperture...
[    0.000000] AGP: No AGP bridge found
[    0.000000] Memory: 3975908K/4193768K available (12300K kernel code, 2481K rwdata, 4260K rodata, 2428K init, 2704K bss, 217860K reserve
d, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=4, Nodes=1
[    0.000000] ftrace: allocating 39322 entries in 154 pages
[    0.004000] Hierarchical RCU implementation.
[    0.004000]  RCU restricting CPUs from NR_CPUS=8192 to nr_cpu_ids=4.
[    0.004000]  Tasks RCU enabled.
[    0.004000] RCU: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=4
[    0.004000] NR_IRQS: 524544, nr_irqs: 456, preallocated irqs: 16
[    0.004000] Console: colour VGA+ 80x25
[    0.004000] console [tty0] enabled
[    0.004000] console [ttyS0] enabled
[    0.004000] ACPI: Core revision 20170831
[    0.004000] ACPI: 1 ACPI AML tables successfully acquired and loaded
[    0.004000] clocksource: hpet: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604467 ns
[    0.004008] APIC: Switch to symmetric I/O mode setup
[    0.005225] x2apic enabled
[    0.006060] Switched APIC routing to physical x2apic.
[    0.008000] ..TIMER: vector=0x30 apic1=0 pin1=2 apic2=-1 pin2=-1
[    0.008000] tsc: Detected 4013.492 MHz processor
[    0.008000] tsc: Marking TSC unstable due to TSCs unsynchronized
[    0.008000] Calibrating delay loop (skipped) preset value.. 8026.98 BogoMIPS (lpj=16053968)
[    0.008002] pid_max: default: 32768 minimum: 301
[    0.009076] Security Framework initialized
[    0.009982] Yama: becoming mindful.
[    0.012021] AppArmor: AppArmor initialized
[    0.014232] Dentry cache hash table entries: 524288 (order: 10, 4194304 bytes)
[    0.016636] Inode-cache hash table entries: 262144 (order: 9, 2097152 bytes)
[    0.018161] Mount-cache hash table entries: 8192 (order: 4, 65536 bytes)
[    0.019554] Mountpoint-cache hash table entries: 8192 (order: 4, 65536 bytes)
[    0.020274] Last level iTLB entries: 4KB 512, 2MB 1024, 4MB 512
[    0.021536] Last level dTLB entries: 4KB 512, 2MB 255, 4MB 127, 1GB 0
[    0.024003] Spectre V1 : Mitigation: usercopy/swapgs barriers and __user pointer sanitization
[    0.025823] Spectre V2 : Mitigation: Full AMD retpoline
[    0.026967] Spectre V2 : Spectre v2 / SpectreRSB mitigation: Filling RSB on context switch
[    0.028008] Spectre V2 : mitigation: Enabling conditional Indirect Branch Prediction Barrier
[    0.029803] Speculative Store Bypass: Mitigation: Speculative Store Bypass disabled via prctl and seccomp
[    0.032199] Freeing SMP alternatives memory: 36K
[    0.036374] smpboot: CPU0: AMD FX(tm)-8350 Eight-Core Processor (family: 0x15, model: 0x2, stepping: 0x0)
[    0.038465] Performance Events: Fam15h core perfctr, AMD PMU driver.
[    0.039873] ... version:                0
[    0.040004] ... bit width:              48
[    0.040930] ... generic registers:      6
[    0.041820] ... value mask:             0000ffffffffffff
[    0.043003] ... max period:             00007fffffffffff
[    0.044003] ... fixed-purpose events:   0
[    0.044903] ... event mask:             000000000000003f
[    0.046094] Hierarchical SRCU implementation.
[    0.047681] smp: Bringing up secondary CPUs ...
[    0.048555] x86: Booting SMP configuration:
[    0.049504] .... node  #0, CPUs:      #1
[    0.004000] kvm-clock: cpu 1, msr 1:3ff52041, secondary cpu clock
[    0.051760] KVM setup async PF for cpu 1
[    0.051760] kvm-stealtime: cpu 1, msr 13fca3040
[    0.052105]  #2
[    0.004000] kvm-clock: cpu 2, msr 1:3ff52081, secondary cpu clock
[    0.053889] KVM setup async PF for cpu 2
[    0.053889] kvm-stealtime: cpu 2, msr 13fd23040
[    0.056103]  #3
[    0.004000] kvm-clock: cpu 3, msr 1:3ff520c1, secondary cpu clock
[    0.057757] KVM setup async PF for cpu 3
[    0.057757] kvm-stealtime: cpu 3, msr 13fda3040
[    0.060002] smp: Brought up 1 node, 4 CPUs
[    0.060931] smpboot: Max logical packages: 4
[    0.061849] smpboot: Total of 4 processors activated (32107.93 BogoMIPS)
[    0.064415] devtmpfs: initialized
[    0.064808] x86/mm: Memory block size: 128MB
[    0.066110] evm: security.selinux
[    0.066885] evm: security.SMACK64
[    0.068005] evm: security.SMACK64EXEC
[    0.068833] evm: security.SMACK64TRANSMUTE
[    0.069743] evm: security.SMACK64MMAP
[    0.070565] evm: security.apparmor
[    0.071326] evm: security.ima
[    0.072004] evm: security.capability
[    0.072832] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645041785100000 ns
[    0.073941] futex hash table entries: 1024 (order: 4, 65536 bytes)
[    0.076083] pinctrl core: initialized pinctrl subsystem
[    0.077330] RTC time:  4:28:46, date: 01/22/20
[    0.079317] NET: Registered protocol family 16
[    0.080073] audit: initializing netlink subsys (disabled)
[    0.081248] audit: type=2000 audit(1579667326.637:1): state=initialized audit_enabled=0 res=1
[    0.081248] cpuidle: using governor ladder
[    0.081248] cpuidle: using governor menu
[    0.084433] ACPI: bus type PCI registered
[    0.084997] acpiphp: ACPI Hot Plug PCI Controller Driver version: 0.5
[    0.086408] PCI: Using configuration type 1 for base access
[    0.088005] PCI: Using configuration type 1 for extended access
[    0.089286] HugeTLB registered 1.00 GiB page size, pre-allocated 0 pages
[    0.092011] HugeTLB registered 2.00 MiB page size, pre-allocated 0 pages
[    0.093395] ACPI: Added _OSI(Module Device)
[    0.093395] ACPI: Added _OSI(Processor Device)
[    0.096006] ACPI: Added _OSI(3.0 _SCP Extensions)
[    0.097030] ACPI: Added _OSI(Processor Aggregator Device)
[    0.098146] ACPI: Added _OSI(Linux-Dell-Video)
[    0.099101] ACPI: Added _OSI(Linux-Lenovo-NV-HDMI-Audio)
[    0.100004] ACPI: Added _OSI(Linux-HPI-Hybrid-Graphics)
[    0.102441] ACPI: Interpreter enabled
[    0.103287] ACPI: (supports S0 S5)
[    0.104005] ACPI: Using IOAPIC for interrupt routing
[    0.105070] PCI: Using host bridge windows from ACPI; if necessary, use "pci=nocrs" and report a bug
[    0.107077] ACPI: Enabled 2 GPEs in block 00 to 0F
[    0.111194] ACPI: PCI Root Bridge [PCI0] (domain 0000 [bus 00-ff])
[    0.112008] acpi PNP0A03:00: _OSC: OS supports [ExtendedConfig ASPM ClockPM Segments MSI]
[    0.113708] acpi PNP0A03:00: _OSC failed (AE_NOT_FOUND); disabling ASPM
[    0.115397] acpiphp: Slot [3] registered
[    0.116035] acpiphp: Slot [4] registered
[    0.116929] acpiphp: Slot [5] registered
[    0.117822] acpiphp: Slot [6] registered
[    0.118710] acpiphp: Slot [7] registered
[    0.119597] acpiphp: Slot [8] registered
[    0.120034] acpiphp: Slot [9] registered
[    0.120934] acpiphp: Slot [10] registered
[    0.121854] acpiphp: Slot [11] registered
[    0.122765] acpiphp: Slot [12] registered
[    0.123680] acpiphp: Slot [13] registered
[    0.124033] acpiphp: Slot [14] registered
[    0.124962] acpiphp: Slot [15] registered
[    0.125884] acpiphp: Slot [16] registered
[    0.126781] acpiphp: Slot [17] registered
[    0.127684] acpiphp: Slot [18] registered
[    0.128034] acpiphp: Slot [19] registered
[    0.128982] acpiphp: Slot [20] registered
[    0.129909] acpiphp: Slot [21] registered
[    0.130826] acpiphp: Slot [22] registered
[    0.131737] acpiphp: Slot [23] registered
[    0.132034] acpiphp: Slot [24] registered
[    0.132883] acpiphp: Slot [25] registered
[    0.133724] acpiphp: Slot [26] registered
[    0.134574] acpiphp: Slot [27] registered
[    0.135429] acpiphp: Slot [28] registered
[    0.136034] acpiphp: Slot [29] registered
[    0.136875] acpiphp: Slot [30] registered
[    0.137711] acpiphp: Slot [31] registered
[    0.138524] PCI host bridge to bus 0000:00
[    0.139360] pci_bus 0000:00: root bus resource [io  0x0000-0x0cf7 window]
[    0.140004] pci_bus 0000:00: root bus resource [io  0x0d00-0xffff window]
[    0.141293] pci_bus 0000:00: root bus resource [mem 0x000a0000-0x000bffff window]
[    0.144004] pci_bus 0000:00: root bus resource [mem 0xc0000000-0xfebfffff window]
[    0.145595] pci_bus 0000:00: root bus resource [mem 0x140000000-0x1bfffffff window]
[    0.147187] pci_bus 0000:00: root bus resource [bus 00-ff]
[    0.152591] pci 0000:00:01.1: legacy IDE quirk: reg 0x10: [io  0x01f0-0x01f7]
[    0.154107] pci 0000:00:01.1: legacy IDE quirk: reg 0x14: [io  0x03f6]
[    0.155458] pci 0000:00:01.1: legacy IDE quirk: reg 0x18: [io  0x0170-0x0177]
[    0.156005] pci 0000:00:01.1: legacy IDE quirk: reg 0x1c: [io  0x0376]
[    0.161084] pci 0000:00:01.3: quirk: [io  0x0600-0x063f] claimed by PIIX4 ACPI
[    0.162618] pci 0000:00:01.3: quirk: [io  0x0700-0x070f] claimed by PIIX4 SMB
[    0.195632] ACPI: PCI Interrupt Link [LNKA] (IRQs 5 *10 11)
[    0.196115] ACPI: PCI Interrupt Link [LNKB] (IRQs 5 *10 11)
[    0.197388] ACPI: PCI Interrupt Link [LNKC] (IRQs 5 10 *11)
[    0.199048] ACPI: PCI Interrupt Link [LNKD] (IRQs 5 10 *11)
[    0.200059] ACPI: PCI Interrupt Link [LNKS] (IRQs *9)
[    0.201684] SCSI subsystem initialized
[    0.202578] pci 0000:00:02.0: vgaarb: setting as boot VGA device
[    0.202578] pci 0000:00:02.0: vgaarb: VGA device added: decodes=io+mem,owns=io+mem,locks=none
[    0.204012] pci 0000:00:02.0: vgaarb: bridge control possible
[    0.205239] vgaarb: loaded
[    0.205907] ACPI: bus type USB registered
[    0.206800] usbcore: registered new interface driver usbfs
[    0.207941] usbcore: registered new interface driver hub
[    0.208049] usbcore: registered new device driver usb
[    0.209200] EDAC MC: Ver: 3.0.0
[    0.209200] PCI: Using ACPI for IRQ routing
[    0.209200] NetLabel: Initializing
[    0.212005] NetLabel:  domain hash size = 128
[    0.212935] NetLabel:  protocols = UNLABELED CIPSOv4 CALIPSO
[    0.214128] NetLabel:  unlabeled traffic allowed by default
[    0.215299] hpet0: at MMIO 0xfed00000, IRQs 2, 8, 0
[    0.216005] hpet0: 3 comparators, 64-bit 100.000000 MHz counter
[    0.221119] clocksource: Switched to clocksource kvm-clock
[    0.234293] VFS: Disk quotas dquot_6.6.0
[    0.235236] VFS: Dquot-cache hash table entries: 512 (order 0, 4096 bytes)
[    0.236729] AppArmor: AppArmor Filesystem Enabled
[    0.237763] pnp: PnP ACPI init
[    0.238924] pnp: PnP ACPI: found 5 devices
[    0.246467] clocksource: acpi_pm: mask: 0xffffff max_cycles: 0xffffff, max_idle_ns: 2085701024 ns
[    0.248427] NET: Registered protocol family 2
[    0.249534] TCP established hash table entries: 32768 (order: 6, 262144 bytes)
[    0.251087] TCP bind hash table entries: 32768 (order: 7, 524288 bytes)
[    0.252969] TCP: Hash tables configured (established 32768 bind 32768)
[    0.254423] UDP hash table entries: 2048 (order: 4, 65536 bytes)
[    0.255801] UDP-Lite hash table entries: 2048 (order: 4, 65536 bytes)
[    0.257079] NET: Registered protocol family 1
[    0.257962] pci 0000:00:00.0: Limiting direct PCI/PCI transfers
[    0.259166] pci 0000:00:01.0: PIIX3: Enabling Passive Release
[    0.260391] pci 0000:00:01.0: Activating ISA DMA hang workarounds
[    0.290879] ACPI: PCI Interrupt Link [LNKD] enabled at IRQ 11
[    0.321358] pci 0000:00:02.0: Video device with shadowed ROM at [mem 0x000c0000-0x000dffff]
[    0.323148] Unpacking initramfs...
[    0.986349] Freeing initrd memory: 56548K
[    0.987385] PCI-DMA: Using software bounce buffering for IO (SWIOTLB)
[    0.988765] software IO TLB: mapped [mem 0xbbfdc000-0xbffdc000] (64MB)
[    0.990190] clocksource: tsc: mask: 0xffffffffffffffff max_cycles: 0x39da262945c, max_idle_ns: 440795296057 ns
[    0.992322] Scanning for low memory corruption every 60 seconds
[    0.994179] Initialise system trusted keyrings
[    0.995139] Key type blacklist registered
[    0.996048] workingset: timestamp_bits=36 max_order=20 bucket_order=0
[    0.998560] zbud: loaded
[    0.999659] squashfs: version 4.0 (2009/01/31) Phillip Lougher
[    1.001124] fuse init (API version 7.26)
[    1.003653] Key type asymmetric registered
[    1.004587] Asymmetric key parser 'x509' registered
[    1.005658] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 246)
[    1.007252] io scheduler noop registered
[    1.008152] io scheduler deadline registered
[    1.009102] io scheduler cfq registered (default)
[    1.010834] input: Power Button as /devices/LNXSYSTM:00/LNXPWRBN:00/input/input0
[    1.012474] ACPI: Power Button [PWRF]
[    1.042940] ACPI: PCI Interrupt Link [LNKC] enabled at IRQ 10
[    1.104182] ACPI: PCI Interrupt Link [LNKA] enabled at IRQ 10
[    1.106610] Serial: 8250/16550 driver, 32 ports, IRQ sharing enabled
[    1.133519] 00:04: ttyS0 at I/O 0x3f8 (irq = 4, base_baud = 115200) is a 16550A
[    1.137011] Linux agpgart interface v0.103
[    1.139468] loop: module loaded
[    1.140696] scsi host0: ata_piix
[    1.141502] scsi host1: ata_piix
[    1.142225] ata1: PATA max MWDMA2 cmd 0x1f0 ctl 0x3f6 bmdma 0xc100 irq 14
[    1.143512] ata2: PATA max MWDMA2 cmd 0x170 ctl 0x376 bmdma 0xc108 irq 15
[    1.144996] libphy: Fixed MDIO Bus: probed
[    1.146108] tun: Universal TUN/TAP device driver, 1.6
[    1.147212] PPP generic driver version 2.4.2
[    1.148222] ehci_hcd: USB 2.0 'Enhanced' Host Controller (EHCI) Driver
[    1.149579] ehci-pci: EHCI PCI platform driver
[    1.150551] ehci-platform: EHCI generic platform driver
[    1.151662] ohci_hcd: USB 1.1 'Open' Host Controller (OHCI) Driver
[    1.152977] ohci-pci: OHCI PCI platform driver
[    1.153954] ohci-platform: OHCI generic platform driver
[    1.155083] uhci_hcd: USB Universal Host Controller Interface driver
[    1.185982] uhci_hcd 0000:00:01.2: UHCI Host Controller
[    1.187145] uhci_hcd 0000:00:01.2: new USB bus registered, assigned bus number 1
[    1.188745] uhci_hcd 0000:00:01.2: detected 2 ports
[    1.189918] uhci_hcd 0000:00:01.2: irq 11, io base 0x0000c0c0
[    1.191211] usb usb1: New USB device found, idVendor=1d6b, idProduct=0001
[    1.192687] usb usb1: New USB device strings: Mfr=3, Product=2, SerialNumber=1
[    1.194219] usb usb1: Product: UHCI Host Controller
[    1.195325] usb usb1: Manufacturer: Linux 4.15.0-76-generic uhci_hcd
[    1.196694] usb usb1: SerialNumber: 0000:00:01.2
[    1.197747] hub 1-0:1.0: USB hub found
[    1.198554] hub 1-0:1.0: 2 ports detected
[    1.199541] i8042: PNP: PS/2 Controller [PNP0303:KBD,PNP0f13:MOU] at 0x60,0x64 irq 1,12
[    1.201848] serio: i8042 KBD port at 0x60,0x64 irq 1
[    1.202880] serio: i8042 AUX port at 0x60,0x64 irq 12
[    1.204019] mousedev: PS/2 mouse device common for all mice
[    1.205322] rtc_cmos 00:00: RTC can wake from S4
[    1.206618] rtc_cmos 00:00: rtc core: registered rtc_cmos as rtc0
[    1.207956] input: AT Translated Set 2 keyboard as /devices/platform/i8042/serio0/input/input1
[    1.209770] rtc_cmos 00:00: alarms up to one day, y3k, 114 bytes nvram, hpet irqs
[    1.211735] i2c /dev entries driver
[    1.212711] device-mapper: uevent: version 1.0.3
[    1.213942] device-mapper: ioctl: 4.37.0-ioctl (2017-09-20) initialised: dm-devel@redhat.com
[    1.216059] ledtrig-cpu: registered to indicate activity on CPUs
[    1.217797] x86/pm: family 0x15 cpu detected, MSR saving is needed during suspending.
[    1.220369] NET: Registered protocol family 10
[    1.224481] Segment Routing with IPv6
[    1.225480] NET: Registered protocol family 17
[    1.226683] Key type dns_resolver registered
[    1.228099] mce: Using 10 MCE banks
[    1.229025] RAS: Correctable Errors collector initialized.
[    1.230391] sched_clock: Marking stable (1228063389, 0)->(1564092572, -336029183)
[    1.232543] registered taskstats version 1
[    1.233599] Loading compiled-in X.509 certificates
[    1.236820] Loaded X.509 cert 'Build time autogenerated kernel key: 665cd2b89e03521f57c41865f552ebce30a0c7fb'
[    1.239265] zswap: loaded using pool lzo/zbud
[    1.243007] Key type big_key registered
[    1.244014] Key type trusted registered
[    1.246309] Key type encrypted registered
[    1.247317] AppArmor: AppArmor sha1 policy hashing enabled
[    1.248660] ima: No TPM chip found, activating TPM-bypass! (rc=-19)
[    1.250168] ima: Allocated hash algorithm: sha1
[    1.251324] evm: HMAC attrs: 0x1
[    1.252484]   Magic number: 4:968:464
[    1.253549] rtc_cmos 00:00: setting system clock to 2020-01-22 04:28:47 UTC (1579667327)
[    1.255674] BIOS EDD facility v0.16 2004-Jun-25, 0 devices found
[    1.257176] EDD information not available.
[    1.305129] ata2.00: ATAPI: QEMU DVD-ROM, 2.5+, max UDMA/100
[    1.306732] ata2.00: configured for MWDMA2
[    1.308152] scsi 1:0:0:0: CD-ROM            QEMU     QEMU DVD-ROM     2.5+ PQ: 0 ANSI: 5
[    1.310627] sr 1:0:0:0: [sr0] scsi3-mmc drive: 4x/4x cd/rw xa/form2 tray
[    1.311914] cdrom: Uniform CD-ROM driver Revision: 3.20
[    1.313141] sr 1:0:0:0: Attached scsi generic sg0 type 5
[    1.317169] Freeing unused kernel image memory: 2428K
[    1.328126] Write protecting the kernel read-only data: 20480k
[    1.330218] Freeing unused kernel image memory: 2008K
[    1.331858] Freeing unused kernel image memory: 1884K
[    1.341125] x86/mm: Checked W+X mappings: passed, no W+X pages found.
Loading, please wait...
starting version 237
[    1.410913]  vda: vda1 vda2
[    1.411189] input: VirtualPS/2 VMware VMMouse as /devices/platform/i8042/serio1/input/input4
[    1.413985] piix4_smbus 0000:00:01.3: SMBus Host Controller at 0x700, revision 0
[    1.414321] input: VirtualPS/2 VMware VMMouse as /devices/platform/i8042/serio1/input/input3
[    1.417604] FDC 0 is a S82078B
[    1.427073] AVX version of gcm_enc/dec engaged.
[    1.428206] AES CTR mode by8 optimization enabled
[    1.437567] [TTM] Zone  kernel: Available graphics memory: 2019406 kiB
[    1.437980] virtio_net virtio0 ens3: renamed from eth0
[    1.440190] [TTM] Initializing pool allocator
[    1.443539] [TTM] Initializing DMA pool allocator
[    1.446351] [drm] fb mappable at 0xFC000000
[    1.447813] [drm] vram aper at 0xFC000000
[    1.448821] [drm] size 33554432
[    1.449591] [drm] fb depth is 24
[    1.450389] [drm]    pitch is 3072
[    1.451303] fbcon: cirrusdrmfb (fb0) is primary device
[    1.466761] Console: switching to colour frame buffer device 128x48
[    1.472958] cirrus 0000:00:02.0: fb0: cirrusdrmfb frame buffer device
[    1.488173] [drm] Initialized cirrus 1.0.0 20110418 for 0000:00:02.0 on minor 0
Begin: Loading essential drivers ... [    1.656027] raid6: sse2x1   gen()  6849 MB/s
[    1.704024] raid6: sse2x1   xor()  4687 MB/s
[    1.752025] raid6: sse2x2   gen() 10891 MB/s
[    1.800022] raid6: sse2x2   xor()  7022 MB/s
[    1.848027] raid6: sse2x4   gen() 12852 MB/s
[    1.896023] raid6: sse2x4   xor()  6381 MB/s
[    1.896795] raid6: using algorithm sse2x4 gen() 12852 MB/s
[    1.897742] raid6: .... xor() 6381 MB/s, rmw enabled
[    1.898596] raid6: using ssse3x2 recovery algorithm
[    1.900604] xor: automatically using best checksumming function   avx
[    1.902993] async_tx: api initialized (async)
done.
Begin: Running /scripts/init-premount ... done.
Begin: Mounting root file system ... Begin: Running /scripts/local-top ... done.
Begin: Running /scripts/local-premount ... [    1.948452] Btrfs loaded, crc32c=crc32c-intel
Scanning for Btrfs filesystems
done.
Warning: fsck not present, so skipping root file system
[    1.985342] EXT4-fs (vda2): mounted filesystem with ordered data mode. Opts: (null)
done.
Begin: Running /scripts/local-bottom ... done.
Begin: Running /scripts/init-bottom ... done.
[    2.057624] random: fast init done
[    2.094320] ip_tables: (C) 2000-2006 Netfilter Core Team
[    2.098211] random: systemd: uninitialized urandom read (16 bytes read)
[    2.099987] systemd[1]: systemd 237 running in system mode. (+PAM +AUDIT +SELINUX +IMA +APPARMOR +SMACK +SYSVINIT +UTMP +LIBCRYPTSETUP
+GCRYPT +GNUTLS +ACL +XZ +LZ4 +SECCOMP +BLKID +ELFUTILS +KMOD -IDN2 +IDN -PCRE2 default-hierarchy=hybrid)
[    2.103361] systemd[1]: Detected virtualization kvm.
[    2.104174] systemd[1]: Detected architecture x86-64.
[    2.105904] random: systemd: uninitialized urandom read (16 bytes read)
[    2.107829] random: systemd: uninitialized urandom read (16 bytes read)

Welcome to Ubuntu 18.04.3 LTS!

[    2.113249] systemd[1]: Set hostname to <ubuntu>.
[    2.115234] systemd[1]: Initializing machine ID from KVM UUID.
[    2.117114] systemd[1]: Installed transient /etc/machine-id file.
[    2.223016] systemd[1]: Created slice User and Session Slice.
[  OK  ] Created slice User and Session Slice.
[    2.225840] systemd[1]: Started Forward Password Requests to Wall Directory Watch.
[  OK  ] Started Forward Password Requests to Wall Directory Watch.
[    2.229194] systemd[1]: Reached target User and Group Name Lookups.
[  OK  ] Reached target User and Group Name Lookups.
[    2.232127] systemd[1]: Set up automount Arbitrary Executable File Formats File System Automount Point.
[  OK  ] Set up automount Arbitrary Executab&rmats File System Automount Point.
[  OK  ] Created slice System Slice.
[  OK  ] Reached target Slices.
[  OK  ] Listening on Device-mapper event daemon FIFOs.
[  OK  ] Listening on LVM2 poll daemon socket.
[  OK  ] Listening on udev Control Socket.
[  OK  ] Listening on udev Kernel Socket.
[  OK  ] Created slice system-serial\x2dgetty.slice.
[  OK  ] Listening on Network Service Netlink Socket.
[  OK  ] Listening on /dev/initctl Compatibility Named Pipe.
[  OK  ] Listening on Journal Socket.
         Starting Create list of required st&ce nodes for the current kernel...
         Starting Set the console keyboard layout...
         Starting Uncomplicated firewall...
         Starting Remount Root and Kernel File Systems...
         Starting udev Coldplug all Devices...
         Starting Load Kernel Modules...
         Mounting POSIX Message Queue File Syste[    2.258808] EXT4-fs (vda2): re-mounted. Opts: errors=remount-ro
m...
         Mounting Huge Pages File System...
[  OK  ] Listening on Journal Audit Socket.
[  OK  ] Listening on Syslog Socket.
[  OK  ] Listening on LVM2 metadata daemon socket.
[    2.265331] Loading iSCSI transport class v2.0-870.
         Starting Monitoring of LVM2 mirrors&ng dmeventd or progress polling...
         Mounting Kernel Debug File System...
[  OK  ] Listening on Journal Socket (/dev/log).
[    2.274097] iscsi: registered transport (tcp)
         Starting Journal Service...
[  OK  ] Started Create list of required sta&vice nodes for the current kernel.
[  OK  ] Started Uncomplicated firewall.
[  OK  ] Started Remount Root and Kernel File Systems.
[  OK  ] Mounted POSIX Message Queue File System.
[  OK  ] Mounted Huge Pages File System.
[  OK  ] Mounted Kernel Debug File System.
         Activating swap /swap.img...
         Starting Load/Save Random Seed...
         Starting Create Static Device Nodes in /dev...
[  OK  ] Started LVM2 metadata daemon.
[  OK  ] Started Create Static Device Nodes in /dev.
[  OK  ] Started Monitoring of LVM2 mirrors,&sing dmeventd or progress polling.
         Starting udev Kernel Device Manager...
[  OK  ] Started Load/Save Random Seed.
[    2.317811] iscsi: registered transport (iser)
[  OK  ] Started Load Kernel Modules.
         Mounting Kernel Configuration File System...
         Starting Apply Kernel Variables...
         Mounting FUSE Control File System...
[  OK  ] Mounted Kernel Configuration File System.
[  OK  ] Mounted FUSE Control File System.
[  OK  ] Started Apply Kernel Variables.
[  OK  ] Started udev Kernel Device Manager.
[  OK  ] Started Journal Service.
         Starting Flush Journal to Persistent Storage...
[  OK  ] Started udev Coldplug all Devices.
[  OK  ] Started Set the console keyboard layout.
[  OK  ] Reached target Local File Systems (Pre).
[  OK  ] Reached target Local File Systems.
         Starting AppArmor initialization...
         Starting ebtables ruleset management...
         Starting Commit a transient machine-id on disk...
         Starting Tell Plymouth To Write Out Runtime Data...
         Starting Set console font and keymap...
[  OK  ] Started Dispatch Password Requests to Console Directory Watch.
[  OK  ] Reached target Local Encrypted Volumes.
[  OK  ] Started Flush Journal to Persistent Storage.
         Starting Create Volatile Files and Directories...
[  OK  ] Started Set console font and keymap.
[  OK  ] Started Tell Plymouth To Write Out Runtime Data.
[  OK  ] Started Create Volatile Files and Directories.
         Starting Network Time Synchronization...
         Starting Update UTMP about System Boot/Shutdown...
[  OK  ] Started Update UTMP about System Boot/Shutdown.
[  OK  ] Started ebtables ruleset management.
[  OK  ] Activated swap /swap.img.
[  OK  ] Reached target Swap.
[  OK  ] Started Commit a transient machine-id on disk.
[  OK  ] Started Network Time Synchronization.
[  OK  ] Reached target System Time Synchronized.
[  OK  ] Found device /dev/ttyS0.
[  OK  ] Listening on Load/Save RF Kill Switch Status /dev/rfkill Watch.
[  OK  ] Started AppArmor initialization.
         Starting Initial cloud-init job (pre-networking)...
[    3.891512] cloud-init[608]: Cloud-init v. 19.3-41-gc4735dd3-0ubuntu1~18.04.1 running 'init-local' at Wed, 22 Jan 2020 04:28:49 +0000.
Up 3.46 seconds.
[  OK  ] Started Initial cloud-init job (pre-networking).
[  OK  ] Reached target Network (Pre).
         Starting Network Service...
[  OK  ] Started Network Service.
         Starting Network Name Resolution...
         Starting Wait for Network to be Configured...
[  OK  ] Started Network Name Resolution.
[  OK  ] Reached target Host and Network Name Lookups.
[  OK  ] Reached target Network.
[  OK  ] Started Wait for Network to be Configured.
         Starting Initial cloud-init job (metadata service crawler)...
[    7.631993] cloud-init[714]: Cloud-init v. 19.3-41-gc4735dd3-0ubuntu1~18.04.1 running 'init' at Wed, 22 Jan 2020 04:28:53 +0000. Up 7.3
7 seconds.
[    7.634406] cloud-init[714]: ci-info: ++++++++++++++++++++++++++++++++++++++Net device info++++++++++++++++++++++++++++++++++++++
[    7.636330] cloud-init[714]: ci-info: +--------+------+----------------------------+---------------+--------+-------------------+
[    7.638246] cloud-init[714]: ci-info: | Device |  Up  |          Address           |      Mask     | Scope  |     Hw-Address    |
[    7.640109] cloud-init[714]: ci-info: +--------+------+----------------------------+---------------+--------+-------------------+
[    7.642027] cloud-init[714]: ci-info: |  ens3  | True |       10.250.99.151        | 255.255.255.0 | global | 52:54:00:97:3f:af |
[    7.644056] cloud-init[714]: ci-info: |  ens3  | True | fe80::5054:ff:fe97:3faf/64 |       .       |  link  | 52:54:00:97:3f:af |
[    7.646070] cloud-init[714]: ci-info: |   lo   | True |         127.0.0.1          |   255.0.0.0   |  host  |         .         |
[    7.648154] cloud-init[714]: ci-info: |   lo   | True |          ::1/128           |       .       |  host  |         .         |
[    7.650002] cloud-init[714]: ci-info: +--------+------+----------------------------+---------------+--------+-------------------+
[    7.651793] cloud-init[714]: ci-info: ++++++++++++++++++++++++++++++Route IPv4 info++++++++++++++++++++++++++++++
[    7.653454] cloud-init[714]: ci-info: +-------+-------------+-------------+-----------------+-----------+-------+
[    7.655249] cloud-init[714]: ci-info: | Route | Destination |   Gateway   |     Genmask     | Interface | Flags |
[    7.657030] cloud-init[714]: ci-info: +-------+-------------+-------------+-----------------+-----------+-------+
[    7.658734] cloud-init[714]: ci-info: |   0   |   0.0.0.0   | 10.250.99.1 |     0.0.0.0     |    ens3   |   UG  |
[    7.660415] cloud-init[714]: ci-info: |   1   | 10.250.99.0 |   0.0.0.0   |  255.255.255.0  |    ens3   |   U   |
[    7.662119] cloud-init[714]: ci-info: |   2   | 10.250.99.1 |   0.0.0.0   | 255.255.255.255 |    ens3   |   UH  |
[    7.663929] cloud-init[714]: ci-info: +-------+-------------+-------------+-----------------+-----------+-------+
[    7.665630] cloud-init[714]: ci-info: +++++++++++++++++++Route IPv6 info+++++++++++++++++++
[    7.666981] cloud-init[714]: ci-info: +-------+-------------+---------+-----------+-------+
[    7.668340] cloud-init[714]: ci-info: | Route | Destination | Gateway | Interface | Flags |
[    7.669579] cloud-init[714]: ci-info: +-------+-------------+---------+-----------+-------+
[    7.670901] cloud-init[714]: ci-info: |   1   |  fe80::/64  |    ::   |    ens3   |   U   |
[    7.672127] cloud-init[714]: ci-info: |   3   |    local    |    ::   |    ens3   |   U   |
[    7.673391] cloud-init[714]: ci-info: |   4   |   ff00::/8  |    ::   |    ens3   |   U   |
[    7.674723] cloud-init[714]: ci-info: +-------+-------------+---------+-----------+-------+
[    7.997536] cloud-init[714]: Generating public/private rsa key pair.
[    7.998626] cloud-init[714]: Your identification has been saved in /etc/ssh/ssh_host_rsa_key.
[    7.999846] cloud-init[714]: Your public key has been saved in /etc/ssh/ssh_host_rsa_key.pub.
[    8.001177] cloud-init[714]: The key fingerprint is:
[    8.001975] cloud-init[714]: SHA256:mMNSKQK3xWxTXkLWM0S7GhTJfTutFQknWDoV2tpxS18 root@ubuntu
[    8.003240] cloud-init[714]: The key's randomart image is:
[    8.004198] cloud-init[714]: +---[RSA 2048]----+
[    8.004950] cloud-init[714]: |. .o.+**+o*o..   |
[    8.005700] cloud-init[714]: | o o=oo=**.oo    |
[    8.006439] cloud-init[714]: |  o...= =+ooo.  E|
[    8.007179] cloud-init[714]: |   . = o =o+oo . |
[    8.007954] cloud-init[714]: |    . * S .+. .  |
[    8.008712] cloud-init[714]: |     . +  .      |
[    8.009518] cloud-init[714]: |      .          |
[    8.010269] cloud-init[714]: |                 |
[    8.011028] cloud-init[714]: |                 |
[    8.011783] cloud-init[714]: +----[SHA256]-----+
[    8.012472] cloud-init[714]: Generating public/private dsa key pair.
[    8.013384] cloud-init[714]: Your identification has been saved in /etc/ssh/ssh_host_dsa_key.
[    8.014586] cloud-init[714]: Your public key has been saved in /etc/ssh/ssh_host_dsa_key.pub.
[    8.015789] cloud-init[714]: The key fingerprint is:
[    8.016529] cloud-init[714]: SHA256:fRR8GxqC5TY9vWFOD1zpCzKOtAF9hZ5adH+JJpRnJUc root@ubuntu
[    8.017710] cloud-init[714]: The key's randomart image is:
[    8.018492] cloud-init[714]: +---[DSA 1024]----+
[    8.019192] cloud-init[714]: |        .o..=ooEo|
[    8.019889] cloud-init[714]: |       ..o.BoB=o |
[    8.020583] cloud-init[714]: |        . O.O+@o.|
[    8.021299] cloud-init[714]: |         = X.O.O.|
[    8.022001] cloud-init[714]: |        S O * + +|
[    8.022697] cloud-init[714]: |         + o   . |
[    8.023401] cloud-init[714]: |                 |
[    8.024113] cloud-init[714]: |                 |
[    8.024793] cloud-init[714]: |                 |
[    8.025480] cloud-init[714]: +----[SHA256]-----+
[    8.026171] cloud-init[714]: Generating public/private ecdsa key pair.
[    8.027102] cloud-init[714]: Your identification has been saved in /etc/ssh/ssh_host_ecdsa_key.
[    8.028435] cloud-init[714]: Your public key has been saved in /etc/ssh/ssh_host_ecdsa_key.pub.
[    8.029702] cloud-init[714]: The key fingerprint is:
[    8.030529] cloud-init[714]: SHA256:hKVu8st7m1haYfyq2+Wa3JpK9Kpn+LN3HKBMbIjjCWU root@ubuntu
[    8.032136] cloud-init[714]: The key's randomart image is:
[    8.033219] cloud-init[714]: +---[ECDSA 256]---+
[    8.034182] cloud-init[714]: |        .        |
[    8.035189] cloud-init[714]: |  E    +         |
[    8.036252] cloud-init[714]: | o . oo .        |
[    8.037296] cloud-init[714]: |. o ..+o.        |
[    8.038328] cloud-init[714]: | o o.++.S.       |
[    8.039336] cloud-init[714]: |  o  =oo o.      |
[    8.040391] cloud-init[714]: |     .o +.o.     |
[    8.041420] cloud-init[714]: |    .o+XoOo      |
[    8.042464] cloud-init[714]: |    .=&X@=o      |
[    8.043493] cloud-init[714]: +----[SHA256]-----+
[    8.044551] cloud-init[714]: Generating public/private ed25519 key pair.
[    8.045857] cloud-init[714]: Your identification has been saved in /etc/ssh/ssh_host_ed25519_key.
[    8.047395] cloud-init[714]: Your public key has been saved in /etc/ssh/ssh_host_ed25519_key.pub.
[    8.048967] cloud-init[714]: The key fingerprint is:
[    8.050003] cloud-init[714]: SHA256:kiLPS974tw0nUt51he0BiyeYCPT5iLZTgHOq/XjUhvE root@ubuntu
[    8.051471] cloud-init[714]: The key's randomart image is:
[    8.052582] cloud-init[714]: +--[ED25519 256]--+
[    8.053543] cloud-init[714]: |    .o       .   |
[    8.054502] cloud-init[714]: |    . o o o . oo |
[    8.055458] cloud-init[714]: |   o o + o o o..o|
[    8.056470] cloud-init[714]: |    +.o.o   o  o.|
[    8.057432] cloud-init[714]: |  ...oBoS.  . . .|
[    8.058412] cloud-init[714]: |  o+.+oE . . .   |
[    8.059370] cloud-init[714]: | . .=oo + o      |
[    8.060381] cloud-init[714]: |   oo=...=       |
[    8.061345] cloud-init[714]: |   .=oo....      |
[    8.062311] cloud-init[714]: +----[SHA256]-----+
[  OK  ] Started Initial cloud-init job (metadata service crawler).
[  OK  ] Reached target Network is Online.
         Starting Availability of block devices...
[  OK  ] Reached target Remote File Systems (Pre).
[  OK  ] Reached target Remote File Systems.
[  OK  ] Reached target System Initialization.
[  OK  ] Started ACPI Events Check.
[  OK  ] Listening on UUID daemon activation socket.
[  OK  ] Listening on ACPID Listen Socket.
[  OK  ] Started Message of the Day.
[  OK  ] Started Discard unused blocks once a week.
[  OK  ] Reached target Paths.
[  OK  ] Started Daily Cleanup of Temporary Directories.
[  OK  ] Started Daily apt download activities.
[  OK  ] Started Daily apt upgrade and clean activities.
         Starting Socket activation for snappy daemon.
[  OK  ] Reached target Timers.
[  OK  ] Listening on D-Bus System Message Bus Socket.
         Starting LXD - unix socket.
[  OK  ] Listening on Open-iSCSI iscsid Socket.
[  OK  ] Reached target Cloud-config availability.
[  OK  ] Started Availability of block devices.
[  OK  ] Listening on Socket activation for snappy daemon.
[  OK  ] Listening on LXD - unix socket.
[  OK  ] Reached target Sockets.
[  OK  ] Reached target Basic System.
[  OK  ] Started Regular background program processing daemon.
         Starting Dispatcher daemon for systemd-networkd...
[  OK  ] Started Deferred execution scheduler.
         Starting Accounts Service...
[  OK  ] Started D-Bus System Message Bus.
         Starting Login Service...
         Starting LSB: Record successful boot for GRUB...
         Starting Pollinate to seed the pseudo random number generator...
         Starting LSB: automatic crash report generation...
         Starting Snappy daemon...
[  OK  ] Started irqbalance daemon.
         Starting System Logging Service...
         Starting Permit User Sessions...
[  OK  ] Started FUSE filesystem for LXC.
         Starting LXD - container startup/shutdown...
[  OK  ] Started Permit User Sessions.
         Starting Authorization Manager...
         Starting Hostname Service...
         Starting Terminate Plymouth Boot Screen...
         Starting Hold until boot process finishes up...
[  OK  ] Started System Logging Service.
[  OK  ] Started LSB: automatic crash report generation.
[  OK  ] Started Hold until boot process finishes up.
[  OK  ] Started Terminate Plymouth Boot Screen.
[  OK  ] Started Authorization Manager.
[  OK  ] Started Accounts Service.
[  OK  ] Started Login Service.
[  OK  ] Started Serial Getty on ttyS0.
         Starting Set console scheme...
[  OK  ] Started Set console scheme.
[  OK  ] Created slice system-getty.slice.
[  OK  ] Started Getty on tty1.
[  OK  ] Reached target Login Prompts.
[  OK  ] Started LSB: Record successful boot for GRUB.
[  OK  ] Started LXD - container startup/shutdown.
[  OK  ] Started Dispatcher daemon for systemd-networkd.
[  OK  ] Started Hostname Service.
[  OK  ] Started Snappy daemon.
         Starting Wait until snapd is fully seeded...
[  OK  ] Started Pollinate to seed the pseudo random number generator.
         Starting OpenBSD Secure Shell server...
[  OK  ] Started OpenBSD Secure Shell server.
[  OK  ] Started Wait until snapd is fully seeded.
         Starting Apply the settings specified in cloud-config...
[  OK  ] Reached target Multi-User System.
[  OK  ] Reached target Graphical Interface.
         Starting Update UTMP about System Runlevel Changes...
[  OK  ] Started Update UTMP about System Runlevel Changes.
[   13.357413] cloud-init[1051]: 2020-01-22 04:28:59,603 INFO Authorized key ['2048', 'SHA256:UKrYMRQCA5uOuMwVP/xnMRnbzMn4PIiHT0bHZt3kPuk'
, 'personalkey', '(RSA)']
[   13.357583] cloud-init[1051]: 2020-01-22 04:28:59,603 INFO [1] SSH keys [Authorized]

Ubuntu 18.04.3 LTS ubuntu ttyS0

ubuntu login: [   14.824463] cloud-init[1051]: Get:1 http://us.archive.ubuntu.com/ubuntu bionic InRelease [242 kB]
[   15.562014] cloud-init[1051]: Get:2 http://us.archive.ubuntu.com/ubuntu bionic-updates InRelease [88.7 kB]
[   15.752334] cloud-init[1051]: Get:3 http://us.archive.ubuntu.com/ubuntu bionic-proposed InRelease [242 kB]
[   15.996181] cloud-init[1051]: Get:4 http://us.archive.ubuntu.com/ubuntu bionic-security InRelease [88.7 kB]
[   16.186865] cloud-init[1051]: Get:5 http://us.archive.ubuntu.com/ubuntu bionic/main Sources [829 kB]
[   16.449167] cloud-init[1051]: Get:6 http://us.archive.ubuntu.com/ubuntu bionic/universe Sources [9051 kB]
[   17.166459] cloud-init[1051]: Get:7 http://us.archive.ubuntu.com/ubuntu bionic/restricted Sources [5324 B]
[   17.168981] cloud-init[1051]: Get:8 http://us.archive.ubuntu.com/ubuntu bionic/multiverse Sources [181 kB]
[   17.178255] cloud-init[1051]: Get:9 http://us.archive.ubuntu.com/ubuntu bionic/main amd64 Packages [1019 kB]
[   17.481903] cloud-init[1051]: Get:10 http://us.archive.ubuntu.com/ubuntu bionic/main Translation-en [516 kB]
[   17.489222] cloud-init[1051]: Get:11 http://us.archive.ubuntu.com/ubuntu bionic/restricted amd64 Packages [9184 B]
[   17.489906] cloud-init[1051]: Get:12 http://us.archive.ubuntu.com/ubuntu bionic/restricted Translation-en [3584 B]
[   17.490423] cloud-init[1051]: Get:13 http://us.archive.ubuntu.com/ubuntu bionic/universe amd64 Packages [8570 kB]
[   18.235242] cloud-init[1051]: Get:14 http://us.archive.ubuntu.com/ubuntu bionic/universe Translation-en [4941 kB]
[   18.466159] cloud-init[1051]: Get:15 http://us.archive.ubuntu.com/ubuntu bionic/multiverse amd64 Packages [151 kB]
[   18.487263] cloud-init[1051]: Get:16 http://us.archive.ubuntu.com/ubuntu bionic/multiverse Translation-en [108 kB]
[   18.490966] cloud-init[1051]: Get:17 http://us.archive.ubuntu.com/ubuntu bionic-updates/restricted Sources [6536 B]
[   18.493065] cloud-init[1051]: Get:18 http://us.archive.ubuntu.com/ubuntu bionic-updates/main Sources [304 kB]
[   18.499908] cloud-init[1051]: Get:19 http://us.archive.ubuntu.com/ubuntu bionic-updates/multiverse Sources [5844 B]
[   18.501814] cloud-init[1051]: Get:20 http://us.archive.ubuntu.com/ubuntu bionic-updates/universe Sources [274 kB]
[   18.509209] cloud-init[1051]: Get:21 http://us.archive.ubuntu.com/ubuntu bionic-updates/main amd64 Packages [833 kB]
[   18.905686] cloud-init[1051]: Get:22 http://us.archive.ubuntu.com/ubuntu bionic-updates/main Translation-en [292 kB]
[   19.661729] cloud-init[1051]: Get:23 http://us.archive.ubuntu.com/ubuntu bionic-updates/restricted amd64 Packages [27.4 kB]
[   19.670242] cloud-init[1051]: Get:24 http://us.archive.ubuntu.com/ubuntu bionic-updates/restricted Translation-en [7356 B]
[   19.672487] cloud-init[1051]: Get:25 http://us.archive.ubuntu.com/ubuntu bionic-updates/universe amd64 Packages [1044 kB]
[   19.954208] cloud-init[1051]: Get:26 http://us.archive.ubuntu.com/ubuntu bionic-updates/universe Translation-en [322 kB]
[   19.998738] cloud-init[1051]: Get:27 http://us.archive.ubuntu.com/ubuntu bionic-updates/multiverse amd64 Packages [9500 B]
[   20.000893] cloud-init[1051]: Get:28 http://us.archive.ubuntu.com/ubuntu bionic-updates/multiverse Translation-en [4540 B]
[   20.002776] cloud-init[1051]: Get:29 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main Sources [40.5 kB]
[   20.005939] cloud-init[1051]: Get:30 http://us.archive.ubuntu.com/ubuntu bionic-proposed/restricted Sources [4528 B]
[   20.007918] cloud-init[1051]: Get:31 http://us.archive.ubuntu.com/ubuntu bionic-proposed/universe Sources [19.9 kB]
[   20.009992] cloud-init[1051]: Get:32 http://us.archive.ubuntu.com/ubuntu bionic-proposed/multiverse Sources [1256 B]
[   20.011804] cloud-init[1051]: Get:33 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 Packages [84.4 kB]
[   20.020200] cloud-init[1051]: Get:34 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main Translation-en [35.1 kB]
[   20.114710] cloud-init[1051]: Get:35 http://us.archive.ubuntu.com/ubuntu bionic-proposed/restricted amd64 Packages [10.5 kB]
[   20.174673] cloud-init[1051]: Get:36 http://us.archive.ubuntu.com/ubuntu bionic-proposed/restricted Translation-en [3880 B]
[   20.176905] cloud-init[1051]: Get:37 http://us.archive.ubuntu.com/ubuntu bionic-proposed/universe amd64 Packages [145 kB]
[   20.181542] cloud-init[1051]: Get:38 http://us.archive.ubuntu.com/ubuntu bionic-proposed/universe Translation-en [31.4 kB]
[   20.274978] cloud-init[1051]: Get:39 http://us.archive.ubuntu.com/ubuntu bionic-proposed/multiverse amd64 Packages [1548 B]
[   20.277013] cloud-init[1051]: Get:40 http://us.archive.ubuntu.com/ubuntu bionic-proposed/multiverse Translation-en [764 B]
[   20.278953] cloud-init[1051]: Get:41 http://us.archive.ubuntu.com/ubuntu bionic-security/multiverse Sources [3184 B]
[   20.280808] cloud-init[1051]: Get:42 http://us.archive.ubuntu.com/ubuntu bionic-security/universe Sources [164 kB]
[   20.608342] cloud-init[1051]: Get:43 http://us.archive.ubuntu.com/ubuntu bionic-security/universe amd64 Packages [634 kB]
[   21.523520] cloud-init[1051]: Get:44 http://us.archive.ubuntu.com/ubuntu bionic-security/universe Translation-en [213 kB]
[   21.555163] cloud-init[1051]: Get:45 http://us.archive.ubuntu.com/ubuntu bionic-security/multiverse amd64 Packages [6116 B]
[   21.557144] cloud-init[1051]: Get:46 http://us.archive.ubuntu.com/ubuntu bionic-security/multiverse Translation-en [2600 B]
[   24.000605] cloud-init[1051]: Fetched 30.6 MB in 8s (3807 kB/s)
[   25.012120] cloud-init[1051]: Reading package lists...
[   25.062187] cloud-init[1051]: Cloud-init v. 19.3-41-gc4735dd3-0ubuntu1~18.04.1 running 'modules:config' at Wed, 22 Jan 2020 04:28:58
+0000. Up 11.77 seconds.
[   25.783239] cloud-init[1401]: Reading package lists...
[   25.950068] cloud-init[1401]: Building dependency tree...
[   25.951114] cloud-init[1401]: Reading state information...
[   26.102141] cloud-init[1401]: bash-completion is already the newest version (1:2.8-1ubuntu1).
[   26.102276] cloud-init[1401]: bash-completion set to manually installed.
[   26.102669] cloud-init[1401]: less is already the newest version (487-0.1).
[   26.103043] cloud-init[1401]: less set to manually installed.
[   26.103384] cloud-init[1401]: locales is already the newest version (2.27-3ubuntu1).
[   26.103761] cloud-init[1401]: locales set to manually installed.
[   26.104335] cloud-init[1401]: manpages is already the newest version (4.15-1).
[   26.104688] cloud-init[1401]: manpages set to manually installed.
[   26.105038] cloud-init[1401]: mtr-tiny is already the newest version (0.92-1).
[   26.105403] cloud-init[1401]: mtr-tiny set to manually installed.
[   26.105764] cloud-init[1401]: net-tools is already the newest version (1.60+git20161116.90da8a0-1ubuntu1).
[   26.106108] cloud-init[1401]: net-tools set to manually installed.
[   26.106448] cloud-init[1401]: rsync is already the newest version (3.1.2-2.1ubuntu1).
[   26.106812] cloud-init[1401]: rsync set to manually installed.
[   26.107158] cloud-init[1401]: tcpdump is already the newest version (4.9.2-3).
[   26.107516] cloud-init[1401]: tcpdump set to manually installed.
[   26.107873] cloud-init[1401]: dnsutils is already the newest version (1:9.11.3+dfsg-1ubuntu1.11).
[   26.108296] cloud-init[1401]: dnsutils set to manually installed.
[   26.108639] cloud-init[1401]: iputils-ping is already the newest version (3:20161105-1ubuntu3).
[   26.109005] cloud-init[1401]: iputils-ping set to manually installed.
[   26.109384] cloud-init[1401]: iputils-tracepath is already the newest version (3:20161105-1ubuntu3).
[   26.109744] cloud-init[1401]: iputils-tracepath set to manually installed.
[   26.110116] cloud-init[1401]: man-db is already the newest version (2.8.3-2ubuntu0.1).
[   26.110472] cloud-init[1401]: man-db set to manually installed.
[   26.110864] cloud-init[1401]: ncurses-term is already the newest version (6.1-1ubuntu1.18.04).
[   26.111243] cloud-init[1401]: openssh-client is already the newest version (1:7.6p1-4ubuntu0.3).
[   26.111615] cloud-init[1401]: openssh-client set to manually installed.
[   26.111986] cloud-init[1401]: openssh-server is already the newest version (1:7.6p1-4ubuntu0.3).
[   26.112373] cloud-init[1401]: software-properties-common is already the newest version (0.96.24.32.12).
[   26.112725] cloud-init[1401]: software-properties-common set to manually installed.
[   26.113117] cloud-init[1401]: ssh-import-id is already the newest version (5.7-0ubuntu1.1).
[   26.113447] cloud-init[1401]: sudo is already the newest version (1.8.21p2-3ubuntu1.1).
[   26.113825] cloud-init[1401]: sudo set to manually installed.
[   26.114203] cloud-init[1401]: vim is already the newest version (2:8.0.1453-1ubuntu1.1).
[   26.114563] cloud-init[1401]: vim set to manually installed.
[   26.115006] cloud-init[1401]: The following additional packages will be installed:
[   26.115324] cloud-init[1401]:   libjq1 libonig4 libossp-uuid16
[   26.115648] cloud-init[1401]: Suggested packages:
[   26.115974] cloud-init[1401]:   ifupdown
[   26.151265] cloud-init[1401]: The following NEW packages will be installed:
[   26.152333] cloud-init[1401]:   bridge-utils hello iputils-arping jq libjq1 libonig4 libossp-uuid16
[   26.152544] cloud-init[1401]:   traceroute uuid vlan
[   26.488714] cloud-init[1401]: 0 upgraded, 10 newly installed, 0 to remove and 20 not upgraded.
[   26.488861] cloud-init[1401]: Need to get 479 kB of archives.
[   26.489292] cloud-init[1401]: After this operation, 1637 kB of additional disk space will be used.
[   26.489703] cloud-init[1401]: Get:1 http://us.archive.ubuntu.com/ubuntu bionic/main amd64 bridge-utils amd64 1.5-15ubuntu1 [30.1 kB]
[   26.820098] cloud-init[1401]: Get:2 http://us.archive.ubuntu.com/ubuntu bionic/main amd64 hello amd64 2.10-1build1 [27.2 kB]
[   26.885572] cloud-init[1401]: Get:3 http://us.archive.ubuntu.com/ubuntu bionic-updates/main amd64 iputils-arping amd64 3:20161105-1ubun
tu3 [29.7 kB]
[   26.977406] cloud-init[1401]: Get:4 http://us.archive.ubuntu.com/ubuntu bionic/universe amd64 libonig4 amd64 6.7.0-1 [119 kB]
[   27.155908] cloud-init[1401]: Get:5 http://us.archive.ubuntu.com/ubuntu bionic/universe amd64 libjq1 amd64 1.5+dfsg-2 [111 kB]
[   27.246233] cloud-init[1401]: Get:6 http://us.archive.ubuntu.com/ubuntu bionic/universe amd64 jq amd64 1.5+dfsg-2 [45.6 kB]
[   27.270958] cloud-init[1401]: Get:7 http://us.archive.ubuntu.com/ubuntu bionic/universe amd64 libossp-uuid16 amd64 1.6.2-1.5build4 [29.
0 kB]
[   27.284848] cloud-init[1401]: Get:8 http://us.archive.ubuntu.com/ubuntu bionic/universe amd64 traceroute amd64 1:2.1.0-2 [45.4 kB]
[   27.305625] cloud-init[1401]: Get:9 http://us.archive.ubuntu.com/ubuntu bionic/universe amd64 uuid amd64 1.6.2-1.5build4 [10.9 kB]
[   27.310062] cloud-init[1401]: Get:10 http://us.archive.ubuntu.com/ubuntu bionic-updates/main amd64 vlan amd64 1.9-3.2ubuntu6 [30.7 kB]
[   27.704490] cloud-init[1401]: Fetched 479 kB in 1s (414 kB/s)
[   27.723759] cloud-init[1401]: Selecting previously unselected package bridge-utils.
(Reading database ... 38186 files and directories currently installed.)
[   27.771881] cloud-init[1401]: Preparing to unpack .../0-bridge-utils_1.5-15ubuntu1_amd64.deb ...
[   27.772573] cloud-init[1401]: Unpacking bridge-utils (1.5-15ubuntu1) ...
[   27.795692] cloud-init[1401]: Selecting previously unselected package hello.
[   27.798869] cloud-init[1401]: Preparing to unpack .../1-hello_2.10-1build1_amd64.deb ...
[   27.799240] cloud-init[1401]: Unpacking hello (2.10-1build1) ...
[   27.812927] cloud-init[1401]: Selecting previously unselected package iputils-arping.
[   27.816123] cloud-init[1401]: Preparing to unpack .../2-iputils-arping_3%3a20161105-1ubuntu3_amd64.deb ...
[   27.816522] cloud-init[1401]: Unpacking iputils-arping (3:20161105-1ubuntu3) ...
[   27.831893] cloud-init[1401]: Selecting previously unselected package libonig4:amd64.
[   27.834991] cloud-init[1401]: Preparing to unpack .../3-libonig4_6.7.0-1_amd64.deb ...
[   27.835595] cloud-init[1401]: Unpacking libonig4:amd64 (6.7.0-1) ...
[   27.859017] cloud-init[1401]: Selecting previously unselected package libjq1:amd64.
[   27.861834] cloud-init[1401]: Preparing to unpack .../4-libjq1_1.5+dfsg-2_amd64.deb ...
[   27.862174] cloud-init[1401]: Unpacking libjq1:amd64 (1.5+dfsg-2) ...
[   27.883191] cloud-init[1401]: Selecting previously unselected package jq.
[   27.886440] cloud-init[1401]: Preparing to unpack .../5-jq_1.5+dfsg-2_amd64.deb ...
[   27.886771] cloud-init[1401]: Unpacking jq (1.5+dfsg-2) ...
[   27.902995] cloud-init[1401]: Selecting previously unselected package libossp-uuid16:amd64.
[   27.906150] cloud-init[1401]: Preparing to unpack .../6-libossp-uuid16_1.6.2-1.5build4_amd64.deb ...
[   27.906359] cloud-init[1401]: Unpacking libossp-uuid16:amd64 (1.6.2-1.5build4) ...
[   27.922039] cloud-init[1401]: Selecting previously unselected package traceroute.
[   27.925227] cloud-init[1401]: Preparing to unpack .../7-traceroute_1%3a2.1.0-2_amd64.deb ...
[   27.925425] cloud-init[1401]: Unpacking traceroute (1:2.1.0-2) ...
[   27.943219] cloud-init[1401]: Selecting previously unselected package uuid.
[   27.946435] cloud-init[1401]: Preparing to unpack .../8-uuid_1.6.2-1.5build4_amd64.deb ...
[   27.946549] cloud-init[1401]: Unpacking uuid (1.6.2-1.5build4) ...
[   27.960086] cloud-init[1401]: Selecting previously unselected package vlan.
[   27.963324] cloud-init[1401]: Preparing to unpack .../9-vlan_1.9-3.2ubuntu6_amd64.deb ...
[   27.963425] cloud-init[1401]: Unpacking vlan (1.9-3.2ubuntu6) ...
[   27.987811] cloud-init[1401]: Setting up vlan (1.9-3.2ubuntu6) ...
[   27.989418] cloud-init[1401]: Setting up hello (2.10-1build1) ...
[   27.990629] cloud-init[1401]: Setting up libossp-uuid16:amd64 (1.6.2-1.5build4) ...
[   27.992159] cloud-init[1401]: Setting up libonig4:amd64 (6.7.0-1) ...
[   27.993370] cloud-init[1401]: Setting up bridge-utils (1.5-15ubuntu1) ...
[   28.098808] cloud-init[1401]: Setting up uuid (1.6.2-1.5build4) ...
[   28.098956] cloud-init[1401]: Setting up libjq1:amd64 (1.5+dfsg-2) ...
[   28.101223] cloud-init[1401]: Setting up iputils-arping (3:20161105-1ubuntu3) ...
[   28.104743] cloud-init[1401]: Setting up traceroute (1:2.1.0-2) ...
[   28.111614] cloud-init[1401]: update-alternatives: using /usr/bin/traceroute.db to provide /usr/bin/traceroute (traceroute) in auto mod
e
[   28.115698] cloud-init[1401]: update-alternatives: using /usr/bin/lft.db to provide /usr/bin/lft (lft) in auto mode
[   28.118968] cloud-init[1401]: update-alternatives: using /usr/bin/traceproto.db to provide /usr/bin/traceproto (traceproto) in auto mod
e
[   28.120951] cloud-init[1401]: update-alternatives: using /usr/sbin/tcptraceroute.db to provide /usr/sbin/tcptraceroute (tcptraceroute)
in auto mode
[   28.123280] cloud-init[1401]: Setting up jq (1.5+dfsg-2) ...
[   28.124611] cloud-init[1401]: Processing triggers for libc-bin (2.27-3ubuntu1) ...
[   28.145448] cloud-init[1401]: Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
[   28.667371] cloud-init[1401]: Processing triggers for install-info (6.5.0.dfsg.1-2) ...
[   30.221995] cloud-init[1401]: snapd: no process found
[   30.226248] cloud-init[1401]: Warning: Stopping snapd.service, but it can still be activated by:
[   30.226347] cloud-init[1401]:   snapd.socket
[   30.230783] cloud-init[1401]: Failed to stop unattended-upgrades.service: Unit unattended-upgrades.service not loaded.
[   30.235443] cloud-init[1401]: /var/lib/cloud/instance/scripts/runcmd: 6: /var/lib/cloud/instance/scripts/runcmd: system: not found
[   31.069272] cloud-init[1401]: Hit:1 http://us.archive.ubuntu.com/ubuntu bionic InRelease
[   31.222098] cloud-init[1401]: Hit:2 http://us.archive.ubuntu.com/ubuntu bionic-updates InRelease
[   31.381819] cloud-init[1401]: Hit:3 http://us.archive.ubuntu.com/ubuntu bionic-proposed InRelease
[   31.543590] cloud-init[1401]: Hit:4 http://us.archive.ubuntu.com/ubuntu bionic-security InRelease
[   32.744679] cloud-init[1401]: Reading package lists...
[   32.916580] cloud-init[1401]: Reading package lists...
[   33.084261] cloud-init[1401]: Building dependency tree...
[   33.084905] cloud-init[1401]: Reading state information...
[   33.180730] cloud-init[1401]: Calculating upgrade...
[   33.308662] cloud-init[1401]: The following packages will be upgraded:
[   33.308986] cloud-init[1401]:   apport cloud-init gcc-8-base libbsd0 libdrm-common libdrm2 libgcc1
[   33.309519] cloud-init[1401]:   libgcrypt20 libglib2.0-0 libglib2.0-data libgnutls30 libstdc++6 login mdadm
[   33.309876] cloud-init[1401]:   open-iscsi passwd python3-apport python3-problem-report rsyslog uidmap
[   33.646013] cloud-init[1401]: 20 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
[   33.646127] cloud-init[1401]: Need to get 5699 kB of archives.
[   33.646568] cloud-init[1401]: After this operation, 23.6 kB of additional disk space will be used.
[   33.646970] cloud-init[1401]: Get:1 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 login amd64 1:4.5-1ubuntu2.1 [307
kB]
[   34.401322] cloud-init[1401]: Get:2 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 open-iscsi amd64 2.0.874-5ubuntu2.9
[280 kB]
[   34.484119] cloud-init[1401]: Get:3 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 gcc-8-base amd64 8.3.0-26ubuntu1~18.
04 [18.3 kB]
[   34.490348] cloud-init[1401]: Get:4 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 libstdc++6 amd64 8.3.0-26ubuntu1~18.
04 [400 kB]
[   34.629998] cloud-init[1401]: Get:5 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 libgcc1 amd64 1:8.3.0-26ubuntu1~18.0
4 [40.7 kB]
[   34.640126] cloud-init[1401]: Get:6 http://us.archive.ubuntu.com/ubuntu bionic-updates/main amd64 libgcrypt20 amd64 1.8.1-4ubuntu1.2
[417 kB]
[   34.699636] cloud-init[1401]: Get:7 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 passwd amd64 1:4.5-1ubuntu2.1 [819 k
B]
[   34.793306] cloud-init[1401]: Get:8 http://us.archive.ubuntu.com/ubuntu bionic-updates/main amd64 libgnutls30 amd64 3.5.18-1ubuntu1.2 [
645 kB]
[   34.837042] cloud-init[1401]: Get:9 http://us.archive.ubuntu.com/ubuntu bionic-updates/main amd64 libbsd0 amd64 0.8.7-1ubuntu0.1 [41.6
kB]
[   34.839850] cloud-init[1401]: Get:10 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 libglib2.0-0 amd64 2.56.4-0ubuntu0.
18.04.5 [1170 kB]
[   34.925123] cloud-init[1401]: Get:11 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 libglib2.0-data all 2.56.4-0ubuntu0
.18.04.5 [4692 B]
[   34.925303] cloud-init[1401]: Get:12 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 rsyslog amd64 8.32.0-1ubuntu4.1 [41
2 kB]
[   34.940767] cloud-init[1401]: Get:13 http://us.archive.ubuntu.com/ubuntu bionic-updates/main amd64 libdrm-common all 2.4.99-1ubuntu1~18
.04.1 [5264 B]
[   34.940979] cloud-init[1401]: Get:14 http://us.archive.ubuntu.com/ubuntu bionic-updates/main amd64 libdrm2 amd64 2.4.99-1ubuntu1~18.04.
1 [31.7 kB]
[   34.942728] cloud-init[1401]: Get:15 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 python3-problem-report all 2.20.9-0
ubuntu7.10 [10.6 kB]
[   34.943585] cloud-init[1401]: Get:16 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 python3-apport all 2.20.9-0ubuntu7.
10 [81.8 kB]
[   35.019121] cloud-init[1401]: Get:17 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 apport all 2.20.9-0ubuntu7.10 [124
kB]
[   35.023499] cloud-init[1401]: Get:18 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 mdadm amd64 4.1~rc1-3~ubuntu18.04.4
 [416 kB]
[   35.036131] cloud-init[1401]: Get:19 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 uidmap amd64 1:4.5-1ubuntu2.1 [65.6
 kB]
[   35.174723] cloud-init[1401]: Get:20 http://us.archive.ubuntu.com/ubuntu bionic-proposed/main amd64 cloud-init all 19.4-33-gbb4131a2-0u
buntu1~18.04.1 [409 kB]
[   35.553984] cloud-init[1401]: Preconfiguring packages ...
[   35.668367] cloud-init[1401]: Fetched 5699 kB in 2s (3033 kB/s)
(Reading database ... 38293 files and directories currently installed.)
[   35.714203] cloud-init[1401]: Preparing to unpack .../login_1%3a4.5-1ubuntu2.1_amd64.deb ...
[   35.739547] cloud-init[1401]: Unpacking login (1:4.5-1ubuntu2.1) over (1:4.5-1ubuntu2) ...
[   35.844615] cloud-init[1401]: Setting up login (1:4.5-1ubuntu2.1) ...
(Reading database ... 38293 files and directories currently installed.)
[   35.966022] cloud-init[1401]: Preparing to unpack .../open-iscsi_2.0.874-5ubuntu2.9_amd64.deb ...
[   36.259097] cloud-init[1401]: Unpacking open-iscsi (2.0.874-5ubuntu2.9) over (2.0.874-5ubuntu2.7) ...
[   36.563314] cloud-init[1401]: Preparing to unpack .../gcc-8-base_8.3.0-26ubuntu1~18.04_amd64.deb ...
[   36.578408] cloud-init[1401]: Unpacking gcc-8-base:amd64 (8.3.0-26ubuntu1~18.04) over (8.3.0-6ubuntu1~18.04.1) ...
[   36.635491] cloud-init[1401]: Setting up gcc-8-base:amd64 (8.3.0-26ubuntu1~18.04) ...
(Reading database ... 38295 files and directories currently installed.)
[   36.715759] cloud-init[1401]: Preparing to unpack .../libstdc++6_8.3.0-26ubuntu1~18.04_amd64.deb ...
[   36.768448] cloud-init[1401]: Unpacking libstdc++6:amd64 (8.3.0-26ubuntu1~18.04) over (8.3.0-6ubuntu1~18.04.1) ...
[   36.867522] cloud-init[1401]: Setting up libstdc++6:amd64 (8.3.0-26ubuntu1~18.04) ...
(Reading database ... 38295 files and directories currently installed.)
[   36.944022] cloud-init[1401]: Preparing to unpack .../libgcc1_1%3a8.3.0-26ubuntu1~18.04_amd64.deb ...
[   36.964653] cloud-init[1401]: Unpacking libgcc1:amd64 (1:8.3.0-26ubuntu1~18.04) over (1:8.3.0-6ubuntu1~18.04.1) ...
[   37.023735] cloud-init[1401]: Setting up libgcc1:amd64 (1:8.3.0-26ubuntu1~18.04) ...
(Reading database ... 38295 files and directories currently installed.)
[   37.109157] cloud-init[1401]: Preparing to unpack .../libgcrypt20_1.8.1-4ubuntu1.2_amd64.deb ...
[   37.130740] cloud-init[1401]: Unpacking libgcrypt20:amd64 (1.8.1-4ubuntu1.2) over (1.8.1-4ubuntu1.1) ...
[   37.231797] cloud-init[1401]: Setting up libgcrypt20:amd64 (1.8.1-4ubuntu1.2) ...
(Reading database ... 38295 files and directories currently installed.)
[   37.317138] cloud-init[1401]: Preparing to unpack .../passwd_1%3a4.5-1ubuntu2.1_amd64.deb ...
[   37.345306] cloud-init[1401]: Unpacking passwd (1:4.5-1ubuntu2.1) over (1:4.5-1ubuntu2) ...
[   37.507750] cloud-init[1401]: Setting up passwd (1:4.5-1ubuntu2.1) ...
(Reading database ... 38295 files and directories currently installed.)
[   37.637017] cloud-init[1401]: Preparing to unpack .../libgnutls30_3.5.18-1ubuntu1.2_amd64.deb ...
[   37.651737] cloud-init[1401]: Unpacking libgnutls30:amd64 (3.5.18-1ubuntu1.2) over (3.5.18-1ubuntu1.1) ...
[   37.763770] cloud-init[1401]: Setting up libgnutls30:amd64 (3.5.18-1ubuntu1.2) ...
(Reading database ... 38295 files and directories currently installed.)
[   37.840339] cloud-init[1401]: Preparing to unpack .../00-libbsd0_0.8.7-1ubuntu0.1_amd64.deb ...
[   37.846697] cloud-init[1401]: Unpacking libbsd0:amd64 (0.8.7-1ubuntu0.1) over (0.8.7-1) ...
[   37.907333] cloud-init[1401]: Preparing to unpack .../01-libglib2.0-0_2.56.4-0ubuntu0.18.04.5_amd64.deb ...
[   37.920844] cloud-init[1401]: Unpacking libglib2.0-0:amd64 (2.56.4-0ubuntu0.18.04.5) over (2.56.4-0ubuntu0.18.04.4) ...
[   38.066910] cloud-init[1401]: Preparing to unpack .../02-libglib2.0-data_2.56.4-0ubuntu0.18.04.5_all.deb ...
[   38.079782] cloud-init[1401]: Unpacking libglib2.0-data (2.56.4-0ubuntu0.18.04.5) over (2.56.4-0ubuntu0.18.04.4) ...
[   38.136424] cloud-init[1401]: Preparing to unpack .../03-rsyslog_8.32.0-1ubuntu4.1_amd64.deb ...
[   38.163326] cloud-init[1401]: Unpacking rsyslog (8.32.0-1ubuntu4.1) over (8.32.0-1ubuntu4) ...
[   38.407669] cloud-init[1401]: Preparing to unpack .../04-libdrm-common_2.4.99-1ubuntu1~18.04.1_all.deb ...
[   38.424693] cloud-init[1401]: Unpacking libdrm-common (2.4.99-1ubuntu1~18.04.1) over (2.4.97-1ubuntu1~18.04.1) ...
[   38.480986] cloud-init[1401]: Preparing to unpack .../05-libdrm2_2.4.99-1ubuntu1~18.04.1_amd64.deb ...
[   38.498530] cloud-init[1401]: Unpacking libdrm2:amd64 (2.4.99-1ubuntu1~18.04.1) over (2.4.97-1ubuntu1~18.04.1) ...
[   38.554957] cloud-init[1401]: Preparing to unpack .../06-python3-problem-report_2.20.9-0ubuntu7.10_all.deb ...
[   38.643163] cloud-init[1401]: Unpacking python3-problem-report (2.20.9-0ubuntu7.10) over (2.20.9-0ubuntu7.9) ...
[   38.695691] cloud-init[1401]: Preparing to unpack .../07-python3-apport_2.20.9-0ubuntu7.10_all.deb ...
[   38.784668] cloud-init[1401]: Unpacking python3-apport (2.20.9-0ubuntu7.10) over (2.20.9-0ubuntu7.9) ...
[   38.857799] cloud-init[1401]: Preparing to unpack .../08-apport_2.20.9-0ubuntu7.10_all.deb ...
         Stopping LSB: automatic crash report generation...
[  OK  ] Stopped LSB: automatic crash report generation.
[   39.067862] cloud-init[1401]: Unpacking apport (2.20.9-0ubuntu7.10) over (2.20.9-0ubuntu7.9) ...
[   39.426549] cloud-init[1401]: Preparing to unpack .../09-mdadm_4.1~rc1-3~ubuntu18.04.4_amd64.deb ...
[   39.453149] cloud-init[1401]: Unpacking mdadm (4.1~rc1-3~ubuntu18.04.4) over (4.1~rc1-3~ubuntu18.04.2) ...
[   39.897276] cloud-init[1401]: Preparing to unpack .../10-uidmap_1%3a4.5-1ubuntu2.1_amd64.deb ...
[   39.910261] cloud-init[1401]: Unpacking uidmap (1:4.5-1ubuntu2.1) over (1:4.5-1ubuntu2) ...
[   39.987492] cloud-init[1401]: Preparing to unpack .../11-cloud-init_19.4-33-gbb4131a2-0ubuntu1~18.04.1_all.deb ...
[   40.213313] cloud-init[1401]: Unpacking cloud-init (19.4-33-gbb4131a2-0ubuntu1~18.04.1) over (19.3-41-gc4735dd3-0ubuntu1~18.04.1) ...
[   40.480157] cloud-init[1401]: Setting up libglib2.0-0:amd64 (2.56.4-0ubuntu0.18.04.5) ...
[   40.493088] cloud-init[1401]: No schema files found: doing nothing.
[   40.498996] cloud-init[1401]: Setting up uidmap (1:4.5-1ubuntu2.1) ...
[   40.513802] cloud-init[1401]: Setting up libbsd0:amd64 (0.8.7-1ubuntu0.1) ...
[   40.528703] cloud-init[1401]: Setting up open-iscsi (2.0.874-5ubuntu2.9) ...
[   41.657469] cloud-init[1401]: Setting up mdadm (4.1~rc1-3~ubuntu18.04.4) ...
[   41.944622] cloud-init[1401]: update-initramfs: deferring update (trigger activated)
[   42.397262] cloud-init[1401]: Sourcing file `/etc/default/grub'
[   42.399265] cloud-init[1401]: /usr/sbin/grub-mkconfig: 12: /etc/default/grub: Syntax error: Unterminated quoted string
[   42.530748] cloud-init[1401]: update-rc.d: warning: start and stop actions are no longer supported; falling back to defaults
[   42.964669] cloud-init[1401]: Setting up libdrm-common (2.4.99-1ubuntu1~18.04.1) ...
[   42.987700] cloud-init[1401]: Setting up python3-problem-report (2.20.9-0ubuntu7.10) ...
[   43.154274] cloud-init[1401]: Setting up libglib2.0-data (2.56.4-0ubuntu0.18.04.5) ...
[   43.167769] cloud-init[1401]: Setting up rsyslog (8.32.0-1ubuntu4.1) ...
[   43.178904] cloud-init[1401]: Installing new version of config file /etc/apparmor.d/usr.sbin.rsyslogd ...
[   43.521858] cloud-init[1401]: The user `syslog' is already a member of `adm'.
[   43.658993] cloud-init[1401]: Skipping profile in /etc/apparmor.d/disable: usr.sbin.rsyslogd
         Stopping System Logging Service...
[  OK  ] Stopped System Logging Service.
         Starting System Logging Service...
[  OK  ] Started System Logging Service.
[   43.943049] cloud-init[1401]: Setting up cloud-init (19.4-33-gbb4131a2-0ubuntu1~18.04.1) ...
[   43.952275] cloud-init[1401]: Installing new version of config file /etc/cloud/cloud.cfg ...
[   43.961911] cloud-init[1401]: Installing new version of config file /etc/cloud/cloud.cfg.d/README ...
[   45.217967] cloud-init[1401]: Setting up python3-apport (2.20.9-0ubuntu7.10) ...
[   45.438304] cloud-init[1401]: Setting up libdrm2:amd64 (2.4.99-1ubuntu1~18.04.1) ...
[   45.455262] cloud-init[1401]: Setting up apport (2.20.9-0ubuntu7.10) ...
[   45.898690] cloud-init[1401]: apport-autoreport.service is a disabled or a static unit, not starting it.
         Starting LSB: automatic crash report generation...
[  OK  ] Started LSB: automatic crash report generation.
[   46.207229] cloud-init[1401]: Processing triggers for ureadahead (0.100.0-21) ...
[   46.226861] cloud-init[1401]: Processing triggers for initramfs-tools (0.130ubuntu3.9) ...
[   46.261687] cloud-init[1401]: update-initramfs: Generating /boot/initrd.img-4.15.0-76-generic
[   62.217893] cloud-init[1401]: Processing triggers for libc-bin (2.27-3ubuntu1) ...
[   62.235064] cloud-init[1401]: Processing triggers for systemd (237-3ubuntu10.33) ...
[   62.359705] cloud-init[1401]: Processing triggers for man-db (2.8.3-2ubuntu0.1) ...
[   68.930573] cloud-init[1401]: Reading package lists...
[   69.097266] cloud-init[1401]: Building dependency tree...
[   69.097899] cloud-init[1401]: Reading state information...
[   69.307411] cloud-init[1401]: 0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
[   69.445714] cloud-init[1401]: Reading package lists...
[   69.613139] cloud-init[1401]: Building dependency tree...
[   69.613952] cloud-init[1401]: Reading state information...
[   69.743646] cloud-init[1401]: Failed to disable unit: Unit file unattended-upgrades.service does not exist.
[   69.748839] cloud-init[1401]: Removed /etc/systemd/system/timers.target.wants/apt-daily-upgrade.timer.
[   69.871334] cloud-init[1401]: Removed /etc/systemd/system/timers.target.wants/apt-daily.timer.
[   69.981941] cloud-init[1401]: Removed /etc/systemd/system/graphical.target.wants/accounts-daemon.service.
[   70.106520] cloud-init[1401]: Removed /etc/systemd/system/timers.target.wants/motd-news.timer.
[   70.216762] cloud-init[1401]: Synchronizing state of irqbalance.service with SysV service script with /lib/systemd/systemd-sysv-install
.
[   70.216902] cloud-init[1401]: Executing: /lib/systemd/systemd-sysv-install disable irqbalance
[   70.609219] cloud-init[1401]: Synchronizing state of rsync.service with SysV service script with /lib/systemd/systemd-sysv-install.
[   70.609385] cloud-init[1401]: Executing: /lib/systemd/systemd-sysv-install disable rsync
[   70.940166] cloud-init[1401]: Synchronizing state of ebtables.service with SysV service script with /lib/systemd/systemd-sysv-install.
[   70.940300] cloud-init[1401]: Executing: /lib/systemd/systemd-sysv-install disable ebtables
[   71.304306] cloud-init[1401]: Removed /etc/systemd/system/multi-user.target.wants/pollinate.service.
[   71.414170] cloud-init[1401]: Synchronizing state of ufw.service with SysV service script with /lib/systemd/systemd-sysv-install.
[   71.414328] cloud-init[1401]: Executing: /lib/systemd/systemd-sysv-install disable ufw
[   71.788470] cloud-init[1401]: Synchronizing state of apparmor.service with SysV service script with /lib/systemd/systemd-sysv-install.
[   71.788747] cloud-init[1401]: Executing: /lib/systemd/systemd-sysv-install disable apparmor
[   72.148837] cloud-init[1401]: Removed /etc/systemd/system/paths.target.wants/apport-autoreport.path.
[   72.260256] cloud-init[1401]: Removed /etc/systemd/system/sockets.target.wants/apport-forward.socket.
[   72.371631] cloud-init[1401]: Removed /etc/systemd/system/iscsi.service.
[   72.371753] cloud-init[1401]: Removed /etc/systemd/system/sysinit.target.wants/open-iscsi.service.
[   72.478576] cloud-init[1401]: Synchronizing state of open-iscsi.service with SysV service script with /lib/systemd/systemd-sysv-install
.
[   72.478758] cloud-init[1401]: Executing: /lib/systemd/systemd-sysv-install disable open-iscsi
[   72.842374] cloud-init[1401]: Removed /etc/systemd/system/sockets.target.wants/iscsid.socket.
[   72.955505] cloud-init[1401]: Failed to disable unit: Unit file multipathd.socket does not exist.
[   72.959693] cloud-init[1401]: Failed to disable unit: Unit file multipath-tools.service does not exist.
[   72.963989] cloud-init[1401]: Failed to disable unit: Unit file multipathd.service does not exist.
[   72.968933] cloud-init[1401]: Removed /etc/systemd/system/sysinit.target.wants/lvm2-monitor.service.
[   73.092103] cloud-init[1401]: Removed /etc/systemd/system/sysinit.target.wants/lvm2-lvmpolld.socket.
[   73.209743] cloud-init[1401]: Removed /etc/systemd/system/sysinit.target.wants/lvm2-lvmetad.socket.
[   73.346234] cloud-init[1401]: passwd: password expiry information changed.
[   73.355421] cloud-init[1401]: passwd: password expiry information changed.
ci-info: +++++++++++++++++Authorized keys from /home/rafaeldtinoco/.ssh/authorized_keys for user rafaeldtinoco+++++++++++++++++
ci-info: +---------+-------------------------------------------------+---------+----------------------------------------------+
ci-info: | Keytype |                Fingerprint (md5)                | Options |                   Comment                    |
ci-info: +---------+-------------------------------------------------+---------+----------------------------------------------+
ci-info: | ssh-rsa | 42:46:b4:02:d9:11:8f:02:af:54:c5:23:06:46:76:15 |    -    |                      -                       |
ci-info: | ssh-rsa | 42:46:b4:02:d9:11:8f:02:af:54:c5:23:06:46:76:15 |    -    | personalkey # ssh-import-id lp:rafaeldtinoco |
ci-info: +---------+-------------------------------------------------+---------+----------------------------------------------+
<14>Jan 22 04:30:00 ec2:
<14>Jan 22 04:30:00 ec2: #############################################################
<14>Jan 22 04:30:00 ec2: -----BEGIN SSH HOST KEY FINGERPRINTS-----
<14>Jan 22 04:30:00 ec2: 1024 SHA256:fRR8GxqC5TY9vWFOD1zpCzKOtAF9hZ5adH+JJpRnJUc root@ubuntu (DSA)
<14>Jan 22 04:30:00 ec2: 256 SHA256:hKVu8st7m1haYfyq2+Wa3JpK9Kpn+LN3HKBMbIjjCWU root@ubuntu (ECDSA)
<14>Jan 22 04:30:00 ec2: 256 SHA256:kiLPS974tw0nUt51he0BiyeYCPT5iLZTgHOq/XjUhvE root@ubuntu (ED25519)
<14>Jan 22 04:30:00 ec2: 2048 SHA256:mMNSKQK3xWxTXkLWM0S7GhTJfTutFQknWDoV2tpxS18 root@ubuntu (RSA)
<14>Jan 22 04:30:00 ec2: -----END SSH HOST KEY FINGERPRINTS-----
<14>Jan 22 04:30:00 ec2: #############################################################
-----BEGIN SSH HOST KEY KEYS-----
ecdsa-sha2-nistp256 AAAAE2VjZHNhLXNoYTItbmlzdHAyNTYAAAAIbmlzdHAyNTYAAABBBNz7DTsJKjF1NWH25gUMDkZUkXYy7PJ3T5mybngxULjkx667bgYw5Vbz8MiIgcE43E
oBoHvziQgE58Dhid77OxI= root@ubuntu
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILK+X99qV0Xj2UTYJ9PLYybOmHDA1pY+u2+0LszrsRvP root@ubuntu
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCyR9mtXS8Z4VEPH5EL+XTVZ2gpgt5IhM0iULkq4ec0VctNvwlrQ3d4YWSoYYDbM/aF+wm/+VflXC9E0r8BVllr/ZRcPvrCv4LjKb
TbU45Hn5yq1a2jQ7/Jh8wqPQO98DJr9TsniJhZag+bCsQ6UpfobabbkMy8veBoA3nr3otXsRW3M4lq9Vi7wikjswxsvGpo9iZxOjdwZF7HapPq+Tga5BVa/uS8SYBzdiRIM3Kkv0y/
raX94j4ljq2l2daCutTVHbNwq2utrXcUPvAJ4CXfpfAicmkMyFrHBj7JbCcA/e6sd3Ut2ZOUOnEp8Ut9JC/SgpUzuZnK/izTBN3AH25p root@ubuntu
-----END SSH HOST KEY KEYS-----
[   73.415745] cloud-init[1401]: Cloud-init v. 19.3-41-gc4735dd3-0ubuntu1~18.04.1 running 'modules:final' at Wed, 22 Jan 2020 04:29:11 +00
00. Up 25.47 seconds.
[   73.415899] cloud-init[1401]: The system is finally up! Enjoy!
[  OK  ] Started Execute cloud user/final scripts.
[  OK  ] Reached target Cloud-init target.
[  OK  ] Stopped target Graphical Interface.
[  OK  ] Closed Load/Save RF Kill Switch Status /dev/rfkill Watch.
         Stopping Accounts Service...
         Stopping irqbalance daemon...
[  OK  ] Stopped target Timers.
[  OK  ] Stopped Discard unused blocks once a week.
         Stopping Availability of block devices...
[  OK  ] Stopped Daily Cleanup of Temporary Directories.
[  OK  ] Stopped target Host and Network Name Lookups.
[  OK  ] Stopped Message of the Day.
[  OK  ] Stopped target Cloud-init target.
[  OK  ] Stopped Execute cloud user/final scripts.
[  OK  ] Stopped target Multi-User System.
         Stopping LSB: Record successful boot for GRUB...
         Stopping System Logging Service...
         Stopping Login Service...
         Stopping LSB: automatic crash report generation...
         Stopping LXD - container startup/shutdown...
         Stopping Regular background program processing daemon...
         Stopping D-Bus System Message Bus...
[  OK  ] Stopped target Login Prompts.
         Stopping Getty on tty1...
         Stopping OpenBSD Secure Shell server...
         Stopping Dispatcher daemon for systemd-networkd...
         Stopping FUSE filesystem for LXC...
[  OK  ] Stopped Daily apt upgrade and clean activities.
[  OK  ] Stopped Daily apt download activities.
[  OK  ] Stopped target System Time Synchronized.
[  OK  ] Stopped Apply the settings specified in cloud-config.
[  OK  ] Stopped target Network is Online.
[  OK  ] Stopped Wait until snapd is fully seeded.
[  OK
       topping Serial Getty on ttyS0...
         Stopping Authorization Manager...
         Stopping Deferred execution scheduler...
[  OK  ] Unmounted /var/lib/lxcfs.
[  OK  ] Stopped Regular background program processing daemon.
[  OK  ] Stopped Dispatcher daemon for systemd-networkd.
[  OK  ] Stopped Deferred execution scheduler.
[  OK  ] Stopped Accounts Service.
[  OK  ] Stopped irqbalance daemon.
[  OK  ] Stopped Authorization Manager.
[  OK  ] Stopped Serial Getty on ttyS0.
[  OK  ] Stopped Getty on tty1.
[  OK  ] Stopped OpenBSD Secure Shell server.
[  OK  ] Stopped System Logging Service.
[  OK  ] Stopped Availability of block devices.
[  OK  ] Stopped D-Bus System Message Bus.
[  OK  ] Stopped FUSE filesystem for LXC.
[  OK  ] Removed slice system-getty.slice.
[  OK  ] Removed slice system-serial\x2dgetty.slice.
         Stopping Permit User Sessions...
[  OK  ] Stopped LSB: Record successful boot for GRUB.
[  OK  ] Stopped LXD - container startup/shutdown.
[  OK  ] Stopped Login Service.
[  OK  ] Stopped Permit User Sessions.
[  OK  ] Stopped target Network.
         Stopping Network Name Resolution...
[  OK  ] Stopped target User and Group Name Lookups.
[  OK  ] Stopped LSB: automatic crash report generation.
[  OK  ] Stopped target Basic System.
[  OK  ] Stopped target Slices.
[  OK  ] Removed slice User and Session Slice.
[  OK  ] Stopped target Sockets.
[  OK  ] Closed D-Bus System Message Bus Socket.
[  OK  ] Closed ACPID Listen Socket.
[  OK  ] Closed Syslog Socket.
[  OK  ] Closed LXD - unix socket.
[  OK  ] Closed Open-iSCSI iscsid Socket.
[  OK  ] Closed Socket activation for snappy daemon.
[  OK  ] Closed UUID daemon activation socket.
[  OK  ] Stopped target Paths.
[  OK  ] Stopped ACPI Events Check.
[  OK  ] Stopped target Remote File Systems.
[  OK  ] Stopped target Remote File Systems (Pre).
[  OK  ] Stopped target System Initialization.
[  OK  ] Stopped Initial cloud-init job (metadata service crawler).
[  OK  ] Stopped Wait for Network to be Configured.
         Stopping Update UTMP about System Boot/Shutdown...
         Stopping Network Time Synchronization...
[  OK  ] Stopped Commit a transient machine-id on disk.
         Stopping Load/Save Random Seed...
[  OK  ] Stopped target Local Encrypted Volumes.
[  OK  ] Stopped Dispatch Password Requests to Console Directory Watch.
[  OK  ] Stopped Forward Password Requests to Wall Directory Watch.
[  OK  ] Stopped target Swap.
         Deactivating swap /swap.img...
[  OK  ] Stopped Network Time Synchronization.
[  OK  ] Stopped Network Name Resolution.
[  OK  ] Stopped Load/Save Random Seed.
         Stopping Network Service...
[  OK  ] Stopped Update UTMP about System Boot/Shutdown.
[  OK  ] Stopped Create Volatile Files and Directories.
[  OK  ] Stopped target Local File Systems.
[  OK  ] Stopped target Local File Systems (Pre).
         Stopping Monitoring of LVM2 mirrors&ng dmeventd or progress polling...
[  OK  ] Stopped Create Static Device Nodes in /dev.
[  OK  ] Stopped Monitoring of LVM2 mirrors,&sing dmeventd or progress polling.
         Stopping LVM2 metadata daemon...
[  OK  ] Stopped LVM2 metadata daemon.
[  OK  ] Deactivated swap /swap.img.
[  OK  ] Reached target Unmount All Filesystems.
[  OK  ] Stopped Network Service.
[  OK  ] Stopped Apply Kernel Variables.
[  OK  ] Stopped Load Kernel Modules.
[  OK  ] Stopped target Network (Pre).
[  OK  ] Stopped Initial cloud-init job (pre-networking).
[  OK  ] Reached target Shutdown.
[  OK  ] Reached target Final Step.
         Starting Reboot...

--------

Cloud-Init has finished its work. It has fully upgraded the installed machine
using online archive. It has created my user, given to iso.sh tool, it has
imported my launchpad_id ssh key, also given to the tool, etc.

Next reboot is the final one:

--------

[   74.053178] reboot: Restarting system
[    0.000000] Linux version 4.15.0-76-generic (buildd@lcy01-amd64-029) (gcc version 7.4.0 (Ubuntu 7.4.0-1ubuntu1~18.04.1)) #86-Ubuntu SMP
 Fri Jan 17 17:24:28 UTC 2020 (Ubuntu 4.15.0-76.86-generic 4.15.18)
[    0.000000] Command line: BOOT_IMAGE=/boot/vmlinuz-4.15.0-76-generic root=UUID=cb3c594d-2432-47eb-a114-09fea1c13716 ro console=tty0 con
sole=ttyS0,38400n8
[    0.000000] KERNEL supported cpus:
[    0.000000]   Intel GenuineIntel
[    0.000000]   AMD AuthenticAMD
[    0.000000]   Centaur CentaurHauls
[    0.000000] random: get_random_u32 called from bsp_init_amd+0x207/0x2c0 with crng_init=0
[    0.000000] x86/fpu: Supporting XSAVE feature 0x001: 'x87 floating point registers'
[    0.000000] x86/fpu: Supporting XSAVE feature 0x002: 'SSE registers'
[    0.000000] x86/fpu: Supporting XSAVE feature 0x004: 'AVX registers'
[    0.000000] x86/fpu: xstate_offset[2]:  576, xstate_sizes[2]:  256
[    0.000000] x86/fpu: Enabled xstate features 0x7, context size is 832 bytes, using 'standard' format.
[    0.000000] e820: BIOS-provided physical RAM map:
[    0.000000] BIOS-e820: [mem 0x0000000000000000-0x000000000009fbff] usable
[    0.000000] BIOS-e820: [mem 0x000000000009fc00-0x000000000009ffff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000000f0000-0x00000000000fffff] reserved
[    0.000000] BIOS-e820: [mem 0x0000000000100000-0x00000000bffdbfff] usable
[    0.000000] BIOS-e820: [mem 0x00000000bffdc000-0x00000000bfffffff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000feffc000-0x00000000feffffff] reserved
[    0.000000] BIOS-e820: [mem 0x00000000fffc0000-0x00000000ffffffff] reserved
[    0.000000] BIOS-e820: [mem 0x0000000100000000-0x000000013fffffff] usable
[    0.000000] NX (Execute Disable) protection: active
[    0.000000] SMBIOS 2.8 present.
[    0.000000] DMI: QEMU Standard PC (i440FX + PIIX, 1996), BIOS 1.12.0-1 04/01/2014
[    0.000000] Hypervisor detected: KVM
[    0.000000] AGP: No AGP bridge found
[    0.000000] e820: last_pfn = 0x140000 max_arch_pfn = 0x400000000
[    0.000000] x86/PAT: Configuration [0-7]: WB  WC  UC- UC  WB  WP  UC- WT
[    0.000000] e820: last_pfn = 0xbffdc max_arch_pfn = 0x400000000
[    0.000000] found SMP MP-table at [mem 0x000f5a40-0x000f5a4f]
[    0.000000] Scanning 1 areas for low memory corruption
[    0.000000] Using GB pages for direct mapping
[    0.000000] RAMDISK: [mem 0x3115f000-0x348a6fff]
[    0.000000] ACPI: Early table checksum verification disabled
[    0.000000] ACPI: RSDP 0x00000000000F5A00 000014 (v00 BOCHS )
[    0.000000] ACPI: RSDT 0x00000000BFFE13B8 000030 (v01 BOCHS  BXPCRSDT 00000001 BXPC 00000001)
[    0.000000] ACPI: FACP 0x00000000BFFE127C 000074 (v01 BOCHS  BXPCFACP 00000001 BXPC 00000001)
[    0.000000] ACPI: DSDT 0x00000000BFFDFDC0 0014BC (v01 BOCHS  BXPCDSDT 00000001 BXPC 00000001)
[    0.000000] ACPI: FACS 0x00000000BFFDFD80 000040
[    0.000000] ACPI: APIC 0x00000000BFFE12F0 000090 (v01 BOCHS  BXPCAPIC 00000001 BXPC 00000001)
[    0.000000] ACPI: HPET 0x00000000BFFE1380 000038 (v01 BOCHS  BXPCHPET 00000001 BXPC 00000001)
[    0.000000] No NUMA configuration found
[    0.000000] Faking a node at [mem 0x0000000000000000-0x000000013fffffff]
[    0.000000] NODE_DATA(0) allocated [mem 0x13ffd3000-0x13fffdfff]
[    0.000000] kvm-clock: cpu 0, msr 1:3ff52001, primary cpu clock
[    0.000000] kvm-clock: Using msrs 4b564d01 and 4b564d00
[    0.000000] kvm-clock: using sched offset of 78506583736 cycles
[    0.000000] clocksource: kvm-clock: mask: 0xffffffffffffffff max_cycles: 0x1cd42e4dffb, max_idle_ns: 881590591483 ns
[    0.000000] Zone ranges:
[    0.000000]   DMA      [mem 0x0000000000001000-0x0000000000ffffff]
[    0.000000]   DMA32    [mem 0x0000000001000000-0x00000000ffffffff]
[    0.000000]   Normal   [mem 0x0000000100000000-0x000000013fffffff]
[    0.000000]   Device   empty
[    0.000000] Movable zone start for each node
[    0.000000] Early memory node ranges
[    0.000000]   node   0: [mem 0x0000000000001000-0x000000000009efff]
[    0.000000]   node   0: [mem 0x0000000000100000-0x00000000bffdbfff]
[    0.000000]   node   0: [mem 0x0000000100000000-0x000000013fffffff]
[    0.000000] Reserved but unavailable: 98 pages
[    0.000000] Initmem setup node 0 [mem 0x0000000000001000-0x000000013fffffff]
[    0.000000] ACPI: PM-Timer IO Port: 0x608
[    0.000000] ACPI: LAPIC_NMI (acpi_id[0xff] dfl dfl lint[0x1])
[    0.000000] IOAPIC[0]: apic_id 0, version 17, address 0xfec00000, GSI 0-23
[    0.000000] ACPI: INT_SRC_OVR (bus 0 bus_irq 0 global_irq 2 dfl dfl)
[    0.000000] ACPI: INT_SRC_OVR (bus 0 bus_irq 5 global_irq 5 high level)
[    0.000000] ACPI: INT_SRC_OVR (bus 0 bus_irq 9 global_irq 9 high level)
[    0.000000] ACPI: INT_SRC_OVR (bus 0 bus_irq 10 global_irq 10 high level)
[    0.000000] ACPI: INT_SRC_OVR (bus 0 bus_irq 11 global_irq 11 high level)
[    0.000000] Using ACPI (MADT) for SMP configuration information
[    0.000000] ACPI: HPET id: 0x8086a201 base: 0xfed00000
[    0.000000] smpboot: Allowing 4 CPUs, 0 hotplug CPUs
[    0.000000] PM: Registered nosave memory: [mem 0x00000000-0x00000fff]
[    0.000000] PM: Registered nosave memory: [mem 0x0009f000-0x0009ffff]
[    0.000000] PM: Registered nosave memory: [mem 0x000a0000-0x000effff]
[    0.000000] PM: Registered nosave memory: [mem 0x000f0000-0x000fffff]
[    0.000000] PM: Registered nosave memory: [mem 0xbffdc000-0xbfffffff]
[    0.000000] PM: Registered nosave memory: [mem 0xc0000000-0xfeffbfff]
[    0.000000] PM: Registered nosave memory: [mem 0xfeffc000-0xfeffffff]
[    0.000000] PM: Registered nosave memory: [mem 0xff000000-0xfffbffff]
[    0.000000] PM: Registered nosave memory: [mem 0xfffc0000-0xffffffff]
[    0.000000] e820: [mem 0xc0000000-0xfeffbfff] available for PCI devices
[    0.000000] Booting paravirtualized kernel on KVM
[    0.000000] clocksource: refined-jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645519600211568 ns
[    0.000000] setup_percpu: NR_CPUS:8192 nr_cpumask_bits:4 nr_cpu_ids:4 nr_node_ids:1
[    0.000000] percpu: Embedded 45 pages/cpu s147456 r8192 d28672 u524288
[    0.000000] KVM setup async PF for cpu 0
[    0.000000] kvm-stealtime: cpu 0, msr 13fc23040
[    0.000000] PV qspinlock hash table entries: 256 (order: 0, 4096 bytes)
[    0.000000] Built 1 zonelists, mobility grouping on.  Total pages: 1032037
[    0.000000] Policy zone: Normal
[    0.000000] Kernel command line: BOOT_IMAGE=/boot/vmlinuz-4.15.0-76-generic root=UUID=cb3c594d-2432-47eb-a114-09fea1c13716 ro console=t
ty0 console=ttyS0,38400n8
[    0.000000] AGP: Checking aperture...
[    0.000000] AGP: No AGP bridge found
[    0.000000] Memory: 3975848K/4193768K available (12300K kernel code, 2481K rwdata, 4260K rodata, 2428K init, 2704K bss, 217920K reserve
d, 0K cma-reserved)
[    0.000000] SLUB: HWalign=64, Order=0-3, MinObjects=0, CPUs=4, Nodes=1
[    0.000000] ftrace: allocating 39322 entries in 154 pages
[    0.004000] Hierarchical RCU implementation.
[    0.004000]  RCU restricting CPUs from NR_CPUS=8192 to nr_cpu_ids=4.
[    0.004000]  Tasks RCU enabled.
[    0.004000] RCU: Adjusting geometry for rcu_fanout_leaf=16, nr_cpu_ids=4
[    0.004000] NR_IRQS: 524544, nr_irqs: 456, preallocated irqs: 16
[    0.004000] Console: colour VGA+ 80x25
[    0.004000] console [tty0] enabled
[    0.004000] console [ttyS0] enabled
[    0.004000] ACPI: Core revision 20170831
[    0.004000] ACPI: 1 ACPI AML tables successfully acquired and loaded
[    0.004000] clocksource: hpet: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 19112604467 ns
[    0.004008] APIC: Switch to symmetric I/O mode setup
[    0.005312] x2apic enabled
[    0.006185] Switched APIC routing to physical x2apic.
[    0.008000] ..TIMER: vector=0x30 apic1=0 pin1=2 apic2=-1 pin2=-1
[    0.008000] tsc: Detected 4013.492 MHz processor
[    0.008000] tsc: Marking TSC unstable due to TSCs unsynchronized
[    0.008002] Calibrating delay loop (skipped) preset value.. 8026.98 BogoMIPS (lpj=16053968)
[    0.009868] pid_max: default: 32768 minimum: 301
[    0.010942] Security Framework initialized
[    0.011854] Yama: becoming mindful.
[    0.012021] AppArmor: AppArmor initialized
[    0.013718] Dentry cache hash table entries: 524288 (order: 10, 4194304 bytes)
[    0.016401] Inode-cache hash table entries: 262144 (order: 9, 2097152 bytes)
[    0.017966] Mount-cache hash table entries: 8192 (order: 4, 65536 bytes)
[    0.019438] Mountpoint-cache hash table entries: 8192 (order: 4, 65536 bytes)
[    0.020276] Last level iTLB entries: 4KB 512, 2MB 1024, 4MB 512
[    0.021504] Last level dTLB entries: 4KB 512, 2MB 255, 4MB 127, 1GB 0
[    0.022837] Spectre V1 : Mitigation: usercopy/swapgs barriers and __user pointer sanitization
[    0.024002] Spectre V2 : Mitigation: Full AMD retpoline
[    0.025130] Spectre V2 : Spectre v2 / SpectreRSB mitigation: Filling RSB on context switch
[    0.028008] Spectre V2 : mitigation: Enabling conditional Indirect Branch Prediction Barrier
[    0.029799] Speculative Store Bypass: Mitigation: Speculative Store Bypass disabled via prctl and seccomp
[    0.039856] Freeing SMP alternatives memory: 36K
[    0.042252] smpboot: CPU0: AMD FX(tm)-8350 Eight-Core Processor (family: 0x15, model: 0x2, stepping: 0x0)
[    0.044000] Performance Events: Fam15h core perfctr, AMD PMU driver.
[    0.044000] ... version:                0
[    0.044005] ... bit width:              48
[    0.044941] ... generic registers:      6
[    0.045854] ... value mask:             0000ffffffffffff
[    0.047019] ... max period:             00007fffffffffff
[    0.048003] ... fixed-purpose events:   0
[    0.048917] ... event mask:             000000000000003f
[    0.050187] Hierarchical SRCU implementation.
[    0.051875] smp: Bringing up secondary CPUs ...
[    0.052145] x86: Booting SMP configuration:
[    0.053160] .... node  #0, CPUs:      #1
[    0.004000] kvm-clock: cpu 1, msr 1:3ff52041, secondary cpu clock
[    0.055414] KVM setup async PF for cpu 1
[    0.055414] kvm-stealtime: cpu 1, msr 13fca3040
[    0.056124]  #2
[    0.004000] kvm-clock: cpu 2, msr 1:3ff52081, secondary cpu clock
[    0.057975] KVM setup async PF for cpu 2
[    0.057975] kvm-stealtime: cpu 2, msr 13fd23040
[    0.060113]  #3
[    0.004000] kvm-clock: cpu 3, msr 1:3ff520c1, secondary cpu clock
[    0.061973] KVM setup async PF for cpu 3
[    0.061973] kvm-stealtime: cpu 3, msr 13fda3040
[    0.064003] smp: Brought up 1 node, 4 CPUs
[    0.064969] smpboot: Max logical packages: 4
[    0.065974] smpboot: Total of 4 processors activated (32107.93 BogoMIPS)
[    0.068399] devtmpfs: initialized
[    0.068821] x86/mm: Memory block size: 128MB
[    0.070184] evm: security.selinux
[    0.070968] evm: security.SMACK64
[    0.072005] evm: security.SMACK64EXEC
[    0.072820] evm: security.SMACK64TRANSMUTE
[    0.073717] evm: security.SMACK64MMAP
[    0.074538] evm: security.apparmor
[    0.075311] evm: security.ima
[    0.076004] evm: security.capability
[    0.076842] clocksource: jiffies: mask: 0xffffffff max_cycles: 0xffffffff, max_idle_ns: 7645041785100000 ns
[    0.078018] futex hash table entries: 1024 (order: 4, 65536 bytes)
[    0.080084] pinctrl core: initialized pinctrl subsystem
[    0.081306] RTC time:  4:30:04, date: 01/22/20
[    0.083298] NET: Registered protocol family 16
[    0.084077] audit: initializing netlink subsys (disabled)
[    0.085236] audit: type=2000 audit(1579667403.114:1): state=initialized audit_enabled=0 res=1
[    0.085236] cpuidle: using governor ladder
[    0.088010] cpuidle: using governor menu
[    0.089458] ACPI: bus type PCI registered
[    0.089458] acpiphp: ACPI Hot Plug PCI Controller Driver version: 0.5
[    0.092098] PCI: Using configuration type 1 for base access
[    0.093450] PCI: Using configuration type 1 for extended access
[    0.096290] HugeTLB registered 1.00 GiB page size, pre-allocated 0 pages
[    0.097588] HugeTLB registered 2.00 MiB page size, pre-allocated 0 pages
[    0.099228] ACPI: Added _OSI(Module Device)
[    0.100005] ACPI: Added _OSI(Processor Device)
[    0.101114] ACPI: Added _OSI(3.0 _SCP Extensions)
[    0.102276] ACPI: Added _OSI(Processor Aggregator Device)
[    0.103587] ACPI: Added _OSI(Linux-Dell-Video)
[    0.104004] ACPI: Added _OSI(Linux-Lenovo-NV-HDMI-Audio)
[    0.105283] ACPI: Added _OSI(Linux-HPI-Hybrid-Graphics)
[    0.107222] ACPI: Interpreter enabled
[    0.108013] ACPI: (supports S0 S5)
[    0.108800] ACPI: Using IOAPIC for interrupt routing
[    0.109851] PCI: Using host bridge windows from ACPI; if necessary, use "pci=nocrs" and report a bug
[    0.111891] ACPI: Enabled 2 GPEs in block 00 to 0F
[    0.115266] ACPI: PCI Root Bridge [PCI0] (domain 0000 [bus 00-ff])
[    0.116009] acpi PNP0A03:00: _OSC: OS supports [ExtendedConfig ASPM ClockPM Segments MSI]
[    0.117955] acpi PNP0A03:00: _OSC failed (AE_NOT_FOUND); disabling ASPM
[    0.119798] acpiphp: Slot [3] registered
[    0.120036] acpiphp: Slot [4] registered
[    0.120933] acpiphp: Slot [5] registered
[    0.121869] acpiphp: Slot [6] registered
[    0.122777] acpiphp: Slot [7] registered
[    0.123698] acpiphp: Slot [8] registered
[    0.124038] acpiphp: Slot [9] registered
[    0.124940] acpiphp: Slot [10] registered
[    0.125920] acpiphp: Slot [11] registered
[    0.126968] acpiphp: Slot [12] registered
[    0.128023] acpiphp: Slot [13] registered
[    0.129103] acpiphp: Slot [14] registered
[    0.130166] acpiphp: Slot [15] registered
[    0.131201] acpiphp: Slot [16] registered
[    0.132037] acpiphp: Slot [17] registered
[    0.133078] acpiphp: Slot [18] registered
[    0.134128] acpiphp: Slot [19] registered
[    0.135164] acpiphp: Slot [20] registered
[    0.136039] acpiphp: Slot [21] registered
[    0.137087] acpiphp: Slot [22] registered
[    0.138124] acpiphp: Slot [23] registered
[    0.139164] acpiphp: Slot [24] registered
[    0.140036] acpiphp: Slot [25] registered
[    0.141111] acpiphp: Slot [26] registered
[    0.142156] acpiphp: Slot [27] registered
[    0.143204] acpiphp: Slot [28] registered
[    0.144039] acpiphp: Slot [29] registered
[    0.145060] acpiphp: Slot [30] registered
[    0.146051] acpiphp: Slot [31] registered
[    0.147037] PCI host bridge to bus 0000:00
[    0.148005] pci_bus 0000:00: root bus resource [io  0x0000-0x0cf7 window]
[    0.149535] pci_bus 0000:00: root bus resource [io  0x0d00-0xffff window]
[    0.150985] pci_bus 0000:00: root bus resource [mem 0x000a0000-0x000bffff window]
[    0.152004] pci_bus 0000:00: root bus resource [mem 0xc0000000-0xfebfffff window]
[    0.153730] pci_bus 0000:00: root bus resource [mem 0x140000000-0x1bfffffff window]
[    0.155504] pci_bus 0000:00: root bus resource [bus 00-ff]
[    0.160545] pci 0000:00:01.1: legacy IDE quirk: reg 0x10: [io  0x01f0-0x01f7]
[    0.162075] pci 0000:00:01.1: legacy IDE quirk: reg 0x14: [io  0x03f6]
[    0.163438] pci 0000:00:01.1: legacy IDE quirk: reg 0x18: [io  0x0170-0x0177]
[    0.164004] pci 0000:00:01.1: legacy IDE quirk: reg 0x1c: [io  0x0376]
[    0.169362] pci 0000:00:01.3: quirk: [io  0x0600-0x063f] claimed by PIIX4 ACPI
[    0.170981] pci 0000:00:01.3: quirk: [io  0x0700-0x070f] claimed by PIIX4 SMB
[    0.201763] ACPI: PCI Interrupt Link [LNKA] (IRQs 5 *10 11)
[    0.203115] ACPI: PCI Interrupt Link [LNKB] (IRQs 5 *10 11)
[    0.204117] ACPI: PCI Interrupt Link [LNKC] (IRQs 5 10 *11)
[    0.205435] ACPI: PCI Interrupt Link [LNKD] (IRQs 5 10 *11)
[    0.206686] ACPI: PCI Interrupt Link [LNKS] (IRQs *9)
[    0.208557] SCSI subsystem initialized
[    0.209465] pci 0000:00:02.0: vgaarb: setting as boot VGA device
[    0.209465] pci 0000:00:02.0: vgaarb: VGA device added: decodes=io+mem,owns=io+mem,locks=none
[    0.212013] pci 0000:00:02.0: vgaarb: bridge control possible
[    0.213237] vgaarb: loaded
[    0.213936] ACPI: bus type USB registered
[    0.214894] usbcore: registered new interface driver usbfs
[    0.216021] usbcore: registered new interface driver hub
[    0.217184] usbcore: registered new device driver usb
[    0.218331] EDAC MC: Ver: 3.0.0
[    0.218331] PCI: Using ACPI for IRQ routing
[    0.220204] NetLabel: Initializing
[    0.221035] NetLabel:  domain hash size = 128
[    0.222147] NetLabel:  protocols = UNLABELED CIPSOv4 CALIPSO
[    0.223539] NetLabel:  unlabeled traffic allowed by default
[    0.224075] hpet0: at MMIO 0xfed00000, IRQs 2, 8, 0
[    0.225286] hpet0: 3 comparators, 64-bit 100.000000 MHz counter
[    0.232057] clocksource: Switched to clocksource kvm-clock
[    0.246174] VFS: Disk quotas dquot_6.6.0
[    0.247203] VFS: Dquot-cache hash table entries: 512 (order 0, 4096 bytes)
[    0.248947] AppArmor: AppArmor Filesystem Enabled
[    0.250159] pnp: PnP ACPI init
[    0.251452] pnp: PnP ACPI: found 5 devices
[    0.259262] clocksource: acpi_pm: mask: 0xffffff max_cycles: 0xffffff, max_idle_ns: 2085701024 ns
[    0.261493] NET: Registered protocol family 2
[    0.262761] TCP established hash table entries: 32768 (order: 6, 262144 bytes)
[    0.264607] TCP bind hash table entries: 32768 (order: 7, 524288 bytes)
[    0.266437] TCP: Hash tables configured (established 32768 bind 32768)
[    0.268043] UDP hash table entries: 2048 (order: 4, 65536 bytes)
[    0.269504] UDP-Lite hash table entries: 2048 (order: 4, 65536 bytes)
[    0.271062] NET: Registered protocol family 1
[    0.272164] pci 0000:00:00.0: Limiting direct PCI/PCI transfers
[    0.273631] pci 0000:00:01.0: PIIX3: Enabling Passive Release
[    0.275018] pci 0000:00:01.0: Activating ISA DMA hang workarounds
[    0.305713] ACPI: PCI Interrupt Link [LNKD] enabled at IRQ 11
[    0.337541] pci 0000:00:02.0: Video device with shadowed ROM at [mem 0x000c0000-0x000dffff]
[    0.339524] Unpacking initramfs...
[    0.978185] Freeing initrd memory: 56608K
[    0.979283] PCI-DMA: Using software bounce buffering for IO (SWIOTLB)
[    0.980781] software IO TLB: mapped [mem 0xbbfdc000-0xbffdc000] (64MB)
[    0.982296] clocksource: tsc: mask: 0xffffffffffffffff max_cycles: 0x39da262945c, max_idle_ns: 440795296057 ns
[    0.984542] Scanning for low memory corruption every 60 seconds
[    0.986503] Initialise system trusted keyrings
[    0.987504] Key type blacklist registered
[    0.988463] workingset: timestamp_bits=36 max_order=20 bucket_order=0
[    0.990938] zbud: loaded
[    0.992057] squashfs: version 4.0 (2009/01/31) Phillip Lougher
[    0.993497] fuse init (API version 7.26)
[    0.996068] Key type asymmetric registered
[    0.997082] Asymmetric key parser 'x509' registered
[    0.998269] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 246)
[    1.000069] io scheduler noop registered
[    1.000900] io scheduler deadline registered
[    1.001810] io scheduler cfq registered (default)
[    1.003037] input: Power Button as /devices/LNXSYSTM:00/LNXPWRBN:00/input/input0
[    1.004503] ACPI: Power Button [PWRF]
[    1.034830] ACPI: PCI Interrupt Link [LNKC] enabled at IRQ 10
[    1.096187] ACPI: PCI Interrupt Link [LNKA] enabled at IRQ 10
[    1.098802] Serial: 8250/16550 driver, 32 ports, IRQ sharing enabled
[    1.125805] 00:04: ttyS0 at I/O 0x3f8 (irq = 4, base_baud = 115200) is a 16550A
[    1.129635] Linux agpgart interface v0.103
[    1.132258] loop: module loaded
[    1.133541] scsi host0: ata_piix
[    1.134349] scsi host1: ata_piix
[    1.135050] ata1: PATA max MWDMA2 cmd 0x1f0 ctl 0x3f6 bmdma 0xc100 irq 14
[    1.136369] ata2: PATA max MWDMA2 cmd 0x170 ctl 0x376 bmdma 0xc108 irq 15
[    1.137783] libphy: Fixed MDIO Bus: probed
[    1.138820] tun: Universal TUN/TAP device driver, 1.6
[    1.139916] PPP generic driver version 2.4.2
[    1.140826] ehci_hcd: USB 2.0 'Enhanced' Host Controller (EHCI) Driver
[    1.142054] ehci-pci: EHCI PCI platform driver
[    1.142937] ehci-platform: EHCI generic platform driver
[    1.143966] ohci_hcd: USB 1.1 'Open' Host Controller (OHCI) Driver
[    1.145157] ohci-pci: OHCI PCI platform driver
[    1.146052] ohci-platform: OHCI generic platform driver
[    1.147072] uhci_hcd: USB Universal Host Controller Interface driver
[    1.177573] uhci_hcd 0000:00:01.2: UHCI Host Controller
[    1.178603] uhci_hcd 0000:00:01.2: new USB bus registered, assigned bus number 1
[    1.180042] uhci_hcd 0000:00:01.2: detected 2 ports
[    1.181065] uhci_hcd 0000:00:01.2: irq 11, io base 0x0000c0c0
[    1.182233] usb usb1: New USB device found, idVendor=1d6b, idProduct=0001
[    1.183529] usb usb1: New USB device strings: Mfr=3, Product=2, SerialNumber=1
[    1.185198] usb usb1: Product: UHCI Host Controller
[    1.186436] usb usb1: Manufacturer: Linux 4.15.0-76-generic uhci_hcd
[    1.187930] usb usb1: SerialNumber: 0000:00:01.2
[    1.189268] hub 1-0:1.0: USB hub found
[    1.190291] hub 1-0:1.0: 2 ports detected
[    1.191527] i8042: PNP: PS/2 Controller [PNP0303:KBD,PNP0f13:MOU] at 0x60,0x64 irq 1,12
[    1.194229] serio: i8042 KBD port at 0x60,0x64 irq 1
[    1.195582] serio: i8042 AUX port at 0x60,0x64 irq 12
[    1.196981] mousedev: PS/2 mouse device common for all mice
[    1.198469] rtc_cmos 00:00: RTC can wake from S4
[    1.199978] input: AT Translated Set 2 keyboard as /devices/platform/i8042/serio0/input/input1
[    1.201933] rtc_cmos 00:00: rtc core: registered rtc_cmos as rtc0
[    1.203605] rtc_cmos 00:00: alarms up to one day, y3k, 114 bytes nvram, hpet irqs
[    1.205209] i2c /dev entries driver
[    1.206038] device-mapper: uevent: version 1.0.3
[    1.207075] device-mapper: ioctl: 4.37.0-ioctl (2017-09-20) initialised: dm-devel@redhat.com
[    1.208847] ledtrig-cpu: registered to indicate activity on CPUs
[    1.210206] x86/pm: family 0x15 cpu detected, MSR saving is needed during suspending.
[    1.211891] NET: Registered protocol family 10
[    1.215918] Segment Routing with IPv6
[    1.216852] NET: Registered protocol family 17
[    1.217979] Key type dns_resolver registered
[    1.219321] mce: Using 10 MCE banks
[    1.220232] RAS: Correctable Errors collector initialized.
[    1.221526] sched_clock: Marking stable (1220210061, 0)->(1545842276, -325632215)
[    1.223554] registered taskstats version 1
[    1.224575] Loading compiled-in X.509 certificates
[    1.227809] Loaded X.509 cert 'Build time autogenerated kernel key: 665cd2b89e03521f57c41865f552ebce30a0c7fb'
[    1.230131] zswap: loaded using pool lzo/zbud
[    1.234063] Key type big_key registered
[    1.235018] Key type trusted registered
[    1.237406] Key type encrypted registered
[    1.238385] AppArmor: AppArmor sha1 policy hashing enabled
[    1.239662] ima: No TPM chip found, activating TPM-bypass! (rc=-19)
[    1.241101] ima: Allocated hash algorithm: sha1
[    1.242205] evm: HMAC attrs: 0x1
[    1.243310]   Magic number: 4:521:515
[    1.244357] rtc_cmos 00:00: setting system clock to 2020-01-22 04:30:05 UTC (1579667405)
[    1.246274] BIOS EDD facility v0.16 2004-Jun-25, 0 devices found
[    1.247521] EDD information not available.
[    1.296990] ata2.00: ATAPI: QEMU DVD-ROM, 2.5+, max UDMA/100
[    1.298854] ata2.00: configured for MWDMA2
[    1.300517] scsi 1:0:0:0: CD-ROM            QEMU     QEMU DVD-ROM     2.5+ PQ: 0 ANSI: 5
[    1.303677] sr 1:0:0:0: [sr0] scsi3-mmc drive: 4x/4x cd/rw xa/form2 tray
[    1.305554] cdrom: Uniform CD-ROM driver Revision: 3.20
[    1.307219] sr 1:0:0:0: Attached scsi generic sg0 type 5
[    1.793458] Freeing unused kernel image memory: 2428K
[    1.816250] Write protecting the kernel read-only data: 20480k
[    1.819296] Freeing unused kernel image memory: 2008K
[    1.820947] Freeing unused kernel image memory: 1884K
[    1.830098] x86/mm: Checked W+X mappings: passed, no W+X pages found.
Loading, please wait...
starting version 237
[    1.897158] input: VirtualPS/2 VMware VMMouse as /devices/platform/i8042/serio1/input/input4
[    1.900284] input: VirtualPS/2 VMware VMMouse as /devices/platform/i8042/serio1/input/input3
[    1.904327]  vda: vda1 vda2
[    1.908512] FDC 0 is a S82078B
[    1.918469] [TTM] Zone  kernel: Available graphics memory: 2019406 kiB
[    1.919980] [TTM] Initializing pool allocator
[    1.921188] AVX version of gcm_enc/dec engaged.
[    1.921820] [TTM] Initializing DMA pool allocator
[    1.922300] AES CTR mode by8 optimization enabled
[    1.926706] [drm] fb mappable at 0xFC000000
[    1.928764] [drm] vram aper at 0xFC000000
[    1.929829] [drm] size 33554432
[    1.930683] [drm] fb depth is 24
[    1.931557] [drm]    pitch is 3072
[    1.933189] fbcon: cirrusdrmfb (fb0) is primary device
[    1.934259] virtio_net virtio0 ens3: renamed from eth0
[    1.949399] Console: switching to colour frame buffer device 128x48
[    1.956345] cirrus 0000:00:02.0: fb0: cirrusdrmfb frame buffer device
[    1.972175] [drm] Initialized cirrus 1.0.0 20110418 for 0000:00:02.0 on minor 0
[    1.973653] piix4_smbus 0000:00:01.3: SMBus Host Controller at 0x700, revision 0
Begin: Loading essential drivers ... [    2.089339] FS-Cache: Loaded
[    2.093276] 9pnet: Installing 9P2000 support
[    2.095722] 9p: Installing v9fs 9p2000 file system support
[    2.096826] FS-Cache: Netfs '9p' registered for caching
[    2.160108] raid6: sse2x1   gen()  7059 MB/s
[    2.208103] raid6: sse2x1   xor()  4694 MB/s
[    2.256099] raid6: sse2x2   gen() 10741 MB/s
[    2.304098] raid6: sse2x2   xor()  7511 MB/s
[    2.352076] raid6: sse2x4   gen() 13048 MB/s
[    2.400033] raid6: sse2x4   xor()  6267 MB/s
[    2.400892] raid6: using algorithm sse2x4 gen() 13048 MB/s
[    2.401982] raid6: .... xor() 6267 MB/s, rmw enabled
[    2.402973] raid6: using ssse3x2 recovery algorithm
[    2.405412] xor: automatically using best checksumming function   avx
[    2.408328] async_tx: api initialized (async)
done.
Begin: Running /scripts/init-premount ... done.
Begin: Mounting root file system ... Begin: Running /scripts/local-top ... done.
Begin: Running /scripts/local-premount ... [    2.457027] Btrfs loaded, crc32c=crc32c-intel
Scanning for Btrfs filesystems
done.
Warning: fsck not present, so skipping root file system
[    2.492691] EXT4-fs (vda2): mounted filesystem with ordered data mode. Opts: (null)
done.
Begin: Running /scripts/local-bottom ... done.
Begin: Running /scripts/init-bottom ... done.
[    2.574887] random: fast init done
[    2.598458] ip_tables: (C) 2000-2006 Netfilter Core Team
[    2.603694] random: systemd: uninitialized urandom read (16 bytes read)
[    2.606357] systemd[1]: systemd 237 running in system mode. (+PAM +AUDIT +SELINUX +IMA +APPARMOR +SMACK +SYSVINIT +UTMP +LIBCRYPTSETUP
+GCRYPT +GNUTLS +ACL +XZ +LZ4 +SECCOMP +BLKID +ELFUTILS +KMOD -IDN2 +IDN -PCRE2 default-hierarchy=hybrid)
[    2.612334] systemd[1]: Detected virtualization kvm.
[    2.614241] systemd[1]: Detected architecture x86-64.
[    2.616208] random: systemd: uninitialized urandom read (16 bytes read)
[    2.618415] random: systemd: uninitialized urandom read (16 bytes read)

Welcome to Ubuntu 18.04.3 LTS!

[    2.623868] systemd[1]: Set hostname to <ubuntu>.
[    2.723048] systemd[1]: Reached target Remote File Systems.
[  OK  ] Reached target Remote File Systems.
[    2.726973] systemd[1]: Created slice User and Session Slice.
[  OK  ] Created slice User and Session Slice.
[    2.729965] systemd[1]: Created slice System Slice.
[  OK  ] Created slice System Slice.
[    2.732676] systemd[1]: Listening on udev Control Socket.
[  OK  ] Listening on udev Control Socket.
[    2.735661] systemd[1]: Created slice system-serial\x2dgetty.slice.
[  OK  ] Created slice system-serial\x2dgetty.slice.
[    2.738621] systemd[1]: Listening on udev Kernel Socket.
[  OK  ] Listening on udev Kernel Socket.
[  OK  ] Listening on Journal Socket.
         Mounting POSIX Message Queue File System...
         Starting Availability of block devices...
         Starting Remount Root and Kernel File Systems...
[  OK  ] Listening on Network Service Netlink Socket.
         Starting udev Coldplug all Devices...
[  OK  ] Set up automount Arbitrary Executab&rmats File System Automount Point.
[  OK  ] Listening on Journal Socket (/dev/log).
[  OK  ] Listening on Device-mapper event daemon FIFOs.
[  OK  ] Reached target Slices.
         Starting Load Kernel Modules...
         Starting Create list of required st&ce nodes for the current kernel...
[  OK  ] Started Forward Password Requests to Wall Directory Watch.
         Mounting Huge Pages File System...
[  OK  ] Listening on /dev/initctl Compatibility Named Pipe.
[  OK  ] Listening on Journal Audit Socket.
[    2.763583] EXT4-fs (vda2): re-mounted. Opts: errors=remount-ro
         Mounting Kernel Debug File System...
[  OK  ] Listening on Syslog Socket.
         Starting Journal Service...
         Starting Set the console keyboard layout...
[  OK  ] Mounted POSIX Message Queue File System.
[  OK  ] Started Availability of block devices.
[    2.775489] Loading iSCSI transport class v2.0-870.
[  OK  ] Started Remount Root and Kernel File Systems.
[  OK  ] Started Create list of required sta&vice nodes for the current kernel.
[  OK  ] Mounted Huge Pages File System.
[  OK  ] Mounted Kernel Debug File System.
         Starting Create Static Device Nodes in /dev...
         Starting Load/Save Random Seed...
         Activating swap /swap.img...
[    2.792415] iscsi: registered transport (tcp)
[  OK  ] Started Create Static Device Nodes in /dev.
         Starting udev Kernel Device Manager...
[  OK  ] Started Load/Save Random Seed.
[  OK  ] Started Journal Service.
         Starting Flush Journal to Persistent Storage...
[  OK  ] Started udev Coldplug all Devices.
[    2.833463] iscsi: registered transport (iser)
[  OK  ] Started Load Kernel Modules.
[  OK  ] Started udev Kernel Device Manager.
         Starting Apply Kernel Variables...
         Mounting FUSE Control File System...
         Mounting Kernel Configuration File System...
[  OK  ] Mounted FUSE Control File System.
[    2.849485] systemd-journald[445]: Received request to flush runtime journal from PID 1
[  OK  ] Mounted Kernel Configuration File System.
[  OK  ] Started Apply Kernel Variables.
[  OK  ] Started Flush Journal to Persistent Storage.
[  OK  ] Started Set the console keyboard layout.
[  OK  ] Started Dispatch Password Requests to Console Directory Watch.
[  OK  ] Reached target Local Encrypted Volumes.
[  OK  ] Reached target Local File Systems (Pre).
[  OK  ] Reached target Local File Systems.
         Starting Tell Plymouth To Write Out Runtime Data...
         Starting Create Volatile Files and Directories...
         Starting Set console font and keymap...
[  OK  ] Activated swap /swap.img.
[  OK  ] Reached target Swap.
[  OK  ] Started Set console font and keymap.
[  OK  ] Started Tell Plymouth To Write Out Runtime Data.
[  OK  ] Started Create Volatile Files and Directories.
         Starting Update UTMP about System Boot/Shutdown...
         Starting Network Time Synchronization...
         Starting Initial cloud-init job (pre-networking)...
[  OK  ] Started Update UTMP about System Boot/Shutdown.
[  OK  ] Found device /dev/ttyS0.
[  OK  ] Started Network Time Synchronization.
[  OK  ] Reached target System Time Synchronized.
[  OK  ] Listening on Load/Save RF Kill Switch Status /dev/rfkill Watch.
[    3.708384] cloud-init[493]: Cloud-init v. 19.4-33-gbb4131a2-0ubuntu1~18.04.1 running 'init-local' at Wed, 22 Jan 2020 04:30:07 +0000.
Up 3.45 seconds.
[  OK  ] Started Initial cloud-init job (pre-networking).
[  OK  ] Reached target Network (Pre).
         Starting Network Service...
[  OK  ] Started Network Service.
         Starting Wait for Network to be Configured...
         Starting Network Name Resolution...
[  OK  ] Started Network Name Resolution.
[  OK  ] Reached target Network.
[  OK  ] Reached target Host and Network Name Lookups.
[  OK  ] Started Wait for Network to be Configured.
         Starting Initial cloud-init job (metadata service crawler)...
[    6.267829] cloud-init[683]: Cloud-init v. 19.4-33-gbb4131a2-0ubuntu1~18.04.1 running 'init' at Wed, 22 Jan 2020 04:30:10 +0000. Up 5.9
4 seconds.
[    6.270042] cloud-init[683]: ci-info: ++++++++++++++++++++++++++++++++++++++Net device info++++++++++++++++++++++++++++++++++++++
[    6.271948] cloud-init[683]: ci-info: +--------+------+----------------------------+---------------+--------+-------------------+
[    6.274051] cloud-init[683]: ci-info: | Device |  Up  |          Address           |      Mask     | Scope  |     Hw-Address    |
[    6.275677] cloud-init[683]: ci-info: +--------+------+----------------------------+---------------+--------+-------------------+
[    6.277684] cloud-init[683]: ci-info: |  ens3  | True |       10.250.99.151        | 255.255.255.0 | global | 52:54:00:97:3f:af |
[    6.279434] cloud-init[683]: ci-info: |  ens3  | True | fe80::5054:ff:fe97:3faf/64 |       .       |  link  | 52:54:00:97:3f:af |
[    6.281238] cloud-init[683]: ci-info: |   lo   | True |         127.0.0.1          |   255.0.0.0   |  host  |         .         |
[    6.283162] cloud-init[683]: ci-info: |   lo   | True |          ::1/128           |       .       |  host  |         .         |
[    6.285067] cloud-init[683]: ci-info: +--------+------+----------------------------+---------------+--------+-------------------+
[    6.287240] cloud-init[683]: ci-info: ++++++++++++++++++++++++++++++Route IPv4 info++++++++++++++++++++++++++++++
[    6.289014] cloud-init[683]: ci-info: +-------+-------------+-------------+-----------------+-----------+-------+
[    6.291035] cloud-init[683]: ci-info: | Route | Destination |   Gateway   |     Genmask     | Interface | Flags |
[    6.293083] cloud-init[683]: ci-info: +-------+-------------+-------------+-----------------+-----------+-------+
[    6.294950] cloud-init[683]: ci-info: |   0   |   0.0.0.0   | 10.250.99.1 |     0.0.0.0     |    ens3   |   UG  |
[    6.296825] cloud-init[683]: ci-info: |   1   | 10.250.99.0 |   0.0.0.0   |  255.255.255.0  |    ens3   |   U   |
[    6.298525] cloud-init[683]: ci-info: |   2   | 10.250.99.1 |   0.0.0.0   | 255.255.255.255 |    ens3   |   UH  |
[    6.300210] cloud-init[683]: ci-info: +-------+-------------+-------------+-----------------+-----------+-------+
[    6.301865] cloud-init[683]: ci-info: +++++++++++++++++++Route IPv6 info+++++++++++++++++++
[    6.303282] cloud-init[683]: ci-info: +-------+-------------+---------+-----------+-------+
[    6.304752] cloud-init[683]: ci-info: | Route | Destination | Gateway | Interface | Flags |
[    6.306272] cloud-init[683]: ci-info: +-------+-------------+---------+-----------+-------+
[    6.307656] cloud-init[683]: ci-info: |   1   |  fe80::/64  |    ::   |    ens3   |   U   |
[    6.309140] cloud-init[683]: ci-info: |   3   |    local    |    ::   |    ens3   |   U   |
[    6.310723] cloud-init[683]: ci-info: |   4   |   ff00::/8  |    ::   |    ens3   |   U   |
[    6.312081] cloud-init[683]: ci-info: +-------+-------------+---------+-----------+-------+
[  OK  ] Started Initial cloud-init job (metadata service crawler).
[  OK  ] Reached target Cloud-config availability.
[  OK  ] Reached target System Initialization.
[  OK  ] Started ACPI Events Check.
[  OK  ] Reached target Paths.
[  OK  ] Started Discard unused blocks once a week.
         Starting LXD - unix socket.
[  OK  ] Listening on UUID daemon activation socket.
[  OK  ] Listening on ACPID Listen Socket.
         Starting Socket activation for snappy daemon.
[  OK  ] Started Daily Cleanup of Temporary Directories.
[  OK  ] Reached target Timers.
[  OK  ] Listening on D-Bus System Message Bus Socket.
[  OK  ] Reached target Network is Online.
[  OK  ] Listening on LXD - unix socket.
[  OK  ] Listening on Socket activation for snappy daemon.
[  OK  ] Reached target Sockets.
[  OK  ] Reached target Basic System.
         Starting Snappy daemon...
         Starting Dispatcher daemon for systemd-networkd...
         Starting Login Service...
[  OK  ] Started Regular background program processing daemon.
[  OK  ] Started D-Bus System Message Bus.
         Starting LSB: Record successful boot for GRUB...
         Starting LSB: automatic crash report generation...
[  OK  ] Started FUSE filesystem for LXC.
         Starting Permit User Sessions...
         Starting System Logging Service...
[  OK  ] Started Deferred execution scheduler.
         Starting OpenBSD Secure Shell server...
         Starting LXD - container startup/shutdown...
[  OK  ] Started Permit User Sessions.
[  OK  ] Started System Logging Service.
[  OK  ] Started Login Service.
         Starting Hostname Service...
         Starting Hold until boot process finishes up...
         Starting Terminate Plymouth Boot Screen...
[  OK  ] Started Hold until boot process finishes up.
         Starting Set console scheme...
[  OK  ] Started Serial Getty on ttyS0.
[  OK  ] Started OpenBSD Secure Shell server.
[  OK  ] Started LSB: Record successful boot for GRUB.
[  OK  ] Started Terminate Plymouth Boot Screen.
[  OK  ] Started Set console scheme.
[  OK  ] Created slice system-getty.slice.
[  OK  ] Started Getty on tty1.
[  OK  ] Reached target Login Prompts.
[  OK  ] Started LSB: automatic crash report generation.
[  OK  ] Started LXD - container startup/shutdown.
[  OK  ] Started Dispatcher daemon for systemd-networkd.
[  OK  ] Started Hostname Service.
[  OK  ] Started Snappy daemon.
         Starting Wait until snapd is fully seeded...
[  OK  ] Started Wait until snapd is fully seeded.
         Starting Apply the settings specified in cloud-config...
[  OK  ] Reached target Multi-User System.
[  OK  ] Reached target Graphical Interface.
         Starting Update UTMP about System Runlevel Changes...
[  OK  ] Started Update UTMP about System Runlevel Changes.
[    7.200510] cloud-init[876]: Cloud-init v. 19.4-33-gbb4131a2-0ubuntu1~18.04.1 running 'modules:config' at Wed, 22 Jan 2020 04:30:11 +00
00. Up 7.03 seconds.
[  OK  ] Started Apply the settings specified in cloud-config.
         Starting Execute cloud user/final scripts...
[    7.793924] cloud-init[932]: Cloud-init v. 19.4-33-gbb4131a2-0ubuntu1~18.04.1 running 'modules:final' at Wed, 22 Jan 2020 04:30:11 +000
0. Up 7.62 seconds.
[    7.796441] cloud-init[932]: The system is finally up! Enjoy!
[  OK  ] Started Execute cloud user/final scripts.
[  OK  ] Reached target Cloud-init target.

Ubuntu 18.04.3 LTS ubuntu ttyS0

ubuntu login:
--------

And, thats it. I can log as "rafaeldtinoco" with no password.

This marks the end of the group of README files. I hope you enjoy it.

Rafael D. Tinoco
rafaeldtinoco@ubuntu.com
