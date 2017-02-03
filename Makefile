# configure these
RISCV_TOOLS_DIR = $(RISCV)
QEMU_URL = https://github.com/riscv/riscv-qemu.git
QEMU_COMMIT = /home/bastian/coding/riscv-csmith-qemu-tests/qemu/install/bin
QEMU_BRANCH = master

CSMITH_DIR = $(shell pwd)/csmith-2.2.0/install
QEMU_DIR = $(shell pwd)/qemu

# RV32 compiler
RISCV_TOOLS_PREFIX32 = $(RISCV_TOOLS_DIR)/bin/riscv32-unknown-elf-
RV32_CC = $(RISCV_TOOLS_PREFIX32)gcc
# RV64 compiler
RISCV_TOOLS_PREFIX64 = $(RISCV_TOOLS_DIR)/bin/riscv64-unknown-elf-
RV64_CC = $(RISCV_TOOLS_PREFIX64)gcc

CSMITH_INCDIR = $(shell ls -d $(CSMITH_DIR)/include/csmith-* | head -n1)
QEMU32 = $(QEMU_DIR)/riscv32-softmmu/qemu-system-riscv32
QEMU64 = $(QEMU_DIR)/riscv64-softmmu/qemu-system-riscv64
JOBS=$(shell echo `nproc`)

help:
	@echo "Usage: make { qemu32 | qemu64 | tools | clean }"

qemu32: test_ref32 test32.elf qemu/build.ok
	timeout 10 ./test_ref32 > output_ref.txt && cat output_ref.txt
	$(QEMU32) -M sifive -nographic -kernel test32.elf > output_sim.txt
	diff -u output_ref.txt output_sim.txt

qemu64: test_ref64 test64.elf qemu/build.ok
	timeout 10 ./test_ref64 > output_ref.txt && cat output_ref.txt
	$(QEMU64) -M sifive -nographic -kernel test64.elf > output_sim.txt
	diff -u output_ref.txt output_sim.txt

start32.elf: start.S start.ld
	$(RV32_CC) -nostdlib -o $@ $<
	chmod -x $@

start64.elf: start.S start.ld
	$(RV64_CC) -nostdlib -o $@ $<
	chmod -x $@

test_ref32: test.c
	gcc -m32 -o $@ -w -Os -I $(CSMITH_INCDIR) $<

test_ref64: test.c
	gcc -m64 -o $@ -w -Os -I $(CSMITH_INCDIR) $<

test32.elf: test.c syscalls.c start.S
	sed -e '/SECTIONS/,+1 s/{/{ . = 0x00001000; .start : { *(.text.start) } application_entry_point = 0x00010000;/;' \
		$(RISCV_TOOLS_DIR)/riscv32-unknown-elf/lib/riscv.ld > test.ld
	$(RV32_CC) -o $@ -w -Os -I $(CSMITH_INCDIR) -T test.ld $^
	chmod -x $@

test64.elf: test.c syscalls.c start.S
	sed -e '/SECTIONS/,+1 s/{/{ . = 0x00001000; .start : { *(.text.start) } application_entry_point = 0x00010000;/;' \
		$(RISCV_TOOLS_DIR)/riscv64-unknown-elf/lib/riscv.ld > test.ld
	$(RV64_CC) -o $@ -w -Os -I $(CSMITH_INCDIR) -T test.ld $^
	chmod -x $@

tools: csmith-2.2.0/build.ok qemu/build.ok

csmith-2.2.0/build.ok:
	wget https://embed.cs.utah.edu/csmith/csmith-2.2.0.tar.gz
	tar -xf csmith-2.2.0.tar.gz && rm csmith-2.2.0.tar.gz
	cd csmith-2.2.0 && mkdir -p install && ./configure --prefix=$(CSMITH_DIR)
	cd csmith-2.2.0 && make -j$(JOBS) && make install && touch build.ok

qemu/build.ok:
	git clone $(QEMU_URL) --branch $(QEMU_BRANCH) qemu
	cd $(QEMU_DIR) && git checkout $(QEMU_COMMIT)
	cd $(QEMU_DIR) && mkdir -p install && patch -p1 < ../qemu.patch 
	cd $(QEMU_DIR) && ./configure --target-list=riscv32-softmmu,riscv64-softmmu --python=python2
	cd $(QEMU_DIR) && make -j$(JOBS) && touch build.ok


test.c: csmith-2.2.0/build.ok
	echo "integer size = 4" > platform.info
	echo "pointer size = 4" >> platform.info
	$(CSMITH_DIR)/bin/csmith --no-packed-struct -o test.c
	gawk '/Seed:/ {print$$2,$$3;}' test.c

clean:
	rm -rf platform.info test.c test.ld obj_dir
	rm -rf test32.elf test64.elf test_ref32 test_ref64
	rm -rf output_ref.txt output_sim.txt

mrproper: clean
	rm -rf csmith-2.2.0
	rm -rf qemu

.PHONY: help tools clean mrproper
