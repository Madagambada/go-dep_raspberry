#!/bin/bash
if (( $EUID != 0 )); then
    echo "Please run as root"
    exit
fi
git clone https://github.com/tgogos/rpi_golang.git  
cd rpi_golang/  
mkdir -p $HOME/go1.4
tar -xzf go1.4.3.linux-armv7.tar.gz -C $HOME/go1.4 --strip-components=1
wget https://dl.google.com/go/go1.12.4.src.tar.gz
tar -xz -C /usr/local -f go1.12.4.src.tar.gz
cd /usr/local/go/src
time GOROOT_BOOTSTRAP=$HOME/go1.4 ./make.bash
go version
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.bashrc
echo "export GOPATH=$HOME/go" >> ~/.bashrc
echo "export PATH=$PATH:$GOPATH/bin" >> ~/.bashrc
source ~/.bashrc
go get -u github.com/golang/dep/cmd/dep