#!/bin/sh

###############################################################################
#
#                             install-full-node.sh
#
# This is the install script for Bitcoin full node based on Bitcoin Core.
#
# This script attempts to make your node automatically reachable by other nodes
# in the network. This is done by using uPnP to open port 8333 on your router
# to accept incoming connections to port 8333 and route the connections to your
# node running inside your local network.
#
# For security reason, wallet functionality is not enabled by default.
#
# Supported OS: Linux, Mac OS X, BSD, Windows (Windows Subsystem for Linux)
# Supported platforms: x86, x86_64, ARM
#
# Usage:
#   Open your terminal and type:
#
#     curl https://bitnodes.io/install-full-node.sh | sh
#
# Bitcoin Core will be installed using binaries provided by bitcoin.org.
#
# If the binaries for your system are not available, the installer will attempt
# to build and install Bitcoin Core from source.
#
# All files will be installed into $HOME/bitcoin-core directory. Layout of this
# directory after the installation is shown below:
#
# Source files:
#   $HOME/bitcoin-core/bitcoin/
#
# Binaries:
#   $HOME/bitcoin-core/bin/
#
# Configuration file:
#   $HOME/bitcoin-core/.bitcoin/bitcoin.conf
#
# Blockchain data files:
#   $HOME/bitcoin-core/.bitcoin/blocks
#   $HOME/bitcoin-core/.bitcoin/chainstate
#
# Need help? Contact ayeowch+bitnodes.io@gmail.com
#
###############################################################################

REPO_URL="https://github.com/bitcoin/bitcoin.git"

# See https://github.com/bitcoin/bitcoin/tags for latest version.
VERSION=24.0.1

TARGET_DIR=$HOME/bitcoin-core
PORT=8333

BUILD=0
UNINSTALL=0

BLUE='\033[94m'
GREEN='\033[32;1m'
YELLOW='\033[33;1m'
RED='\033[91;1m'
RESET='\033[0m'

ARCH=$(uname -m)
SYSTEM=$(uname -s)
MAKE="make"
if [ "$SYSTEM" = "FreeBSD" ]; then
    MAKE="gmake"
fi
SUDO=""

usage() {
    cat <<EOF

This is the install script for Bitcoin full node based on Bitcoin Core.

Usage: $0 [-h] [-v <version>] [-t <target_directory>] [-p <port>] [-b] [-u]

-h
    Print usage.

-v <version>
    Version of Bitcoin Core to install.
    Default: $VERSION

-t <target_directory>
    Target directory for source files and binaries.
    Default: $HOME/bitcoin-core

-p <port>
    Bitcoin Core listening port.
    Default: $PORT

-b
    Build and install Bitcoin Core from source.
    Default: $BUILD

-u
    Uninstall Bitcoin Core.

EOF
}

print_info() {
    printf "$BLUE$1$RESET\n"
}

print_success() {
    printf "$GREEN$1$RESET\n"
    sleep 1
}

print_warning() {
    printf "$YELLOW$1$RESET\n"
}

print_error() {
    printf "$RED$1$RESET\n"
    sleep 1
}

print_start() {
    print_info "Start date: $(date)"
}

print_end() {
    print_info "\nEnd date: $(date)"
}

print_readme() {
    cat <<EOF

# README - COMMANDS

Blockchain file folder:

    $EXTERNAL_FOLDER/.bitcoin

Command to stop Bitcoin Core:

    $HOME/bitcoin-core/bin/stop.sh
    or
    stop-btc

Command to start Bitcoin Core again:

    $HOME/bitcoin-core/bin/start.sh
    or
    start-btc

Command to view Bitcoin Core log file:

    $HOME/bitcoin-core/bin/debug.sh
    or
    debug-btc

    Type "ctrl+c" to exit debug

Command to view network information:

    $HOME/bitcoin-core/bin/get-net-info.sh
    or
    get-net-info

Command to view blockchain information:

    $HOME/bitcoin-core/bin/get-bc-info.sh
    or
    get-bc-info

EOF
}

