#!/bin/bash

mkdir -p /mnt/bbx-disk
chattr +i /mnt/bbx-disk # don't allow creating files in this directory, not even root
echo '/dev/sda1 /mnt/bbx-disk ext4 defaults,nofail 0 0' >> /etc/fstab
mount -a
