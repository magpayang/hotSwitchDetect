--------------------------------------------------------------------------------
-- Filename:
--     lib_Instrument_common.mod
--
-- Purpose:
--  This library provides routines to take inventory and initialize instruments.
--  
--
-- Routines:
--     Inventory_sys_hdw
--     Initialize_all_instruments
--     Powerdown_and_disconnect_all
--     get_meter_id
--     print_generator_status
--
-- History:
--     11/03/2009  timw             -- Original version includes Inventory_sys_hdw
--                                  -- Initialize_all_instruments, Powerdown_and_disconnect_all
--     04/15/2010  pla              -- Corrected faulty set logic; made sets global/static  
--     05/27/2011  dw/pla           -- Added logic for initializing femcon & GTO if in tester
--------------------------------------------------------------------------------

use module "./lib_clkCtrl.mod"
use module "./lib_gtoFrontEndConsts.mod"
use module "./lib_gtoFrontEndCtrl.mod"

const

MAX_SET  = 512

end_const


static
    set[MAX_SET]        : lib_inst_cmn_all_ovi = []
    set[MAX_SET]        : lib_inst_cmn_all_hcovi = []
    set[MAX_SET]        : lib_inst_cmn_all_vi16  = []  
    set[MAX_SET]        : lib_inst_cmn_all_vi16b  = [] 
    set[MAX_SET]        : lib_inst_cmn_all_vi16_vi16b  = [] 
    set[MAX_SET]        : lib_inst_cmn_all_qfvi = []    
    set[MAX_SET]        : lib_inst_cmn_all_fx1  = []  
    set[MAX_SET]        : lib_inst_cmn_all_tmu = []
    set[MAX_SET]        : lib_inst_cmn_all_tmp = []
    set[MAX_SET]        : lib_inst_cmn_all_vx_gto = []
    set[MAX_SET]        : lib_inst_cmn_all_dighsb = []
    set[MAX_SET]        : lib_inst_cmn_all_awghsb = []
    set[MAX_SET]        : lib_inst_cmn_all_dighr = []
    set[MAX_SET]        : lib_inst_cmn_all_awghr = []
    set[MAX_SET]        : lib_inst_cmn_all_dctm = []
    set[MAX_SET]        : lib_inst_cmn_all_hvvi = []
    set[MAX_SET]        : lib_inst_cmn_all_femcon = []    
end_static

 
procedure Inventory_sys_hdw

--------------------------------------------------------------------------------
-- Description:
-- Prints the HW configuration out to the ascii dataviewer.
--
-- Global variables:
--  Declared in lib_instrument_common.mod file:
--  lib_inst_cmn_all_ovi
--  lib_inst_cmn_all_hcovi
--  lib_inst_cmn_all_vi16  
--  lib_inst_cmn_all_vi16b 
--  lib_inst_cmn_all_vi16_vi16b 
--  lib_inst_cmn_all_qfvi    
--  lib_inst_cmn_all_fx1  
--  lib_inst_cmn_all_tmu
--  lib_inst_cmn_all_tmp
--  lib_inst_cmn_all_vx_gto
--  lib_inst_cmn_all_dighsb
--  lib_inst_cmn_all_awghsb 
--  lib_inst_cmn_all_dighr
--  lib_inst_cmn_all_awghr
--  lib_inst_cmn_all_dctm
--  lib_inst_cmn_all_hvvi
--  lib_inst_cmn_all_femcon
--
-- enVision spec variables in Globals_Spec:
--  Tester_Femcon
--  Tester_GTO
--  Meter_GPIB8
--  Meter_GPIB9
--
-- Operator variables:
--     none
--
-- History:
--     11/03/2009  timw             -- Original version.
--     4/15/2010   pla              -- Corrected faulty set logic 
--     05/27/2011  dw/pla           -- Added logic for initializing femcon & GTO if in tester
--------------------------------------------------------------------------------
 

const

    W1 = 15
    W2 = 20

end_const

local

    string[32]     : Tester_id
    string[32]     : Which_os = ""
    string[100]    : meter_id_addr8, meter_id_addr9
    boolean        : femcon_config, GTO_config
    boolean        : meter_addr8, meter_addr9

end_local
 
