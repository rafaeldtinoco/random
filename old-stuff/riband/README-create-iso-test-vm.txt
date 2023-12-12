PREVIOUS: README-practice.txt

Riband: create-iso-test-vm

This tool creates QEMU/KVM machines in general. For Riband, main idea is that
this tool is capable of creating virtual machines to test the generated LIVE
CDROM ISO images. It can also create virtual machines capable of TESTING the
installation done by the LIVE CDROM ISO images CURTIN software, contained
in the LIVE images.

[ Creating a regular QEMU/KVM guest ]

In order to use "create-iso-test-vm" scripts you have to make sure to install
all QEMU and libvirt related packages:

--------

$ dpkg -l | egrep "(qemu|libvirt)" | awk '{print $2}' | xargs
ipxe-qemu ipxe-qemu-256k-compat-efi-roms libnss-libvirt:amd64 libvirt-clients
libvirt-daemon libvirt-daemon-driver-storage-rbd libvirt-daemon-system
libvirt-glib-1.0-0:amd64 libvirt0:amd64 python3-libvirt qemu-block-extra:amd64
qemu-kvm qemu-system-common qemu-system-data qemu-system-gui qemu-system-x86
qemu-utils

--------

TIP: A good tip is to have libnss-libvirt package installed and configure your
/etc/nsswitch.conf file to:

--------

...
hosts:    files libvirt_guest libvirt dns

--------

This will make a DNS resolution attempt with the name of a virtual machine to
be resolved as if it was a FQDN for the VM's IP (libvirt_guest). It will also
make the VM's hostname to be resolved as a FQDN IF there is no VMs with the same
name (libvirt).

After making sure your Linux environment is ready for virtualization, make sure
you have a pool named "default", pointing to "/var/lib/libvirt/images" directory
AND a network also named "default", with a range of IPs and configuring NAT for
the VMs having NICs on that network.

--------

$ cat default.pool
<pool type='dir'>
  <name>default</name>
  <uuid>76e49a63-faf8-4cb1-b038-b3da2053c227</uuid>
  <source>
  </source>
  <target>
    <path>/var/lib/libvirt/images</path>
    <permissions>
      <mode>0711</mode>
      <owner>0</owner>
      <group>0</group>
    </permissions>
  </target>
</pool>

$ virsh define pool-define ./default.pool
Pool default defined from ./default.pool

--------

--------

$ cat default.xml
<network>
  <name>default</name>
  <forward mode='nat'/>
  <bridge name='virbr0' stp='on' delay='0'/>
  <ip address='10.250.99.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='10.250.99.10' end='10.250.99.254'/>
    </dhcp>
  </ip>
</network>

$ virsh net-define ./default.xml
Network default defined from ./default.xml

$ virsh net-autostart --network default
Network default marked as autostarted

$ virsh net-start default
Network default started

--------

After this initial adjustment you're ready to create your first VM using this
tool. The first VM will be a basic VM with an installed Ubuntu.

--------

rafaeldtinoco@workstation:~/.../create-iso-test-vm$ ./kvm.sh -h
info: logs at /tmp/kvm.log

syntax: ./kvm.sh [options]

