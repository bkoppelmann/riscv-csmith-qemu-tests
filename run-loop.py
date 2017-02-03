#!/usr/bin/env python3
from subprocess import Popen
from termcolor import colored
import os,sys, subprocess
import argparse

def safe_testcase(i,isa_size):

    path = "failed/test-" + str(i)

    os.system("mkdir -p " + path)
    os.system("cp test" + isa_size + ".elf " + path)
    os.system("cp test.c " + path)
    os.system("cp test_ref" + isa_size + " " + path)
    os.system("cp output_sim.txt " + path)
    os.system("cp output_ref.txt " + path)

def run_single(i, isa_size):
    sys.stdout.write("Test " + str(i) + " ... ")
    sys.stdout.flush()
    p = Popen(['make', 'qemu' + isa_size], stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
    retcode = None

    while retcode == None:
        retcode = p.poll()

    if retcode != 0:
        if not os.path.isfile("output_sim.txt"):
            sys.stdout.write('[' + colored('Expected Fail', 'yellow') + ']\n')
        else:
            sys.stdout.write('[' + colored('Fail', 'red') + ']\n')
            safe_testcase(i,isa_size)
    else:
        sys.stdout.write('[' + colored('Success', 'green') + ']\n')

def run_loop(numRuns, isa_size):

    for i in range(0, int(numRuns)):
        os.system("make clean > /dev/null")
        run_single(i, isa_size)
 
def run_failed(num, isa_size):
    if os.path.isfile("failed/test-" + str(num) + "/test.c"):
        os.system("make clean > /dev/null")
        os.system("cp failed/test-" + str(num) + "/test.c .")
        run_single(num, isa_size)
    else:
        sys.stderr.write("Cannot load test-" + str(num) + ". Test does not exist")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description='Csmith testloop for QEMU')
    group = parser.add_mutually_exclusive_group()
    parser.add_argument('--isa-size', nargs=1, default=["32"], type=str,
                        help='Defines the reg-size used by QEMU (e.g. RV32/RV64)', choices=['32','64'])
    group.add_argument('--runs', nargs=1, required=False, type=int,
                        help='Defines the number of runs to be executed')
    group.add_argument('--rerun', nargs=1, required=False, type=int,
                        help='Rerun failed test number X')

    args = parser.parse_args()

    if args.rerun != None:
        run_failed(args.rerun[0], args.isa_size[0])
    else:
        if args.runs == None:
            sys.stderr.write("please specify '--runs'\n")
            sys.exit(1)
        
        run_loop(args.runs[0], args.isa_size[0])
   
main()