body
 
    debug_text( "@n")
    debug_text( "Running system inventory routines @n")
    debug_text( "@n")
    
    Tester_id    = tester_name    
    if not tester_simulated then
        Which_os     = tester_os  -- simulation issue.
    end_if
 
    lib_inst_cmn_all_ovi    = []     
    lib_inst_cmn_all_hcovi  = []
    lib_inst_cmn_all_vi16   = []   
    lib_inst_cmn_all_vi16b  = []
    lib_inst_cmn_all_vi16_vi16b = [] 
    lib_inst_cmn_all_fx1    = []
    lib_inst_cmn_all_tmu    = [] 
    lib_inst_cmn_all_tmp    = []  
    lib_inst_cmn_all_vx_gto = []
    lib_inst_cmn_all_dighsb = []
    lib_inst_cmn_all_awghsb = []
    lib_inst_cmn_all_dighr  = []
    lib_inst_cmn_all_awghr  = []
    lib_inst_cmn_all_qfvi   = []
    lib_inst_cmn_all_dctm   = []
    lib_inst_cmn_all_hvvi   = []
    lib_inst_cmn_all_femcon = []

  -- Initialize booleans used to initialize meters
    femcon_config   = FALSE
    GTO_config    = FALSE
    meter_addr8   = FALSE
    meter_addr9   = FALSE
    
    set_expr("Tester_Femcon.Meas", FALSE)
    set_expr("Tester_GTO.Meas", FALSE)
    set_expr("Meter_GPIB8.Meas", FALSE)
    set_expr("Meter_GPIB9.Meas", FALSE)
     
  --**** On-line system inventory
  --iu = "inventoriable unit".  
  --OpTool --> Help --> About This Tester
  --or:
  --file: /opt/ltx_nic/user_data/.iu_all_output  for all boards and SN#s
  --file: /opt/ltx_nic/user_data/iu_data
  --
  -- sample code for future use:  Ovi_present = iu_present("ovi", all_ovi, "silent") -- returns boolean
  -- 
 

    lib_inst_cmn_all_ovi        = inventory_all_chans ("ovi")
    lib_inst_cmn_all_hcovi      = inventory_all_chans ("hcovi")
    lib_inst_cmn_all_vi16       = inventory_all_chans ("vi16") 
    lib_inst_cmn_all_vi16b      = inventory_all_chans ("vi16b")    
    lib_inst_cmn_all_qfvi       = inventory_all_chans ("qfvi")    
    lib_inst_cmn_all_fx1        = inventory_all_chans ("fx1")
    lib_inst_cmn_all_tmu        = inventory_all_chans ("fx1_tmu")
    lib_inst_cmn_all_tmp        = inventory_all_chans ("fx1_tmp")
    lib_inst_cmn_all_vx_gto     = inventory_all_chans ("vx_gto")
    lib_inst_cmn_all_dighsb     = inventory_all_chans ("dighsb")
    lib_inst_cmn_all_awghsb     = inventory_all_chans ("awghsb")
    lib_inst_cmn_all_dighr      = inventory_all_chans ("dighr")
    lib_inst_cmn_all_awghr      = inventory_all_chans ("awghr")
    lib_inst_cmn_all_dctm       = inventory_all_chans ("dctm")    
    lib_inst_cmn_all_hvvi       = inventory_all_chans ("hvvi")  
    lib_inst_cmn_all_vi16_vi16b = lib_inst_cmn_all_vi16 | lib_inst_cmn_all_vi16b    --set of all vi16 & vi16b channels
    lib_inst_cmn_all_femcon     = inventory_all_chans ("femcon")     

  -- Determine if tester configuration contains femcon and/or GTO with assorted generators
  -- Used to identify missing generators

    if lib_inst_cmn_all_femcon <> [] then        
        set_expr("Tester_Femcon.Meas", TRUE)
        femcon_config = TRUE
    end_if
    
    if lib_inst_cmn_all_vx_gto <> [] then
        set_expr("Tester_GTO.Meas", TRUE)
        GTO_config = TRUE      
    end_if
    
  --Poll for generators on GPIB address 8 and 9 and set enVision global variables
  --If meter doesn't exist, polling takes about 1 second
    poll cx gpib address AUX_CLK_GPIB_ADDR existence into meter_addr8
    poll cx gpib address SAMPLE_CLK_GPIB_ADDR existence into meter_addr9

    set_expr("Meter_GPIB8.Meas", meter_addr8)
    set_expr("Meter_GPIB9.Meas", meter_addr9)

  -- If meters present, poll for identification    
    if meter_addr8 then
        meter_id_addr8 = get_meter_id(AUX_CLK_GPIB_ADDR)
    end_if
    
    if meter_addr9 then
        meter_id_addr9 = get_meter_id(SAMPLE_CLK_GPIB_ADDR)
    end_if 

  --Print out the following inventory items
    debug_text( sprint( "TESTER NAME: ":W1,   Tester_id, " @n") )
    debug_text( sprint( "TESTER OS  : ":W1,   Which_os, " @n" ) )
    
    debug_text( "@n" )
    debug_text( sprint( "--INVENTORY---------------------------------@n"))
    debug_text( sprint( "OVI:       ":W1, "PRESENT ",  lib_inst_cmn_all_ovi:W2     , "@n"))
    debug_text( sprint( "HCOVI:     ":W1, "PRESENT ",  lib_inst_cmn_all_hcovi:W2   , "@n"))
    debug_text( sprint( "VI16:      ":W1, "PRESENT ",  lib_inst_cmn_all_vi16:W2    , "@n"))
    debug_text( sprint( "VI16B:     ":W1, "PRESENT ",  lib_inst_cmn_all_vi16b:W2   , "@n"))
    debug_text( sprint( "QFVI:      ":W1, "PRESENT ",  lib_inst_cmn_all_qfvi:W2    , "@n"))
    debug_text( sprint( "HVVI:      ":W1, "PRESENT ",  lib_inst_cmn_all_hvvi:W2    , "@n"))
    debug_text( sprint( "FX1:       ":W1, "PRESENT ",  lib_inst_cmn_all_fx1:W2     , "@n"))
    debug_text( sprint( "TMU:       ":W1, "PRESENT ",  lib_inst_cmn_all_tmu:W2     , "@n"))
    debug_text( sprint( "TMP:       ":W1, "PRESENT ",  lib_inst_cmn_all_tmp:W2     , "@n"))
    debug_text( sprint( "VX GTO:    ":W1, "PRESENT ",  lib_inst_cmn_all_vx_gto:W2  , "@n"))
    debug_text( sprint( "FEMCON:    ":W1, "PRESENT ",  lib_inst_cmn_all_femcon:W2  , "@n"))   
    debug_text( sprint( "DIGHSB:    ":W1, "PRESENT ",  lib_inst_cmn_all_dighsb:W2  , "@n"))
    debug_text( sprint( "AWGHSB:    ":W1, "PRESENT ",  lib_inst_cmn_all_awghsb:W2  , "@n"))
    debug_text( sprint( "DIGHR:     ":W1, "PRESENT ",  lib_inst_cmn_all_dighr:W2   , "@n"))
    debug_text( sprint( "AWGHR:     ":W1, "PRESENT ",  lib_inst_cmn_all_awghr:W2   , "@n"))
    debug_text( sprint( "DCTM:      ":W1, "PRESENT ",  lib_inst_cmn_all_dctm:W2    , "@n")) 
    debug_text( sprint( "--------------------------------------------", "@n"))
    debug_text( "@n" )

  -- Print status of generators found if SSIP config
    if femcon_config and NOT GTO_config then
        if meter_addr8 and meter_addr9 then
            print_generator_status("all_clear")
        else
            print_generator_status("missing")
        end_if
    end_if 
    
  -- Print status of generators found if OCS config
    if GTO_config then
        if meter_addr8 and meter_addr9 then
            print_generator_status("all_clear")
        else_if meter_addr8 and NOT(meter_addr9) then
            if pos("SMATE", meter_id_addr8) > 1 then
                print_generator_status("all_clear")
            else
                print_generator_status("missing")
            end_if
        else
            print_generator_status("missing")
        end_if
    end_if
                   
