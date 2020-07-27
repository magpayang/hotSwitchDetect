-- Controls OVI, HCOVI and FX TMBD CBITs
-- mimics behaviour of individual CBIT statements
-- Limitations:
--  Requires that all CBITs within a pin be of the same type (OVI or HCOVI)

-- set this to the total number of HCOVI or OVI CBITs you expect to control

const MAX_CBITS = 256

static
    string[32] :            os_rev = ""
end_static

procedure open_tester_cbits(cbit_list)
----------------------------------
--  
in pin list[MAX_CBITS] :    cbit_list

local
    pin list[MAX_CBITS] :   ovi_list
    pin list[MAX_CBITS] :   hcovi_list
    pin list[MAX_CBITS] :   fx_list
    set[MAX_CBITS] :        hcovi_chan_set

end_local

body

    ovi_list =   get_ovi_list(cbit_list)
    hcovi_list = get_hcovi_list(cbit_list)
    fx_list =    get_fx_list(cbit_list)

    if len(ovi_list) > 0 then
        open ovi chan ovi_list cbits
    end_if

    if len(hcovi_list) > 0 then
        if os_rev = "" then
            os_rev = tester_os
        end_if
        if os_rev[1:7] < "R14.4.1" then
            hcovi_chan_set = convert_hcovi_chan_set(hcovi_list)
            open hcovi hcovi_chan_set cbits
        else
            open hcovi hcovi_list cbits
        end_if
    end_if
    
    if len(fx_list) > 0 then
        open digital cbit fx_list
    end_if

end_body

procedure close_tester_cbits(cbit_list)
----------------------------------
--  
in pin list[MAX_CBITS] :  cbit_list

local
    pin list[MAX_CBITS] :   ovi_list
    pin list[MAX_CBITS] :   hcovi_list
    pin list[MAX_CBITS] :   fx_list
    set[MAX_CBITS] :        hcovi_chan_set
    
end_local

body

    ovi_list =   get_ovi_list(cbit_list)
    hcovi_list = get_hcovi_list(cbit_list)
    fx_list =    get_fx_list(cbit_list)

    if len(ovi_list) > 0 then
        close ovi chan ovi_list cbits
    end_if

    if len(hcovi_list) > 0 then
        if os_rev = "" then
            os_rev = tester_os
        end_if
        if os_rev[1:7] < "R14.4.1" then
            hcovi_chan_set = convert_hcovi_chan_set(hcovi_list)
            close hcovi hcovi_chan_set cbits
        else
            close hcovi hcovi_list cbits
        end_if
    end_if

    if len(fx_list) > 0 then
        close digital cbit fx_list
    end_if
--     wait(20000us)
    
end_body


procedure set_tester_cbits(all_cbit_list,cbit_list)
----------------------------------
--  
in pin list[MAX_CBITS] :  all_cbit_list
in pin list[MAX_CBITS] :  cbit_list

local
    pin list[MAX_CBITS] :   ovi_list
    pin list[MAX_CBITS] :   all_ovi_list
    set[MAX_CBITS] :        ovi_cbit_index

    pin list[MAX_CBITS] :   hcovi_list
    word list[MAX_CBITS] :  hcovi_chan_list
    set[MAX_CBITS] :        hcovi_chan_set
    pin list[MAX_CBITS] :   all_hcovi_list
    word list[MAX_CBITS] :  all_hcovi_chan_list
    set[MAX_CBITS] :        all_hcovi_chan_set
    set[MAX_CBITS] :        hcovi_cbit_index
    word :                  x
    
    pin list[MAX_CBITS] :   fx_list
    pin list[MAX_CBITS] :   all_fx_list
    
end_local

body

    if os_rev = "" then
        os_rev = tester_os
    end_if
    
    -- Find out which pins are OVI and which are HCOVI
    ovi_list =     get_ovi_list(cbit_list)
    all_ovi_list = get_ovi_list(all_cbit_list)

    ovi_cbit_index = get_list_index(all_ovi_list,ovi_list)

    hcovi_list =     get_hcovi_list(cbit_list)
    all_hcovi_list = get_hcovi_list(all_cbit_list)
    hcovi_cbit_index = get_list_index(all_hcovi_list,hcovi_list)

    fx_list =       get_fx_list(cbit_list)
    all_fx_list =   get_fx_list(all_cbit_list)

    if len(all_hcovi_list) > 0 then
        if os_rev[1:7] > "R14.4.0" then
            -- Post R14.4.1 HCOVI works like OVI
            set hcovi all_hcovi_list cbits hcovi_cbit_index
        else_if os_rev[1:7] > "R14.3.0" then
            -- between R14.3.1 and R14.4.0 inclusive HCOVI pins can't be used
            all_hcovi_chan_list = convert_hcovi_chan_list(all_hcovi_list)
            hcovi_chan_list = convert_hcovi_chan_list(hcovi_list)

            set hcovi all_hcovi_chan_list cbits hcovi_cbit_index
        else
            -- workaround for broken non-OVI-like behaviour pre-R14.3.1
            hcovi_chan_set = convert_hcovi_chan_set(hcovi_list)
            all_hcovi_chan_set = convert_hcovi_chan_set(all_hcovi_list)
    
            -- workaround for empty set not working prior to R14.3.1
            if hcovi_chan_set = [] then
                open hcovi all_hcovi_chan_set cbits
            else
                set hcovi all_hcovi_chan_set cbits hcovi_chan_set
            end_if
        end_if
    
    end_if

    if len(all_ovi_list) > 0 then
        set ovi chan all_ovi_list cbits to ovi_cbit_index
    end_if

    if len(all_fx_list) > 0 then
        -- workaround for SPR 116062
        if len(fx_list) > 0 then
            set digital cbit all_fx_list to fx_list
        else
            open digital cbit all_fx_list
        end_if
    end_if
    
