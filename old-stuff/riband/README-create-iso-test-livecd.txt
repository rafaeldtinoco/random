PREVIOUS: README-create-iso-test-vm.txt

*** Make sure to read "PREVIOUS" README file before moving on! ***

[ Creating a livecd QEMU/KVM guest ]

Now, just like you created a simple "vanilla" virtual machine, containing an
Ubuntu installed guest, you will create a "livecd" only VM and then a
"livecdinstall" VM.

First, the "livecd" only VM:

--------

$ ./kvm.sh -c 4 -m 4 -n livecd -i livecd -k \
   -o /home/rafaeldtinoco/example/riband/liveboot/ubuntu-livecd.iso

info: logs at /tmp/kvm.log
option: vcpus=4
option: ramgb=4
option: hostname=livecd
option: libvirt=libvirt/livecd.xml
option: noqcow2create
option: noinstall
option: cdromvol=/home/rafaeldtinoco/example/riband/liveboot/ubuntu-livecd.iso
...
mark: creating vm
mark: kvm profiles sanity checks
mark: meta-data and user-data
mark: cleaning things up
finish: cleaning up leftovers
mark: starting virtual machine livecd
note: don't forget to wait cloud-init to finish
note: cloud-init will reboot virtual machine 1 time

--------

Note that we used "-i livecd", to use libvirt/livecd.xml as a libvirt domain xml
base for our VM, but we haven't used "-t <cloudinit>", as we only have "default
.yaml" file, being the default, AND, for a "livecd" only VM, a cloud-init yaml
configuration file won't be needed.

That explains also why we used "-k" (noinstall) option, as the "livecd" template
does not have a local disk, as you can see bellow, in the XML dump from "livecd"
virtual machine.

--------

$ virsh dumpxml livecd
<domain type='kvm' id='63'>
  <name>livecd</name>
  <uuid>afc81461-c46c-4564-981e-9b6b9c305828</uuid>
  <memory unit='KiB'>4194304</memory>
  <currentMemory unit='KiB'>4194304</currentMemory>
  <vcpu placement='static'>4</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch='x86_64' machine='pc-i440fx-4.0'>hvm</type>
    <boot dev='cdrom'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='host-passthrough' check='none'/>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='yes'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='.../devel/example/riband/liveboot/ubuntu-livecd.iso'/>
      <backingStore/>
      <target dev='hdc' bus='ide'/>
      <readonly/>
      <alias name='ide0-1-0'/>
    </disk>
    <controller type='usb' index='0' model='piix3-uhci'>
      <alias name='usb'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'>
      <alias name='pci.0'/>
    </controller>
    <controller type='ide' index='0'>
      <alias name='ide'/>
    </controller>
    <interface type='network'>
      <mac address='52:54:00:d8:59:ef'/>
      <source network='default' bridge='virbr0'/>
      <target dev='vnet1'/>
      <model type='virtio'/>
      <alias name='net0'/>
    </interface>
    <serial type='pty'>
      <source path='/dev/pts/7'/>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/7'>
      <source path='/dev/pts/7'/>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/7'>
      <source path='/dev/pts/7'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <input type='mouse' bus='ps2'>
      <alias name='input0'/>
    </input>
    <input type='keyboard' bus='ps2'>
      <alias name='input1'/>
    </input>
    <graphics type='vnc' port='5900' autoport='yes' listen='127.0.0.1' keymap='en-us'>
      <listen type='address' address='127.0.0.1'/>
    </graphics>
    <video>
      <model type='cirrus' vram='16384' heads='1' primary='yes'/>
      <alias name='video0'/>
    </video>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
    </memballoon>
  </devices>
  <seclabel type='dynamic' model='dac' relabel='yes'>
    <label>+0:+0</label>
    <imagelabel>+0:+0</imagelabel>
  </seclabel>
</domain>

--------

Obviously we need an ISO to make a good use of the virtual machine created
above, and we will do that in the NEXT "README" file. For now, its important
to get to know how to create these virtual machines. They will be important
to develop the "create-iso" tool by making modifications you judge important for
your use case.

Bellow, just like the first example, we are going to create another "livecd"
virtual machine, but this one will contain a local disk "vda" (using virtio
driver) and that is why its libvirt XML domain file is called "livecdguest": it
will allow you to use a LIVE ISO image to test installation on a local disk.
More than the previous example, this one is certainly needed to test any
modifications done in "create-iso" tool (to be explained in next README file).

--------

$ ./kvm.sh -c 4 -m 4 -n livecdinstall -i livecdinstall -k \
  -o  /home/rafaeldtinoco/devel/example/riband/liveboot/ubuntu-livecd.iso

