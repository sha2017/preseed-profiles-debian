in-target mkdir -p /target/root/.ssh
in-target wget -O /root/.ssh/authorized_keys https://raw.githubusercontent.com/sha2017/preseed-profiles-debian/master/files/sshkeys.pub
in-target chmod -R go-rwx /target/root/.ssh
