KERNEL_SRC=$(HOME)/src/linux-rdma

# KVM
#KVM_RELEASE=wheezy
#KVM_RELEASE=jessie
#KVM_RELEASE=sid
KVM_RELEASE=testing
#KVM_PACKAGES=openssh-server,python,perl,vim,pciutils,ibverbs-utils,libibverbs-dev,libmlx5-dev,infiniband-diags,opensm,librdmacm-dev,rdmacm-utils
#KVM_PACKAGES=openssh-server,python,perl,vim,pciutils,ibverbs-utils,libibverbs-dev,libmlx5-dev,infiniband-diags,librdmacm-dev,rdmacm-utils
KVM_PACKAGES=openssh-server,python,perl,vim,pciutils,iproute2
KVM_SHARED=$(HOME)/src

# SimX
SIMX_BIN=$(HOME)/src/simx/x86_64-softmmu/qemu-system-x86_64

ssh:
	@ssh root@localhost -p4444

kvm:
	@echo "Start KVM image"
	@# add -s option for running gdb
	@# and run "ggb vmlinux"
	@qemu-system-x86_64 -enable-kvm -kernel $(KERNEL_SRC)/arch/x86/boot/bzImage -drive \
		file=$(HOME)/src/dev-scripts/build/$(KVM_RELEASE).img,if=virtio,format=raw \
		-append 'root=/dev/vda earlyprintk=serial,ttyS0,115200 console=hvc0 debug rw net.ifnames=0' \
		-device virtio-serial-pci -serial mon:stdio -nographic \
		-net nic,model=virtio,macaddr=52:54:01:12:34:56 \
		-net user,hostfwd=tcp:127.0.0.1:4444-:22 \
		-virtfs local,path=$(KVM_SHARED),mount_tag=host0,security_model=passthrough,id=host0

simx:
	@echo "Start SimX image"
	@# add -s option for running gdb
	@# and run "ggb vmlinux"
	@$(SIMX_BIN) -enable-kvm -kernel $(KERNEL_SRC)/arch/x86/boot/bzImage -drive \
		file=$(HOME)/src/dev-scripts/build/$(KVM_RELEASE).img,if=virtio,format=raw \
		-no-reboot -nographic -m 512M \
		-append 'root=/dev/vda earlyprintk=serial,ttyS0,115200 console=hvc0 debug rw net.ifnames=0' \
		-net nic,model=virtio \
		-net user,hostfwd=tcp:127.0.0.1:4444-:22 \
		-device e1000 -device connectx4 \
		-virtfs local,path=$(KVM_SHARED),mount_tag=host0,security_model=passthrough,id=host0

kvm-image:
	@echo "Build Debian $(KVM_RELEASE) image"
	@mkdir -p build/
	@mkdir -p build/kvm-image
	@sudo debootstrap --include=$(KVM_PACKAGES) $(KVM_RELEASE) build/kvm-image http://http.debian.net/debian/
	@sudo sed -i '/^root/ { s/:x:/::/ }' build/kvm-image/etc/passwd
	@echo 'V0:23:respawn:/sbin/getty 115200 hvc0' | sudo tee -a build/kvm-image/etc/inittab
	@printf '\nauto eth0\niface eth0 inet dhcp\n' | sudo tee -a build/kvm-image/etc/network/interfaces
	@printf '\nhost0   /mnt    9p      trans=virtio,version=9p2000.L   0 0\n' | sudo tee -a build/kvm-image/etc/fstab
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

kvm-config:
	@cp configs/kvm-config $(KERNEL_SRC)/.config

off:
	@ssh -p4444 root@localhost "poweroff"

all:
	@echo "Do nothing!!!!!"
