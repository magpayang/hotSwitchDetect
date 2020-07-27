--------------------------------------------------------------------------------
-- Filename:
--     FlowControl.mod
--
-- Purpose:
--     LTX MX Flow Control-specific routines that are used in SP&C Template.
--
-- Routines:
--     Enable_Testing	         -- Set state of Enable_boolean.  Typically used in FlowEnable_Subflow.
--     Set_FlowEnable_False      -- Set OpVar_FlowEnable & OpVar_FlowEnableOverride to FALSE.  Typically used in OnLoad.
--     Check_Loadboard_ID        -- Compare installed LB Barcode to version stored during OnLoad.  Typically used in FlowEnable_Subflow.
--     Get_LB_Barcode            -- Gets Barcode of installed LB from enVision and stores into Cadence variable Stored_HardwareBarcode.
--     Display_Disable_Statement -- Prints failure information to stdout when FocusCalibration fails.  Also displays HW Check fail if TRUE.
--     LoVDD_Testing             -- Sets LoVDD_PASS flag to TRUE if run.  Typically used in UsrCal_Flow
--     HiVDD_Testing             -- Sets HiVDD_PASS flag to TRUE if run.  Typically used in UsrCal_Flow
--     Get_LB_Name		 -- Gets Loadboard name from enVision and stores into Cadence variable Stored_HardwareName.
--     Set_FCal_Flags_False	 -- Sets LoVDD_PASS & HiVDD_PASS flags to FALSE.  Typically used in UsrCal_Flow.
--     Set_Enable_boolean 	 -- Run after HW Checker.  Sets Enable_boolean and OpVar_FlowEnable to TRUE  if Checker & FocusCal pass.
--     UsrCal_FlowEnable	 -- Evaluates state of OpVar_RunUsrCal_Flow to enable UsrCal_Flow
--     Get_FlowEnableOverride    -- Determines state of OpVar_FlowEnableOverride.
--
--
-- History:
--     04/16/2010  pla             -- Original version.
--     08/08/2011  pla             -- Updated lib_operator_prompt.mod path in "use module" statement   
--
-- Operator variables:
--      OpVar_FlowEnable
--	OpVar_FlowEnableOverride
--	OpVar_Force_HW_Check
--      OpVar_RunUsrCal_Flow
--
-- Globals:
--	
--------------------------------------------------------------------------------
use module "user_globals.mod"
use module "user_digital.mod"
use module "user_cbit_ctrl.mod"
use module "tester_cbits.mod"
use module "./lib/lib_HP3458A_gpib.mod"
use module "/testeng/testprog/loc/cardcat/ltx_mx/libraries/lib_operator_prompt/lib_operator_prompt.mod"

const

end_const

global

end_global

static
    word list[MAX_SITES]   : store_active_sites 
    boolean                : Checker_PASS = FALSE
    boolean                : Enable_boolean = FALSE
    boolean                : LoVDD_PASS = FALSE
    boolean                : HiVDD_PASS = FALSE
    string[255]            : Stored_HardwareBarcode
    string[255]            : Stored_HardwareName=""
end_static
    

function Enable_Testing : boolean
--------------------------------------------------------------------------------
--  

local

    boolean          : EnableTesting = FALSE
    boolean          : EnableTestingOverride = FALSE
    boolean          : EnableBoolean = FALSE

end_local

--******************************************************************************
--  The OpVar_FlowEnable variable is set TRUE or FALSE depending on the results
--   of the loadboard checks performed during program load.

--  This test reads back the state of OpVar_FlowEnable and OpVar_FlowEnableOverride.
--              
--  If OpVar_FlowEnableOverride=TRUE, the test result is TRUE, otherwise
--   the test result is equal to the state of OpVar_FlowEnable.
--
--  The result of this test and the previous test together determine whether or
--  not test flow is ENABLED.
--******************************************************************************

body

    get_expr("OpVar_FlowEnable", EnableTesting)  
    get_expr("OpVar_FlowEnableOverride", EnableTestingOverride )  
    
    if EnableTestingOverride then
        EnableBoolean = EnableTestingOverride
     else
        EnableBoolean = EnableTesting  
    end_if

    return(EnableBoolean)

end_body