options:
        -c <#.cpus>             - number of cpus
        -m <mem.GB>             - memory size
        -n <vm.name>            - virtual machine name
        -t <cloudinit>          - default/devel (check cloud-init/*.yaml files)
        -i <libvirt>            - vanilla/numa/... (check libvirt/*.xmlfiles)
        -d <ubuntu.codename>    - xenial/bionic/disco/eoan/focal (default: stable)
        -u <username>           - as 1000:1000 in the installed vm (default: ubuntu)
        -l <launchpad_id>       - for the ssh key import (default: rafaeldtinoco)
        -r <repo.url>           - url for the ubuntu mirror (default: us.archive)
        -o <isofile>            - file containing iso image to be used as cdrom
        -k                      - do not attempt to install anything (livecd cases)
        -q                      - do not attempt to create qcow2 volumes (livecd cases)

--------

The create-iso-test-vm tool options can be seen using the "-h" argument. The
idea here is to create a VM and customize this VM using the command line
arguments.

Some less obvious arguments can be better explained here:

    -t <cloudinit> = This is the file name of a file inside "cloud-init/"
    directory. This file will contain all cloud-init configuration/options you
    would like to run after the guest is provisioned. For this case, there is
    only one: default.yaml.

    -i <libvirt> = This is the file name of a file inside the "libvirt/"
    directory. This XML file is the "heart" of the VM to be created: it
    describes the virtual machine in details libvirt is capable of understand.
    There are 2 types to be used for regular machines: "vanilla.xml" and "numa
    .xml". There are other 2 types to be used for live image tests and
    development: "livecd.xml" (without a local disk, only a single ISO being
    booted) and "liveinstall.xml" (contains a local disk and is booted from the
    ISO given as an argument to kvm.sh).

    -d <ubuntu.codename> = This specifies the Ubuntu version to be installed if
    the VM being created is either "vanilla.xml" or "numa.xml".

    -u <username> = This is the default username (uid:1000/gid:1000) to be
    created in the installed OS.

    -l <launchpad_id> = Since you can choose to either embed your ssh key inside
     the cloud-init file, or just instruct cloud-init to import the ssh key
     using the network during the first boot, this option tells cloud-init which
     launchpad_id to use in the second case. For the first case you can change
     default.yaml file for your own ssh key to be provisioned.

     -r <repo.url> = http//archive.ubuntu.com/ubuntu is the most simple option
     you can have here. Pick a better mirror if that suites you.

     -o <isofile> = In case you're provisioning a "livecd.xml" and/or
     "livecdinstall.xml" type VM, you can tell which ISO file to use for it.

     -k = In case you're provisioning the "live" VMs, you must tell the tool not
      to install anything

     -q = In case you're installing a "livecd.xml" VM, you don't have to create
     a backing qcow2 file as its main disk.

Enough written, let's check a quick example where we provision a simple
"vanilla.xml" machine with Ubuntu Eoan:

--------

$ ./kvm.sh -c 4 -m 4 -n myname -t default -i vanilla -d eoan -u rafaeldtinoco \
 -l rafaeldtinoco -r http://us.archive.ubuntu.com/ubuntu/

info: logs at /tmp/kvm.log
option: vcpus=4
option: ramgb=4
option: hostname=myname
option: cloudinit=cloud-init/default.yaml
option: libvirt=libvirt/vanilla.xml
option: distro=eoan
option: username=rafaeldtinoco
option: launchpad_id=rafaeldtinoco
option: repository=http://us.archive.ubuntu.com/ubuntu/
...
mark: qcow2 image
mark: nbd connecting qcow2 image
mark: disk formatting
mark: vfat partition
mark: ext4 partition
mark: debootstraping
mark: mount {procfs,sysfs,devfs}
mark: setting hostname
mark: adjusting accounts
mark: /etc/fstab
mark: /etc/network/interfaces
mark: /etc/modules
mark: /etc/default/grub
mark: /etc/apt/sources.list
mark: update and upgrade
mark: grub setup
mark: creating vm
mark: kvm profiles sanity checks
mark: meta-data and user-data
mark: adjust user-data
mark: cleaning things up
finish: cleaning up leftovers
mark: starting virtual machine myname
note: don't forget to wait cloud-init to finish
note: cloud-init will reboot virtual machine 1 time

rafaeldtinoco@workstation:~$ virsh list --name
myname
--------

After the machine is created, remember that cloud-init will execute everything
that is set in the cloud-init/XXX.yaml file you've chosen (default.yaml in this
case).

It is always good to connect to the virtual machine and check cloud-init status
before starting to work:

--------
rafaeldtinoco@workstation:~$ ssh myname
Warning: Permanently added 'myname' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 19.10 (GNU/Linux 5.3.0-29-generic x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

/usr/bin/xauth:  file /home/rafaeldtinoco/.Xauthority does not exist
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

rafaeldtinoco@myname:~$ cloud-init status
status: done
--------

Perfect. That is all for this README file.

NEXT: README-create-iso-test-livecd.txt
