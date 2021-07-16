#!/bin/bash

apt update && apt install samba

./install-disk.sh
./install-bbx.sh
./install-smb.sh
