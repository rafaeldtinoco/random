# -*- mode: ruby -*-

def load_user_files(config)
  always_files = {
    "~/.ssh/config" => "~/.ssh/config",
    "~/.gitconfig" => "~/.gitconfig",
    "~/.gitignore" => "~/.gitignore",
    "~/.bashrc" => "~/.bashrc",
    "~/.bash_history" => "~/.bash_history",
    "~/.vimrc" => "~/.vimrc"
  }

  once_files = {
    "~/.ssh/id_rsa" => "~/.ssh/id_rsa",
    "~/.ssh/id_rsa.pub" => "~/.ssh/id_rsa.pub",
  }

  always_files.each do |src, dest|
    full_src_path = File.expand_path(src)
    if File.exist?(full_src_path)
      config.vm.provision :file, run: "always", source: full_src_path, destination: dest
    end
  end

  once_files.each do |src, dest|
    full_src_path = File.expand_path(src)
    if File.exist?(full_src_path)
      config.vm.provision :file, source: full_src_path, destination: dest
    end
  end

  config.vm.provision :shell, privileged: false, inline: "cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys"
end