end_body
 

procedure Initialize_all_instruments

--------------------------------------------------------------------------------
-- Description:
--     This routine will initialize vi16, dighsb, awghsb, fx1, dighr, awghr, qfvi, 
--     hvvi instruments
--
-- Global variable usage:
--  Declared in lib_instrument_common.mod file:
--  lib_inst_cmn_all_ovi
--  lib_inst_cmn_all_hcovi
--  lib_inst_cmn_all_vi16  
--  lib_inst_cmn_all_vi16b 
--  lib_inst_cmn_all_vi16_vi16b 
--  lib_inst_cmn_all_qfvi    
--  lib_inst_cmn_all_fx1  
--  lib_inst_cmn_all_tmu
--  lib_inst_cmn_all_tmp
--  lib_inst_cmn_all_vx_gto
--  lib_inst_cmn_all_dighsb
--  lib_inst_cmn_all_awghsb 
--  lib_inst_cmn_all_dighr
--  lib_inst_cmn_all_awghr
--  lib_inst_cmn_all_dctm
--  lib_inst_cmn_all_hvvi
--  lib_inst_cmn_all_femcon
--
-- Operator variables:
--     none
--
-- History:
--     11/03/2009  timw             -- Original version.
--     04/15/2010  pla              -- Corrected faulty set logic
--------------------------------------------------------------------------------

local
    pin list [192] : ALL_PINS
end_local