info: logs at /tmp/kvm.log
option: vcpus=4
option: ramgb=4
option: hostname=livecdinstall
option: libvirt=libvirt/livecdinstall.xml
option: noinstall
option: cdromvol=/home/rafaeldtinoco/devel/example/riband/liveboot/ubuntu-livecd.iso
...
mark: qcow2 image
mark: creating vm
mark: kvm profiles sanity checks
mark: meta-data and user-data
mark: cleaning things up
finish: cleaning up leftovers
mark: starting virtual machine livecdinstall
note: don't forget to wait cloud-init to finish
note: cloud-init will reboot virtual machine 1 time

--------

Bellow you can see how the machine domain is declared:

--------

$ virsh dump-xml livecdinstall
<domain type='kvm' id='64'>
  <name>livecdinstall</name>
  <uuid>44741456-eb80-48e3-9ab3-c33a5aaf84e1</uuid>
  <memory unit='KiB'>4194304</memory>
  <currentMemory unit='KiB'>4194304</currentMemory>
  <vcpu placement='static'>4</vcpu>
  <resource>
    <partition>/machine</partition>
  </resource>
  <os>
    <type arch='x86_64' machine='pc-i440fx-4.0'>hvm</type>
    <boot dev='cdrom'/>
    <boot dev='hd'/>
  </os>
  <features>
    <acpi/>
    <apic/>
  </features>
  <cpu mode='host-passthrough' check='none'/>
  <clock offset='utc'>
    <timer name='rtc' tickpolicy='catchup'/>
    <timer name='pit' tickpolicy='delay'/>
    <timer name='hpet' present='yes'/>
  </clock>
  <on_poweroff>destroy</on_poweroff>
  <on_reboot>restart</on_reboot>
  <on_crash>restart</on_crash>
  <pm>
    <suspend-to-mem enabled='no'/>
    <suspend-to-disk enabled='no'/>
  </pm>
  <devices>
    <emulator>/usr/bin/qemu-system-x86_64</emulator>
    <disk type='file' device='disk'>
      <driver name='qemu' type='qcow2'/>
      <source file='/var/lib/libvirt/images/livecdinstall-disk01.qcow2'/>
      <backingStore/>
      <target dev='vda' bus='virtio'/>
      <alias name='virtio-disk0'/>
    </disk>
    <disk type='file' device='cdrom'>
      <driver name='qemu' type='raw'/>
      <source file='.../devel/example/riband/liveboot/ubuntu-livecd.iso'/>
      <backingStore/>
      <target dev='hdc' bus='ide'/>
      <readonly/>
      <alias name='ide0-1-0'/>
    </disk>
    <controller type='usb' index='0' model='piix3-uhci'>
      <alias name='usb'/>
    </controller>
    <controller type='pci' index='0' model='pci-root'>
      <alias name='pci.0'/>
    </controller>
    <controller type='ide' index='0'>
      <alias name='ide'/>
    </controller>
    <interface type='network'>
      <mac address='52:54:00:97:3f:af'/>
      <source network='default' bridge='virbr0'/>
      <target dev='vnet2'/>
      <model type='virtio'/>
      <alias name='net0'/>
    </interface>
    <serial type='pty'>
      <source path='/dev/pts/8'/>
      <target type='isa-serial' port='0'>
        <model name='isa-serial'/>
      </target>
      <alias name='serial0'/>
    </serial>
    <console type='pty' tty='/dev/pts/8'>
      <source path='/dev/pts/8'/>
      <target type='serial' port='0'/>
      <alias name='serial0'/>
    </console>
    <input type='mouse' bus='ps2'>
      <alias name='input0'/>
    </input>
    <input type='keyboard' bus='ps2'>
      <alias name='input1'/>
    </input>
    <graphics type='vnc' port='5902' autoport='yes' listen='127.0.0.1' keymap='en-us'>
      <listen type='address' address='127.0.0.1'/>
    </graphics>
    <video>
      <model type='cirrus' vram='16384' heads='1' primary='yes'/>
      <alias name='video0'/>
    </video>
    <memballoon model='virtio'>
      <alias name='balloon0'/>
    </memballoon>
  </devices>
  <seclabel type='dynamic' model='dac' relabel='yes'>
    <label>+0:+0</label>
    <imagelabel>+0:+0</imagelabel>
  </seclabel>
</domain>

--------

INFO: In all examples showed in the README files, I have "cloned" the git
repository in the following directory path: /home/rafaeldtinoco/example/. This
is important because the tool "create-iso" will create an ISO in the default
location: /home/rafaeldtinoco/example/riband/liveboot/ubuntu-livecd.iso. That
explains why I'm telling the "kvm.sh" script to use ISO from that path, right
after creating the ISO with another tool, I'm able to spin up a virtual machine
and test the ISO installation.

NEXT: README-create-iso-test-livecd.txt
