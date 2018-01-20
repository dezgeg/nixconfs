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
    eval "$@"
}

packageListToAttrParams() {
    echo -n "-E 'with import ./nixpkgs { system = \"${arch}l-linux\"; }; [ "
    for attr in $(cat "$@" | sed -e 's/#.*$//g'); do
        echo -n "$attr.all "
    done
    echo -n "]'"
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
echo "$(git rev-list --count HEAD).$(git rev-parse HEAD | cut -c 1-10)" > svn-revision

cd $HOME/arm-builder
trace rsync --exclude .git -a --delete nixpkgs.git/ nixpkgs/

##### Build packages
instopts="--keep-going --fallback --show-trace"
nixopts="$instopts --no-out-link --option use-binary-caches false"
export NIXPKGS_ALLOW_UNFREE=1

# ARMv6 hack
if [ "$arch" = armv6 ]; then
    cmd="nix-instantiate $instopts $(packageListToAttrParams $confDir/packages-impure.txt)"
    drvs=$(trace "$cmd" | sed -e 's/!.*$//' | tr '\n' ' ')
    trace sudo nix-copy-closure --to root@raspi $drvs
    outputs=$(trace ssh raspi "sudo nix-store -r $drvs --option signed-binary-caches 0 --fallback -j1")
    if [ -z "$outputs" ]; then
        echo "Impure build failed."
        exit 1
    fi
    trace "sudo nix-copy-closure --from root@raspi --include-outputs $drvs $outputs"
fi

if [ "$target" != images ]; then
    cmd="nix-build --timeout 28800 $nixopts $(packageListToAttrParams $confDir/packages.txt $confDir/packages-$arch.txt)"
    set +e
    closure=$(trace "$cmd")
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
        trace "nix-build $nixopts ./nixpkgs -A ubootRaspberryPi >> installer-closure"
    else
        conf='nixpkgs/nixos/modules/installer/cd-dvd/sd-image-armv7l-multiplatform.nix'
        trace "nix-build $nixopts $(packageListToAttrParams $confDir/packages-uboots.txt)" >> installer-closure
    fi
    trace "nix-build --timeout 28800 -I nixpkgs=./nixpkgs -I nixos-config=$conf '<nixpkgs/nixos>' $nixopts --argstr system ${arch}l-linux -A config.system.build.sdImage" >> installer-closure

    for f in $(find $(cat installer-closure) -type f); do
        trace "sudo ln $f installer/$(cleanName $f)"
    done

    for host in jetson pcduino; do
        trace "ssh $host 'sudo nix-store --delete --ignore-liveness /nix/store/*.img' >&2" || true
    done
fi
