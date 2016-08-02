in-target echo "Starting Bootstrap process." >> /root/bootstrap.log
in-target mkdir --mode=700 -p /target/root/.ssh
in-target echo " .ssh Directory Created." >> /root/bootstrap.log
in-target wget -O /root/.ssh/authorized_keys https://raw.githubusercontent.com/sha2017/preseed-profiles-debian/master/files/sshkeys.pub
in-target echo "Public SSH keys downloaded." >> /root/bootstrap.log

