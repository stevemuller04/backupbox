## Set up

Execute as root (`sudo su`):

```bash
passwd pi

echo 'backupbox' > /etc/hostname
sed -i 's/raspberrypi/backupbox/' /etc/hosts

mkdir ~/.ssh
chmod 0700 ~/.ssh
echo $SSHKEY > ~/.ssh/authorized_keys
chmod 0600 ~/.ssh/authorized_keys
echo 'PasswordAuthentication no' >> /etc/ssh/sshd_config

apt update && apt upgrade

raspi-config # enable I2C at "Interface Options" → "I2C"
```

## Configure boot LED

On GPIO pin 26 (BCM):

```bash
echo 'dtparam=act_led_trigger=heartbeat' >> /boot/config.txt
echo 'dtoverlay=pi3-act-led,gpio=26' >> /boot/config.txt
echo 'echo "default-on" >/sys/class/leds/led0/trigger' >> /etc/rc.local

echo '[Unit]' > /etc/systemd/system/powerled.service
echo 'Description=Turn Power LED on when boot completed' >> /etc/systemd/system/powerled.service
echo 'After=multi-user.target' >> /etc/systemd/system/powerled.service
echo '' >> /etc/systemd/system/powerled.service
echo '[Service]' >> /etc/systemd/system/powerled.service
echo 'Type=idle' >> /etc/systemd/system/powerled.service
echo 'ExecStart=/bin/echo "default-on"' >> /etc/systemd/system/powerled.service
echo 'StandardOutput=append:/sys/class/leds/led0/trigger' >> /etc/systemd/system/powerled.service
echo '' >> /etc/systemd/system/powerled.service
echo '[Install]' >> /etc/systemd/system/powerled.service
echo 'WantedBy=multi-user.target' >> /etc/systemd/system/powerled.service

systemctl enable powerled
```

## Configure mount

```bash
mkdir /mnt/usb
chattr +i /mnt/usb # readonly
echo '/dev/sda1 /mnt/usb ext4 defaults,nofail 0 0' >> /etc/fstab
```

## Install Samba

```bash
apt update && apt install samba

sed -i '/Share Definitions/,$d' /etc/samba/smb.conf

echo 'security = user' >> /etc/samba/smb.conf
echo 'follow symlinks = no' >> /etc/samba/smb.conf
echo 'load printers = no' >> /etc/samba/smb.conf
echo 'printing = bsd' >> /etc/samba/smb.conf
echo 'printcap name = /dev/null' >> /etc/samba/smb.conf
echo 'disable spoolss = yes' >> /etc/samba/smb.conf
echo 'socket options = TCP_NODELAY' >> /etc/samba/smb.conf
echo 'strict locking = no' >> /etc/samba/smb.conf
echo 'veto files = /._*/.apdisk/.AppleDouble/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/' >> /etc/samba/smb.conf
echo 'delete veto files = yes' >> /etc/samba/smb.conf
echo 'map to guest = never' >> /etc/samba/smb.conf
echo 'include = /etc/samba/smb-shares.conf' >> /etc/samba/smb.conf

echo '[backup]' > /etc/samba/smb-shares.conf
echo 'path = /mnt/usb/live' >> /etc/samba/smb-shares.conf
echo 'browseable = yes' >> /etc/samba/smb-shares.conf
echo 'read only = no' >> /etc/samba/smb-shares.conf
echo 'writeable = yes' >> /etc/samba/smb-shares.conf
echo 'create mask = 0770' >> /etc/samba/smb-shares.conf
echo 'force create mode = 0770' >> /etc/samba/smb-shares.conf
echo 'directory mask = 2770' >> /etc/samba/smb-shares.conf
echo 'force directory mode = 2770' >> /etc/samba/smb-shares.conf
echo 'guest ok = no' >> /etc/samba/smb-shares.conf
echo 'valid users = @backupusers' >> /etc/samba/smb-shares.conf
```

## Add users

```bash
addgroup backupusers
```

For each user `$USER`:

```bash
adduser --shell /bin/false $USER
adduser $USER backupusers
smbpasswd -a $USER
```

## Prepare external USB drive

* Format as ext4
* Create folders `/live` and `/backup`

Give correct access rights:

```bash
chown root:backupusers $MOUNT/live
chown root:root $MOUNT/backup
chmod 2770 $MOUNT/live
```

## Configure ransomware protection

```bash
echo '[Unit]' > /etc/systemd/system/rwprot.service
echo 'Description=Execute ransomware protection on /mnt/usb' >> /etc/systemd/system/rwprot.service
echo '' >> /etc/systemd/system/rwprot.service
echo '[Service]' >> /etc/systemd/system/rwprot.service
echo 'Type=oneshot' >> /etc/systemd/system/rwprot.service
echo 'ExecStart=/usr/local/bin/rwprot "/mnt/usb/live" "/mnt/usb/backup"' >> /etc/systemd/system/rwprot.service
echo 'User=root' >> /etc/systemd/system/rwprot.service
echo 'Group=root' >> /etc/systemd/system/rwprot.service

echo '[Unit]' > /etc/systemd/system/rwprot.timer
echo 'Description=Run ransomware protection once per night' >> /etc/systemd/system/rwprot.timer
echo '' >> /etc/systemd/system/rwprot.timer
echo '[Timer]' >> /etc/systemd/system/rwprot.timer
echo 'OnCalendar=*-*-* 4:00:00' >> /etc/systemd/system/rwprot.timer
echo '' >> /etc/systemd/system/rwprot.timer
echo '[Install]' >> /etc/systemd/system/rwprot.timer
echo 'WantedBy=timers.target' >> /etc/systemd/system/rwprot.timer

systemctl daemon-reload
systemctl enable rwprot.timer
```

## Install other dependencies

* Copy `rwprot.sh`, `rot.sh` and `dirbak.sh` to `/usr/local/bin/`
* Install dependencies:

```bash
apt install git golang scons

cd && git clone https://github.com/jgarff/rpi_ws281x.git && cd rpi_ws281x && scons && cp *.a /lib && cp *.h /usr/local/include && cd && rm -r rpi_ws281x
```

* Install Backup Box software:

```bash
git -c http.sslVerify=false clone https://intranet.octarine.lu/git/steve/backupbox.git /usr/local/src/bbx
cd /usr/local/src/bbx/
make
ln -s /usr/local/src/bbx/build/bbxd /usr/local/bin/bbxd
ln -s /usr/local/src/bbx/build/bbxweb /usr/local/bin/bbxweb
ln -s /usr/local/src/bbx/bbxd.service /etc/systemd/system/bbxd.service && systemctl enable bbxd
ln -s /usr/local/src/bbx/bbxweb.service /etc/systemd/system/bbxweb.service && systemctl enable bbxweb
```

## Configure read-only file system

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