procedure Set_FlowEnable_False
--------------------------------------------------------------------------------
--  

local
   
end_local

body

    set_expr("OpVar_FlowEnable", FALSE) -- Set FlowEnable to FALSE to force the FlowEnable checker to Run first time through OnStart flow
    if tester_simulated then
        set_expr("OpVar_FlowEnableOverride", TRUE) -- Set FlowEnableOverride to TRUE in simulation mode
    else    
    set_expr("OpVar_FlowEnableOverride", FALSE) -- Set FlowEnableOverride to FALSE to force the FlowEnable checker to Run first time through OnStart flow
    end_if
    
end_body

function Check_Loadboard_ID(Allow_Retry)  : boolean
--------------------------------------------------------------------------------
--  

in boolean  :   Allow_Retry

local


  integer            : PromStatus,PromNum
  string[MAX_STRING] : Board1_HardwareRevision  -- Return values read from EEPROM
  string[MAX_STRING] : Board1_HardwareBarcode   -- Return values read from EEPROM
  string[MAX_STRING] : Board1_HardwareName      -- Return values read from EEPROM
  integer            : Board1_HardwareNumber    -- Return values read from EEPROM
  boolean            : BarcodeMatch = FALSE
  boolean            : EnableTestingOverride = FALSE
  boolean            : EnableTesting = FALSE

end_local

static
  boolean            : compareBarcode = TRUE
end_static    

body

--******************************************************************************
--  This test reads back the currently installed loadboard Barcode and compares
--   it to the stored Barcode readback from program load.  
--              
--  If the two strings match then this test passes back TRUE
--
--  If the two strings do not match and OpVar_FlowEnableOverride=TRUE then this
--  test passes back TRUE.
--
--  Otherwise, this test passes back FALSE.
--
--  The result of this test and the previous test together determine whether or
--  not test flow is ENABLED.
--
-- If Allow_Retry is TRUE then original board can be placed back on tester and
-- function will re-read Barcode and perform logic based on results.

-- If Allow_Retry is FALSE and original board is removed then program MUST be
-- unloaded and reloaded to recover testing capability.
--******************************************************************************

-- Revision History
-- 01/30/2010       pla     original
-- 02/10/2010       pla     added logic for allowing/disallowing retry after board removal



  -- Read from load board EEPROM (look for memory map revision first)
    PromNum = 1  -- Load Board EEPROM
    get_expr("OpVar_FlowEnableOverride", EnableTestingOverride )  
    get_expr("OpVar_FlowEnable", EnableTesting )
    
    if NOT EnableTestingOverride AND compareBarcode then
        PromStatus = RW_Maxim_EEPROM_Data(READ_EEPROM_BARCODE, PromNum, Board1_HardwareRevision, Board1_HardwareBarcode, Board1_HardwareName, Board1_HardwareNumber)
        if (PromStatus <> 0) then
            println(stdout,"ERROR Reading Load Board EEPROM!")
        end_if

        if Stored_HardwareBarcode <> Board1_HardwareBarcode then
            set_expr("OpVar_FlowEnable", FALSE)  -- Test flow is disabled
            
            println(stdout, " ")
            println(stdout, " ")
            println(stdout, " ****************************************************************************************************")
            println(stdout, " ****************************************************************************************************")
            println(stdout, " **********                                                                                **********")    
            println(stdout, " ")
            println(stdout, " ")
            println(stdout, "         CURRENTLY INSTALLED LOADBOARD BARCODE DOES NOT MATCH VALUE READ ON PROGRAM LOAD ")
            println(stdout, " ")
            println(stdout, "@t@t          Program Load Barcode  = ", Stored_HardwareBarcode)
            println(stdout, " ")
            println(stdout, "@t@t          Installed LB Barcode  = ", Board1_HardwareBarcode)   
            println(stdout, " ") 
            println(stdout, "               TESTING IS PERMANENTLY DISABLED UNTIL PROGRAM UNLOAD AND RELOAD ")
            println(stdout, " ") 
            
            if Allow_Retry then
                println(stdout, "               OR LOADBOARD INSTALLED DURING PROGRAM LOAD IS REDOCKED TO TESTHEAD. ")
                println(stdout, " ")
            else
                compareBarcode = FALSE  --This will force unload and reload of test program
            end_if
            
            println(stdout, " ")
            println(stdout, " **********                                                                                **********")
            println(stdout, " ****************************************************************************************************")
            println(stdout, " ****************************************************************************************************")
           
        else
            BarcodeMatch = TRUE  
            --**********************************************************
            -- The next if statement logic allows Operator to recover
            -- after reinstalling original loadboard back on testhead
 
            --**********************************************************           
            if Allow_Retry then
                if NOT Enable_Testing AND Enable_boolean then
                    set_expr("OpVar_FlowEnable", TRUE )
                end_if
           end_if
       end_if
              
    else_if NOT EnableTestingOverride AND NOT compareBarcode then
        BarcodeMatch = FALSE

        println(stdout, " ")
        println(stdout, " ")
        println(stdout, " ****************************************************************************************************")
        println(stdout, " ****************************************************************************************************")
        println(stdout, " **********                                                                                **********")    

        println(stdout, " ")
        println(stdout, "            LAST LOADBOARD BARCODE TESTED DID NOT MATCH VALUE READ ON PROGRAM LOAD ")
        println(stdout, " ")
        println(stdout, "@t@t            Program Load Barcode  = ", Stored_HardwareBarcode)
        println(stdout, " ")
        println(stdout, "               TESTING IS PERMANENTLY DISABLED UNTIL PROGRAM UNLOAD AND RELOAD ")
        println(stdout, " ") 
        println(stdout, " **********                                                                                **********")
        println(stdout, " ****************************************************************************************************")
        println(stdout, " ****************************************************************************************************")
    else  
    --***************OVERRIDE CHECK FOR LOADBOARD MATCH********************--
    --***************** EnableTestingOverride = TRUE  *********************--       
        BarcodeMatch = TRUE    
    end_if

    return(BarcodeMatch) 
 
