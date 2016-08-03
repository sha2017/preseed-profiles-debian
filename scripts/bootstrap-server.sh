#!/bin/bash

echo "Post install started on `date`" > /root/manifest

echo "* Installing SSH Keys..." >> /root/manifest
mkdir --mode=700 -p /root/.ssh
wget -O /root/.ssh/authorized_keys https://raw.githubusercontent.com/sha2017/preseed-profiles-debian/master/files/sshkeys.pub
chmod -R 700 /root/.ssh/

echo "Post install completed on `date`" >> /root/manifest




exit 0
