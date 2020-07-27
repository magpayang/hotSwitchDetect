--------------------------------------------------------------------------------
-- Filename:
--     lib_common.mod
--
-- Purpose:
--     LTX MX non variant specific routines that are commonly used.
--
-- Routines:
--     Check_testhead_power      -- Checks if testhead power is on.  Typically used in OnLoad.
--     Start_timer               -- For starting the elapsed and cumulative test timer.
--     Print_timer               -- For printing the elapsed and cumulative test times to the ascii dataviewer.
--     Print_banner_message      -- Print a standard 1 to 3 line banner message to the ascii dataviewer.
--     lc_Print_alarms           -- Prints alarms to stdout
--     Set_Device_Name           -- Sets TestProgData.Device to value stored in OpVar_ProductUnderTest
--
-- History:
--     11/03/2009  timw             -- Original version. Check_testhead_power, Start_timer, 
--                                  -- Print_timer, Print_message_banner added.
--     01/18/2010  pla              -- lc_Print_alarms added - copied from /ltx/apps_modules/print_alarms 
--     01/19/2010  pla              -- Set_Device_Name added 
--
-- Operator variables:
--     None
--
-- Globals:
--                                             -- The following 2 globals are use by Used by Start_timer and Print_timer
static boolean:    g_print_test_time = FALSE   -- flag to enable or disable printing of the timer. 
static float:      g_last_print_timer = 0s     -- variable to keep the time at the last Print_timer call
--
--------------------------------------------------------------------------------

function Check_testhead_power  :  boolean
--------------------------------------------------------------------------------
-- Description:
-- Gets the status of the testhead and socket adapter power
-- If the power is not turned on then an error message will be printed out on the 
-- dataviewer to prompt the user to turn on the power.
--
-- Function:
--     Returns TRUE if power is turned on.
--
-- Global variable usage:  
--     none
--
-- Operator variable usage:
--     Error_Message : string : If there is an error, then it is set to the current 
--                              error message and is printed out to the dataviewer.
--
-- History:
--     11/03/2009  timw             -- Original version
--     04/06/2010  pla              -- changed procedure to function and removed OnLoad_Error Operator Variable setting    
--------------------------------------------------------------------------------

local
   string[80]  : error_message
   string[10]  : response
   integer     : loopcnt 
   boolean     : PowerOn                                         
end_local

const max_loops = 4               -- put a limit on how many times the user is prompted

body

    loopcnt    = max_loops

--------------------------------------------------------------------------------
-- ** Check to ensure Test Head Power and DUT Power are switched "On"
--     	    1    ==    Test Head power is on 
--          0    ==    Test Head power switch is in the "off" position 
--         -2    ==    Test Head power is unavailable
--                     (there is no power to the test head digital backplane)
--         -3    ==    Test Head power is unavailable
--                     (there is no power to the test head analog backplane)
--         -4    ==    Test Head power is unavailable
--                     (due to a power supply fault condition)
--------------------------------------------------------------------------------

    head_pwr_sts       -- get the status of the testhead power
    while not (head_pwr_sts = 1 and loopcnt > 0) do
        if head_pwr_sts = 0 then
            Print_banner_message( "Please ensure Test Head Power is turned ON", "Press 'Enter' to Continue", "" )
        else_if head_pwr_sts = -2  then
            Print_banner_message( "Test Head power is unavailable", "There is no power to the test head digital backplane", "")
        else_if head_pwr_sts = -3  then
            Print_banner_message( "Test Head power is unavailable", "There is no power to the test head analog backplane", "")
        else_if head_pwr_sts = -4  then
            Print_banner_message( "Test Head power is unavailable due to a power supply fault condition", "", "")                
        end_if
        
        input(stdin, response!L)
    
        head_pwr_sts
        loopcnt = loopcnt - 1
    end_while

