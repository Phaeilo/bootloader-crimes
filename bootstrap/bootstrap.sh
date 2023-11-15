#!/bin/sh

echo hello from bootstrap

if [ ! -f /root/bootstrap.sh ] ; then
    cp "$0" /root/bootstrap.sh
    chmod +x /root/bootstrap.sh
    exec /root/bootstrap.sh
    exit 0
fi

[ -f /root/.bootstrap_ran ] && exit 1
touch /root/.bootstrap_ran


announce() {
    >&2 echo "${1}..."
}

chk_fail() {
    if [[ $1 -ne 0 ]]; then
        type __hook_pre_fail &>/dev/null && __hook_pre_fail
        >&2 echo "FAIL!"
        exit $1
    else
        >&2 echo "OK!"
    fi
}


CFG_FILE=/mnt/bootstrap/usercfg
TMP_CFG=$(mktemp)

announce "Locating user configuration"
test $(cat $CFG_FILE | head -n1) = "cfg"
chk_fail $?

announce "Reading user configuration"
dd \
    if=$CFG_FILE of=$TMP_CFG bs=1 \
    skip=$(cat $CFG_FILE | head -n2 | tail -n1) \
    count=$(cat $CFG_FILE | head -n3 | tail -n1)
chk_fail $?

announce "Verifying user configuration"
CFG_SHA=$(cat $CFG_FILE | head -n4 | tail -n1)
echo "$CFG_SHA  $TMP_CFG" | sha256sum -c -
chk_fail $?

announce "Decompressing user configuration"
cat $TMP_CFG | gunzip - > /tmp/usercfg_final
chk_fail $?

announce "Sourcing user configuration"
. /tmp/usercfg_final
chk_fail $?


announce "Downloading ISO"
# Retry up to 10 times. -C - makes downloads resume where they stopped upon retry.
curl -L "$ISO_URL" --output /mnt/scratch/win.iso --retry 10 -C -
chk_fail $?

announce "Verifying ISO"
echo "$ISO_HASH  /mnt/scratch/win.iso" | sha256sum -c -
chk_fail $?

announce "Mounting ISO"
mkdir /mnt/iso && mount -t udf /mnt/scratch/win.iso /mnt/iso
chk_fail $?

announce "Extracting PE files from ISO"
cp \
    /mnt/iso/boot/bcd \
    /mnt/iso/boot/boot.sdi \
    /mnt/iso/sources/boot.wim \
    /mnt/bootstrap
chk_fail $?

announce "Extracting install.wim from ISO"
cp /mnt/iso/sources/install.wim /mnt/scratch
chk_fail $?


WIMBOOT_URL=https://github.com/ipxe/wimboot/releases/download/v2.7.5/wimboot
WIMBOOT_HASH=7083f2ea6bb8f7f0801d52d38e6ba25d6e46b0e5b2fb668e65dd0720bf33f7bd

announce "Downloading wimboot"
curl -L "$WIMBOOT_URL" --output /mnt/bootstrap/wimboot
chk_fail $?

announce "Verifying wimboot"
echo "$WIMBOOT_HASH  /mnt/bootstrap/wimboot" | sha256sum -c -
chk_fail $?


announce "Installing firstboot scripts"
sh /mnt/bootstrap/unattend.tpl > /mnt/scratch/unattend.xml && \
sh /mnt/bootstrap/firstlogon_header.tpl > /mnt/scratch/firstlogon.ps1 && \
cat /mnt/bootstrap/firstlogon.ps1 >> /mnt/scratch/firstlogon.ps1
chk_fail $?

announce "Installing PE scripts"
cat << EOF > /mnt/bootstrap/winpeshl.ini
[LaunchApps]
"install.bat"
EOF

cat << EOF > /mnt/bootstrap/install.bat
wpeinit

> diskpart.script (
    echo.select disk 0
    echo.select part 1
    echo.delete part
    echo.create part primary
    echo.format fs=ntfs label=Windows quick
    echo.active
    echo.assign letter=W
    echo.select part 2
    echo.assign letter=U
)
diskpart /s diskpart.script

dism /Apply-Image /ImageFile:U:\\install.wim /Index:${WIM_INDEX} /ApplyDir:W:\\
copy U:\\unattend.xml W:\\Windows\\System32\\sysprep\\unattend.xml
copy U:\\firstlogon.ps1 W:\\firstlogon.ps1

> diskpart.script (
    echo.select disk 0
    echo.select part 2
    echo.delete part
    echo.select vol 1
    echo.extend
)
diskpart /s diskpart.script

W:\\Windows\\System32\\bcdboot W:\\Windows /s W:
bootsect /nt60 W: /mbr
EOF

announce "Re-configuring bootloader"
cat << EOF > /mnt/bootstrap/syslinux/syslinux.cfg
DEFAULT winpe
LABEL winpe
  COM32 linux.c32
  APPEND /wimboot initrdfile=/bcd,/boot.sdi,/boot.wim,/winpeshl.ini,/install.bat
EOF


type __hook_pre_umount &>/dev/null && __hook_pre_umount

announce "Unmounting and deleting ISO"
umount /mnt/iso && rmdir /mnt/iso && rm /mnt/scratch/win.iso
chk_fail $?

announce "Unmounting disk"
umount /mnt/scratch /mnt/bootstrap && sync
chk_fail $?


type __hook_pre_reboot &>/dev/null && __hook_pre_reboot

announce "Reboot"
reboot
