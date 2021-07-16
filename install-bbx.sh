#!/bin/bash

BINDIR=$(realpath bin)
BBXDIR=$(realpath src/bbx)
SERVICESDIR=$(realpath etc/systemd)

# ----------------------------------------------------------------------

(cd "$BBXDIR"; make all)
chmod +x $BINDIR/*

mkdir -p /usr/local/bin
ln -s "$BINDIR/dirbak" /usr/local/bin/dirbak
ln -s "$BINDIR/rot" /usr/local/bin/rot
ln -s "$BINDIR/rwprot" /usr/local/bin/rwprot
ln -s "$BBXDIR/build/bbxwebd" /usr/local/bin/bbxwebd
ln -s "$BBXDIR/build/bbxdevd" /usr/local/bin/bbxdevd

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