body

   debug_text("Initializing Instruments...@n")

  if (lib_inst_cmn_all_fx1 <> []) then
     debug_text("Initializing fx1...@n")
     initialize digital dsp_send   -- works for both MSD and VLSI
     initialize digital tmu fx1    -- works for both MSD and VLSI
     initialize cx sync
  end_if

--***********************************
-- need to add a check for VLSI mode
--***********************************

   debug_text("Initializing ovi...@n")
   initialize ovi  -- everyone has an ovi

   if (lib_inst_cmn_all_hcovi <> []) then
      debug_text("Initializing hcovi...@n")
      initialize hcovi
   end_if
  if (lib_inst_cmn_all_vi16_vi16b <> []) then
     debug_text("Initializing vi16...@n")
     initialize vi16
     -- Does this initialize the vi16b?
  end_if
  if (lib_inst_cmn_all_dighsb <> []) then
     debug_text("Initializing dighsb...@n")
     initialize dighsb
  end_if
  if (lib_inst_cmn_all_awghsb <> []) then
     debug_text("Initializing awghsb...@n")
     initialize awghsb
  end_if
  if (lib_inst_cmn_all_dighr <> []) then
     debug_text("Initializing dighr...@n")
     initialize dighr hardware and memory
  end_if
  if (lib_inst_cmn_all_awghr <> []) then
     debug_text("Initializing awghr...@n")
     initialize awghr hardware and memory
  end_if
   if (lib_inst_cmn_all_qfvi <> []) then
       debug_text("Initializing qfvi...@n")
       initialize qfvi                             
   end_if
   if (lib_inst_cmn_all_hvvi <> []) then
      debug_text("Initializing hvvi...@n")
      initialize hvvi
   end_if
   if (lib_inst_cmn_all_dctm <> []) then
      debug_text("Initializing dctm...@n")
      initialize dctm
   end_if

   debug_text( "Instrument initialization complete.@n" ) 

end_body


procedure Powerdown_and_disconnect_all

-------------------------------------------------------------------------------------------
-- Description:
--    This routine will put the all pins on all instruments into a safe disabled state
--
-- Global variables:
--  Declared in lib_instrument_common.mod file:
--  lib_inst_cmn_all_ovi
--  lib_inst_cmn_all_hcovi
--  lib_inst_cmn_all_vi16  
--  lib_inst_cmn_all_vi16b 
--  lib_inst_cmn_all_vi16_vi16b 
--  lib_inst_cmn_all_qfvi    
--  lib_inst_cmn_all_fx1  
--  lib_inst_cmn_all_tmu
--  lib_inst_cmn_all_tmp
--  lib_inst_cmn_all_vx_gto
--  lib_inst_cmn_all_dighsb
--  lib_inst_cmn_all_awghsb 
--  lib_inst_cmn_all_dighr
--  lib_inst_cmn_all_awghr
--  lib_inst_cmn_all_dctm
--  lib_inst_cmn_all_hvvi
--  lib_inst_cmn_all_femcon
--
-- Operator variable usage:
--     none
--
-- History:
--     11/03/2009  timw             -- Original version.
--     04/16/2010  pla              -- Corrected faulty set logic
-------------------------------------------------------------------------------------------

local
   lword           : Silent_pattern[20]
   pin list [512]  : all_fx1_pinlist
end_local

body

    Inventory_sys_hdw  

    -- cannot easily go from set expression to pinlist expression
    abort digital pattern
    --set digital pin driver static tristate
    --disconnect digital pin all_fx1_pinlist from dcl
    --disconnect digital pin fx1 from all relays
   
   if (lib_inst_cmn_all_hcovi <> []) then
      set hcovi lib_inst_cmn_all_hcovi to fv 0.0V measure i max 1A clamp imax 1A imin -1A
      gate hcovi lib_inst_cmn_all_hcovi off
      disconnect hcovi lib_inst_cmn_all_hcovi
      debug_text("hcovi disconnected")
   end_if
   
   if (lib_inst_cmn_all_ovi <> []) then
      set ovi chan lib_inst_cmn_all_ovi to fv 0.0V measure i max 1A clamp imax 1A imin -1A
      gate ovi chan lib_inst_cmn_all_ovi off
      disconnect ovi chan lib_inst_cmn_all_ovi
      debug_text("ovi disconnected")
   end_if

   if (lib_inst_cmn_all_vi16_vi16b <> []) then
      set vi16 chan lib_inst_cmn_all_vi16_vi16b to fv 0.0V measure i max 100mA clamp imax 100mA imin -100mA
      gate vi16 chan lib_inst_cmn_all_vi16_vi16b off
      disconnect vi16 chan lib_inst_cmn_all_vi16_vi16b
      debug_text("vi16 disconnected")
   end_if

   if (lib_inst_cmn_all_qfvi <> [] and not tester_simulated ) then
      set qfvi lib_inst_cmn_all_qfvi irange to r5ma iclamps to imax 1mA imin -1mA
      gate qfvi lib_inst_cmn_all_qfvi off
      disconnect qfvi lib_inst_cmn_all_qfvi
      debug_text("qfvi disconnected")
   end_if

   if (lib_inst_cmn_all_hvvi <> []) then
      set hvvi chan lib_inst_cmn_all_hvvi to fv 0.0V max r2p5v bandwidth bw160khz
      gate hvvi chan lib_inst_cmn_all_hvvi off
      disconnect hvvi chan lib_inst_cmn_all_hvvi
      debug_text("hvvi disconnected")
   end_if


   Silent_pattern = 0
   if (lib_inst_cmn_all_vx_gto <> []) then
      load vx_gto lib_inst_cmn_all_vx_gto output pattern Silent_pattern identified by "Silent"
      stop vx_gto lib_inst_cmn_all_vx_gto output
      start vx_gto lib_inst_cmn_all_vx_gto output with user pattern "Silent"
      debug_text("GTO set to silent pattern")
   end_if

