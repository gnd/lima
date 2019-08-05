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
		f = file(vmlist, 'r')
		vms = f.readlines()
		f.close()

		# get all vm ips
		used = []
		for vm in vms:
			attr = vm.split()
			if (((attr[4] == 'sta') and (vmtype == 'static')) or ((attr[4] == 'dyn') and (vmtype == 'dynamic'))):
				used.append(attr[0].split['-'][2])

		# find the first free number
		for i in range(100,199):
			if i not in used:
				return i
				break

print genIP(vmtype, vmlist)
