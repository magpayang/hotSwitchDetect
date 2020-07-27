--------------------------------------------------------------------------------
-- Filename:
--     lib_Glitch_Detect.mod
--
-- Purpose:
--     LTX MX non variant specific routines for use during EOS testing.
--
-- Routines:
--     Check_for_Glitch              -- Checks for Glitch on specific DUT pin on which external scope is connected
--     Enable_UHIB_for_Glitch_Detect -- Initializes UHIB for receiving Start-of-Test requests from scope; included in OnInit Flow
--
--
-- History:
--     05/27/2011  tw/dw            -- Original version.
--     06/15/2011  pla/dw           -- made UHIB_ADDRESS private const; added "g_" to global variable; comment edits
--                                  -- Changed Enable_UHIB_for_Glitch_Detect from function to procedure
--
-- Operator variables:
--     None
--
-- Globals:
--  Gets value of DEGLITCH_ON parameter in Globals_Spec of Template
--                                            
--------------------------------------------------------------------------------


private const UHIB_ADDRESS = 5		-- initialize UHIB address for use in GPIB syntax

global
    
        boolean : g_Deglitch_On
        
end_global


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
procedure Check_for_Glitch
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------  

local

    boolean         : timeout
    string[100]     : readback = ""
    string[100]     : status_byte
    word            : status_byte_word
    
end_local

body
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------
--												-------
--    Enable_UHIB_for_Glitch_Detect function below must be in OnInit Flow  			-------
--    Enable_UHIB_for_Glitch_Detect(UHIB_address)  -- sets up UHIB board to generate SRQ	-------
--												-------
-------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------    																					

   -- Get enVision variable to define deglitch status    
   get_expr("DEGLITCH_ON", g_Deglitch_On)
	 
   if g_Deglitch_On then
   
        -- Request the status byte and see if the scope sent a Glitch trigger pulse.		
    	talk cx to gpib address UHIB_ADDRESS with sprint ("*STB?")					
    	listen cx to gpib address UHIB_ADDRESS into readback for 100 bytes timeout into timeout	
    	status_byte = readback
    
    	status_byte_word = word(status_byte)
     
    	if status_byte_word = 65 then	-- if TRUE, Glitch Detected
   
        	-- Run following line in order to clear UHIB SRQ line and re-arm for other glitches     
        	talk cx to gpib address UHIB_ADDRESS with sprint ("rstEDR 1")
                
        	GLITCH DETECTED			-- This statement will cause an error and the program
						-- will stop.

        	-- To trace back to the function call that caused the glitch, go to the Navigation Panel in the 
		-- Debugger. Then use Echo Call Chain and/or Get Caller to trace back to the function that 
		-- caused the glitch (keep clicking on Get Caller until the offending function is found).
        	-- The Echo Call Chain will display a list of functions that were called to get to the 
		-- Glitch Detection.  If the same function is called more than once in the test plan
		-- (very likely) the user may not know which was the offending function call; whereas 
		-- Get Caller, after multiple clicks will take the user directly back to the offending 
		-- function call.
		--
		-- Another method to switch to the routine that caused the glitch, is to use the tb
		-- (trace back) command in the Debugger window; the window at the bottom of the LTX
		-- Cadence Debugger window, directly to the right of the word enVision.
       
         
    	end_if
    end_if

end_body


--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
procedure Enable_UHIB_for_Glitch_Detect
--------------------------------------------------------------------------------
-------- This procedure must be included in OnInit Flow ------------------------
--------------------------------------------------------------------------------

local


end_local

body

    -- Get enVision variable to define deglitch status    
    get_expr("DEGLITCH_ON", g_Deglitch_On)
    
    if g_Deglitch_On then
    
    -- Enable status byte register bits (according to UHIB board documentation, SRQmask command
    -- below works more intuitively (comes from LTX EIM files)

    -- Added to clear any SRQ's left over from previous run
        talk cx to gpib address UHIB_ADDRESS with sprint ("rstEDR 1")

    -- Enable status byte register bits (set SRQ mask)
        talk cx to gpib address UHIB_ADDRESS with sprint ("SRQmask 0F")

    -- Save the SRQ mask
        talk cx to gpib address UHIB_ADDRESS with sprint ("*PSC 0")
    
    end_if
    
    

end_body
