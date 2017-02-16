#!/usr/bin/env bash
set -e

# Usage: arm-builder.sh -a (armv6|armv7) -r (own|master|unstable) -t (build|images|channel)

##### Initialization and parameter parsing

repo=own
arch=armv7
target=build

while getopts "a:r:t:" opt; do
    case "$opt" in
        a)
            arch=$OPTARG
            ;;
        r)
            repo=$OPTARG
            ;;
        t)
            target=$OPTARG
            ;;
        *)
            echo "Unknown option" >&2
            exit 1
    esac
done

cleanName() {
    # Strip /nix/store + hash part
    echo "$(readlink -f "$1")" | cut -c45- | tr '/' '_'
}

trace() {
    echo "+ $@" >&2
    "$@"
}

##### Initial git cloning

confDir=$(readlink -f $(dirname $0)/..)
mkdir -p $HOME/arm-builder

if [ ! -d $HOME/arm-builder/nixpkgs.git ]; then
    (
        cd $HOME/arm-builder
        trace git clone https://github.com/NixOS/nixpkgs.git nixpkgs.git
    )
fi

##### Git fetch

cd $HOME/arm-builder/nixpkgs.git
if [ "$repo" = own ]; then
    trace git fetch https://github.com/dezgeg/nixpkgs.git arm-work
elif [ "$repo" = master ]; then
    trace git fetch https://github.com/NixOS/nixpkgs.git master
elif [ "$repo" = unstable ]; then
    trace git fetch https://github.com/NixOS/nixpkgs-channels nixos-unstable
else
    echo "Bad repo: $repo" >&2
    exit 1
fi

trace git reset --hard FETCH_HEAD -q
echo -n "$(NIX_PATH=nixpkgs=. bash nixos/modules/installer/tools/get-version-suffix)" > .version-suffix
echo -n "$(git rev-parse HEAD)" > .git-revision

cd $HOME/arm-builder
trace rsync --exclude .git -a --delete nixpkgs.git/ nixpkgs/

cd $HOME/arm-builder/nixpkgs
##### Prepare build slaves

#trace ssh jetson 'nix-store --gc --print-live' | trace sudo xargs nix-copy-closure --from root@jetson
#trace ssh jetson 'nix-store --gc --print-dead' | trace sudo xargs nix-copy-closure --from root@jetson

##### Build packages
instopts="--keep-going --fallback --show-trace --argstr system ${arch}l-linux"
nixopts="$instopts --no-out-link --option use-binary-caches false"
export NIXPKGS_ALLOW_UNFREE=1

# ARMv6 hack
if [ "$arch" = armv6 ]; then
    #trace nix-build $nixopts -A stdenv.all >/dev/null
    #drvs=$(trace nix-instantiate $instopts -A openssl -A openssl_1_0_1 -A openssl_1_0_2 -A nix -A nixStable | tr '\n' ' ')

    cmd="nix-instantiate $instopts"
    for attr in $(cat $confDir/packages-impure.txt 2>/dev/null | sed -e 's/#.*$//g'); do
        cmd="$cmd -A ${attr}.all"
    done
    drvs=$(trace $cmd | sed -e 's/!.*$//' | tr '\n' ' ')
    trace sudo nix-copy-closure --to root@raspi $drvs
    outputs=$(trace ssh raspi "sudo nix-store -r $drvs --option signed-binary-caches 0 --fallback -j1")
    if [ -z "$outputs" ]; then
        echo "Impure build failed."
        exit 1
    fi
    trace sudo nix-copy-closure --from root@raspi --include-outputs $drvs $outputs
fi

if [ "$target" != images ]; then

    cmd="nix-build --timeout 14400 $nixopts"
    for attr in $(cat $confDir/packages.txt $confDir/packages-$arch.txt 2>/dev/null | sed -e 's/#.*$//g'); do
        cmd="$cmd -A ${attr}.all"
    done
    set +e
    closure=$(NIXPKGS_ALLOW_UNFREE=1 trace $cmd)
    set -e
    echo 'Package build done.'
fi

##### Finally, build the channel or install artifacts

cd $HOME/arm-builder
if [ "$target" = channel ]; then
    sudo rm -rf channel
    trace sudo nix-push --dest channel --link --key-file $HOME/nixos-configs/keypair.priv $closure # Need sudo to create hard links
elif [ "$target" = images ]; then
    rm -rf installer installer-closure
    mkdir -p installer

    if [ "$arch" = armv6 ]; then
        conf='nixpkgs/nixos/modules/installer/cd-dvd/sd-image-raspberrypi.nix'
        trace nix-build ./nixpkgs $nixopts -A ubootRaspberryPi >> installer-closure
    else
        conf='nixpkgs/nixos/modules/installer/cd-dvd/sd-image-armv7l-multiplatform.nix'
        trace nix-build ./nixpkgs $nixopts -A ubootBananaPi -A ubootBeagleboneBlack -A ubootJetsonTK1 -A ubootPcduino3Nano -A ubootRaspberryPi2 -A ubootRaspberryPi3_32bit -A ubootWandboard >> installer-closure
    fi

    trace nix-build --timeout 14400 -I nixpkgs=./nixpkgs -I nixos-config="$conf" '<nixpkgs/nixos>' $nixopts -A config.system.build.sdImage >> installer-closure
    for f in $(find $(cat installer-closure) -type f); do
        trace sudo ln $f installer/$(cleanName $f)
    done

    for host in jetson pcduino; do
        trace ssh $host 'sudo nix-store --delete --ignore-liveness /nix/store/*.img' >&2 || true
    done
fi
