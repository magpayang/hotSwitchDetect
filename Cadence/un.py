
#! /usr/bin/python

f = open('HS89.tp', 'r')
ff = f.read()

indexWordArray = []
tempoString = ''
newLineCounter = 0

for entry in ff:
	if entry == '\n':
		tempoString = tempoString + entry
		newLineCounter = newLineCounter + 1
		if 'body' in ff:
			indexWordArray.append(newLineCounter)
		tempoString = ''	
	elif entry == ' ':
		tempoString = tempoString + entry
		if 'body' in ff:
			indexWordArray.append(newLineCounter)			
	else:
		tempoString = tempoString + entry

for i in indexWordArray:
	print(i)
