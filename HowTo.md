Simplified Mini-HowTo
=====================

This is an addendum to the SolidRun [README.md](README.md) focusing on the
CEx7 CN9132 EVK and creating a reproducible build.


Building
--------

To build you need to have your GIT identity set up in `~/.gitconfig`:

    if [ ! -e ~/.gitconfig ]; then \
        echo "[user]"                    > ~/.gitconfig; \
        echo "name  = John Doe"         >> ~/.gitconfig; \
        echo "email = user@example.com" >> ~/.gitconfig; \
    fi

Now you can start your first build, notice the script arguments to select
the CEx7 CN9132 EVK.  See the script comments for more information:

    ./run-docker.sh

If needed indivitual steps can be run by listing them.

    ./run-docker.sh linux-menuconfig linux rootfs sdcard


> **Note:** There is no safe support for cleaning or restarting a build
> with some changes.  To be 100% sure of your changes taking effect,
> remove the `build/` directory.  YMMV. Usually works fine.

Gotchas
-------

You **MUST** change SW2 to boot from SD card:

    SW2:  10110X

> Beware, the DIP switches are fidgety and may easily get worn so that
> they slide out of their positions when you lift the board (to change
> SD card) :-/


Booting
-------

First boot is important!  Abort U-Boot to get a prompt so we can change
the default device tree for our board:

    Marvell>> setenv fdtfile marvell/cn9132-cex7.dtb
    Marvell>> saveenv

Resume the boot by manually calling the `bootcmd` to launch Linux:

    Marvell>> run bootcmd


Ubuntu Checklist
----------------

When booting up the board, we get a custom built kernel and unconfigured
ubuntu-core.  Meaning pretty much nothing is set up for us.  Here's a
checklist to get started:

  * [ ] Change `/etc/hostname`
  * [ ] Call `depmod` so the `modprobe` tool works, takes a bit of time
  * [ ] Set up basic networking, use left-most Ethernet port (eth1).  We
        have no editor yet, so we use a HERE script:
  
        cat <<EOF >/etc/network/interfaces.d/eth1
        auto eth1
        iface eth1 inet dhcp
        EOF
        ifup eth1

    You should get an IP address in the 172.21.104.0/24 range.  Check
	with the `ifconfig eth1` command.
  * [ ] For easier access during set up, allow root SSH logins:
  
        echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
        systemctl restart sshd

  * [ ] You can now log in to the board using SSH from your laptop:
  
        $ ssh root@172.21.104.58
  
  * [ ] Resize file system to fit the SD card:
  * [ ] Carefully wake up the package manager:
  
        apt update
        apt install -y dialog
        apt dist-upgrade

  * [ ] Add other useful tools:

        apt install -y nano vim mg nftables wireguard-tools

> **Note:** if the serial console gets garbled during any of the above
> commands, use `reset` and `stty sane` to restore it.

To get modprobe to work, patiently wait for this command to finish:

    depmod

Now you can insert modules:

    for m in sch_hfsc vxlan wireguard bridge 8021q; do \
        modprobe $m; \
    done

Bridge Setup
------------

The ports lan1, lan2, lan3, and lan4 on the EVK are connected to a
Marvell 6341 switchcore, which Linux gives us as isolated ports.  These
are set up as bridge, to enable switching between them, with the
following configuration in `/etc/network/interfaces.d/bridge`:

```
# Bridge of LAN ports with VLAN interface on top. 
# The following is an illustration of an example. 
# The actual setup is all lanX ports in the same 
# VLAN and only one VLAN interface on top. 
# 
#     vlan1     vlan2      Layer-3 :: IP networking 
#          \   /           ------------------------------- 
#           br0 
#      ______|_______      Layer-2 :: Switching 
#     [#_#_#_#_#_#_#]  
#     /  |   :  |    \     ------------------------------- 
# lan2 lan1  : lan4 lan3   Layer-1 :: Link layer 
#            : 
#   VLAN 1   :    VLAN

auto vlan1 
iface vlan1 inet static 
        pre-up ip link add br0 type bridge vlan_filtering 1 
        pre-up ip link set lan1 master br0 
        pre-up ip link set lan2 master br0 
        pre-up ip link set lan3 master br0 
        pre-up ip link set lan4 master br0 
        pre-up bridge vlan add vid 1 dev br0 self 
        pre-up ip link add name vlan1 link br0 type vlan id 1 
        pre-up ip link set lan1 up 
        pre-up ip link set lan2 up 
        pre-up ip link set lan3 up 
        pre-up ip link set lan4 up 
        pre-up ip link set br0 up 
        address 198.18.105.10 
        netmask 255.255.255.0 
```

