#! /usr/bin/python

## this file will  find the folder cadence and execute the needed commands

import os

class smartfinder():
	def __init__(self):
		self.dir_path = ''
		self.dir_path_array = []
		self.file_list = []
		self.directory_list = []
		self.refineArray = []
		self.tempoString = ''
	
	def searchUsingDirThenDelete(self, enDebug, targetDir, targetFile):
		contents = os.listdir(targetDir)
		toBeDeleted = ''
		
		for entry in contents:
			if targetFile in entry:
				toBeDeleted = targetDir+'/'+entry
				os.system('rm -rf '+targetDir+'/'+entry)
		debug.debugFunc(self, enDebug, 'found: '+toBeDeleted+' , DELETED!')
				
	def pinNameFinder(self, enDebug, targetWord, targetString, targetLength, targetEndKey, targetFile, outputFile):
		"""
			from the list of pins with attributes of the file ExtRefs/HS87_TQFN_package.evo (targetFile), this pin will extract the
			desired pin name (output file), by searching for the adaptertype (target word), then searching for the
			keyword (targetString), counting from start to first letter of pin name (targetLength), then stopping at 
			Maxsites (targetEndKey)
		"""
		#f = open('ExtRefs/HS87_TQFN_package.evo', 'r')
		f = open(targetFile, 'r')
		ff = f.read()
		#g = open('ExtRefs/HS87_TQFN_package.evo.map', 'w')
		g = open(outputFile, 'a')
		#targetWord = 'hs87_56tqfnB'
		targerWord = targetWord ##targetAdapterName
		#targetString = 'CbitPins'
		targetString = targetString ##targetPinNameType
		targetLength = targetLength ## the length of target string before the pin name. assumed to be 14 for all TP
		targetEndKey = targetEndKey ## keyword that will signal the end of search for pinnames. assumed to be 'MaxSite' for all TP
		tempoString = ''
		start = 0
		count = 0
		record = ''
		startCount = 0

		for entry in ff:
			if start == 0:
				if 	entry == '\n':
					if targetWord in tempoString: ##target word is adapter name
						start = 1
						tempoString = ''
					else:
						tempoString = ''	
				else: 
					tempoString = tempoString + entry
			elif start == 1:
				if entry == '\n':
					if targetEndKey in tempoString: ##hardCoded since possibly true for all evos ##MaxSites
						count = 0
						record = ''
						start = 0
						tempoString = ''
					elif targetString in tempoString:	##extractPinName() targetString is the keyword 'CbitPins'
						for i in tempoString:
							if startCount == 1:
								if i == ';':
									startCount = 0
									tempoString = ''
									g.write('\n')
									break
								else:
									debug.debugFunc(self, enDebug, i)
									g.write(i)
							else:		
								count = count + 1	
								if count == targetLength:	##count of characters equals tempoInt
									startCount = 1
									count = 0
								else:
									startCount = 0		
					else:	
						debug.debugFunc(self, 0, tempoString)
						count = 0
						record = ''	
						tempoString = ''
				else:
					tempoString = tempoString + entry
			else:
				pass
	
	def listFoundAdapterEVO(self, enDebug, evoDirectory):
		f = open(evoDirectory, 'r')
		ff = f.read()

		tempoString = ''
		tempoArray = []
		counter = 0
		for entry in ff:
			if entry == '\n':
				#debug
				debug.debugFunc(self, enDebug, tempoString)
				if 'AdapterBoard' in tempoString:
					tempoString = tempoString.replace('AdapterBoard ', '')
					tempoString = tempoString.replace(' {','')
					tempoArray.append(tempoString)
				tempoString = ''
			else:
				tempoString = tempoString + entry
		tempoString = ''
		
		if enDebug == 1:
			os.system('clear')	
		print('choose the correct loadboard adapter: ')	
		print('Type 1,2,3,4,...')					
		for entry in tempoArray:
			counter = counter + 1
			print(str(counter)+' '+entry)	
		userInput = input()		
	
		f.close()
		
		return tempoArray[int(userInput)-1]						
	
	def refineArrayFunc(self, enDebug, inputArray, toBeReplaced, replacement):
		tempoArray = inputArray		

		for entry in tempoArray:
			entry = entry.replace(toBeReplaced, replacement)
			if 'package' in entry:
				debug.debugFunc(self, enDebug, 'refineArrayFunc') ##from class debug method debug func located below
				self.refineArray.append(entry)			
		
		return self.refineArray		

	def list(self, enDebug):	##list the folders in the folder this file is located. for debug purposes
		self.file_list = []
		
		self.dir_path = os.path.realpath(__file__)		
		debug.debugFunc(self, enDebug, 'current file location directory is \n'+str(self.dir_path))	
       
		self.dir_path = os.path.dirname(self.dir_path)
		debug.debugFunc(self, enDebug, 'current file directory is \n' + str(self.dir_path))

		ff = os.listdir(self.dir_path)
				
		for entry in ff:
			debug.debugFunc(self, enDebug, entry)
			if os.path.isfile(entry):
				pass
			else:
				self.file_list.append(entry)
		
		if enDebug == 1:
			print("At: "+self.dir_path+" found the following directories:")
			for entry in self.file_list: ##debug
				print(entry)

		return self.file_list

	def listUsingInputDir(self, enDebug, inputString, fileExtension): ## looks up for 
		self.file_list = []
		self.dir_path_array = []
		inputString = inputString
		tempoEntry = ''
		tempoArray = []
		ff = os.listdir(inputString)
		fileExtension = fileExtension

		if fileExtension == '.mod':
			for entry in ff:
				if '.mod' in entry or '.tp' in entry:
					debug.debugFunc(self, enDebug, entry)
					self.file_list.append(entry)
				else:
					tempoEntry = inputString + '/' + entry 
					if os.path.isdir(tempoEntry): ##for directories within Cadence. for processing in the future
						self.dir_path_array.append(tempoEntry)
				tempoEntry = ''		
		elif fileExtension == '.evo':
			for entry in ff:
				if '.evo' in entry:
					debug.debugFunc(self, enDebug, entry)
					self.file_list.append(entry)
				else:
					tempoEntry = inputString + '/' + entry 
					if os.path.isdir(tempoEntry): ##for directories within Cadence. for processing in the future
						self.dir_path_array.append(tempoEntry)
				tempoEntry = ''	
		else:
			print('invalid file extension')							
        
		if enDebug == 1:
			print("At: "+inputString+" found the following .mod and .tp files: ")
			for entry in self.file_list: ##debug
				print(entry)

			print("At: "+inputString+" found the following directories: ")
			for entry in self.dir_path_array: ##debug
				print(entry)
            
		return self.file_list   

	def find(self, enDebug, inputWord):	##finds the inputWord folder specified. returns full folder path as self.tempoString
		self.dir_path = os.path.realpath(__file__)
		self.dir_path = os.path.dirname(self.dir_path)
		inputWord = inputWord
				    
		ff = os.listdir(self.dir_path)
				
		for entry in ff:
			if os.path.isfile(entry):
				pass
			elif entry == inputWord:
				self.tempoString = self.dir_path +'/'+ inputWord
		if enDebug == 1:		
			print('found ' + inputWord + ' at this directory '	+ self.tempoString)	
			
		return self.tempoString

	def debug(self, inputString):
		inputString = inputString
		ff = os.listdir(inputString)

		for entry in ff:
			print(entry)

	def CadenceItemsFullPath(self, debug):
		CadenceList = self.file_list
		targetFile = ''
		fullTargetPath = []

		for entry in CadenceList:
			if '.mod' in entry or '.tp' in entry: ##refine and narrow the list to .mod and .tp only
				targetFile = CadenceDir + '/' + entry ##rebuild cadence list + directory
				fullTargetPath.append(targetFile)
        
		if debug == 1:
			for entry in fullTargetPath:
				print(entry)
            
	def edit(self, enDebug, inputString, inputArray, typeEdit): ##writes stuff on file
		location = inputString
		typeEdit = typeEdit
		tempoArray = []				
				
		if inputArray == 'self.file_list':	##needed for importing modules 
			inputArray = self.file_list
			
		if typeEdit == 1: ##type 1 if edit is add import module
			g = open(location, 'w')
			debug.debugFunc(self, enDebug, 'these are the modules to be writen on ' + location)
			if enDebug == 1:
				print(inputArray)
			for entry in inputArray:
				#print('hit')			
				tempoString = 'use module'+'"'+'./'+entry+'"'
				tempoArray.append(tempoString)
				tempoString = ''	
			for entry in tempoArray:
				g.write(entry)   
				g.write('\n')
			g.close()	
			tempoArray = []  
		elif typeEdit == 2: ##type2 not needed anymore. obsolete
			g = open(location, 'a')
			debug.debugFunc(self, enDebug, 'edit type: ' + str(typeEdit))
			g.close()
			
		elif typeEdit == 3: ##type3 add the getPreviousCbitStatus getCurrentCbitStatus and other procedures
			g = open(location, 'a')
			h = open('synthetic_mod_template','r') ##hardcoded. make sure synthetic_mod_template is on the same dir as this __file__
			hh = h.read()
			tempoString = ''
			
			for entry in hh:
				if entry == '\n':
					tempoString = tempoString + entry
					debug.debugFunc(self, enDebug, tempoString)
					g.write(tempoString)
					tempoString = ''
				else:
					tempoString = tempoString + entry
			g.write(tempoString)
			tempoString = ''
			g.close()
			h.close()
						    	               
