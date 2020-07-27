#! /usr/bin/python3

class findThenReplace:
	indexWordArray = []	#global
	stringInEachIndex = []	#global
	indexWordArrayFindWordAfterIndex = [] #global
	targetFile = ''
	outputFile = ''

	def __init__(self):
		pass

	def debug(self):
		print('hello! debug #1')
	
	## function that scans the inputWord and updates the global variable indexWordArray
	def findWord(self, inputWord, targetFile, outputFile):
		f = open(targetFile, 'r')
		ff = f.read()
		indexWord = inputWord
		tempoString = ''
		newLineCounter = 0
		spaceCounter = 0
		tabCounter = 0
		global indexWordArray
		indexWordArray = [] #clear of all contents
		print(indexWord)
		print('--findWord----------------------------------------------------------------------')
		for entry in ff:	# find targetWord then index
			if entry == '\n':
				newLineCounter = newLineCounter + 1
				tempoString = ''
				spaceCounter = 0
				tabCounter = 0
			elif entry == ' ':
				if tempoString[spaceCounter:] == indexWord:
					indexWordArray.append(newLineCounter + 1)
					tempoString = tempoString + entry
					spaceCounter = 0
					tabCounter = 0
				elif tempoString[tabCounter:] == indexWord:
					indexWordArray.append(newLineCounter + 1)
					tempoString = tempoString + entry
					spaceCounter = 0
					tabCounter = 0				
				else:
					tempoString = tempoString + entry
					spaceCounter = spaceCounter + 1
			elif entry == '\t':
				if tempoString[tabCounter:] == indexWord:
						indexWordArray.append(newLineCounter + 1)
						tempoString = tempoString + entry
						tabCounter = 0
				else:
					tempoString = tempoString + entry
					tabCounter = tabCounter + 1
			else:
				tempoString = tempoString + entry		
		print(indexWord+' found in line ')
		for i in range(len(indexWordArray)):
			print(indexWordArray[i])
		f.close()	
			
	def findString2(findThis2, targetFile, outputFile):
		## find 'open cbit' this only accepts two worded string
		f = open(targetFile,'r')
		ff = f.read()
		global indexWordArray
		
		indexWordArray = []
		targetWord = findThis2
		newLineCounter = 1
		tabCounter = 0
		tempoString = ''
		spaceCounter = 0
		tempoArray = []
		tempoi = ''
		hit = 0
		tempoString = ''
		
		for i in targetWord:
			if i == ' ':
				if tempoi == '':
					pass
				else:	
					tempoArray.append(tempoi)
					tempoi = ''
			else:
				tempoi = tempoi + i
		tempoArray.append(tempoi)
		tempoi = ''
				
	
		print('target word(s) are: ')
		for i in tempoArray:
			tempoString = tempoString + ' ' + i
		print(tempoString)
		tempoString = ''
	
		for entry in ff:
			if entry == '\n':
				newLineCounter = newLineCounter + 1
				tempoString = ''
				spaceCounter = 0
				tabCounter = 0
			elif entry == ' ': 
				if tempoString[spaceCounter:] == tempoArray[0]:
					hit = 1
					tempoString = ''
					spaceCounter = 0
				elif tempoString[spaceCounter:] == tempoArray[1]:
					if hit == 1:
						indexWordArray.append(newLineCounter)
						tempoString = ''
						hit = 0
						spaceCounter = 0
					else:
						pass
				elif tempoString[tabCounter:] == tempoArray[0]:
					hit = 1
					tempoString = ''
					spaceCounter = 0
					tabCounter = 0
				else:
					spaceCounter = spaceCounter + 1
					tempoString = tempoString + entry
			elif entry == '\t':
				tabCounter = tabCounter + 1
				tempoString = tempoString + entry					
			else:
				tempoString = tempoString + entry
			
							
		tempoString = ''
		newLineCounter = 0
		spaceCounter = 0
		hit = 0
			
	#	for i in indexWordArray:
	#		print(tempoString + ' found on line : ')
	#		print(i)	
		
		tempoString = ''
		f.close()
	
	## write before the index on indexWordArray	
	def writeBeforeIndexWordArray(targetFile, outputFile, inputString):
		## write getPreviousCbitStatus
		## must be written before the indexWordArray[i]
		global indexWordArray
		
		tempoString = ''
		newLineCounter = 0
		additionalInput = inputString
		offset = 0
		
		for i in indexWordArray:
			f = open(targetFile,'r')
			ff = f.read()
			g = open(outputFile,'w')
			for entry in ff:
				if entry == '\n':
					newLineCounter = newLineCounter + 1
					if (i + offset) == newLineCounter: ## before the index
						#print('hit')
						g.write('\n')
						g.write(additionalInput)
					g.write(tempoString)				
					tempoString = ''
				if entry == ' ':
					tempoString = tempoString + entry
				else:
					tempoString = tempoString + entry	
			g.write(tempoString)
			g.close()	
			f.close()
			tempoString = ''
			newLineCounter = 0	
			offset = offset + 1
	
	## write before the index on indexWordArray	
	def writeAfterIndexWordArray(targetFile, outputFile, inputString):
		## write getPreviousCbitStatus
		## must be written before the indexWordArray[i]
		global indexWordArray
		
		tempoString = ''
		newLineCounter = 0
		additionalInput = inputString
		offset = 0
		
		for i in indexWordArray:
			f = open(targetFile,'r')
			ff = f.read()
			g = open(outputFile,'w')
			i = i + 1
			for entry in ff:
				if entry == '\n':
					newLineCounter = newLineCounter + 1
					if (i + offset) == newLineCounter: ## before the index
						#print('hit')
						g.write('\n')
						g.write(additionalInput)
					g.write(tempoString)				
					tempoString = ''
				if entry == ' ':
					tempoString = tempoString + entry
				else:
					tempoString = tempoString + entry	
			g.write(tempoString)
			g.close()	
			f.close()
			tempoString = ''
			newLineCounter = 0	
			offset = offset + 1
	
	## writes getCurrentCbitStatus and hotSwitchDetect
	#def writeAfterIndexWordArray(targetFile, outputFile, inputString):
	#
	#	global indexWordArray
	#	
	#	tempoString = ''
	#	newLineCounter = 0
	#	additionalEntry = inputString
	#	additionalEntry = additionalEntry + '\n'
	#	offset = 0
	#
	#	for i in indexWordArray:
	#		f = open(targetFile,'r')
	#		ff = f.read()
	#		g = open(outputFile,'w')
	#		for entry in ff:
	#			if entry == '\n':
	#				newLineCounter = newLineCounter + 1
	#				tempoString = tempoString + entry
	#				g.write(tempoString)
	#				tempoString = ''
	#				if newLineCounter == (i + offset): #after the open cbit if newLineCounter == i
	#					print(newLineCounter)
	#					g.write(additionalEntry)
	#			elif entry == ' ':
	#				tempoString = tempoString + entry
	#			else:
	#				tempoString = tempoString + entry
	#		g.write(tempoString)
	#		tempoString = ''
	#		newLineCounter = 0
	#		offset = offset + 1
			
							
	# index the appearances of index word based as dictated by an array it is also based on 
	def findWordAfterIndex(inputWord, indexArray, targetFile): 
		indexWord = inputWord
		referenceArray = indexArray
		newLineCounter = 0
		indexWordStartFind = 0
		tempoString = ''
		global indexWordArrayFindWordAfterIndex
		print('--findWordAfterIndex----------------------------------------------------------------------')	
		indexWordArrayFindWordAfterIndex = [] #clear of all contents
		for i in range(len(referenceArray)):
			f = open(targetFile, 'r')
			ff = f.read()
			for entry in ff:
				if entry == '\n':
					newLineCounter = newLineCounter + 1
					if newLineCounter == referenceArray[i]:
						indexWordStartFind = 1
					if indexWordStartFind == 1:	
						if tempoString == indexWord:
							indexWordArrayFindWordAfterIndex.append(newLineCounter)
							indexWordStartFind = 0
					tempoString = '' #clear tempoString entry newline
				elif entry == ' ':
					tempoString = tempoString + entry
				else:
					tempoString = tempoString + entry
			tempoString = '' #clear tempoString for next loop of referenceArray
			newLineCounter = 0
			indexWordStartFind = 0
		#print(indexWordArrayFindWordAfterIndex)
		print(indexWord + ' found in line ')
		for i in range(len(indexWordArrayFindWordAfterIndex)):
			print(indexWordArrayFindWordAfterIndex[i])
		f.close()
			
	# get the name after the word procedure // get the procedure name
	def getStringInEachIndex(inputArray, targetFile):
		inputArray = inputArray
		tempoString = ''
		newLineCounter = 0
		global stringInEachIndex
		stringInEachIndex = [] #clear array
		print('--getStringInEachIndex----------------------------------------------------------------------')
		for i in range(len(inputArray)):
			f = open(targetFile, 'r')
			ff = f.read()
			for entry in ff:
				if entry == '\n':
					newLineCounter = newLineCounter + 1
					if newLineCounter == inputArray[i]:
						stringInEachIndex.append(tempoString)
					tempoString = ''
				elif entry == ' ':
					tempoString = tempoString + entry
				else:
					tempoString = tempoString + entry
			tempoString = ''
			newLineCounter = 0
		for i in range(len(stringInEachIndex)):
			print(stringInEachIndex[i])
		f.close()
			
	#refine StringInEachIndex, remove word procedure and update the same array
	def refineArray(inputArray, targetWord):
		inputArray = inputArray
		targetWord = targetWord
		tempoString = ''
		global stringInEachIndex 
		stringInEachIndex = [] #clear array, to be updated 
		print('--refineArray---------------------------------------------------------------------')	
		for entry in inputArray:
			for i in entry:
				if tempoString == targetWord:
					tempoString = '' 
					continue
				elif tempoString == ' ':
					tempoString = ''
				else:
					tempoString = tempoString + i				
			stringInEachIndex.append(tempoString)
			tempoString = ''
		for i in range(len(stringInEachIndex)):
			print(stringInEachIndex[i])
	
	# loop through first argument, then write items on second argument		
	def writeAfterIndex(inputArray, inputString, inputName, targetFile, outputFile):
		inputArray = inputArray	# line location ng word na body
		inputString = inputString 	#  procedure names
		inputName = inputName
		tempoString = ''
		newLineCounter = 0
		tempoPhrase = ''
		startCount = 0
		print('--writeAfterIndex----------------------------------------------------------------------')
		
		f = open(targetFile, 'r')
		ff = f.read()
		g = open(outputFile, 'w')
		for entry in ff:
			if entry == '\n':
				newLineCounter = newLineCounter + 1
				g.write(tempoString)
				if newLineCounter == inputArray[startCount]:
					g.write('\n')
					tempoPhrase = inputName+'_name = '+'"'+inputString[startCount]+'"'
					g.write(tempoPhrase)
					print(tempoPhrase)
					tempoPhrase = ''
					if startCount == len(inputArray)-1:
						pass
					else:
						startCount = startCount + 1
				tempoString = ''	
			if entry == ' ':
				tempoString = tempoString + entry
			else:
				tempoString = tempoString + entry
		newLineCounter = 0
		tempoString = ''
		tempoPhrase = ''
		f.close()
	
	def refineArrayExtract(inputArray): ## remove the arguments after the procedure and function name
		inputArray = inputArray
		tempoString = ''
		loopHere = ''
		global stringInEachIndex
		stringInEachIndex = []
		print('--refineArrayExtract----------------------------------------------------------------')	
		for entry in inputArray:
			for i in entry:
				if i == '(':
					break
				elif i == '\n':
					break
				else:
					tempoString = tempoString + i
			stringInEachIndex.append(tempoString)
			tempoString = ''
		for i in range(len(stringInEachIndex)):
			print(stringInEachIndex[i])
	
	def refineArrayRemoveComments(inputArray):
		inputArray = inputArray
		tempoString = ''
		previousEntryAlert = 0
		global stringInEachIndexrefineArrayExtract
		stringInEachIndex = []
		print('--refineArraySpacezThenDash2x--------------------------------------------------------')
		for entry in inputArray:
			for i in entry:
				if i == ' ':
					if previousEntryAlert == 1:
						previousEntryAlert = 0 #reset
					tempoString = tempoString + i
				elif i == '-':
					if previousEntryAlert == 1:
						previousEntryAlert = 0 #reset
						break
					else:	
						previousEntryAlert = 1
						tempoString = tempoString + i
				else:
					if previousEntryAlert == 1:
						previousEntryAlert = 0 #reset
					tempoString = tempoString + i 
			stringInEachIndex.append(tempoString[:-1])
			tempoString = '' #reset tempoString		
		for i in range(len(stringInEachIndex)):
			print(StringInEachIndex[i])
	#############################################################################################


	
	
	
	
	
	
