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


ExtRefsDir = ee.find(enDebug, 'ExtRefs')		##full directory of ExtRefs
CadenceDir = aa.find(enDebug, "Cadence")     	##finds and returns full Cadence directory

ee.searchUsingDirThenDelete(1, ExtRefsDir, '.map')	##deletes '.map' files
##aa.searchUsingDirThenDelete(1, CadenceDir, 'synthetic.mod') ##deletes synthetic.mod file

ExtRefsList = ee.listUsingInputDir(enDebug, ExtRefsDir, '.evo')			##list the contents of ExtRefs folder. returns an array
CadenceList = aa.listUsingInputDir(enDebug, CadenceDir, '.mod') 			## List the contents of Cadence folder. returns an array self.file_list

packageTypesFound = ee.refineArrayFunc(enDebug, ExtRefsList, '.evo', '')	##removes '.evo' extension for prosperity

packageTypeSelected = hh.askForPackageType(enDebug, packageTypesFound)		##for hs87, allows user to select between HS87_TQFN and HS87_MRQ. needs user input
mrDebug.debugFunc(enDebug, packageTypeSelected)								##replace enDebug with int 1 to get feedback after user input

packageTypeSelectedDir = ExtRefsDir + '/' + packageTypeSelected + '.evo'	##full path of selected package type .evo
mrDebug.debugFunc(enDebug, packageTypeSelectedDir)							

adapterSelected = ee.listFoundAdapterEVO(enDebug, packageTypeSelectedDir) 	##ask user to pick the correct adapter type
mrDebug.debugFunc(1, adapterSelected)

cbitPinMapDir = packageTypeSelectedDir+'.map'
ee.pinNameFinder(enDebug, adapterSelected, 'CbitPins', 14, 'MaxSite', packageTypeSelectedDir, cbitPinMapDir) ##extract and catalogue all CbitPins

mrDebug.debugFunc(enDebug, CadenceDir)		    ##debug

## beware of additional folders inside Cadence

##comment for the moment synthetic.mod creation and level 1 and level 2 edits
createThisFile = CadenceDir + '/' + 'synthetic.mod' 	##fullpath with filename of synthetic.mod
cc.create(enDebug, createThisFile)						##create synthetic.mod

##now time to edit synthetic.mod
aa.edit(enDebug, createThisFile, 'self.file_list', 1) 	##type1 edit. write all detected .mod and .tp as imports 
aa.edit(enDebug, createThisFile, '', 3) 				##types the majority of synthetic.mod			
##aa.edit(enDebug, createThisFile, packageTypeSelectedDir+'.map', 4)	##adds maping using synthetic.mod ## maybe we can use findthenreplace instead of this
allCbits = aa.pinArranger(enDebug, cbitPinMapDir)	##opens HS87_TQFN_packages.evo.map then rearanges pins so that results in only one phrase separated by plus		