program_exists() {
    type "$1" > /dev/null 2>&1
    return $?
}

create_target_dir() {
    if [ ! -d "$TARGET_DIR" ]; then
        print_info "\nCreating target directory: $TARGET_DIR"
        mkdir -p $TARGET_DIR
    fi
}

init_system_install() {
    if [ $(id -u) -ne 0 ]; then
        if program_exists "sudo"; then
            SUDO="sudo"
            print_info "\nInstalling required system packages..."
        else
            print_error "\nsudo program is required to install system packages. Please install sudo as root and rerun this script as normal user."
            exit 1
        fi
    fi
}

install_miniupnpc() {
    print_info "Installing miniupnpc from source..."
    rm -rf miniupnpc-2.0 miniupnpc-2.0.tar.gz &&
        wget -q http://miniupnp.free.fr/files/download.php?file=miniupnpc-2.0.tar.gz -O miniupnpc-2.0.tar.gz && \
        tar xzf miniupnpc-2.0.tar.gz && \
        cd miniupnpc-2.0 && \
        $SUDO $MAKE install > build.out 2>&1 && \
        cd .. && \
        rm -rf miniupnpc-2.0 miniupnpc-2.0.tar.gz
}

install_debian_build_dependencies() {
    $SUDO apt-get update
    $SUDO apt-get install -y \
        automake \
        autotools-dev \
        build-essential \
        curl \
        git \
        libboost-all-dev \
        libevent-dev \
        libminiupnpc-dev \
        libssl-dev \
        libtool \
        pkg-config
}

install_fedora_build_dependencies() {
    $SUDO dnf install -y \
        automake \
        boost-devel \
        curl \
        gcc-c++ \
        git \
        libevent-devel \
        libtool \
        miniupnpc-devel \
        openssl-devel
}

install_centos_build_dependencies() {
    $SUDO yum install -y \
        automake \
        boost-devel \
        curl \
        gcc-c++ \
        git \
        libevent-devel \
        libtool \
        openssl-devel
    install_miniupnpc
    echo '/usr/lib' | $SUDO tee /etc/ld.so.conf.d/miniupnpc-x86.conf > /dev/null && $SUDO ldconfig
}

install_archlinux_build_dependencies() {
    $SUDO pacman -S --noconfirm \
        automake \
        boost \
        curl \
        git \
        libevent \
        libtool \
        miniupnpc \
        openssl
}

install_alpine_build_dependencies() {
    $SUDO apk update
    $SUDO apk add \
        autoconf \
        automake \
        boost-dev \
        build-base \
        curl \
        git \
        libevent-dev \
        libtool \
        openssl-dev
    install_miniupnpc
}

install_mac_build_dependencies() {
    if ! program_exists "gcc"; then
        print_info "When the popup appears, click 'Install' to install the XCode Command Line Tools."
        xcode-select --install
    fi

    if ! program_exists "brew"; then
        /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    fi

    brew install \
        --c++11 \
        automake \
        boost \
        libevent \
        libtool \
        miniupnpc \
        openssl \
        pkg-config
}

install_freebsd_build_dependencies() {
    $SUDO pkg install -y \
        autoconf \
        automake \
        boost-libs \
        curl \
        git \
        gmake \
        libevent2 \
        libtool \
        openssl \
        pkgconf \
        wget
    install_miniupnpc
}

install_build_dependencies() {
    init_system_install
    case "$SYSTEM" in
        Linux)
            if program_exists "apt-get"; then
                install_debian_build_dependencies
            elif program_exists "dnf"; then
                install_fedora_build_dependencies
            elif program_exists "yum"; then
                install_centos_build_dependencies
            elif program_exists "pacman"; then
                install_archlinux_build_dependencies
            elif program_exists "apk"; then
                install_alpine_build_dependencies
            else
                print_error "\nSorry, your system is not supported by this installer."
                exit 1
            fi
            ;;
        Darwin)
            install_mac_build_dependencies
            ;;
        FreeBSD)
            install_freebsd_build_dependencies
            ;;
        *)
            print_error "\nSorry, your system is not supported by this installer."
            exit 1
            ;;
    esac
}

