# Backup Box

Daemon that monitors the backup status on a Raspberry Pi and displays it using peripherals (LED, LCD screen).

# Hardware

TODO

# Prerequisites

Make sure that the I2C interface is enabled:
```bash
raspi-config # enable I2C at "Interface Options" → "I2C"
# this may work:
raspi-config nonint do_i2c 0
```

Make sure that the Raspberry Pi has the desired hostname by editing the following files accordingly:
* `/etc/hostname`
* `/etc/hosts`

Make sure that the SSH access is properly secured.

# Install

Run:

```bash
sudo ./install.sh
```

## Add users

A default user `backup0` has already been created by the installation script.
It can be deleted if not required.

To add a new user `$USER`:

```bash
adduser --shell /bin/false --disabled-password --gecos --disabled-login $USER
adduser $USER backupusers
smbpasswd -a $USER
```

## Prepare external USB drive (can also be done through web interface)

* Format as ext4
* Create folders `./live` and `./backup`

Give correct access rights:

```bash
chown root:backupusers ./live
chown root:root ./backup
chmod 2770 ./live
```

## (OPTIONAL, EXPERIMENTAL) Configure read-only file system

/!\ **Warning:** The procedure in this section is experimental! Making the file system read-only causes many problems like services not starting correctly and NTP not working (see workaround below).

* Add `fastboot noswap ro` to the end of the boot line in `/boot/cmdline.txt`
* Add the option `,ro` to all block devices in `/etc/fstab`
* Add the line `ExecStartPre=/usr/bin/touch /tmp/random-seed` before `ExecStart=` in `/lib/systemd/system/systemd-random-seed.service`
* Add the line `ExecStartPre=cp -R /var/lib/samba.orig /tmp/samba` before `ExecStart=` in `/lib/systemd/system/smbd.service`

```bash
apt install busybox-syslogd
apt remove --purge rsyslog # should be included with the previous

echo 'tmpfs /tmp tmpfs nosuid,nodev,mode=1777 0 0' >> /etc/fstab
echo 'tmpfs /var/log tmpfs nosuid,nodev 0 0' >> /etc/fstab
echo 'tmpfs /var/tmp tmpfs nosuid,nodev 0 0' >> /etc/fstab

rm -rf /var/lib/dhcp /var/lib/dhcpcd5 /var/spool /etc/resolv.conf /var/lib/systemd/random-seed
ln -s /tmp /var/lib/dhcp
ln -s /tmp /var/lib/dhcpcd5
ln -s /tmp /var/spool
ln -s /tmp/random-seed /var/lib/systemd/random-seed
ln -s /tmp/dhcpcd.resolv.conf /etc/resolv.conf

mv /var/lib/samba /var/lib/samba.orig
ln -s /tmp/samba /var/lib/samba
ln -s /tmp /var/cache/samba
```

Work-around for non-working NTP:

```bash
apt install sntp

echo '[Unit]' > /etc/systemd/system/manualntp.service
echo 'Description=Run manual time synchronisation' >> /etc/systemd/system/manualntp.service
echo '' >> /etc/systemd/system/manualntp.service
echo '[Service]' >> /etc/systemd/system/manualntp.service
echo 'Type=oneshot' >> /etc/systemd/system/manualntp.service
echo 'ExecStart=/usr/bin/sntp -S pool.ntp.org' >> /etc/systemd/system/manualntp.service
echo 'User=root' >> /etc/systemd/system/manualntp.service
echo 'Group=root' >> /etc/systemd/system/manualntp.service

echo '[Unit]' > /etc/systemd/system/manualntp.timer
echo 'Description=Run time synchronisation regularly' >> /etc/systemd/system/manualntp.timer
echo '' >> /etc/systemd/system/manualntp.timer
echo '[Timer]' >> /etc/systemd/system/manualntp.timer
echo 'OnBootSec=1min ' >> /etc/systemd/system/manualntp.timer
echo 'OnUnitActiveSec=1d ' >> /etc/systemd/system/manualntp.timer
echo '' >> /etc/systemd/system/manualntp.timer
echo '[Install]' >> /etc/systemd/system/manualntp.timer
echo 'WantedBy=timers.target' >> /etc/systemd/system/manualntp.timer

systemctl daemon-reload
systemctl enable manualntp.timer
```