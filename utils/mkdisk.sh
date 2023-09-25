#!/bin/bash

IMAGE_SIZE_G=100
BOOTSTRAP_SIZE_G=2
SCRATCH_SIZE_G=20

BUILD_DIR=./build
IMAGE_DIR=./build/images
SRC_DIR=./bootstrap

MK_INITRD_BIN=./utils/mk_initrd.py
MK_PLACEHOLDER_BIN=./utils/mk_cfg_placeholder.py
FIND_PLACEHOLDER_BIN=./utils/find_cfg_placeholder.py

rm -rf "${BUILD_DIR}"

# TODO run all of this in an (alpine) docker, to make things easier/portable

# configure apk
ROOTFS_DIR="${BUILD_DIR}/rootfs"
mkdir -p "${ROOTFS_DIR}/etc/apk"
echo x86_64 > "${ROOTFS_DIR}/etc/apk/arch"
cat <<EOF > "${ROOTFS_DIR}/etc/apk/repositories"
http://dl-cdn.alpinelinux.org/alpine/v3.18/main
http://dl-cdn.alpinelinux.org/alpine/v3.18/community
EOF

# download alpine signing keys
ALPINE_KEYS_APK="${BUILD_DIR}/alpine-keys.apk"
curl "https://dl-cdn.alpinelinux.org/alpine/v3.18/main/x86_64/alpine-keys-2.4-r1.apk" > "${ALPINE_KEYS_APK}"
echo "880983a4ba0e6403db432e7b2687af976e023567ab11d1428c758351011263e9  ${ALPINE_KEYS_APK}"
tar -C "${ROOTFS_DIR}" -xf "${ALPINE_KEYS_APK}" etc/apk/keys

# download apk
APK_TOOLS_APK="${BUILD_DIR}/apk-tools-static.apk"
APK_BIN="${BUILD_DIR}/apk"
curl "https://dl-cdn.alpinelinux.org/alpine/v3.18/main/x86_64/apk-tools-static-2.14.0-r2.apk" > "${APK_TOOLS_APK}"
echo "c8465a56bac138677d3fb025f7e13a30d18210ef327880673314ad63d59c1977  ${APK_TOOLS_APK}"
tar -xvf "${APK_TOOLS_APK}" sbin/apk.static -O > "${APK_BIN}"
chmod +x "${APK_BIN}"

# install needed packages
"${APK_BIN}" add \
    --root "${ROOTFS_DIR}" \
    --no-scripts \
    --no-chown \
    --initdb \
    linux-virt syslinux curl

# select files for ramdisk
INITRD_DIR="${BUILD_DIR}/initrd"
mkdir -p "${INITRD_DIR}"
"${MK_INITRD_BIN}" "${ROOTFS_DIR}" "${INITRD_DIR}" <<EOF
./bin/busybox
./usr/bin/curl

./etc/ssl/certs/ca-certificates.crt
./usr/share/udhcpc/default.script

./lib/ld-musl-x86_64.so.1
./lib/libcrypto.so.3
./lib/libz.so.1.*
./lib/libc.musl-x86_64.so.1

./usr/lib/libbrotlidec.so.1.*
./usr/lib/libbrotlicommon.so.1.*
./usr/lib/libcurl.so.4.*
./usr/lib/liblzma.so.5.*
./usr/lib/libssl.so.3
./usr/lib/libzstd.so.1.*
./usr/lib/libnghttp2.so.14.*
./usr/lib/libidn2.so.0.*
./usr/lib/libunistring.so.5.*

./lib/modules/*/kernel/lib/crc64.ko.gz
./lib/modules/*/kernel/lib/crc64-rocksoft.ko.gz
./lib/modules/*/kernel/block/t10-pi.ko.gz
./lib/modules/*/kernel/drivers/scsi/sd_mod.ko.gz

./lib/modules/*/kernel/drivers/ata/ata_generic.ko.gz
./lib/modules/*/kernel/drivers/block/loop.ko.gz

./lib/modules/*/kernel/drivers/cdrom/cdrom.ko.gz
./lib/modules/*/kernel/lib/crc-itu-t.ko.gz
./lib/modules/*/kernel/fs/udf/udf.ko.gz

./lib/modules/*/kernel/crypto/crc32_generic.ko.gz
./lib/modules/*/kernel/crypto/crc32c_generic.ko.gz
./lib/modules/*/kernel/lib/crc16.ko.gz
./lib/modules/*/kernel/fs/jbd2/jbd2.ko.gz
./lib/modules/*/kernel/fs/mbcache.ko.gz
./lib/modules/*/kernel/fs/ext4/ext4.ko.gz

./lib/modules/*/kernel/fs/ntfs3/ntfs3.ko.gz