end_body

procedure Get_LB_Barcode
--------------------------------------------------------------------------------
--  

local


end_local

body

  get_expr("TestProgData.LoadBrdId", Stored_HardwareBarcode)

end_body

procedure Display_Disable_Statement  
--------------------------------------------------------------------------------
--  

local


end_local

body


    println(stdout, " ")
    println(stdout, "")
    println(stdout, " ****************************************************************************************************")
    println(stdout, " ****************************************************************************************************")
    println(stdout, " **********                                                                                **********")    
    println(stdout, " ")
    println(stdout, "                       FAILING RESULTS FOR HW CHECKER RUN DURING PROGRAM LOAD ")
    println(stdout, " ")

-- Uncomment this section when Focus Calibration added to test program  ***Note use of LoVDD_PASS***
if NOT LoVDD_PASS then
    println(stdout, "@t@t@t  LoVDD Focus Calibration FAILED  ")
    println(stdout, " ")
end_if

-- Uncomment this section when Focus Calibration added to test program***Note use of HiVDD_PASS***
if NOT HiVDD_PASS then
    println(stdout, "@t@t@t  HiVDD Focus Calibration FAILED  ")
    println(stdout, " ")
end_if

if NOT Checker_PASS then
    println(stdout, "@t@t@t  Loadboard Checker FAILED  ")
    println(stdout, " ")
end_if

    println(stdout, "                     TESTING IS DISABLED UNTIL HW ISSUE RESOLVED  ")
    println(stdout, " ")
    println(stdout, " **********                                                                                **********")
    println(stdout, " ****************************************************************************************************")
    println(stdout, " ****************************************************************************************************")
    println(stdout, "")

end_body

function LoVDD_Testing : boolean
--------------------------------------------------------------------------------
--  

local

end_local

body

    LoVDD_PASS = TRUE  

    return(LoVDD_PASS)

end_body

function HiVDD_Testing : boolean
--------------------------------------------------------------------------------
--  

local

end_local

body

    HiVDD_PASS = TRUE  

    return(HiVDD_PASS)

end_body

procedure Get_LB_Name
--------------------------------------------------------------------------------
--  

local


end_local

body

  get_expr("TestProgData.LoadBrdType", Stored_HardwareName) 

end_body

procedure Set_FCal_Flags_False
--------------------------------------------------------------------------------
--  

local

end_local

body

    HiVDD_PASS = FALSE
    LoVDD_PASS = FALSE  

