# smartino

Bash scripts for installing Bitcoin Core on Android device and run a full node!  

That's possible because:
- you can run Ubuntu (or other distro) in your Android phone thanks to [Andronix](https://andronix.app)
- you can attach an external drive to the phone using a Type-c USB hub

Installation process is based on the process described in [this tutorial](https://bitbrasil.com.br/node-android-external-drive.html) (found [here](https://portaldobitcoin.uol.com.br/brazilian-teaches-how-to-run-a-full-bitcoin-node-on-an-android-smartphone-tutorial)), which in turn is a modified version of [BitNodes.io scripts](https://bitnodes.io/install-full-node.sh).

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
- Root privileges (otherwise you can use the original guide that works only with old Samsung phones having [DeX](https://en.wikipedia.org/wiki/Samsung_DeX) support)
- 1 TB external USB drive
- One or more USB adapters to have both power and external drive attached to the phone
- Not more than one external drive connected to the phone

Installation
-
- Connect the external drive to the phone and be sure you can open it with a file explorer
- Install the latest version of [Termux](https://f-droid.org/en/packages/com.termux)
- Check if you can access the external drive within Termux, otherwise you have to root the phone
- Run the following command (it will basically install Ubuntu on your phone)
```
pkg upgrade && termux-setup-storage && curl https://raw.githubusercontent.com/AndronixApp/AndronixOrigin/master/repo-fix.sh > repo.sh && chmod +x repo.sh && bash repo.sh && pkg update -y && pkg install wget curl proot tar -y && wget https://raw.githubusercontent.com/smartm0use/smartino/main/ubuntu20.sh -O ubuntu20.sh && chmod +x ubuntu20.sh && bash ubuntu20.sh
```
- Be sure you got no errors in mounting external drive, then run the following command from Ubuntu shell (it will install Bitcoin Core and it will set the `datadir` to the external drive):
```
apt-get update && apt-get upgrade -y && apt install curl -y && curl https://raw.githubusercontent.com/smartm0use/smartino/main/install-full-node.sh | sh
```
