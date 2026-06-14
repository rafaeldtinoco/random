# -*- mode: ruby -*-

$llvm14_url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-14.0.6/clang+llvm-14.0.6-x86_64-linux-gnu-rhel-8.4.tar.xz"
$llvm14_filename = $llvm14_url.split("/")[-1]
$llvm14_dirname = $llvm14_filename.split(".tar.xz")[0]

def install_llvm_14(config)
  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    # Download and install LLVM 14
    if [[ ! -f /cache/#{$llvm14_filename} ]]; then
      curl -L -o /cache/#{$llvm14_filename} #{$llvm14_url}
    fi
    tar -C /usr/local -xJf /cache/#{$llvm14_filename}
    mv "/usr/local/#{$llvm14_dirname}" /usr/local/clang

    # Remove old symlinks
    rm -f /usr/bin/cc
    rm -f /usr/bin/clang
    rm -f /usr/bin/clang++
    rm -f /usr/bin/llc
    rm -f /usr/bin/lld
    rm -f /usr/bin/clangd
    rm -f /usr/bin/clang-format
    rm -f /usr/bin/llvm-strip
    rm -f /usr/bin/llvm-config
    rm -f /usr/bin/ld.lld
    rm -f /usr/bin/llvm-ar
    rm -f /usr/bin/llvm-nm
    rm -f /usr/bin/llvm-objcopy
    rm -f /usr/bin/llvm-objdump
    rm -f /usr/bin/llvm-readelf
    rm -f /usr/bin/opt

    # Create new symlinks
    ln -s /usr/local/clang/bin/clang /usr/bin/clang
    ln -s /usr/local/clang/bin/clang++ /usr/bin/clang++
    ln -s /usr/local/clang/bin/clangd /usr/bin/clangd
    ln -s /usr/local/clang/bin/clang-format /usr/bin/clang-format
    ln -s /usr/local/clang/bin/lld /usr/bin/lld
    ln -s /usr/local/clang/bin/llc /usr/bin/llc
    ln -s /usr/local/clang/bin/llvm-strip /usr/bin/llvm-strip
    ln -s /usr/local/clang/bin/llvm-config /usr/bin/llvm-config
    ln -s /usr/local/clang/bin/ld.lld /usr/bin/ld.lld
    ln -s /usr/local/clang/bin/llvm-ar /usr/bin/llvm-ar
    ln -s /usr/local/clang/bin/llvm-nm /usr/bin/llvm-nm
    ln -s /usr/local/clang/bin/llvm-objcopy /usr/bin/llvm-objcopy
    ln -s /usr/local/clang/bin/llvm-objdump /usr/bin/llvm-objdump
    ln -s /usr/local/clang/bin/llvm-readelf /usr/bin/llvm-readelf
    ln -s /usr/local/clang/bin/opt /usr/bin/opt
  SHELL
end
