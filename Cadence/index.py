#! /usr/bin/python

import os
from findThenReplace3 import findThenReplace

targetfile = ''
outputfile = ''

Anna = findThenReplace()

dir_path = os.path.dirname(os.path.realpath(__file__))
print(dir_path)

##variables
listOfMODFiles = []

ff = os.listdir(dir_path)

for f in ff:
	if '.mod' in f:
		#print('found: ')
		#print(f)
		listOfMODFiles.append(f)

for i in listOfMODFiles:
	print(i)

Anna.debug()
Anna.findWord('body', listOfMODFiles[1],'tempo.txt')
print(listOfMODFiles[1])
