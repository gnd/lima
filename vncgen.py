#!/usr/bin/python
# vncden.py script to find a free VNC port for LIMA guests
import sys
import random
import os.path

# parse args
vmlist = sys.argv[1]

# generate IP according to machine type
def genVNC(vmlist):
	if (os.path.isfile(vmlist)):
		# parse vmlist
		f = file(vmlist, r)
		vms = f.readlines()
		f.close()

		# get all vm vnc ports
		used = []
		max_used = 0
		for vm in vms:
			attr = vm.split()
			used.append(attr[3])
			if (int(attr[3]) > max_used):
				max_used = int(attr[3]
		
		# find the first free number
		for i in range(11231,max_used+2):
			if i not in used:
				return i
				break

print genVNC(vmlist)
