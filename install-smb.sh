#!/bin/bash

cp /etc/samba/smb.conf /etc/samba/smb.conf.bak
sed -n '/=== Share Definitions ===/q;p' /etc/samba/smb.conf.bak > /etc/samba/smb.conf

cat << EOF >> /etc/samba/smb.conf
security = user
follow symlinks = no
load printers = no
printing = bsd
printcap name = /dev/null
disable spoolss = yes
socket options = TCP_NODELAY
strict locking = no
veto files = /._*/.apdisk/.AppleDouble/.DS_Store/.TemporaryItems/.Trashes/desktop.ini/ehthumbs.db/Network Trash Folder/Temporary Items/Thumbs.db/
delete veto files = yes
map to guest = never

include = /etc/samba/shares.conf
EOF

cat << EOF > /etc/samba/shares.conf
[backup]
path = /mnt/bbx-disk/live
browseable = yes
read only = no
writeable = yes
create mask = 0770
force create mode = 0770
directory mask = 2770
force directory mode = 2770
guest ok = no
valid users = @backupusers
EOF

addgroup backupusers
adduser --shell /bin/false --disabled-password --gecos --disabled-login backup0
adduser backup0 backupusers
smbpasswd -a backup0

systemctl restart smbd
