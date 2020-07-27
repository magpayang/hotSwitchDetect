#! /usr/bin/python3

class mySuperFile:
	
	mySuperFileGlobalVariable1 = '' ## class variable shared by all instances

	def __init__(self):
		self.indexWordArray = []
		self.indexWordArrayFindWordAfterIndex = []
		self.stringInEachIndex = []

	def debug(self):
		print('debug')

	def printer(self, targetFile):
		f = open(targetFile, 'r')
		ff = f.read()
		for entry in ff:
			print(entry)
		f.close()

	def tempoStringPrinter(self, targetFile):
		f = open(targetFile, 'r')
		ff = f.read()
		tempoString = ''
		newLineCounter = 0
		for entry in ff:
			if entry == '\n':
				#tempoString = tempoString + entry
				print(tempoString)
				tempoString = ''
				newLineCounter = newLineCounter + 1
			elif entry == ' ':
				tempoString = tempoString + entry
			else:
				tempoString = tempoString + entry
	
	## function that scans the inputWord and updates the self variable indexWordArray
	def findWord(self, inputWord, targetFile, outputFile):
		f = open(targetFile, 'r')
		ff = f.read()
		indexWord = inputWord
		tempoString = ''
		newLineCounter = 0
		spaceCounter = 0
		tabCounter = 0
		indexWordArray = []
		print('--findWord----------------------------------------------------------------------')
		for entry in ff:	# find targetWord then index
			if entry == '\n':
				if tempoString[spaceCounter:] == indexWord:
					indexWordArray.append(newLineCounter + 1)
				elif tempoString[tabCounter:] == indexWord:
					indexWordArray.append(newLineCounter + 1)
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
		self.indexWordArray = indexWordArray
		f.close()	
			
	def findString2(self, findThis2, targetFile, outputFile):	
		## find 'open cbit' this string[100] : procedure_name, function_name --reeglysononly accepts two worded string
		f = open(targetFile,'r')
		ff = f.read()		
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
			
		for i in indexWordArray:
			print(tempoString + 'string[100] : procedure_name, function_name --reeglyson found on line : ')
			print(i)	
		
		self.indexWordArray = indexWordArray		

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
	#		offset = offset + 1		inputArray = self.indexWordArray
			
							
	# index the appearances of index word as dictated by an array it is also based on 
	def findWordAfterIndex(self, targetWord, targetFile, referenceArray): 
		f = open(targetFile,'r')
		ff = f.read()	
		
		indexWord = targetWord
		referenceArray = self.indexWordArray
		newLineCounter = 0
		indexWordStartFind = 0
		tempoString = ''
		print('--findWordAfterIndex----------------------------------------------------------------------')	
		indexWordArrayFindWordAfterIndex = [] #clear of all contents
		for i in range(len(referenceArray)):
			print('finding in line: '+str(referenceArray[i]))
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

		self.indexWordArrayFindWordAfterIndex = indexWordArrayFindWordAfterIndex
			
	# get the name after the word procedure // get the procedure name
	def getStringInEachIndex(self, inputArray, targetFile, outputFile):
		f = open(targetFile,'r')
		ff = f.read()	

		inputArray = self.indexWordArray
		tempoString = ''
		newLineCounter = 0		
		StringInEachIndex = [] #clear array
		print('--getStringInEachIndex----------------------------------------------------------------------')
		for i in range(len(inputArray)):
			print('getting in line: '+str(inputArray[i]))
			for entry in ff:
				if entry == '\n':
					newLineCounter = newLineCounter + 1
					if newLineCounter == inputArray[i]:
						StringInEachIndex.append(tempoString)
					tempoString = ''
				elif entry == ' ':
					tempoString = tempoString + entry
				else:
					tempoString = tempoString + entry
			tempoString = ''
			newLineCounter = 0
		for i in range(len(StringInEachIndex)):
			print(StringInEachIndex[i])
		
		self.stringInEachIndex = StringInEachIndex
			
	#refine StringInEachIndex, remove word procedure and update the same array
	def refineArray(self, inputArray, targetWord):
		inputArray = self.stringInEachIndex
		targetWord = targetWord
		tempoString = ''		
		StringInEachIndex = [] 	

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
			StringInEachIndex.append(tempoString)
			tempoString = ''
		for i in range(len(StringInEachIndex)):
			print(StringInEachIndex[i])
		
		self.stringInEachIndex = StringInEachIndex
	
	# loop through first argument, then write items on second argument		
	def writeAfterIndex(self, inputArray, inputString, inputName, targetFile, outputFile):
		f = open(targetFile, 'r')
		ff = f.read()
		g = open(outputFile, 'w')

		inputArray = self.indexWordArrayFindWordAfterIndex	# line location ng word na body
		inputString = self.stringInEachIndex 	#  procedure names
		inputName = inputName					#  either 'procedure' or 'function'
		tempoString = ''
		newLineCounter = 0
		tempoPhrase = ''
		startCount = 0
		print('--writeAfterIndex----------------------------------------------------------------------')
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
		g.write(tempoString) ##possible cause of missing end_body
		newLineCounter = 0
		startCount = 0
		tempoString = ''
		tempoPhrase = ''
		
		f.close()
		g.close()
	
	def refineArrayExtract(self, inputArray): ## remove the arguments after the procedure and function name
		inputArray = self.stringInEachIndex
		tempoString = ''
		loopHere = ''
		StringInEachIndex = []
		print('--refineArrayExtract----------------------------------------------------------------')	
		for entry in inputArray:
			for i in entry:
				if i == '(':
					break
				elif i == '\n':
					break
				else:
					tempoString = tempoString + i
			StringInEachIndex.append(tempoString)
			tempoString = ''
		for i in range(len(StringInEachIndex)):
			print(StringInEachIndex[i])
		
		self.stringInEachIndex = StringInEachIndex
	
	def refineArrayRemoveComments(inputArray):
		inputArray = inputArray
		tempoString = ''
		previousEntryAlert = 0
		global StringInEachIndex
		StringInEachIndex = []
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
			StringInEachIndex.append(tempoString[:-1])
			tempoString = '' #reset tempoString		
		for i in range(len(StringInEachIndex)):
			print(StringInEachIndex[i])
	
	#write inputSting on outputFile	
	def writer(self, inputArray, inputString, targetFile, outputFile):
		f = open(targetFile, 'r')
		ff = f.read()
		g = open(outputFile, 'w')
		
		inputArray = self.indexWordArray
		inputString = inputString
		tempoString = ''
		newLineCounter = 0
		startCount = 0
		for entry in ff:
			if entry == '\n':
				newLineCounter = newLineCounter + 1
				g.write(tempoString+'\n')
				if newLineCounter == inputArray[startCount]:
					g.write(inputString)
					if startCount == len(inputArray)-1: ## if inputArray has only 1 entry
						pass
					else:
						startCount = startCount + 1	
				tempoString = ''				
			elif entry == ' ':
				tempoString = tempoString + entry
			else:
				tempoString = tempoString + entry
		g.write(tempoString)
		tempoString = ''
		newLineCounter = 0
		startCount = 0
		
		
	#############################################################################################
	#targetFile = 'gpio.mod'
	#outputFile = targetFile
	#indexWordArray =[]
	
	#findThis2 = 'open cbit'
	#findString2(targetFile, outputFile, findThis2)	# finds tring 'open cbit and updates indexWordArray
	
	#findWord('open', targetFile, outputFile)
	
	#inputString = 'hotSwitchDetect --reeglyson'
	#writeAfterIndexWordArray(targetFile, outputFile, inputString)
	#inputString = 'getCurrentCbitStatus --reeglyson'
	#writeAfterIndexWordArray(targetFile, outputFile, inputString)
	##-----------------------------------------------------------------------------------------------------------------------------
	#findWord('open', targetFile, outputFile)
	#findString2('open cbit', targetFile, outputFile)
	#inputString = 'getPreviousCbitStatus -- reeglyson' ## write before the index on indexWordArray
	#writeBeforeIndexWordArray(targetFile, outputFile, inputString)	
			
	#findString2('open cbit', targetFile, outputFile)		
	#inputString = 'getCurrentCbitStatus --reeglyson'
	#writeAfterIndexWordArray(targetFile, outputFile, inputString)	
	
	#findString2('open cbit', targetFile, outputFile)	
	#findWord('getCurrentCbitStatus', targetFile, outputFile)	
	#inputString = 'hotSwitchDetect --reeglyson'
	#writeAfterIndexWordArray(targetFile, outputFile, inputString)
