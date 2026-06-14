# -*- mode: ruby -*-

$ubuntu_mirror = "http://archive.ubuntu.com/ubuntu/"

Vagrant.configure("2") do |config|

  # Configure VM and OS defaults
  require_relative "default-vm"
  load_default_vm(config, "ubuntu/" + DISTRO + "64")

  #
  # Configure Ubuntu Linux
  #

  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    echo """
    deb #{$ubuntu_mirror} #{DISTRO} main restricted universe multiverse
    deb #{$ubuntu_mirror} #{DISTRO}-updates main restricted universe multiverse
    deb-src #{$ubuntu_mirror} #{DISTRO} main restricted universe multiverse
    deb-src #{$ubuntu_mirror} #{DISTRO}-updates main restricted universe multiverse
    """ > /etc/apt/sources.list
  SHELL

  config.vm.provision "shell", run: "always", privileged: true, inline: <<-SHELL
    export DEBIAN_FRONTEND=noninteractive
    apt-get update
    apt-get dist-upgrade -y
    apt-get install -y \
      lsb-release \
      ca-certificates \
      curl \
      wget \
      git \
      gnupg \
      bat \
      build-essential \
      automake \
      autoconf \
      pkg-config \
      libelf-dev \
      zlib1g-dev \
      libssl-dev
    # not available on all versions
    apt-get install -y exa || true
  SHELL

  # Install LLVM 14
  require_relative "llvm"
  install_llvm_14(config)

  # Install LLVM Format 12
  require_relative("llvm-format")
  install_llvm_format_12(config)

  # Install Golang 1.20
  require_relative "golang"
  install_go_120(config)

  # Install Golang Tools
  require_relative "golang"
  install_go_tools(config)

  # Install OPA 0.56
  require_relative "opa"
  install_opa_056(config)

  # Modify OS Files
  require_relative "os-files"
  modify_os_files(config)

  # Install User Files
  require_relative "user-files"
  load_user_files(config)

  # Shares
  require_relative "shares"
  configure_shares(config)

  # Reboot
  config.vm.provision :reload
end
