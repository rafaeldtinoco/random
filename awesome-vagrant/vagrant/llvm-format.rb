# -*- mode: ruby -*-

$llvm12_format_url = "https://github.com/muttleyxd/clang-tools-static-binaries/releases/download/master-f4f85437/clang-format-12.0.1_linux-amd64"
$llvm12_format_filename = $llvm12_format_url.split("/")[-1]

def install_llvm_format_12(config)
  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    # Download and install LLVM Format 12
    if [[ ! -f /cache/#{$llvm12_format_filename} ]]; then
      curl -L -o /cache/#{$llvm12_format_filename} #{$llvm12_format_url}
    fi

    # Remove old binary
    rm -f /usr/bin/clang-format-12

    # Create new binary
    cp /cache/#{$llvm12_format_filename} /usr/bin/clang-format-12
    chmod 755 /usr/bin/clang-format-12
  SHELL
end
