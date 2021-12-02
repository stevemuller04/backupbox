#!/bin/bash

BINDIR=$(realpath bin)
BBXDIR=$(realpath src/bbx)
WWWDIR=$(realpath src/bbx/web)
SERVICESDIR=$(realpath etc/systemd)
POWERLED_GPIO_PIN=26

# ----------------------------------------------------------------------


apt update && apt install git golang scons
(git clone https://github.com/jgarff/rpi_ws281x.git && cd rpi_ws281x && scons && cp *.a /lib && cp *.h /usr/local/include && cd .. && rm -rf rpi_ws281x)

(cd "$BBXDIR"; make all)
chmod +x $BINDIR/*

mkdir -p /usr/local/bin
ln -s "$BINDIR/dirbak" /usr/local/bin/dirbak
ln -s "$BINDIR/rot" /usr/local/bin/rot
ln -s "$BINDIR/rwprot" /usr/local/bin/rwprot
ln -s "$BBXDIR/build/bbxwebd" /usr/local/bin/bbxwebd
ln -s "$BBXDIR/build/bbxdevd" /usr/local/bin/bbxdevd

mkdir -p /var/www
ln -s "$WWWDIR" /var/www/bbx

mkdir -p /etc/systemd/system
ln -s "$SERVICESDIR/bbxdevd.service" /etc/systemd/system/bbxdevd.service
ln -s "$SERVICESDIR/bbxwebd.service" /etc/systemd/system/bbxwebd.service
ln -s "$SERVICESDIR/powerled.service" /etc/systemd/system/powerled.service
ln -s "$SERVICESDIR/rwprot.service" /etc/systemd/system/rwprot.service
ln -s "$SERVICESDIR/rwprot.timer" /etc/systemd/system/rwprot.timer

systemctl enable bbxdevd && systemctl start bbxdevd
systemctl enable bbxwebd && systemctl start bbxwebd
systemctl enable powerled && systemctl start powerled
systemctl enable rwprot.timer

echo 'dtparam=act_led_trigger=heartbeat' >> /boot/config.txt
echo "dtoverlay=pi3-act-led,gpio=$POWERLED_GPIO_PIN" >> /boot/config.txt
echo 'echo "default-on" >/sys/class/leds/led0/trigger' >> /etc/rc.local