class fileCreate():
	def __init__(self):
		pass

	def create(self,enDebug, inputString):
		inputName = inputString
		
		debug.debugFunc(self, enDebug, inputString)
		f = open(inputString, 'w')

		return True

class inputOutput():
	def __init__(self):
		self.className = inputOutput
		pass
	
	def debug(self, debug):
		if debug == 1:
			print(self.className)
		else:
			pass	
	
	def askForPackageType(self, debug, inputArray): ##after scanning ExtRefs, select for package if MRQ or TQFN
		debug = debug
		inputArray = inputArray
		tempoArray = []
		counter = 0
		
		if inputArray == []:
			print('package type not found')
		else:
			print('choose the package type: ')
			print('Type 1,2,3,4,..')
			for entry in inputArray:
					counter = counter + 1
					print(str(counter)+' '+entry)
			counter = 0		

		userInput = input()			
		return inputArray[int(userInput)-1]		
		
class true_map():
	def __init__(self):
		self.digital_pin_array = []
		self.digital_pin_array_string = ''
		
	def create_cbit_to_dp_map(self, enable_debug, cbit_reference_file,	dp_reference_file, output_file):
		f = open(cbit_reference_file, 'r')
		ff = f.read()
		h = open(dp_reference_file, 'r')
		hh = h.read()
		
		g = open(output_file, 'w') ##true cbit to dp map ## can be recycled
		
		tempo_string = ''
		digital_pin_array = []
		digital_pin_array_string = ''
		
		debug.debugFunc(self, enable_debug, '')
		
		for entry in hh:	##read .DPmap and produre a one line string no space consist of all dp pins
			if entry == '\n':
				debug.debugFunc(self, enable_debug, tempo_string + '\n')
				digital_pin_array.append(tempo_string)
				digital_pin_array_string = digital_pin_array_string +'+'+ tempo_string
				tempo_string = ''
			else:
				tempo_string = tempo_string + entry
		
		digital_pin_array_string = digital_pin_array_string[1:] ##remove the + at the start of this string
		
		self.digital_pin_array_string = digital_pin_array_string ##update class variable self.digital_pin_array_string
		self.digital_pin_array = digital_pin_array ##update class variable self.digital_pin_array
		
		i = 0
		hit = 0
		tempo_string = ''
		
		for entry in ff:
			if entry == '\n':
				while i == 0:
					prompt_message = '\n enter the digital pin associated with ' + str(tempo_string + '\n')
					user_input = input(prompt_message)
					if user_input == '/':	##user skips this digital pin
						tempo_string = ''
						break
					else:
						if user_input in digital_pin_array: ## user input matches or is found in the list of catalogued dp pins
							g.write(tempo_string + ' ' + user_input + '\n')	##format: <cbit name><space><digital pin name>
							hit = 1 ## alert the while loop that
							
							prompt_message = ' do you want to add more digital pin? yes or no '
							user_input = input(prompt_message)
							user_input = user_input.lower()
							if (user_input == 'y') or (user_input == 'ye') or (user_input == 'yes'):
								i = 0	##this if else statement here is confusing
							else:
								i = 0
								break
						else:
							print('\n invalid input, please try again \n')
							i = 0
				tempo_string = '' ##clear tempo_string 
			else:
				tempo_string = tempo_string + entry						
									
class debug():
	def __init__(self):
		pass
	def debugFunc(self, toggle, additionalWords):
		if toggle == 1:
			print(str(additionalWords))
		else:
			pass		
			
class myPrinter():
	def __init__(self):
		pass
	def printThis(self, inputString):
		print(inputString)	
		



















