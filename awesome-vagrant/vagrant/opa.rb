# -*- mode: ruby -*-

$opa_url = "https://github.com/open-policy-agent/opa/releases/download/v0.56.0/opa_linux_amd64_static"
$opa_filename = $opa_url.split("/")[-1]

def install_opa_056(config)
  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    # Download and install OPA 0.56
    if [[ ! -f /cache/#{$opa_filename} ]]; then
      curl -L -o /cache/#{$opa_filename} #{$opa_url}
    fi

    # Remove old binary
    rm -f /usr/bin/opa

    # Create new binary
    cp /cache/#{$opa_filename} /usr/bin/opa
    chmod 755 /usr/bin/opa
  SHELL
end
