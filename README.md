# riscv-csmith-qemu-tests

Hacked-together scripts for running csmith on riscv-qemu.

# Setup

1) Put riscv-tools (commit ad9ebb8557e32241bfca047f2bc628a2bc1c18cb) into your path.

2) Select the qemu repository you want to test by editing the Makefile using the variable
  - QEMU_URL
  - QEMU_COMMIT
  - QEMU_BRANCH

3) Install csmith and qemu by running ```$ make tools```

4) Test your setup by running ```$ make qemu32``` to run one test for RV32 QEMU.
Run ```$ make qemu64``` for RV64 QEMU respectively.

# Usage

Type ```$ ./run-loop.py --runs X``` to run X testcases against QEMU. Whenever a
fail occurs the failing tests are saved into a folder failed/test-X/

To rerun a failed test, type ```$ ./run-loop.py --rerun X``` where X is the
testcase that failed.

Note, that csmith is not guaranteed to produce terminating test programs, so any
 timed out test it marked by ```[Expected Fail]``` in the output of the script.
