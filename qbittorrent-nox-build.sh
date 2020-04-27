#!/bin/bash

#update and install packages 
echo "check & install build dependencies"
sudo apt-get update && sudo apt-get install curl qtbase5-dev qttools5-dev-tools libqt5svg5-dev python3 curl cmake build-essential pkg-config automake libtool git zlib1g-dev libssl-dev libgeoip-dev libboost-all-dev -y -qq > /dev/null

#get version and url for the latest qBittorrent release
locationq="https://github.com/qbittorrent/qBittorrent/archive"$(curl -s https://github.com/qbittorrent/qBittorrent/releases | grep -m1 "qBittorrent/releases/tag/release-" | cut -c 53- | sed 's/".*//')".tar.gz"
verq=$(curl -s https://github.com/qbittorrent/qBittorrent/releases | grep -m1 "qBittorrent/releases/tag/release-" | cut -c 62- | sed 's/".*//')

#get version and url for the latest libtorrent release
locationl="https://github.com/arvidn/libtorrent/releases/download"$(curl -s https://github.com/arvidn/libtorrent/releases | grep -m1 "libtorrent/releases/tag/libtorrent-" | cut -c 51- | sed 's/".*//')"/libtorrent-rasterbar-"$(curl -s https://github.com/arvidn/libtorrent/releases | grep -m1 "libtorrent/releases/tag/libtorrent-" | cut -c 81- | sed 's/<.*//')".tar.gz"
verl=$(curl -s https://github.com/arvidn/libtorrent/releases | grep -m1 "libtorrent/releases/tag/libtorrent-" | cut -c 81- | sed 's/<.*//')

#download and unpack the qbittorrent source code
mkdir -p qbittorrent && cd qbittorrent

if [ -f "qbittorrent/qbittorrent-$verq/out/qbittorrent-nox" ]; then
  echo "Found the compiled qbittorrent-nox in qbittorrent-$verq/out/qbittorrent-nox"
  exit
fi

if [ ! -d "qbittorrent-$verq" ]; then
  if [[ $(ls | grep "qbittorrent-") ]]; then
	sudo rm -r qbittorrent-*
  fi
  echo "Download and extract (qbittorrent)"
  mkdir qbittorrent-$verq
  wget -q $locationq -O qbittorrent-$verq/qbittorrent-$verq.tar.gz
fi

if [ ! -f "qbittorrent-$verq/qbittorrent-$verq.tar.gz" ]; then
  echo -e "\e[31mError while download (qbittorrent)\e[0m"
  exit
fi
tar -zxf qbittorrent-$verq/qbittorrent-$verq.tar.gz -C qbittorrent-$verq --strip 1

#download and unpack the libtorrent source code
build=0
if [ ! -d "libtorrent-$verl" ]; then
  if [[ $(ls | grep "libtorrent-") ]]; then
	sudo rm -r libtorrent-*
  fi
  echo "Download and extract (libtorrent)"
  mkdir libtorrent-$verl
  wget -q $locationl -O libtorrent-$verl/libtorrent-$verl.tar.gz
  build=1
fi

if [ ! -f "libtorrent-$verl/libtorrent-$verl.tar.gz" ]; then
  echo -e "\e[31mError while download (libtorrent)\e[0m"
  exit
fi

#build libtorrent and install libtorrent
if [ $build == 1 ]; then
  tar -zxf libtorrent-$verl/libtorrent-$verl.tar.gz -C libtorrent-$verl --strip 1
  cd libtorrent-$verl && mkdir -p cmake-build-dir/release && cd cmake-build-dir/release
  echo "Build libtorrent"
  cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=14 -G "Unix Makefiles" ../..
  make clean && make -j$(nproc)
  sudo make install
  cd ../../../
fi

#build qbittorrent-nox
cd qbittorrent-$verq/
./configure --disable-gui CXXFLAGS="-std=c++14"
make -j$(nproc)
mkdir -p out/other
cp src/qbittorrent-nox out

#create libtorrent.deb
echo "make libtorrent.deb"
cd ../libtorrent-$verl/cmake-build-dir/release
mkdir libtorrent_$verl-1
sed -i "s#/usr/local#$PWD/libtorrent_$verl-1/usr/local#g" cmake_install.cmake
sudo make install
sed -i "s#$PWD/libtorrent_$verl-1#/usr/local#g" cmake_install.cmake
mkdir libtorrent_$verl-1/DEBIAN/
cat <<EOF >libtorrent_$verl-1/DEBIAN/control
Package: libtorrent
Version: $verl-1
Section: base
Priority: optional
Architecture: i386
Depends: libboost-random1.67.0
Maintainer: Madagambada
Description: libtorrent-$verq
EOF
dpkg-deb --build libtorrent_$verl-1
cp libtorrent_$verl-1.deb ../../../qbittorrent-$verq/out/other

#create qbittorrent-nox.deb without libtorrent
cd ../../../qbittorrent-$verq
echo "make qbittorrent-nox.deb without libtorrent"
mkdir -p deb/qbittorrent-nox_$verq-1/usr/local/bin
cp src/qbittorrent-nox deb/qbittorrent-nox_$verq-1/usr/local/bin
mkdir deb/qbittorrent-nox_$verq-1/DEBIAN/
cat <<EOF >deb/qbittorrent-nox_$verq-1/DEBIAN/control
Package: qbittorrent-nox
Version: $verq-1
Section: base
Priority: optional
Architecture: i386
Depends: libboost-system1.67.0, libc6, libgcc1, libqt5core5a, libqt5network5, libqt5xml5, libstdc++6, zlib1g
Maintainer: Madagambada
Description: qbittorrent-nox_$verq
EOF
dpkg-deb --build deb/qbittorrent-nox_$verq-1

#create qbittorrent-nox.deb with libtorrent
echo "make qbittorrent-nox.deb with libtorrent"
cp deb/qbittorrent-nox_$verq-1.deb out/other/qbittorrent-nox_$verq-1_without_libtorrent.deb
cp -R ../libtorrent-$verl/cmake-build-dir/release/libtorrent_$verl-1/usr/ deb/qbittorrent-nox_$verq-1
sed -i '/^Des/ s/$/ with libtorrent_$verl/' deb/qbittorrent-nox_$verq-1/DEBIAN/control
dpkg-deb --build deb/qbittorrent-nox_$verq-1
cp deb/qbittorrent-nox_$verq-1.deb out
echo "When all good, check out qbittorrent-$verq/out"