build_bitcoin_core() {
    cd $TARGET_DIR

    if [ ! -d "$TARGET_DIR/bitcoin" ]; then
        print_info "\nDownloading Bitcoin Core source files..."
        git clone --quiet $REPO_URL
    fi

    # Tune gcc to use less memory on single board computers.
    cxxflags=""
    if [ "$SYSTEM" = "Linux" ]; then
        ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
        if [ $ram_kb -lt 1500000 ]; then
            cxxflags="--param ggc-min-expand=1 --param ggc-min-heapsize=32768"
        fi
    fi

    print_info "\nBuilding Bitcoin Core v$VERSION"
    print_info "Build output: $TARGET_DIR/bitcoin/build.out"
    print_info "This can take up to an hour or more..."
    rm -f build.out
    cd bitcoin &&
        git fetch > build.out 2>&1 &&
        git checkout "v$VERSION" 1>> build.out 2>&1 &&
        git clean -f -d -x 1>> build.out 2>&1 &&
        ./autogen.sh 1>> build.out 2>&1 &&
        ./configure \
            CXXFLAGS="$cxxflags" \
            --without-gui \
            --with-miniupnpc \
            --disable-wallet \
            --disable-tests \
            --enable-upnp-default \
            1>> build.out 2>&1 &&
        $MAKE 1>> build.out 2>&1

    if [ ! -f "$TARGET_DIR/bitcoin/src/bitcoind" ]; then
        print_error "Build failed. See $TARGET_DIR/bitcoin/build.out"
        exit 1
    fi

    sleep 1

    $TARGET_DIR/bitcoin/src/bitcoind -? > /dev/null
    retcode=$?
    if [ $retcode -ne 1 ]; then
        print_error "Failed to execute $TARGET_DIR/bitcoin/src/bitcoind. See $TARGET_DIR/bitcoin/build.out"
        exit 1
    fi
}

get_bin_url() {
    url="https://bitcoincore.org/bin/bitcoin-core-$VERSION"
    case "$SYSTEM" in
        Linux)
            if program_exists "apk"; then
                echo ""
            elif [ "$ARCH" = "armv7l" ]; then
                url="$url/bitcoin-$VERSION-arm-linux-gnueabihf.tar.gz"
                echo "$url"
            else
                url="$url/bitcoin-$VERSION-$ARCH-linux-gnu.tar.gz"
                echo "$url"
            fi
            ;;
        Darwin)
            url="$url/bitcoin-$VERSION-osx64.tar.gz"
            echo "$url"
            ;;
        FreeBSD)
            echo ""
            ;;
        *)
            echo ""
            ;;
    esac
}

download_bin() {
    checksum_url="https://bitcoincore.org/bin/bitcoin-core-$VERSION/SHA256SUMS"

    cd $TARGET_DIR

    rm -f bitcoin-$VERSION.tar.gz checksum.asc

    print_info "\nDownloading Bitcoin Core binaries..."
    if program_exists "wget"; then
        wget -q --show-progress "$1" -O bitcoin-$VERSION.tar.gz &&
            wget -q "$checksum_url" -O checksum.asc &&
            mkdir -p bitcoin-$VERSION &&
            tar xzf bitcoin-$VERSION.tar.gz -C bitcoin-$VERSION --strip-components=1
    elif program_exists "curl"; then
        curl --progress-bar "$1" -o bitcoin-$VERSION.tar.gz &&
            curl -s "$checksum_url" -o checksum.asc &&
            mkdir -p bitcoin-$VERSION &&
            tar xzf bitcoin-$VERSION.tar.gz -C bitcoin-$VERSION --strip-components=1
    else
        print_error "\nwget or curl program is required to continue. Please install wget or curl as root and rerun this script as normal user."
        exit 1
    fi

    if program_exists "shasum"; then
        checksum=$(shasum -a 256 bitcoin-$VERSION.tar.gz | awk '{ print $1 }')
        if grep -q "$checksum" checksum.asc; then
            print_success "Checksum passed: bitcoin-$VERSION.tar.gz ($checksum)"
        else
            print_error "Checksum failed: bitcoin-$VERSION.tar.gz ($checksum). Please rerun this script to download and validate the binaries again."
            exit 1
        fi
    fi

    rm -f bitcoin-$VERSION.tar.gz checksum.asc
}