end_body


procedure Set_Enable_boolean   
--------------------------------------------------------------------------------
--  
--*********************************************************************************
-- This procedure runs once after the HW Checker is performed, and sets both the 
-- Cadence global "Enable_boolean" and the Operator Variable "OpVar_FlowEnable" 
-- based on the results of the HW Checker and Timing Calibration.
--*********************************************************************************

local

    boolean     :   ForceHWCheck
end_local

static
    boolean     :   localSetup = TRUE

end_static

body

    get_expr("OpVar_Force_HW_Check", ForceHWCheck)

    if localSetup AND ForceHWCheck then
        if Checker_PASS AND LoVDD_PASS AND HiVDD_PASS then
            Enable_boolean = TRUE
            set_expr("OpVar_Force_HW_Check", FALSE)
        else
            Enable_boolean = FALSE
            
            if NOT LoVDD_PASS or NOT HiVDD_PASS then
                set_expr("OpVar_FCal_Failed", TRUE)
            end_if
            
        end_if    
        set_expr("OpVar_FlowEnable", Enable_boolean)
    
        if Enable_boolean then
            println(stdout, " ")
            println(stdout, "")
            println(stdout, " ****************************************************************************************************")
            println(stdout, " ****************************************************************************************************")
            println(stdout, " **********                                                                                **********")    
            println(stdout, "                             HW CHECKER PASSED - TESTING IS ENABLED ")
            println(stdout, " **********                                                                                **********")
            println(stdout, " ****************************************************************************************************")
            println(stdout, " ****************************************************************************************************")
            println(stdout, "")

            localSetup = FALSE

        end_if

    elseif NOT localSetup AND ForceHWCheck then  

       --This case is entered upon setting OpVar_Force_HW_Check to TRUE after the HW Checker has already passed earlier in testing process.
       --Reset all logic flags to initial state before running HW Checker

        Enable_boolean = FALSE
        set_expr("OpVar_FlowEnable", Enable_boolean)
        Checker_PASS = FALSE
        localSetup = TRUE
    else

    end_if

 end_body

function UsrCal_FlowEnable   : boolean
--------------------------------------------------------------------------------


--  
    --*****************************************************
    --  This function evaluates the state of OpVar_RunUsrCal_Flow
    --  and chooses an exit port based on its value.
    --  The UsrCal subflow is either entered or bypassed.
    --*****************************************************

local

    boolean     :   Run_UsrCal
      
end_local

body

    --*****************************************************
    --  Setting FocusCal Pass_flags to known state
    --*****************************************************

    LoVDD_PASS = TRUE
    HiVDD_PASS = TRUE

    --*****************************************************
    --  There are two possible flows from here:
    --
    --  ***********BYPASS UsrCal_Flow********************
    --  If FocusCal flow is bypassed, then setting these 
    --  to PASS here prevents unintended error condition
    --  in FlowEnable subflow at start of OnStart flow.  
    --  
    --  **************RUN UsrCal_Flow********************
    --  These flags are set to FALSE when entering the 
    --  LoVDD_Calibration test.  If either Lo or Hi
    --  Focus Calibration passes, then the appropriate
    --  flag is set to TRUE.

    --  Within each Focus Calibration testblock, the
    --  option exists to load stored values from file
    --  instead of executing the TDR process.  This option is
    --  enabled by setting the "Execute_Cal" variable to FALSE
    --  in Operator Variables window.  This parameter should be
    --  set to TRUE for production.
    --*****************************************************    

    get_expr("OpVar_RunUsrCal_Flow", Run_UsrCal)  

    return(Run_UsrCal)

end_body

function Get_FlowEnableOverride : boolean
--------------------------------------------------------------------------------
--  

local

--    boolean          : EnableTesting = FALSE
    boolean          : EnableTestingOverride = FALSE
--    boolean          : EnableBoolean = FALSE

end_local

--******************************************************************************
--  The OpVar_FlowEnableOverride variable setting is determined.

--  This test reads back the state of OpVar_FlowEnableOverride and returns that value.
--              
--
--******************************************************************************

body

    get_expr("OpVar_FlowEnableOverride", EnableTestingOverride )  
   
    return(EnableTestingOverride)

end_body

