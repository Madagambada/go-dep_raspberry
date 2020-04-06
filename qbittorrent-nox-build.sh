#!/bin/sh

#update and install packages 
echo "check & install build dependencies"
sudo apt-get update && sudo apt-get install sudo qtbase5-dev qttools5-dev-tools libqt5svg5-dev python3 curl cmake build-essential pkg-config automake libtool git zlib1g-dev libssl-dev libgeoip-dev libboost-dev libboost-system-dev libboost-chrono-dev libboost-random-dev -y -qq > /dev/null

#get version and url for the latest qBittorrent release
locationq="https://github.com/qbittorrent/qBittorrent/archive"$(curl -s https://github.com/qbittorrent/qBittorrent/releases | grep -m1 "qBittorrent/releases/tag/release-" | cut -c 53- | sed 's/.\{2\}$//')".tar.gz"
verq=$(curl -s https://github.com/qbittorrent/qBittorrent/releases | grep -m1 "qBittorrent/releases/tag/release-" | cut -c 62- | sed 's/.\{2\}$//')

#get version and url for the latest libtorrent release
locationl="https://github.com/arvidn/libtorrent/releases/download"$(curl -s https://github.com/arvidn/libtorrent/releases | grep -m1 "libtorrent/releases/tag/libtorrent-" | cut -c 51- | sed 's/.\{22\}$//')"/libtorrent-rasterbar-"$(curl -s https://github.com/arvidn/libtorrent/releases | grep -m1 "libtorrent/releases/tag/libtorrent-" | cut -c 81- | sed 's/.\{4\}$//')".tar.gz"
verl=$(curl -s https://github.com/arvidn/libtorrent/releases | grep -m1 "libtorrent/releases/tag/libtorrent-" | cut -c 81- | sed 's/.\{4\}$//')

#download and unpack the qbittorrent source code
if [ ! -d "qbittorrent-$verq" ]; then
  mkdir qbittorrent-$verq
fi
if [ -f "qbittorrent-$verq/out/qbittorrent-nox" ]; then
  echo "Found the compiled qbittorrent-nox in qbittorrent-$verq/out/qbittorrent-nox"
  echo "compile it again"
fi
echo "Download and extract (qbittorrent)"
cd qbittorrent-$verq && wget -q $locationq -O qbittorrent-$verq.tar.gz
if [ ! -f "qbittorrent-$verq.tar.gz" ]; then
  echo -e "\e[31mError while download (qbittorrent)\e[0m"
  exit
fi
tar -zxf qbittorrent-$verq.tar.gz --strip 1

#download and unpack the libtorrent source code
if [ ! -d "libtorrent-$verl" ]; then
  mkdir libtorrent-$verl
fi
echo "Download and extract (libtorrent)"
cd libtorrent-$verl && wget -q $locationl -O libtorrent-$verl.tar.gz
if [ ! -f "libtorrent-$verl.tar.gz" ]; then
  echo -e "\e[31mError while download (libtorrent)\e[0m"
  exit
fi

#build libtorrent and install libtorrent
tar -zxf libtorrent-$verl.tar.gz --strip 1
mkdir -p cmake-build-dir/release && cd cmake-build-dir/release
echo "Build libtorrent"
cmake -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=14 -G "Unix Makefiles" ../..
make clean && make -j$(nproc)
if [ ! -f "/usr/local/lib/libtorrent-rasterbar.so.$verl" ]; then
  echo "install libtorrent-$verl"
  sudo make install
fi

#build qbittorrent-nox
cd ../../../
./configure --disable-gui CXXFLAGS="-std=c++14"
make -j$(nproc)
if [ ! -d "out" ]; then
  mkdir -p out/other
fi
cp src/qbittorrent-nox out

#create libtorrent.deb
echo "make libtorrent.deb"
cd libtorrent-$verl/cmake-build-dir/release
if [ -d "libtorrent_$verl-1" ]; then
  sudo rm -r libtorrent_$verl-1
fi
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
cp libtorrent_$verl-1.deb ../../../out/other

#create qbittorrent-nox.deb without libtorrent
cd ../../../
echo "make qbittorrent-nox.deb without libtorrent"
if [ -d "deb/qbittorrent-nox_$verq-1" ]; then
  sudo rm -r deb/qbittorrent-nox_$verq-1
fi
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
cp -R libtorrent-$verl/cmake-build-dir/release/libtorrent_$verl-1/usr/ deb/qbittorrent-nox_$verq-1
sed -i '/^Des/ s/$/ with libtorrent_$verl/' deb/qbittorrent-nox_$verq-1/DEBIAN/control
dpkg-deb --build deb/qbittorrent-nox_$verq-1
cp deb/qbittorrent-nox_$verq-1.deb out
echo "When all good, check out qbittorrent-$verq/out"
