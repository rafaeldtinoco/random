# -*- mode: ruby -*-

def load_default_vm(config, box)
  config.vm.hostname = DISTRO
  config.vm.box = box
  config.vm.box_check_update = true
  config.vm.provider :virtualbox do |v|
    v.memory = 4096
    v.cpus = 4
  end
end