end_body

private function get_ovi_list(vi_list) : pin list[MAX_CBITS]
------------------------------------------------------------
--  
in pin list[MAX_CBITS] :    vi_list

local
    integer :               x
    pin list[MAX_CBITS] :   ovi_list
    pin :                   check_pin
    string[32] :            inst_type
end_local

body

    ovi_list = <::>
    for x = 1 to len(vi_list) do
        check_pin = vi_list[x]
        inst_type = pin_instrument(check_pin)
        if inst_type = "OVICBIT" then
            ovi_list = ovi_list + <:vi_list[x]:>
        end_if
    end_for
    
    return(ovi_list)
    
end_body

private function get_hcovi_list(vi_list) : pin list[MAX_CBITS]
--------------------------------------------------------------
--  
in pin list[MAX_CBITS] :    vi_list

local
    integer :   x
    pin list[MAX_CBITS] :   hcovi_list
    pin :                   check_pin
    string[32] :            inst_type
end_local

body

    hcovi_list = <::>
    for x = 1 to len(vi_list) do
        check_pin = vi_list[x]
        inst_type = pin_instrument(check_pin)
        if inst_type = "HCOVICBIT" then
            hcovi_list = hcovi_list + <:vi_list[x]:>
        end_if
    end_for
    
    return(hcovi_list)
    
end_body

private function convert_hcovi_chan_set(hcovi_pin_list) : set[MAX_CBITS]
--------------------------------------------------------------------------------
--  
in pin list[MAX_CBITS] :    hcovi_pin_list

local
    word list[MAX_SITES] :  site_list
    pin :                   hcovi_pin
    word list[MAX_CBITS] :  hcovi_chan_list
    set[MAX_CBITS] :        hcovi_cbit_chan_set
    word :                  x,  cbit_chan
    integer         : channel
end_local

body

    site_list = get_active_sites
    hcovi_cbit_chan_set = []
    for x = 1 to word(len(hcovi_pin_list)) do
        hcovi_pin = hcovi_pin_list[x]
        hcovi_chan_list = hcovicbits_ptc(hcovi_pin)
        for channel = 1 to len (hcovi_chan_list) do
           cbit_chan = hcovi_chan_list[channel]
           if not(cbit_chan in hcovi_cbit_chan_set) then
              hcovi_cbit_chan_set = hcovi_cbit_chan_set | [cbit_chan]
           end_if
        end_for --channel
    end_for

    return(hcovi_cbit_chan_set)
    
end_body

private function convert_hcovi_chan_list(hcovi_pin_list) : word list[MAX_CBITS]
--------------------------------------------------------------------------------
--  
in pin list[MAX_CBITS] :    hcovi_pin_list

local
    word list[MAX_SITES] :  site_list
    pin :                   hcovi_pin
    word list[MAX_CBITS] :  hcovi_cbit_chan_list
    word list[MAX_CBITS] :  hcovi_chan_list
    word :                  hcovi_chan
    word :                  x
end_local

body

    site_list = get_active_sites
    hcovi_chan_list = <::>
    for x = 1 to word(len(hcovi_pin_list)) do
        hcovi_pin = hcovi_pin_list[x]
        hcovi_cbit_chan_list = hcovicbits_ptc(hcovi_pin)
        hcovi_chan = hcovi_cbit_chan_list[site_list[1]]
        hcovi_chan_list = hcovi_chan_list + <:hcovi_chan:>
    end_for

    return(hcovi_chan_list)
    
end_body

function get_list_index(all_cbit_list,cbit_list) : set[MAX_CBITS]
--------------------------------------------------------------------------------
--  
in pin list[MAX_CBITS] :    all_cbit_list
in pin list[MAX_CBITS] :    cbit_list
 
local
    set[MAX_CBITS] :    cbit_index
    word :              x
end_local

body

    cbit_index = []
    
    for x = 1 to word(len(all_cbit_list)) do
        if all_cbit_list[x] in cbit_list then
            cbit_index = cbit_index | [x]
        end_if
    end_for

    return(cbit_index)
    
end_body

private function get_fx_list(fx_list) : pin list[MAX_CBITS]
------------------------------------------------------------
--  
in pin list[MAX_CBITS] :    fx_list

local
    integer :               x
    pin list[MAX_CBITS] :   fx_cbit_list
    pin :                   check_pin
    string[32] :            inst_type
end_local

body

    fx_cbit_list = <::>
    for x = 1 to len(fx_list) do
        check_pin = fx_list[x]
        inst_type = pin_instrument(check_pin)
        if inst_type = "FXCBIT" then
            fx_cbit_list = fx_cbit_list + <:check_pin:>
        end_if
    end_for
    
    return(fx_cbit_list)
    
end_body
