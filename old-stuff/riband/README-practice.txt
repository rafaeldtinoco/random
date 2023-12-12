PREVIOUS: README.txt

Riband: practice instructions

This exercise is driven to those migrating from debian-installer (d-i) to curtin
and looking for an easy way to test different curtin/cloud-init configuration
options in order to achieve the same results for an installed server as previous
d-i config options did.

[ Cloning source code ]

rafaeldtinoco@work:~$ git clone https://github.com/rafaeldtinoco/riband.git
Cloning into 'riband'...
remote: Enumerating objects: 26, done.
remote: Counting objects: 100% (26/26), done.
remote: Compressing objects: 100% (19/19), done.
remote: Total 26 (delta 8), reused 18 (delta 5), pack-reused 0
Unpacking objects: 100% (26/26), done.

[ Description ]

The debootstrap.sh script will create, using an already existing qemu
installation, 2 virtual machines: "riband" and "testme".

  1. riband: this virtual machine will be simulating the riband installer (iso,
  for example). It contains 2 files: "curtin.yaml" and "user-data.yaml". Those
  files are used, respectively, by curtin and cloud-init.

  2. testme: this virtual machine is the result of riband curtin's execution. It
  simulates the installed machine.

  Note: riband 2nd disk is the boot disk for testme virtual machine.

The idea of this environment is to allow one to customize "curtin.yaml" file
according to its documentation, and setup a second machine (testme in this case)
based on this customization.

Note: For this "practice exercise", curtin is getting an Ubuntu Cloud Image from
the web and deploying to a second disk in the riband virtual machine.

Right after curtin finishes the disk installation, it is possible to shutdown
riband virtual machine, boot testme virtual machine and see cloud-init doing its
final customization work (based on the user-data file generated as metadata in
an installed disk partition).

Note: parts of this final customization work currently requires that the
installed machine is connected, but that is NOT mandatory. It depends what
user-data.yaml describes.

[ Near future ]

Riband ISO generation feature will allow for Ubuntu Cloud Images to be contained
inside the ISO image during its generation. Tracing a parallel, it is like
riband VM is a Live Ubuntu Installer, executing curtin and provisioning the
server where the ISO was booted. After the CDROM removal, and the initial
installed machine boot, cloud-init executes procedures from its user-data file.

[ Instructions ]

Create both virtual machines:

--------
rafaeldtinoco@work:~/riband/practice$ ./debootstrap.sh
I: Target architecture can be executed
I: Retrieving InRelease
I: Checking Release signature
I: Valid Release signature (key id ...)
I: Retrieving Packages
I: Validating Packages
I: Resolving dependencies of required packages...
I: Resolving dependencies of base packages...
...
0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
Reading package lists... Done
Building dependency tree
Reading state information... Done
2019-11-28 18:53:25,330 INFO Authorized key ['2048', ...
2019-11-28 18:53:25,331 INFO [1] SSH keys [Authorized]
finish: cleaning up leftovers
--------

Make sure they exist:

--------
...@work:~/riband/practice$ virsh list --all --name | egrep "(riband|testme)"
riband
testme
--------

Start the riband virtual machine:

--------
rafaeldtinoco@work:~/riband/practice$ virsh start --console riband
Domain riband started
Connected to domain riband
Escape character is ^]
[    0.000000] Linux version 4.15.0-72-generic ...
[    0.000000] Command line: root=/dev/vda ...
[    0.000000]   Intel GenuineIntel
...
riband login: ubuntu
Welcome to Ubuntu 18.04.3 LTS (GNU/Linux 4.15.0-72-generic x86_64)
...
ubuntu@riband:~$
--------

Play with curtin.yaml and user-data.yaml files until you're satisfied.

You don't have to destroy or shutdown the riband vm everytime you want to
install the testme vm. You can run "curtin install" multiple times to test if
the configuration files are doing what you want.

--------
ubuntu@riband:~$ ls
curtin.yaml  user-data.yaml
--------

You can also use riband cloud-init package to verify if the user-data file
you're creating, for cloud-init initial customization of the installed server,
is valid:

--------
ubuntu@riband:~$ sudo cloud-init devel schema -c user-data.yaml
Valid cloud-config file user-data.yaml
before trying to move on.
--------

Execute curtin install to install testme vm:

--------
ubuntu@riband:~$ sudo curtin install -c ./curtin.yaml
curtin: Installation started. (19.1-7-g37a7a0f4-0ubuntu1~18.04.1)
Hit:1 http://br.archive.ubuntu.com/ubuntu bionic InRelease
Get:2 http://br.archive.ubuntu.com/ubuntu bionic-updates InRelease [88.7 kB]
Hit:3 http://br.archive.ubuntu.com/ubuntu bionic-proposed InRelease
...
Processing triggers for systemd (237-3ubuntu10.31) ...
Processing triggers for ureadahead (0.100.0-21) ...
{instance-id: f34cac24-f946-4bd9-83b4-c9eebd3293c4}
curtin: Installation finished.

ubuntu@riband:~$ sudo shutdown -h now
--------

After shutting down riband vm, you're free to start testme vm and check the
remaining customizations about to be done by cloud-init user-data file you
modified:

--------
rafaeldtinoco@work:~/riband/practice$ virsh start --console testme
Domain testme started
Connected to domain testme
Escape character is ^]
[    0.000000] Linux version 4.15.0-72-generic (buildd@lcy01-amd64-026) ...
[    0.000000] Command line: BOOT_IMAGE=/boot/vmlinuz-4.15.0-72-generic ...
[    0.000000] KERNEL supported cpus:
[    0.000000]   Intel GenuineIntel
[    0.000000]   AMD AuthenticAMD
...
<reboots because of cloud-init>
...
[    8.310766] cloud-init[851]: The system is finally up! Enjoy!
[  OK  ] Started Execute cloud user/final scripts.
[  OK  ] Reached target Cloud-init target.

Ubuntu 18.04.3 LTS ubuntu ttyS0

ubuntu login: ubuntu
...
ubuntu@ubuntu:~$
--------

You'll know cloud-init has finished when you read the "The system is finally
up!" message (configurable also). At this point you're free to either shutdown
testme virtual machine and start riband virtual machine again, to modify the
files, or to run everything from the deboostrap phase, by removing what was done
so far:

--------
rafaeldtinoco@work:~$ virsh shutdown testme ; virsh undefine testme
Domain testme has been undefined

rafaeldtinoco@work:~$ virsh undefine riband
Domain riband has been undefined

rafaeldtinoco@work:~$ sudo rm -rf /var/lib/libvirt/images/testme
--------

Please remember: if you've changed 'curtin.yaml' and 'user-data.yaml' files
inside riband, make sure to save those files elsewhere before destroying created
environment.

Have fun!

NEXT: README-create-iso-test-vm.txt