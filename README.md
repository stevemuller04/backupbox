# backupbox-daemon

Daemon that monitors the backup status on a Raspberry Pi and displays it using peripherals (LED, LCD screen).

## Install

```bash
make
cp build/bbxd /usr/local/bin/
ln -s bbxd.service /etc/systemd/system/bbxd.service && systemctl enable bbxd
```
