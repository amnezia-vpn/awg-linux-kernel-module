#!/usr/bin/env bash

if [ "${GIT_URL}" == "" ]; then
  echo "Set the GIT_URL env variable with link to your current kernel's git repository"
  exit 255
fi

if [ "${PATCH_PATH}" == "" ]; then
  echo "Set the PATCH_PATH env variable with path to Amnezia Kmod patch"
  exit 255
fi

if [ "${GIT_BRANCH}" != "" ]; then
  GIT_BRANCH="-b ${GIT_BRANCH}"
fi

set -e

sudo apt-get remove -y git
sudo add-apt-repository -y ppa:git-core/ppa
sudo apt-get update
sudo apt-get install -y --quiet git linux-headers-$(uname -r) build-essential
git clone --filter=blob:none --sparse ${GIT_BRANCH} ${GIT_URL} /tmp/linux-kernel-source
pushd /tmp/linux-kernel-source
git sparse-checkout add drivers/net/wireguard
pushd drivers/net/wireguard
mkdir uapi
cp /usr/src/linux-headers-$(uname -r)/include/uapi/linux/wireguard.h uapi/
echo "/tmp/linux-kernel-source/drivers/net/wireguard/uapi/wireguard.h" | patch -i ${PATCH_PATH}
make
sudo make install
sudo mkdir /etc/amnezia
popd
popd

# install patched wg-tools

git clone -b changes-for-kmod https://github.com/amnezia-vpn/amnezia-wg-tools.git /tmp/awg-tools
pushd /tmp/awg-tools/src
make
sudo make install
popd
rm -rf /tmp/awg-tools