-- add routines to reset SMIQ and SMA100s
-- turn IQ modulation off

--  initialize digital clock fx1
--  initialize digital dsp_send
--  initialize digital tmu fx1
--  initialize vi16
--  initialize ovi
--  initialize hcovi
--  initialize dighsb
--  initialize awghsb
--  initialize dighr hardware and memory
--  initialize awghr hardware and memory

end_body




function get_meter_id(gpib_address) :   string
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description:
--     This function will get the meter id of one meter located at either GPIB8 or GPIB9
--      It is called in the Inventory_sys_hdw procedure 
--
-- Global variable usage:
--     none
--
-- Operator variables:
--     none
--
-- History:
--     05/27/2011  dw              -- Original version.
--------------------------------------------------------------------------------
--  
in integer   : gpib_address

local
    string[100] : meter_id 
    string[100] : readback = "" 
    boolean     : timeout 
     
end_local

body

    talk cx to gpib address AUX_CLK_GPIB_ADDR with sprint ("*IDN?;") 
    listen cx to gpib address AUX_CLK_GPIB_ADDR into readback for 100 bytes timeout into timeout
    meter_id = readback
    
    return(meter_id)
    
end_body

procedure print_generator_status(status_string)
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- Description:
--     This function will message indicating status of meter locate process for either SSIP or OCS testers
--      It is called in the Inventory_sys_hdw procedure 
--
-- Global variable usage:
--     none
--
-- Operator variables:
--     none
--
-- History:
--     05/27/2011  dw              -- Original version.
--------------------------------------------------------------------------------

--  
in string[25]   : status_string

local

end_local

body

    if status_string = "all_clear" then
        println(stdout, "All required generators detected in test system.")
    else_if status_string = "missing" then
        println(stdout, "********************************************************************")
        println(stdout, "W       W     A     RRRRRRR   NN      N IIIIII NN      N  GGGGGGG   ")
        println(stdout, "W       W    A A    R      R  N N     N   II   N N     N G       G  ")
        println(stdout, "W       W   A   A   R       R N N     N   II   N N     N G          ")
        println(stdout, "W       W  A     A  R       R N  N    N   II   N  N    N G          ")
        println(stdout, "W       W A       A R       R N  N    N   II   N  N    N G          ")
        println(stdout, "W       W A       A R      R  N   N   N   II   N   N   N G          ")
        println(stdout, "W   W   W A       A RRRRRRR   N   N   N   II   N   N   N G          ")
        println(stdout, "W   W   W AAAAAAAAA R   R     N    N  N   II   N    N  N G     GGG  ")
        println(stdout, "W   W   W A       A R    R    N    N  N   II   N    N  N G       G  ")
        println(stdout, "W   W   W A       A R     R   N     N N   II   N     N N G       G  ")
        println(stdout, " W W W W  A       A R      R  N     N N   II   N     N N G       G  ")
        println(stdout, "  W   W   A       A R       R N      NN IIIIII N      NN  GGGGGGG   ")
        println(stdout, "********************************************************************")
        println(stdout, "********************************************************************")
        println(stdout, "                                                                    ")
        println(stdout, "WARNING: One or More Generators Not Detected                        ")
        println(stdout, "                                                                    ")
        println(stdout, "********************************************************************")
        println(stdout, "********************************************************************")
    end_if

end_body

