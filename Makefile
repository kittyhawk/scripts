# To cross-compile use: make ARCH=powerpc CROSS_COMPILE=powerpc-linux-
# You should have these in your PATH: $PWD/uboot/tools $PWD/scripts

REPO = /gsa/yktgsa/projects/k/kittyhawk/git

DIST = $(PWD)/uboot/u-boot $(PWD)/linux-kh/arch/powerpc/boot/uImage.elf $(PWD)/linux-kh/vmlinux $(PWD)/appliances/sshd/sshd.cpio.gz.uimg $(PWD)/appliances/sshd/sshd.cpio.gz.uimg.elf appliances/khctl/khctl.cpio.gz.uimg.elf uboot/board/bluegene/scripts/khctl.hush.uimg.elf

BLOCK = /bgsys/drivers/ppcfloor/boot/uloader /bgsys/drivers/ppcfloor/boot/cns,$(PWD)/uboot/u-boot,$(PWD)/linux-kh/arch/powerpc/boot/uImage.elf,$(PWD)/appliances/sshd/sshd.cpio.gz.uimg.elf /bgsys/drivers/ppcfloor/boot/cns,$(PWD)/uboot/u-boot,$(PWD)/linux-kh/arch/powerpc/boot/uImage.elf,$(PWD)/appliances/sshd/sshd.cpio.gz.uimg.elf

all: linux-kh/.done uboot/.done appliances/.done scripts/.done
	@echo setblockinfo R00-M00-N00-J00 $(BLOCK)

scripts/.done: scripts uboot/board/bluegene/scripts/khctl.hush.uimg.elf
	GIT_DIR=scripts/.git git-log -1 > $@

scripts:
	git-clone $(REPO)/scripts.git

appliances/.done: appliances/sshd/sshd.cpio.gz.uimg.elf   \
                  appliances/khctl/khctl.cpio.gz.uimg.elf
	GIT_DIR=appliances/.git git-log -1 > $@

appliances/sshd/sshd.cpio.gz.uimg.elf: uboot/.done scripts/.done appliances
	cd appliances/sshd && mkramdiskelf sshd.cpio

appliances/khctl/khctl.cpio.gz.uimg.elf: uboot/.done scripts/.done appliances
	cd appliances/khctl && mkramdiskelf khctl.cpio

appliances:
	git-clone $(REPO)/appliances.git

uboot/board/bluegene/scripts/khctl.hush.uimg.elf: uboot/board/bluegene/scripts/khctl.hush
	cd uboot/board/bluegene/scripts && ./mkargimg khctl.hush

uboot/board/bluegene/scripts/khctl.hush: uboot

uboot/.done: uboot
	$(MAKE) -C uboot bgp_config
	$(MAKE) -C uboot
	GIT_DIR=uboot/.git git-log -1 > $@

uboot:
	git-clone $(REPO)/uboot.git
	touch uboot/board/bluegene/bgp/fdt.S

linux-kh/.done: uboot/.done linux-kh
	$(MAKE) -C linux-kh bgp_defconfig
	$(MAKE) -C linux-kh
	GIT_DIR=linux-kh/.git git-log -1 > $@

linux-kh:
	git-clone $(REPO)/linux-kh.git

clean:
	$(MAKE) -C uboot mrproper
	$(MAKE) -C linux-kh mrproper

mrproper:
	rm -r -f scripts appliances uboot linux-kh

dist:
	cp $(DIST) .
