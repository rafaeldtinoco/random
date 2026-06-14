# -*- mode: ruby -*-

$go120_url = "https://go.dev/dl/go1.20.8.linux-amd64.tar.gz"
$go120_filename = $go120_url.split("/")[-1]

def install_go_120(config)
  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    export GOROOT=/usr/local/go
    export GOPATH=/home/vagrant/go

    # Download and install Go 1.20.8
    if [[ ! -f /cache/#{$go120_filename} ]]; then
      curl -L -o /cache/#{$go120_filename} #{$go120_url}
    fi
    tar -C /usr/local -xzf /cache/#{$go120_filename}

    # Remove old symlinks
    rm -f /usr/bin/go
    rm -f /usr/bin/gofmt

    # Create new symlinks
    ln -s /usr/local/go/bin/go /usr/bin/go
    ln -s /usr/local/go/bin/gofmt /usr/bin/gofmt
  SHELL
end

def install_go_tools(config)
  config.vm.provision "shell", privileged: true, inline: <<-SHELL
    export GOROOT=/usr/local/go
    export GOPATH=/home/vagrant/go

    # Download Go tools
    go install honnef.co/go/tools/cmd/staticcheck@latest
    go install github.com/mgechev/revive@latest
    go install github.com/incu6us/goimports-reviser/v3@latest
    go install github.com/kisielk/errcheck@latest

    # clean

    cp $GOPATH/bin/* /usr/bin/
    rm -rf $GOPATH
  SHELL
end
