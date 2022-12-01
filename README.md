# smartino
Android Bitcoin Core Full Node

Bash scripts for installing Bitcoin Core on Android device and run a full node!  
Based on the process described in [this tutorial](https://bitbrasil.com.br/node-android-external-drive.html) (found [here](https://portaldobitcoin.uol.com.br/brazilian-teaches-how-to-run-a-full-bitcoin-node-on-an-android-smartphone-tutorial)), which in turn is a modified version of [BitNodes.io scripts](https://bitnodes.io/install-full-node.sh).

Some enhancements:
- Added a more reliable probing strategy for detecting external drive
- *Added the ability of connecting external drive having already blockchain data (".bitcoin" folder)
- Harden the externalization of Bitcoin Core configuration file
- Updated Bitcoin Core version to 24.0
- Added a couple of shortcut commands
- Fixed some typos in comments and messages
- Some other small improvements

**It may be not recognized by Android. Please consider that Android supports exFAT/NTFS/EXT4/F2FS partitions up to version 8.1 (Oreo)*

Requirements
-
- Android phone with OTG support
- Root privileges (otherwise you can use the original guide that works only with old Samsung phones with [DeX](https://en.wikipedia.org/wiki/Samsung_DeX) support)
- 1 TB external USB drive ()
- One or more USB adapters to have both power and external drive attached to the phone
- Not more than one external drive connected to the phone

Installation
-
You can basically follow the original guide (you can find an offline copy in this repository), just replace the two commands with these ones:

```
pkg upgrade && termux-setup-storage && curl https://raw.githubusercontent.com/AndronixApp/AndronixOrigin/master/repo-fix.sh > repo.sh && chmod +x repo.sh && bash repo.sh && pkg update -y && pkg install tsu wget curl proot tar -y && wget https://raw.githubusercontent.com/smartm0use/smartino/main/ubuntu20.sh -O ubuntu20.sh && chmod +x ubuntu20.sh && bash ubuntu20.sh
```

```
apt-get update && apt-get upgrade -y && apt install curl -y && curl https://raw.githubusercontent.com/smartm0use/smartino/main/install-full-node.sh | sh
```