install_bitcoin_core() {
    cd $TARGET_DIR

    print_info "\nInstalling Bitcoin Core v$VERSION"

    if [ ! -d "$TARGET_DIR/bin" ]; then
        mkdir -p $TARGET_DIR/bin
    fi

    if [ ! -d "$TARGET_DIR/.bitcoin" ]; then
        mkdir -p $TARGET_DIR/.bitcoin
    fi

    if [ "$SYSTEM" = "Darwin" ]; then
        if [ ! -e "$HOME/Library/Application Support/Bitcoin" ]; then
            ln -s $TARGET_DIR/.bitcoin "$HOME/Library/Application Support/Bitcoin"
        fi
    else
        if [ ! -e "$HOME/.bitcoin" ]; then
            ln -s $TARGET_DIR/.bitcoin $HOME/.bitcoin
        fi
    fi

    if [ -f "$TARGET_DIR/bitcoin/src/bitcoind" ]; then
        # Install compiled binaries.
        cp "$TARGET_DIR/bitcoin/src/bitcoind" "$TARGET_DIR/bin/" &&
            cp "$TARGET_DIR/bitcoin/src/bitcoin-cli" "$TARGET_DIR/bin/" &&
            print_success "Bitcoin Core v$VERSION (compiled) installed successfully!"
    elif [ -f "$TARGET_DIR/bitcoin-$VERSION/bin/bitcoind" ]; then
        # Install downloaded binaries.
        cp "$TARGET_DIR/bitcoin-$VERSION/bin/bitcoind" "$TARGET_DIR/bin/" &&
            cp "$TARGET_DIR/bitcoin-$VERSION/bin/bitcoin-cli" "$TARGET_DIR/bin/" &&
                rm -rf "$TARGET_DIR/bitcoin-$VERSION"
            print_success "Bitcoin Core v$VERSION (binaries) installed successfully!"
    else
        print_error "Cannot find files to install."
        exit 1
    fi

    cat > $TARGET_DIR/.bitcoin/bitcoin.conf <<EOF
### IPv4/IPv6 mode ###
# This mode requires uPnP feature on your router to allow Bitcoin Core to accept incoming connections.
bind=0.0.0.0
upnp=1

### Tor mode ###
# This mode requires tor (https://www.torproject.org/download/) to be running at the proxy address below.
# No configuration is needed on your router to allow Bitcoin Core to accept incoming connections.
#proxy=127.0.0.1:9050
#bind=127.0.0.1
#onlynet=onion

listen=1
port=$PORT
maxconnections=64

dbcache=64
par=2
checkblocks=24
checklevel=0

disablewallet=1
server=1

datadir=$TARGET_DIR/.bitcoin
daemon=1

rpccookiefile=$TARGET_DIR/.bitcoin/.cookie
rpcbind=127.0.0.1
rpcport=8332
rpcallowip=127.0.0.1
EOF
    chmod go-rw $TARGET_DIR/.bitcoin/bitcoin.conf

    cat > $TARGET_DIR/bin/start.sh <<EOF
#!/bin/sh
if [ -f $TARGET_DIR/bin/bitcoind ]; then
    $TARGET_DIR/bin/bitcoind -conf=$TARGET_DIR/.bitcoin/bitcoin.conf
fi
EOF
    chmod ugo+x $TARGET_DIR/bin/start.sh

    cat > $TARGET_DIR/bin/stop.sh <<EOF
#!/bin/sh
if [ -f $TARGET_DIR/.bitcoin/bitcoind.pid ]; then
    kill \$(cat $TARGET_DIR/.bitcoin/bitcoind.pid)
fi
EOF
    chmod ugo+x $TARGET_DIR/bin/stop.sh

    cat > $TARGET_DIR/bin/get-net-info.sh <<EOF
#!/bin/sh
$TARGET_DIR/bin/bitcoin-cli -conf=$TARGET_DIR/.bitcoin/bitcoin.conf getnetworkinfo
EOF

    chmod ugo+x $TARGET_DIR/bin/get-net-info.sh
}