--------------------------------------------------------------------------------
--          1 == Socket adapter power is on  
--          0 == Socket Adapter power switch is in the "off" position
--         -1 == Socket Adapter power is unavailable
--               (but head power is on)  
--         -2 == Socket Adapter power is unavailable
--               (there is no power to the test head digital backplane)
--         -3 == Socket Adapter power is unavailable
--               (there is no power to the test head analog backplane)
--         -4 == Socket Adapter power is unavailable
--               (due to a power supply fault condition)
--         -5 == Socket Adapter power is unavailable
--               (test head power switch is in the "off" position)
--------------------------------------------------------------------------------

    sa_pwr_sts       -- get the status of the socket adapter power
    while not (sa_pwr_sts = 1) do
        if sa_pwr_sts = 0 then
            Print_banner_message( "Please ensure DUT Power is turned ON", "Press 'Enter' Continue", "") 
        else_if sa_pwr_sts = -1 then 
            Print_banner_message( "Socket Adapter power is unavailable but head power is on", "", "") 
        else_if sa_pwr_sts = -2 then 
            Print_banner_message( "Socket Adapter power is unavailable", "There is no power to the test head digital backplane", "") 
        else_if sa_pwr_sts = -3 then 
            Print_banner_message( "Socket Adapter power is unavailable", "There is no power to the test head analog backplane", "") 
        else_if sa_pwr_sts = -4 then 
            Print_banner_message( "Socket Adapter power is unavailable due to a power supply fault condition", "", "") 
        else_if sa_pwr_sts = -5 then 
            Print_banner_message( "Socket Adapter power is unavailable", "Test head power switch is in the off position", "")                       
        end_if
        
        input(stdin, response!L)
    
        sa_pwr_sts
        loopcnt = loopcnt - 1
    end_while    

    if( loopcnt > 0 ) then                                -- if loopcnt > 0 then power is on and loopcnt not expired
        PowerOn = TRUE
    else
        PowerOn = FALSE
    end_if
    
    return(PowerOn)

end_body

procedure Start_timer(display_time_ena)
in boolean :  display_time_ena  --  input, flag to enable printing of the timer

-------------------------------------------------------------------------------------------
-- Description:
--     If display_time_ena is set, then the timer will be initialized and the timer will be
--     enabled for printing int the Print_timer routine.
--
-- Global variables:
--     g_print_test_time              -- flag to enable or disable printing of the timer
--     g_last_print_timer             -- variable to keep the time at the last Print_timer call
--
-- Operator variable usage:
--     none
--
-- History:
--     11/03/2009  timw             -- Original version
-------------------------------------------------------------------------------------------

body
    if display_time_ena then
        g_print_test_time = true
        println(stdout)
        g_last_print_timer = 0s
        start_timer
    else
        g_print_test_time = false
    end_if
end_body


procedure Print_timer(test_time_string)

in string[40]  : test_time_string    -- input string to be printed out with the timer.
                                     -- Typically, it will be set to test_limits[1].test_text
                                     -- if test_limits is a limit struct. Print_timer is typically
                                     -- called right before or after a test_value statement.
 
-------------------------------------------------------------------------------------------
-- Description:
--     Prints out the value of test_time_string, time since last call(miliseconds), and total time (seconds).
--
-- Global variables:
--     g_print_test_time              -- flag to enable or disable printing of the timer
--     g_last_print_timer             -- variable to keep the time at the last Print_timer call
--
-- Operator variable usage:
--     none
--
-- History:
--     11/03/2009  timw             -- Original version
--
-------------------------------------------------------------------------------------------

local
    float      : current_time, test_time
end_local

body
    
    if g_print_test_time then
        current_time = snap_timer
        test_time = current_time - g_last_print_timer
--        debug_text(sprint("TIMER: ",test_time_string:-40," ",test_time*1000.0:15:3!f," ",current_time:15:3!f))
        debug_text(sprint("TIMER: ",test_time_string:-40," This test (ms):",test_time*1000.0:15:3!f," Total (ms):",current_time*1000.0:15:3!f,"@n"))
        g_last_print_timer = current_time
    end_if
