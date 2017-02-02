#!/usr/bin/env python3
from subprocess import Popen
from termcolor import colored
import os,sys, subprocess
import argparse

def safe_testcase(i):

    path = "failed/test-" + str(i)

    os.system("mkdir -p " + path)
    os.system("cp test.elf " + path)
    os.system("cp test.c " + path)
    os.system("cp test_ref " + path)
    os.system("cp output_sim.txt " + path)
    os.system("cp output_ref.txt " + path)

def main():
    parser = argparse.ArgumentParser(description='Csmith testloop for QEMU')
    parser.add_argument('--isa-size', nargs=1, default=["32"], type=str,
                        help='Defines the reg-size used by QEMU (e.g. RV32/RV64)', choices=['32','64'])
    parser.add_argument('--runs', nargs=1, required=True, type=int,
                        help='Defines the number of runs to be executed')
    args = parser.parse_args()

    for i in range(0, int(args.runs[0])):

        sys.stdout.write("Test " + str(i) + " ... ")
        sys.stdout.flush()
        os.system("make clean > /dev/null")
        p = Popen(['make', 'qemu' + args.isa_size[0]], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        retcode = None

        while retcode == None:
            retcode = p.poll()

        if retcode != 0:
            if not os.path.isfile("output_sim.txt"):
                sys.stdout.write('[' + colored('Expected Fail', 'yellow') + ']\n')
            else:
                sys.stdout.write('[' + colored('Fail', 'red') + ']\n')
                safe_testcase(i)
        else:
            sys.stdout.write('[' + colored('Success', 'green') + ']\n')

main()
