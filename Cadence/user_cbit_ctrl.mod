-------------------------------------------------------------------------------------------
--                 CX USER_CBIT Control Module                     --
--                                  Revision 1.0                                         --
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                           Revision Log                                                --
-------------------------------------------------------------------------------------------


-- rev 1.0  KPG                         


-------------------------------------------------------------------------------------------
--                               Usage                                                   --
-------------------------------------------------------------------------------------------


--      usercbit_reset_all                  -- opens all usercbits
--      usercbits_set  (fbit_set)           -- Sets all usercbits as defined in the set
--      usercbits_close(fbit_set)           -- Closes usercbits specified in the set
--      usercbits_open (fbit_set)           -- Opens usercbits specified in the set
--      usercbits_display                   -- Prints current usercbits setting to DataViewer


-------------------------------------------------------------------------------------------
--                               For Module Use Only                                     --
-------------------------------------------------------------------------------------------

const

    CAGE_NUM    = 0
    
end_const

private

    global set[64]          : usercbits_shadow=[]
 
end_private

function usercbits_set(cbit_set) : boolean
--------------------------------------------------------------------------------
--  Sets User Cbits 1 through 64 on the FB as specified by the set passed in.

    in set[64]  : cbit_set     


local


    word        : data_cbits[8]
       
    integer     : loop
          
        
end_local

body

     -- Split set into 8ea 8-bit registers
     
     data_cbits[1]  = word(cbit_set  & [1..8] )
     data_cbits[2]  = word((cbit_set & [9..16])  >> 8)
     data_cbits[3]  = word((cbit_set & [17..24]) >> 16)
     data_cbits[4]  = word((cbit_set & [25..32]) >> 24)
     data_cbits[5]  = word((cbit_set & [33..40]) >> 32)
     data_cbits[6]  = word((cbit_set & [41..48]) >> 40)
     data_cbits[7]  = word((cbit_set & [49..56]) >> 48)
     data_cbits[8]  = word((cbit_set & [57..64]) >> 56)
    
     -- Write data to FB


--                                              S D S L
--                                              C A C T
--                                              L T L C
--                                          --- R A K H
--set cx dutsite cage CAGE_NUM register 0 to 2#0 0 0 0 0 0 0 0

-- MAM Added to enable CX bus control over DDP control
set cx dutsite cage CAGE_NUM register 0 to 2#1  -- 
wait(100uS)

    for loop = 1 to 8 do
        
-- MAM Changed tp register 2 is data, register 1 is control [SRESET, SLATCH, SCLK] 
         set cx dutsite cage CAGE_NUM register 2 to data_cbits[loop]
         wait(100uS)
         set cx dutsite cage CAGE_NUM register 1 to 2#00000001
         wait(100uS)
         set cx dutsite cage CAGE_NUM register 1 to 2#00000000
         wait(100uS)   
--          set cx dutsite cage CAGE_NUM register 3 to data_cbits[loop]
--          set cx dutsite cage CAGE_NUM register 4 to 2#00000001
--          set cx dutsite cage CAGE_NUM register 4 to 2#00000000   
    end_for


-- latch data



-- MAM Changed tp register 2 is data, register 1 is control [SRESET, SLATCH, SCLK] 
  set cx dutsite cage CAGE_NUM register 1 to 2#00000010
  wait(100uS)
  set cx dutsite cage CAGE_NUM register 1 to 2#00000000
  wait(100uS)
--   set cx dutsite cage CAGE_NUM register 4 to 2#00000010
--   set cx dutsite cage CAGE_NUM register 4 to 2#00000000

    usercbits_shadow = cbit_set
    return(true) 
end_body

function usercbit_reset_all : boolean
-------------------------------------------------------------------------------------------
--      This procedure resets all usercbits to default (open)

body

--     usercbits_shadow =  []
--     
--     -- Set cbits
--     
--     set_usercbits(usercbits_shadow)
--     return(true)

    usercbits_shadow=[]
    set cx dutsite cage CAGE_NUM register 0 to 2#1  -- 

    -- MAM Changed tp register 2 is data, register 1 is control [SRESET, SLATCH, SCLK] 
--    set cx dutsite cage CAGE_NUM register 1 to 2#00000010
--    set cx dutsite cage CAGE_NUM register 1 to 2#00000000
    wait(5ms)                              
    set cx dutsite cage CAGE_NUM register 1 to 2#00000100
    set cx dutsite cage CAGE_NUM register 1 to 2#00000000
    
    return(false)            
end_body

function usercbits_close(cbit_set) : boolean
--------------------------------------------------------------------------------
--      This routine will close/activate the FBITS specified in the
-- set passed in, leaving all other relays unchanged.

    in set[64]  : cbit_set      

body

    -- usercbits_display
    --'Or' in the new bits to close
    usercbits_shadow = usercbits_shadow | cbit_set
    
    -- Set cbits
    usercbits_set(usercbits_shadow)
    return(true)
end_body
function usercbits_open(cbit_set) : boolean
--------------------------------------------------------------------------------
--      This routine will open/deactivate the FBITS specified in the
-- set passed in, leaving all other relays unchanged.

    in set[64]  : cbit_set      

body

    --'And' in zeros to open the specified bits
    usercbits_shadow = usercbits_shadow & ~cbit_set
    
    -- Set cbits
    usercbits_set(usercbits_shadow)
    return(true)
end_body


function usercbits_display : boolean
--------------------------------------------------------------------------------
--  This procedure will display the current status of the USERCBITs based on the
--  shadow register. The information will be printed to the stdout (DataViewer) 
--  window. Information on all 64 CBITs is printed. If the cbit number is 
--  printed (or is in the printed range of numbers) then that cbit is on or closed.

body

    println(stdout,"")
    println(stdout,"USERCBITs Status")
    println(stdout,usercbits_shadow)
 return (true)   
end_body

procedure cbit_verify
--------------------------------------------------------------------------------
--  

local

    word    : i

end_local

body

wait(1ms)
    while true do
        for i = 6 to 6 do -- 
            usercbits_close([i])
            wait(1mS)
            usercbits_open([i])
            wait(1mS)
        end_for
    end_while
    
wait(1ms)    

wait(1ms)
    -- address/data walk
    while false do
        set cx dutsite cage CAGE_NUM register 1 to 16#80  -- 
        wait(500nS)
        set cx dutsite cage CAGE_NUM register 1 to 16#40  -- 
        wait(500nS)
        set cx dutsite cage CAGE_NUM register 1 to 16#20  -- 
        wait(500nS)
        set cx dutsite cage CAGE_NUM register 1 to 16#10  -- 
        wait(500nS)
        set cx dutsite cage CAGE_NUM register 1 to 16#8  -- 
        wait(500nS)
        set cx dutsite cage CAGE_NUM register 1 to 16#4  -- 
        wait(500nS)
        set cx dutsite cage CAGE_NUM register 1 to 16#2  -- 
        wait(500nS)
        set cx dutsite cage CAGE_NUM register 1 to 16#1  -- 
        wait(500nS)
        set cx dutsite cage CAGE_NUM register 0 to 16#0  -- 
        wait(1000nS)
        set cx dutsite cage CAGE_NUM register 1 to 16#0  -- 
        wait(1000nS)
        set cx dutsite cage CAGE_NUM register 2 to 16#0  -- 
        wait(1000nS)
    end_while
    
end_body
