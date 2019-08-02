#!/usr/bin/python
# ipgen.py script to generate a free IP address for LIMA guests
import sys
import random
import os.path

# parse the machine type
vmtype = sys.argv[0]
vmlist = sys.argv[1]

# generate IP according to machine type
def genIP(vmtype, vmlist):
	if (os.path.isfile(vmlist)):
		# parse vmlist
		f = file(vmlist, r)
		vms = f.readlines()
		f.close()

		# get all default vm ips
		used = []
		for vm in vms:
			attr = vm.split()
			if ((attr[4] == 'def') && (vmtype == 'default')) || ((attr[4] == 'sta') && (vmtype == 'static')) || ((attr[4] == 'dyn') && (vmtype == 'dynamic')):
				used.append(attr[0].split['-'][2])

		# find the first free number
		start = 10 if vmtype == 'default' else 100
		for i in range(start,99):
			if i not in used:
				return i
				break
	else:
		# this means its the first default machine
		# (or there is some error :)
		return 10 if vmtype == 'default' else 100

print genIP(vmtype, vmlist)
