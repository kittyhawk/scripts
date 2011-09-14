# To cross-compile use: make ARCH=powerpc CROSS_COMPILE=powerpc-linux-
# You should have these in your PATH: $PWD/uboot/tools $PWD/scripts

REPO = git://github.com/kittyhawk

DIST = $(PWD)/uboot/u-boot $(PWD)/linux/arch/powerpc/boot/uImage.elf $(PWD)/linux/vmlinux $(PWD)/appliances/sshd/sshd.cpio.gz.uimg $(PWD)/appliances/sshd/sshd.cpio.gz.uimg.elf appliances/khctl/khctl.cpio.gz.uimg.elf uboot/board/bluegene/scripts/khctl.hush.uimg.elf

BLOCK = /bgsys/drivers/ppcfloor/boot/uloader /bgsys/drivers/ppcfloor/boot/cns,$(PWD)/uboot/u-boot,$(PWD)/linux/arch/powerpc/boot/uImage.elf,$(PWD)/appliances/sshd/sshd.cpio.gz.uimg.elf /bgsys/drivers/ppcfloor/boot/cns,$(PWD)/uboot/u-boot,$(PWD)/linux/arch/powerpc/boot/uImage.elf,$(PWD)/appliances/sshd/sshd.cpio.gz.uimg.elf

SCRIPTS = $(PWD)/scripts

all: cnk.elf ink.elf ramdisk.elf
	rm -f *.bin

cnk.elf: linux/.done uboot/.done appliances/.done scripts/.done
	$(SCRIPTS)/mergeelfs $@ uboot/u-boot uboot/board/bluegene/scripts/khctl.hush.uimg.elf appliances/khctl/khctl.cpio.gz.uimg.elf linux/arch/powerpc/boot/uImage.elf

ink.elf: linux/.done uboot/.done appliances/.done scripts/.done
	cp uboot/u-boot $@

ramdisk.elf: linux/.done uboot/.done appliances/.done scripts/.done
	$(SCRIPTS)/mergeelfs $@ linux/arch/powerpc/boot/uImage.elf  uboot/board/bluegene/scripts/khctl.hush.uimg.elf appliances/khctl/khctl.cpio.gz.uimg.elf

scripts/.done: scripts uboot/board/bluegene/scripts/khctl.hush.uimg.elf
	GIT_DIR=scripts/.git git log -1 > $@

scripts:
	git clone $(REPO)/scripts.git scripts

appliances/.done: appliances/sshd/sshd.cpio.gz.uimg.elf   \
                  appliances/khctl/khctl.cpio.gz.uimg.elf
	GIT_DIR=appliances/.git git log -1 > $@

appliances/sshd/sshd.cpio.gz.uimg.elf: uboot/.done scripts/.done appliances
	cd appliances/sshd && $(SCRIPTS)/mkramdiskelf sshd.cpio

appliances/khctl/khctl.cpio.gz.uimg.elf: uboot/.done scripts/.done appliances
	cd appliances/khctl && $(SCRIPTS)/mkramdiskelf khctl.cpio

appliances:
	git clone $(REPO)/appliances.git

uboot/board/bluegene/scripts/khctl.hush.uimg.elf: uboot/board/bluegene/scripts/khctl.hush
	cd uboot/board/bluegene/scripts && bash ./mkargimg khctl.hush

uboot/board/bluegene/scripts/khctl.hush: uboot

uboot/.done: uboot
	$(MAKE) -C uboot bgp_config
	$(MAKE) -C uboot
	GIT_DIR=uboot/.git git log -1 > $@

uboot:
	git clone $(REPO)/uboot.git
	touch uboot/board/bluegene/bgp/fdt.S

linux/.done: uboot/.done linux
	ARCH=powerpc $(MAKE) -C linux bgp_defconfig
	ARCH=powerpc $(MAKE) -C linux
	GIT_DIR=linux/.git git log -1 > $@

linux:
	git clone $(REPO)/linux.git

clean:
	rm -f *.elf *.bin
	$(MAKE) -C uboot mrproper
	$(MAKE) -C linux mrproper

mrproper:
	rm -f *.elf *.bin
	rm -r -f scripts appliances uboot linux

dist:
	cp $(DIST) .