start_bitcoin_core() {
    if [ ! -f $TARGET_DIR/.bitcoin/bitcoind.pid ]; then
        print_info "\nChecking if Bitcoin Core can start."
        #print_info "\nStarting Bitcoin Core..."
        cd $TARGET_DIR/bin && ./start.sh

        timer=0
        until [ -f $TARGET_DIR/.bitcoin/bitcoind.pid ] || [ $timer -eq 5 ]; do
            timer=$((timer + 1))
            sleep $timer
        done

        if [ -f $TARGET_DIR/.bitcoin/bitcoind.pid ]; then
            print_success "OK! Bitcoin Core can run! Continuing..."
        else
            print_error "Failed to start Bitcoin Core."
            exit 1
        fi
    fi
}

start_bitcoin_core_external() {
    if [ ! -f $EXTERNAL_FOLDER/.bitcoin/bitcoind.pid ]; then
        print_info "\nStarting Bitcoin Core..."
        $HOME/bitcoin-core/bin/start.sh

        timer=0
        until [ -f $EXTERNAL_FOLDER/.bitcoin/bitcoind.pid ] || [ $timer -eq 5 ]; do
            timer=$((timer + 1))
            sleep $timer
        done

        if [ -f $EXTERNAL_FOLDER/.bitcoin/bitcoind.pid ]; then
            print_success "Bitcoin Core is running!"
        else
            print_error "Failed to start Bitcoin Core: could not create current running instance file (bitcoind.pid) on external folder."
            exit 1
        fi
    fi
}

stop_bitcoin_core() {
    if [ -f $TARGET_DIR/.bitcoin/bitcoind.pid ]; then
        #print_info "\nStopping Bitcoin Core..."
        cd $TARGET_DIR/bin && ./stop.sh

        timer=0
        until [ ! -f $TARGET_DIR/.bitcoin/bitcoind.pid ] || [ $timer -eq 120 ]; do
            timer=$((timer + 1))
            sleep $timer
        done

        if [ ! -f $TARGET_DIR/.bitcoin/bitcoind.pid ]; then
            #print_success "Bitcoin Core stopped."
            echo ""
        else
            print_error "Failed to stop Bitcoin Core."
            exit 1
        fi
    fi
}

