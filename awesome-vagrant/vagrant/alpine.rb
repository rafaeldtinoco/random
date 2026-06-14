# -*- mode: ruby -*-

Vagrant.configure("2") do |config|

  # Configure VM and OS defaults
  require_relative "default-vm"
  load_default_vm(config, "generic/" + DISTRO)

  # Configure Alpine Linux
  config.vm.provision "shell", run: "always", privileged: true, inline: <<-SHELL
    apk --no-cache update
    apk --no-cache add \
      sudo \
      coreutils \
      findutils \
      bash \
      bash-completion \
      man-pages \
      git \
      curl \
      wget \
      rsync \
      musl-dev \
      libc6-compat \
      make \
      gcc \
      linux-headers \
      elfutils-dev \
      libelf \
      zlib \
      vim \
      iproute2 \
      vlan \
      bridge-utils \
      net-tools \
      netcat-openbsd \
      iputils
    # not available on all versions
    apk --no-cache add gcompat || true
  SHELL

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
