KERNEL_SRC=$(HOME)/src/linux/linux-mm
# VMware related
VMWARE_VM=$(HOME)/src/vm-machines/archlinux/archlinux.vmx
VMWARE_VM_REPACK=$(HOME)/src/vm-machines/archlinux/archlinux-000001.vmdk

# KVM related
KVM_RELEASE=wheezy
KVM_PACKAGES=openssh-server,python,perl,vim
ssh:
	@ssh root@localhost -p4444

kvm:
	@echo "Start KVM image"
	@# add -s option for running gdb
	@# and run "ggb vmlinux"
	@kvm -kernel $(KERNEL_SRC)/arch/x86/boot/bzImage -drive \
		file=$(HOME)/src/linux/kernel-dev-scripts/build/wheezy.img,if=virtio \
		-append 'root=/dev/vda console=hvc0' \
		-chardev stdio,id=stdio,mux=on,signal=off \
		-device virtio-serial-pci \
		-device virtconsole,chardev=stdio \
		-mon chardev=stdio \
		-display none \
		-net nic,model=virtio,macaddr=52:54:00:12:34:56 \
		-net user,hostfwd=tcp:127.0.0.1:4444-:22

kvm-image:
	@echo "Build Debian 7.0 image"
	@mkdir -p build/
	@mkdir -p build/kvm-image
	@sudo debootstrap --include=$(KVM_PACKAGES) $(KVM_RELEASE) build/kvm-image http://http.debian.net/debian/
	@sudo sed -i '/^root/ { s/:x:/::/ }' build/kvm-image/etc/passwd
	@echo 'V0:23:respawn:/sbin/getty 115200 hvc0' | sudo tee -a build/kvm-image/etc/inittab
	@printf '\nauto eth0\niface eth0 inet dhcp\n' | sudo tee -a build/kvm-image/etc/network/interfaces
	@sudo mkdir build/kvm-image/root/.ssh/
	@cat ~/.ssh/id_?sa.pub | sudo tee build/kvm-image/root/.ssh/authorized_keys
	@dd if=/dev/zero of=build/$(KVM_RELEASE).img bs=1M seek=4095 count=1
	@mkfs.ext4 -F build/$(KVM_RELEASE).img
	@sudo mkdir -p build/mnt-$(KVM_RELEASE)
	@sudo mount -o loop build/$(KVM_RELEASE).img build/mnt-$(KVM_RELEASE)
	@sudo cp -a build/kvm-image/. build/mnt-$(KVM_RELEASE)/.
	@sudo umount build/mnt-$(KVM_RELEASE)
	@sudo rm -rf build/mnt-$(KVM_RELEASE)
	@echo "Image was built successfuly"

clean-kvm-image:
	@sudo rm -rf build/$(KVM_RELEASE).img build/mnt-$(KVM_RELEASE) build/kvm-image

vmware-config:
	@cp configs/vmware-config $(KERNEL_SRC)/.config

kvm-config:
	@cp configs/kvm-config $(KERNEL_SRC)/.config
build:
	@echo "Start kernel build"
	@make -C $(KERNEL_SRC) oldconfig
	@make -C $(KERNEL_SRC) -j8

stop-vmware-vm:
	@echo "Stop VMware VM"
	@vmrun stop $(VMWARE_VM)

start-vmware-vm:
	@echo "Start VMware VM"
	@vmrun start $(VMWARE_VM)

update-vmware-vm:
	@echo "Patch boot partition"
	@mkdir -p build
	@mkdir -p build/vmware
	@vmware-mount $(VMWARE_VM_REPACK) build/vmware
	@sudo cp -v $(KERNEL_SRC)/arch/x86/boot/bzImage build/vmware/vmlinuz-linux-dev
	@sudo cp -v $(KERNEL_SRC)/System.map build/vmware
	@vmware-mount -d build/vmware
	@rmdir -rf build/vmware

vmware-vm: stop-vmware-vm update-vmware-vm start-vmware-vm

all:
	@echo "Do nothing!!!!!"
