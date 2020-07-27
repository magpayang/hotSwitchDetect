#! /usr/bin/python

import myLibraries
import findThenReplace3

enDebug = 0 ##enDebug = 0 for no verbose, enDebug = 1 for additional information but messy cli


aa = myLibraries.smartfinder()      ##aa finds Cadence full dir, list contents in Cadence dir, outputs CadenceDir and CadenceList(array)
									##aa does type 1 and type 3 edit of synthetic.mod
cc = myLibraries.fileCreate()		##cc creates synthetic.mod
ee = myLibraries.smartfinder()		##ee finds ExtRefs full dir, list contents in ExtRefs dir, outputs ExtRefs and ExtRefsList(array)
									##ee removes '.evo' extension for prosperity
									##ee ask for the adapter type. for HS87 we have hs87tqfn, hs87tqfnB and hs87tqfnC
									##ee extracts all cbitpins from HS87_TQFN_package.evo and creates a file  HS87_TQFN_package.evo.map
hh = myLibraries.inputOutput()		##hh. for hs87, allows user to select between HS87_TQFN and HS87_MRQ. needs user input
mrDebug = myLibraries.debug()		##mrDebug.debugFunc(enDebug, additionalWords). replace enDebug with integer 1 to enable this function
									## the second argument must be a string. use this to confirm if output is the same as expected


aa.list(enDebug = 0)                            ##test
CadenceDir = aa.find(enDebug, "Cadence")     	##find and returns full Cadence directory
mrDebug.debugFunc(enDebug, CadenceDir)		    ##debug

CadenceList = aa.listUsingInputString(enDebug, CadenceDir, '.mod') ## List the contents of Cadence folder. returns an array self.file_list
## beware of additional folders inside Cadence

##comment for the moment synthetic.mod creation and level 1 and level 2 edits
createThisFile = CadenceDir + '/' + 'synthetic.mod' 	##fullpath with filename of synthetic.mod
cc.create(enDebug, createThisFile)						##create synthetic.mod

##now time to edit synthetic.mod
aa.edit(enDebug, createThisFile, 'self.file_list', 1) 	##type1 edit. write all detected .mod and .tp as imports 
aa.edit(enDebug, createThisFile, '', 3) 				##types the majority of synthetic.mod									

ExtRefsDir = ee.find(enDebug, 'ExtRefs')									##full directory of ExtRefs
ExtRefsList = ee.listUsingInputString(enDebug, ExtRefsDir, '.evo')			##list the contents of ExtRefs folder. returns an array

packageTypesFound = ee.refineArrayFunc(enDebug, ExtRefsList, '.evo', '')	##removes '.evo' extension for prosperity

packageTypeSelected = hh.askForPackageType(enDebug, packageTypesFound)		##for hs87, allows user to select between HS87_TQFN and HS87_MRQ. needs user input
mrDebug.debugFunc(enDebug, packageTypeSelected)								##replace enDebug with int 1 to get feedback after user input

packageTypeSelectedDir = ExtRefsDir + '/' + packageTypeSelected + '.evo'	##full path of selected package type .evo
mrDebug.debugFunc(enDebug, packageTypeSelectedDir)							

adapterSelected = ee.listFoundAdapterEVO(enDebug, packageTypeSelectedDir) 	##ask user to pick the correct adapter type
mrDebug.debugFunc(1, adapterSelected)

	##def pinNameFinder(self, debug, targetWord, targetString, targetLength, targetEndKey, targetFile, outputFile)
ee.pinNameFinder(enDebug, adapterSelected, 'CbitPins', 14, 'MaxSite', packageTypeSelectedDir, packageTypeSelectedDir+'.map') ##extract and catalogue all CbitPins
