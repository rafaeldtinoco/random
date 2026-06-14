# -*- mode: ruby -*-

def modify_os_files(config)
  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    if [[ -f /etc/pam.d/login ]]; then
      sed -i '/pam_motd\.so/ s/^/#/' /etc/pam.d/login
      sed -i '/pam_mail\.so/ s/^/#/' /etc/pam.d/login
      sed -i '/pam_lastlog\.so/ s/^/#/' /etc/pam.d/login
    fi
    if [[ -f /etc/pam.d/sshd ]]; then
      sed -i '/pam_motd\.so/ s/^/#/' /etc/pam.d/sshd
      sed -i '/pam_mail\.so/ s/^/#/' /etc/pam.d/sshd
    fi
  SHELL
end
