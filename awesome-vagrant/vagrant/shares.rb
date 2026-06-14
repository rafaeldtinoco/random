# -*- mode: ruby -*-

def configure_shares(config)
  # Disable default share
  config.vm.synced_folder ".", "/vagrant", disabled: true

  # Cache directory (must exist)
  config.vm.synced_folder "../../cache", "/cache", owner:"vagrant", group:"vagrant"

  # Work directory (if exists)
  work_dir = "#{ENV['HOME']}/work"
  if File.directory?(work_dir)
    config.vm.synced_folder work_dir, "/home/vagrant/work", owner:"vagrant", group:"vagrant"
  end
end