end_body


procedure Print_banner_message( line1, line2, line3 )

in string[64] : line1, line2, line3

-------------------------------------------------------------------------------------------
-- Description:
--     Prints a banner message to the dataviewer window in a standard format of up to 3 lines
--     The first line is always printed.  
--     If the second or third lines are empty then the line will not be printed.
--     Each line can be up to 64 characters.
--     The formatted line is 80 characters with a "*" border
--
-- Global variables:
--     none
--
-- Operator variable usage:
--     none
--
-- History:
--     11/03/2009  timw             -- Original version
--
-------------------------------------------------------------------------------------------

local
  string[130] : line1_out, line2_out, line3_out
  integer : num_spaces
  string[40] : spaces
  integer : i
end_local

const MAX_MESSAGE_WIDTH = 80
const stars = "**********"

body

-- Make sure there are an even number of characters in the input text.

  if  len(line1) mod 2 <> 0 then
  line1 = line1 + " "
  end_if

  if  len(line2) mod 2 <> 0 then
  line2 = line2 + " "
  end_if

  if  len(line3) mod 2 <> 0 then
  line3 = line3 + " "
  end_if


-- Center the input text
  
  num_spaces = (MAX_MESSAGE_WIDTH - len( line1 ))/2
  spaces = ""
  for i = 1 to num_spaces do
      spaces[i] = " "
  end_for  
  line1_out = " " + stars + spaces + line1 + spaces + stars
  
  num_spaces = (MAX_MESSAGE_WIDTH - len( line2 ))/2
  spaces = ""
  for i = 1 to num_spaces do
      spaces[i] = " "
  end_for  
  line2_out = " " + stars + spaces + line2 + spaces + stars

  num_spaces = (MAX_MESSAGE_WIDTH - len( line3 ))/2
  spaces = ""
  for i = 1 to num_spaces do
      spaces[i] = " "
  end_for  
  line3_out = " " + stars + spaces + line3 + spaces + stars  


-- Print it out

  println(stdout, "")
  println(stdout, " ****************************************************************************************************")
  println(stdout, " ****************************************************************************************************")
  println(stdout, " **********                                                                                **********")
  println(stdout, line1_out)       -- always print line1

  if len(line2) <> 0 then
      println(stdout, line2_out)   -- only print if not an empty string
  end_if

  if len(line3) <> 0 then
      println(stdout, line3_out)   -- only print if not an empty string
  end_if

  println(stdout, " **********                                                                                **********")
  println(stdout, " ****************************************************************************************************")
  println(stdout, " ****************************************************************************************************")
  println(stdout, "")

end_body

procedure lc_Print_alarms 
-------------------------------------------------------------------------------------------

--             This procedure will print the description of any
--          currently active alarms to stdout.

    local boolean           : alarm_flag            
    local lword             : alarm_count           
    local lword             : alarm_codes[10]       
    local integer           : index                 
    local string[80]        : alarm_text            

body

    clear alarms

    read alarms into alarm_flag

    if alarm_flag then
        read alarms into alarm_codes count into alarm_count
        for index = 1 to integer (alarm_count) do
            alarm_text = errnum_text (alarm_codes[index])
            print (stdout, alarm_text, "@n")
        end_for
    end_if

end_body
procedure Set_Device_Name  
--------------------------------------------------------------------------------
--  
-- This routine sets the TestProgData.Device parameter to the value stored in 
-- the OpVar_ProductUnderTest variable.  It is called in the Set_Device_Name microflow,
-- which can be added as an exit object to the block just before Operator_Prompt to change
-- device name before running the Operator Prompts.  This allows multiple part numbers to be
-- tested from one TestProgData object.
--

local
    string[MAX_STRING]  :   DeviceName
end_local

body
    get_expr("OpVar_ProductUnderTest", DeviceName)
    set_expr("TestProgData.Device", DeviceName)
end_body