check_bitcoin_core() {
    if [ -f $TARGET_DIR/.bitcoin/bitcoind.pid ]; then
        if [ -f $TARGET_DIR/bin/bitcoin-cli ]; then
            print_info "\nChecking Bitcoin Core..."
            $TARGET_DIR/bin/get-net-info.sh
        fi

        reachable=$(curl -I https://bitnodes.io/api/v1/nodes/me-$PORT/ 2> /dev/null | head -n 1 | cut -d ' ' -f2)
        if [ $reachable -eq 200 ]; then
            print_success "Bitcoin Core is accepting incoming connections at port $PORT!"
        else
            print_warning "Bitcoin Core is NOT accepting incoming connections at port $PORT. You may need to configure port forwarding (https://bitcoin.org/en/full-node#port-forwarding) on your router."
        fi
    fi
}

uninstall_bitcoin_core() {
    stop_bitcoin_core

    if [ -d "$TARGET_DIR" ]; then
        print_info "\nUninstalling Bitcoin Core..."
        rm -rf $TARGET_DIR

        # Remove stale symlink.
        if [ "$SYSTEM" = "Darwin" ]; then
            if [ -L "$HOME/Library/Application Support/Bitcoin" ] && [ ! -d "$HOME/Library/Application Support/Bitcoin" ]; then
                rm "$HOME/Library/Application Support/Bitcoin"
            fi
        else
            if [ -L $HOME/.bitcoin ] && [ ! -d $HOME/.bitcoin ]; then
                rm $HOME/.bitcoin
            fi
        fi

        if [ ! -d "$TARGET_DIR" ]; then
            print_success "Bitcoin Core uninstalled successfully!"
        else
            print_error "Uninstallation failed. Is Bitcoin Core still running?"
            exit 1
        fi
    else
        print_error "Bitcoin Core not installed."
    fi
}

probe_external_usb() {
    EXTERNAL_FOLDER=$(mount | grep /mnt/media_rw | cut -d ' ' -f 3);
    if [ -z "$EXTERNAL_FOLDER" ]
    then
        print_warning "\nThe external USB drive is not where it was intended to be."
        print_info "\nSeeking for external USB drive on the whole system. Be sure to have a file named \"usb-hook\" in your drive. Operation can take few minutes..."
        EXTERNAL_FOLDER=$(find / -type f -name "usb-hook" 2>/dev/null  | sed 's@/usb-hook@@g')
        if [ -z "$EXTERNAL_FOLDER" ]
        then
            print_error "\nCan't find external USB drive."
            exit 1
        else
            print_info "\nExternal USB drive found: $EXTERNAL_FOLDER"
        fi
    else
        print_info "\nExternal USB drive found: $EXTERNAL_FOLDER"
    fi
}

move_to_external() {
    mv $HOME/bitcoin-core/.bitcoin/bitcoin.conf ..

    if [ -d "$EXTERNAL_FOLDER/.bitcoin" ]
    then
        print_info "\nBlockchain data found. Continuing from last block..."

        rm -rf $HOME/bitcoin-core/.bitcoin/*
    else
        mv $HOME/bitcoin-core/.bitcoin $EXTERNAL_FOLDER/
    fi

    mv $HOME/bitcoin-core/bitcoin.conf $HOME/bitcoin-core/.bitcoin/

    sed -i "s+datadir=$TARGET_DIR/.bitcoin+datadir=$EXTERNAL_FOLDER/.bitcoin+g" $HOME/.bitcoin/bitcoin.conf
    sed -i "s+rpccookiefile=$TARGET_DIR/.bitcoin+rpccookiefile=$EXTERNAL_FOLDER/.bitcoin+g" $HOME/.bitcoin/bitcoin.conf
}

create_commands() {
    cp $HOME/bitcoin-core/bin/start.sh $HOME/bitcoin-core/bin/start.sh_bkp
    cp $HOME/bitcoin-core/bin/stop.sh $HOME/bitcoin-core/bin/stop.sh_bkp

    sed -i "s+/root/bitcoin-core/.bitcoin+$EXTERNAL_FOLDER/.bitcoin+g" $HOME/bitcoin-core/bin/start.sh
    sed -i "s+/root/bitcoin-core/.bitcoin+$EXTERNAL_FOLDER/.bitcoin+g" $HOME/bitcoin-core/bin/stop.sh
    sed -i "s+/root/bitcoin-core/.bitcoin+$EXTERNAL_FOLDER/.bitcoin+g" $HOME/bitcoin-core/bin/get-net-info.sh

    cat > $HOME/bitcoin-core/bin/debug.sh <<EOF
#!/bin/sh
tail -f $EXTERNAL_FOLDER/.bitcoin/debug.log
EOF

    chmod ugo+x $HOME/bitcoin-core/bin/debug.sh

    cat > $HOME/bitcoin-core/bin/get-bc-info.sh <<EOF
#!/bin/sh
$HOME/bitcoin-core/bin/bitcoin-cli -conf=$EXTERNAL_FOLDER/.bitcoin/bitcoin.conf getblockchaininfo
EOF

    chmod ugo+x $HOME/bitcoin-core/bin/get-bc-info.sh

    cp $HOME/bitcoin-core/bin/start.sh /usr/local/bin/start-btc
    cp $HOME/bitcoin-core/bin/stop.sh /usr/local/bin/stop-btc
    cp $HOME/bitcoin-core/bin/debug.sh /usr/local/bin/debug-btc
    cp $HOME/bitcoin-core/bin/get-net-info.sh /usr/local/bin/get-net-info
    cp $HOME/bitcoin-core/bin/get-bc-info.sh /usr/local/bin/get-bc-info
}


while getopts ":v:t:p:bu" opt
do
    case "$opt" in
        v)
            VERSION=${OPTARG}
            ;;
        t)
            TARGET_DIR=${OPTARG}
            ;;
        p)
            PORT=${OPTARG}
            ;;
        b)
            BUILD=1
            ;;
        u)
            UNINSTALL=1
            ;;
        h)
            usage
            exit 0
            ;;
        ?)
            usage >& 2
            exit 1
            ;;
    esac
done

WELCOME_TEXT=$(cat <<EOF

Welcome!

You are about to install a Bitcoin full node based on Bitcoin Core v$VERSION.

Bitcoin Core files will be installed under $TARGET_DIR directory.

Blockchain files will be instaled under:
$EXTERNAL_FOLDER/.bitcoin

Your node will be configured to accept incoming connections from other nodes in
the Bitcoin network by using uPnP feature on your router.

For security reason, wallet functionality is not enabled by default.

After the installation, it may take several hours for your node to download a
full copy of the blockchain.

If you wish to uninstall Bitcoin Core later, you can download this script and
run "sh install-full-node.sh -u" or run this shortcut command
"sh <( curl -Ls https://bitnodes.io/install-full-node.sh ) -u"

EOF
)

print_start

if [ $UNINSTALL -eq 1 ]; then
    echo
    read -p "WARNING: This will stop Bitcoin Core and uninstall it from your system. Uninstall? (y/n) " answer
    if [ "$answer" = "y" ]; then
        uninstall_bitcoin_core
    fi
else
    echo "$WELCOME_TEXT"
    probe_external_usb
    if [ -t 0 ]; then
        # Prompt for confirmation when invoked in tty.
        echo
        read -p "Install? (y/n) " answer
    else
        # Continue installation when invoked via pipe, e.g. curl .. | sh
        answer="y"
        echo
        echo "Starting installation in 15 seconds..."
        sleep 15
    fi
    if [ "$answer" = "y" ]; then
        if [ "$BUILD" -eq 0 ]; then
            bin_url=$(get_bin_url)
        else
            bin_url=""
        fi
        stop_bitcoin_core
        create_target_dir
        if [ "$bin_url" != "" ]; then
            download_bin "$bin_url"
        else
            install_build_dependencies && build_bitcoin_core
        fi
        install_bitcoin_core && start_bitcoin_core && check_bitcoin_core
        print_readme > $TARGET_DIR/README.md
        #cat $TARGET_DIR/README.md
        #print_success "\nInstallation completed!"
        stop_bitcoin_core
        echo "Customizing Bitcoin Core for Android with External Drive in 5 seconds..."
        sleep 5
        move_to_external
        create_commands
        start_bitcoin_core_external
        cat $TARGET_DIR/README.md
        print_success "\nIf this is your first install, Bitcoin Core may take several hours/days to download a full copy of the blockchain."
        print_success "\nInstallation completed!"
    fi
fi

print_end
