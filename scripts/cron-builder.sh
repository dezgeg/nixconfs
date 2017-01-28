#!/usr/bin/env bash

umask 022
mkdir -p "$HOME/arm-builder/stamps"

if [ -f $HOME/arm-builder/lock ]; then
    [ -t 1 ] && echo "Build lock taken, exiting"
    exit 1
fi
trap "rm -f $HOME/arm-builder/lock" EXIT
touch $HOME/arm-builder/lock

rm -f /tmp/cron-builder-*.log
[ -t 1 ] && echo "Building..."

trace() {
    echo "+ $@" >&2
    "$@"
}

check() {
    local arch="$1"
    local target="$2"
    local repo="$3"
    local interval="$4"

    local triple="$arch-$target-$repo"
    local file="$HOME/arm-builder/stamps/$triple.stamp"

    if ! [ -f "$file" ]; then
        touch "$file";
        age=9999999999
    else
        age=$(( $(date +%s) - $(date -r "$file" +%s) ))
    fi

    if [ "$age" -gt $(( $interval * 60 * 60 )) ]; then
        local log="/tmp/cron-builder-$$_$triple.log"
        if [ ! -t 1 ]; then
            exec >>$log 2>>$log
        fi

        echo "Age of $triple $age passed (interval = $interval hours)"
        if [ "$target" = gc ]; then
            trace ssh kbuilder.dezgeg.me "sudo nix-store --clear-failed-paths '*'"
            #for host in jetson pcduino raspi; do
            for host in jetson; do
                trace ssh kbuilder.dezgeg.me "ssh $host 'sudo nix-collect-garbage'"
                trace ssh kbuilder.dezgeg.me "ssh $host 'sudo nix-store --clear-failed-paths \"*\"'"
            done
        else
            trace ssh kbuilder.dezgeg.me "time ~/nixos-configs/scripts/arm-builder.sh -a $arch -r $repo -t $target"
        fi

        if [ "$target" = channel ]; then
            time (
                echo 'Syncing NARs'
                rsync 'kbuilder.dezgeg.me:arm-builder/channel/*.nar.xz' --chmod F644 ~/cshome/public_html/nixos-arm/channel
                find ~/cshome/public_html/nixos-arm/channel/ -name '*.nar.xz' | xargs chmod 644

                echo 'Syncing narinfos'
                rsync 'kbuilder.dezgeg.me:arm-builder/channel/*.narinfo' --chmod F644 ~/cshome/public_html/nixos-arm/channel
                find ~/cshome/public_html/nixos-arm/channel/ -name '*.narinfo' | xargs chmod 644
            )
        elif [ "$target" = images ]; then
            trace mkdir -p ~/cshome/installer-temp/$arch/
            time trace rsync -rd --delete kbuilder.dezgeg.me:arm-builder/installer/* --chmod F644 ~/cshome/installer-temp/$arch/

            trace rm -rf ~/cshome/public_html/nixos-arm/installer
            trace mkdir -p ~/cshome/public_html/nixos-arm/installer
            trace cp -al ~/cshome/installer-temp/armv*/* ~/cshome/public_html/nixos-arm/installer/
            (
                cd ~/cshome/public_html/nixos-arm/installer
                ls | grep -v SHA256SUMS | xargs sha256sum -b > .shasums.tmp
                chmod 644 .shasums.tmp
                mv -f .shasums.tmp SHA256SUMS
            )
        fi

        touch "$file"
        if [ ! -t 1 ]; then
            if [ "$target" != build ]; then
                cat -v $log | mail -s "Cron build of $triple on $(date)" dezgeg@gmail.com
            fi
            rm -f $log
        fi
    fi
}

# ARMv7 master
check armv7 build   master 1
check armv7 channel master 12

# ARMv7 unstable
check armv7 build   unstable 1
check armv7 channel unstable 4
check armv7 images  unstable 48

check all gc all 24

# ARMv6 master
#check armv6 build   master 2
check armv6 channel master 12

# ARMv6 unstable
check armv6 channel unstable 48
check armv6 images  unstable 96

check all gc all 24