./lib/modules/*/kernel/net/packet/af_packet.ko.gz
./lib/modules/*/kernel/drivers/net/ethernet/intel/e1000/e1000.ko.gz
./lib/modules/*/kernel/drivers/net/ethernet/intel/e1000e/e1000e.ko.gz
EOF

# install init script
cp "${SRC_DIR}/init" "${INITRD_DIR}/"

# start to assemble bootstrap filesystem
FS_DIR="${BUILD_DIR}/fs"
mkdir -p "${FS_DIR}"

# build initramfs
INITRD_IMG="${FS_DIR}/initramfs.img"
_INITRD_IMG=$(realpath "${INITRD_IMG}")
pushd "${INITRD_DIR}"
find . | sort | cpio -o -H newc -R 0:0 | gzip --best > "${_INITRD_IMG}"
popd

# install kernel
cp "${ROOTFS_DIR}/boot/vmlinuz-virt" "${FS_DIR}/kernel"

# install bootstrap scripts
cp "${SRC_DIR}/bootstrap.sh" \
    "${SRC_DIR}/firstlogon_header.tpl" \
    "${SRC_DIR}/firstlogon.ps1" \
    "${SRC_DIR}/unattend.tpl" \
    "${FS_DIR}/"

# install and configure bootloader
mkdir -p "${FS_DIR}/syslinux"
cp "${ROOTFS_DIR}/usr/share/syslinux/mbr.bin" "${FS_DIR}/syslinux/"
# TODO can't use these as they might not be compatible with the host's guestfish installing syslinux
#cp ./root3/usr/share/syslinux/linux.c32 .
#cp ./root3/usr/share/syslinux/libcom32.c32 .
if test -d /usr/lib/syslinux/modules/bios/; then
    SYSLINUXDIR=/usr/lib/syslinux/modules/bios/
elif test -d /usr/lib/syslinux/bios/; then
    SYSLINUXDIR=/usr/lib/syslinux/bios/
else
    echo "WARNING! syslinux dir not detected, assuming /usr/lib/syslinux/bios/"
    SYSLINUXDIR=/usr/lib/syslinux/bios/
fi

cp "$SYSLINUXDIR/linux.c32" "${FS_DIR}/syslinux/"
cp "$SYSLINUXDIR/libcom32.c32" "${FS_DIR}/syslinux/"

cat <<EOF > "${FS_DIR}/syslinux/syslinux.cfg"
DEFAULT linux
LABEL linux
  KERNEL /kernel
  APPEND initrd=/initramfs.img
EOF

# insert placeholder for user configuration
${MK_PLACEHOLDER_BIN} > "${FS_DIR}/usercfg"
#cat ./example.cfg | ./utils/pack_config.py > "${FS_DIR}/usercfg"

FS_TAR="${BUILD_DIR}/fs.tar"
tar -cf "${FS_TAR}" -C "${FS_DIR}" .

# build final disk image
IMAGE_FILE="${BUILD_DIR}/disk.img"
guestfish <<EOF
disk-create ${IMAGE_FILE} raw ${IMAGE_SIZE_G}G preallocation:sparse
add-drive ${IMAGE_FILE}
run

# partition disk
part-init /dev/sda mbr
part-add /dev/sda p 2048 $((2048 + ($BOOTSTRAP_SIZE_G << (30-9))))
part-add /dev/sda p $((($IMAGE_SIZE_G - $SCRATCH_SIZE_G) << (30-9))) -1
part-set-bootable /dev/sda 1 true
part-set-mbr-id /dev/sda 1 0x83
part-set-mbr-id /dev/sda 2 0x7

# create file systems
mkfs ext4 /dev/sda1
mkfs ntfs /dev/sda2

# populate bootstrap partition
mkmountpoint /boot
mount /dev/sda1 /boot
tar-in ${FS_TAR} /boot

# install bootloader
copy-file-to-device /boot/syslinux/mbr.bin /dev/sda size:440
rm /boot/syslinux/mbr.bin
extlinux /boot

umount-all
shutdown
exit
EOF

# convert to various image formats
mkdir -p "${IMAGE_DIR}"
for IMAGE_FORMAT in qcow2 vmdk vdi ; do
    CONVERTED_IMAGE="${IMAGE_DIR}/disk.${IMAGE_FORMAT}"
    IMAGE_MANIFEST="${CONVERTED_IMAGE}.manifest"
    # convert image format
    qemu-img convert -f raw -O ${IMAGE_FORMAT} "${IMAGE_FILE}" "${CONVERTED_IMAGE}"

    # generate manifest
    echo "m1" >> "${IMAGE_MANIFEST}"
    # hash of image
    sha256sum "${CONVERTED_IMAGE}" | awk '{ print $1 }' >> "${IMAGE_MANIFEST}"
    # location and length of config file
    ${FIND_PLACEHOLDER_BIN} "${CONVERTED_IMAGE}" >> "${IMAGE_MANIFEST}"

    # compress image
    gzip -f -9 "${CONVERTED_IMAGE}"
done
