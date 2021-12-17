#!/bin/sh

group_id=${GROUP_ID:-30}
group_name=${GROUP_NAME:-hardware}
user_id=${USER_ID:-39277}
user_name=${USER_NAME:-rdubtsov}
user_shell=${USER_SHELL:-/bin/bash}
skip_su="${SKIP_SU:-0}"

echo "${user_name}:123:${user_id}:${group_id}:${user_id}:/home/${user_name}:${user_shell}" >> /etc/passwd
echo "${group_name}:x:${group_id}:${user_name}" >> /etc/group
sed -i -e '/^sudo/s/:[^:]*$/:rdubtsov/' /etc/group

export TMPDIR=/local/rdubtsov/tmp
export TEMPDIR=/local/rdubtsov/tmp

if test -f /etc/os-release; then
    eval $(cat /etc/os-release | grep 'ID=')
else
    ID=unknown
fi

if test "$ID" = "ubuntu"; then
    apt-get update
    apt-get install -y sudo
    echo >> /etc/sudoers
    echo '%sudo   ALL=(ALL:ALL) NOPASSWD:ALL' >> /etc/sudoers
fi

if test -x /usr/bin/bash -a '!' -x /bin/bash; then
    ln -sf /usr/bin/bash /bin/bash
fi

if test "$skip_su" = "1"; then
    exec /bin/bash "$@"
else
    exec su -s ${user_shell} -l ${user_name} "$@"
fi
