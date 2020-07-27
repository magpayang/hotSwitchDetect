-------------------------------------------------------------------------------------------
--                                                                                       --
--                            GTO Fibre Channel Pattern Generation Tools                    --
--                                                                                       --
--                                     Author : C.HUGHES                                 --  
--                                                                                       --
--                                                                                       --
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                                                                                       --
--                                  REVISION LOG                                         --
--                                                                                       --
-- Revision         Who     Comments                                                     --
--                                                                                       --
-- 1.0  08/29/05    CJH     Creation
-- 2.0  10/28/08    TJW     Collected patterns from several released TPs and added to this
--                          module.  Eliminated writing patterns to files to minimize 
                            failure modes (permissions, missing dir etc).
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                                                                                       --
--                                     HEADER                                            --
--                                                                                       --
-- Major routines:
--     CreateGtoFibreChanPatterns   -- Calls routines to define GTO arrays 
--     LoadGtoFibreChanPatterns     -- Loads arrays into GTO
--     Define_..._data              -- One routine per pattern
--
-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                                                                                       --
--                              TEST PROGRAM  MODULES                                    --
--                                                                                       --

use module "GTO_Ctrl.mod"
use module "GTO_AWGHS.mod"

-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                                                                                       --                           
--                             GENERAL CONSTANTS                                         --                                       
--                                                                                       --

const
    FC_WORD_SIZE        = 10

    ALIGN_SIZE          = 640	-- number of bits in the pattern
    ALIGN_GTO_MULT      = 1     -- multiplier to fit within GTO_MEM_WIDTH boundary
    ALIGN_GTO_SIZE      = ALIGN_SIZE*ALIGN_GTO_MULT/32

    CRPAT_SIZE          = 2280
    CRPAT_GTO_MULT      = 16
    CRPAT_CAP_SIZE      = CRPAT_SIZE/32+1	-- Minimum capture size for 1 complete pattern
    CRPAT_GTO_SIZE      = CRPAT_SIZE*CRPAT_GTO_MULT/32

    CJTPAT_SIZE         = 2640
    CJTPAT_GTO_MULT     = 8
    CJTPAT_GTO_SIZE     = CJTPAT_SIZE*CJTPAT_GTO_MULT/32
--    CJTPAT_JT_N         = 4     -- Use to increase the size of the sample data for Jitter Tolerance
--    CJTPAT_JT_BITS      = CJTPAT_JT_N * CJTPAT_SIZE * CJTPAT_GTO_MULT

    PRBS7_SIZE          = 127
    PRBS7_GTO_MULT      = 128
    PRBS7_GTO_SIZE      = PRBS7_SIZE*PRBS7_GTO_MULT/32

    D21_5_SIZE          = 10
    D21_5_GTO_MULT      = 64
    D21_5_GTO_SIZE      = D21_5_SIZE*D21_5_GTO_MULT/32

    K28_7_SIZE          = 10
    K28_7_GTO_SIZE      = K28_7_SIZE*K28_7_GTO_MULT/32
    K28_7_GTO_MULT      = 64

    K28_5_SIZE          = 20
    K28_5_GTO_MULT      = 32
    K28_5_GTO_SIZE      = K28_5_SIZE*K28_5_GTO_MULT/32

    ONEZERO_SIZE     = 640
    TWOONEZERO_SIZE     = 640
    FOURONEZERO_SIZE     = 640
    FIVEONEZERO_SIZE     = 640
    EIGHTONEZERO_SIZE     = 640
    TENONEZERO_SIZE     = 640
    PRBS7_1010_SIZE  = 16*29*8 / 32
    BITS100_SIZE  = 25 * 4 * 32 / 32

    IDLE_LEN        = 4
    IDLE_RPT        = 6
    SOF_LEN         = 4
    CRC_LEN         = 4
    EOF_LEN         = 4

    RPAT_LEN        = 12
    RPAT_RPT        = 16
    LDPAT_LEN       = 4
    LDPAT_RPT       = 41
    LD2HDPAT_LEN    = 8
    LD2HDPAT_RPT    = 1
    HDPAT_LEN       = 4
    HDPAT_RPT       = 12
    HD2LDPAT_LEN    = 8
    HD2LDPAT_RPT    = 1 

    SOF_MATCH   = 16#3eaaa6a5   -- first 32 bits of SOF primitive

end_const

-------------------------------------------------------------------------------------------

-------------------------------------------------------------------------------------------
--                                                                                       --                           
--                             GENERAL VARIABLES                                         --                                       
--                                                                                       --

static

    lword   : ALIGN_data[ALIGN_SIZE/FC_WORD_SIZE]
    lword   : CRPAT_data[CRPAT_SIZE/FC_WORD_SIZE]
    lword   : CRPAT_trig[CRPAT_SIZE/FC_WORD_SIZE]
    lword   : CJTPAT_data[CJTPAT_SIZE/FC_WORD_SIZE]
    lword   : CJTPAT_trig[CJTPAT_SIZE/FC_WORD_SIZE]
    lword   : PRBS7_data[PRBS7_SIZE]
    lword   : PRBS7_trig[PRBS7_SIZE]
    lword   : D21_5_data[D21_5_SIZE/FC_WORD_SIZE]
    lword   : K28_7_data[K28_7_SIZE/FC_WORD_SIZE]
    lword   : K28_5_data[K28_5_SIZE/FC_WORD_SIZE]
    lword   : ONEZERO_data[ONEZERO_SIZE]
    lword   : TWOZERO_data[TWOZERO_SIZE]
    lword   : FOURZERO_data[FOURZERO_SIZE]
    lword   : FIVEONEZERO_data[FIVEONEZERO_SIZE]
    lword   : EIGHTONEZERO_data[EIGHTONEZERO_SIZE]
    lword   : TENONEZERO_data[TENONEZERO_SIZE]

    lword   : CDR_CID_data[4264*16/32] 
    lword   : CDR_CID_by2_data[4264*16/32]
    lword   : CID_160ones160zeros_data[20]
    lword   : CID_224ones224zeros_data[32]
    lword   : CID_256ones256zeros_data[16]

    lword   : crpat_sof_posn
    lword   : cjtpat_sof_posn


    lword   : Idle_prim[IDLE_LEN]
    lword   : SOFn3[SOF_LEN]
    lword   : RPAT[RPAT_LEN]
    lword   : CRPAT_CRC[CRC_LEN]
    lword   : CJTPAT_CRC[CRC_LEN]
    lword   : EOFn[EOF_LEN]
    lword   : LDPAT[LDPAT_LEN]
    lword   : LD2HDPAT[LD2HDPAT_LEN]
    lword   : HDPAT[HDPAT_LEN]
    lword   : HD2LDPAT[HD2LDPAT_LEN]

    lword   : align_array[ALIGN_GTO_SIZE]
    lword   : clock_array[ALIGN_GTO_SIZE]
    string[10] : align_10b_chars[ALIGN_GTO_SIZE*32/10]
    string[40] : align_10b_prims[ALIGN_GTO_SIZE*32/10/4]
    lword   : crpat_array[CRPAT_GTO_SIZE]
    lword   : cjtpat_array[CJTPAT_GTO_SIZE]
    lword   : prbs7_array[PRBS7_GTO_SIZE]
    lword   : d21_5_array[D21_5_GTO_SIZE]
    lword   : k28_7_array[K28_7_GTO_SIZE]
    lword   : k28_5_array[K28_5_GTO_SIZE]
    lword   : onezero_array[ONEZERO_SIZE/32]
    lword   : twoonezero_array[TWOONEZERO_SIZE/32]
    lword   : fouronezero_array[FOURONEZERO_SIZE/32]
    lword   : fiveonezero_array[FIVEONEZERO_SIZE/32]
    lword   : eightonezero_array[EIGHTONEZERO_SIZE/32]
    lword   : tenonezero_array[TENONEZERO_SIZE/32]

    lword   : crpat_trig_array[CRPAT_GTO_SIZE]
    lword   : cjtpat_trig_array[CJTPAT_GTO_SIZE]
    lword   : prbs7_trig_array[PRBS7_GTO_SIZE]
    lword   : prbs7_1010_array[PRBS7_1010_SIZE]
    lword   : all_ones_array[20]
    lword   : all_zeros_array[20]
    lword   : bits100_array[BITS100_SIZE]


end_static

procedure CreateGtoFibreChanPatterns(create_patterns)
-------------------------------------------------------------------------------------------
-- This is the GTO pattern creation code. All pattern are written to files
-- The Define routines would only need to be created once or if the patterns change.

in boolean      : create_patterns
        
body

Define_FibreChannel_data
Define8b10bCharacters

if create_patterns then

    Define_ALIGN_data("ALIGN",false)
    Define_CRPAT_data("CRPAT",true)
    Define_CJTPAT_data("CJTPAT",true)
    Define_PRBS_7_data("PRBS7",true)
    Define_D21_5_data("D21_5",false)
    Define_K28_7_data("K28_7",false)
    Define_K28_5_data("K28_5",false)
    Define_ONEZERO_data("ONEZERO",false)
    Define_TWOONEZERO_data("TWOONEZERO",false)
    Define_FOURONEZERO_data("FOURONEZERO",false)
    Define_FIVEONEZERO_data("FIVEONEZERO",false)
    Define_EIGHTONEZERO_data("EIGHTONEZERO",false)
    Define_TENONEZERO_data("TENONEZERO",false)
    Define_ALLONES_data("ALLONES",false)
    Define_ALLZEROS_data("ALLZEROS",false)
    
    Define_CDR_CID_data
    Define_64ones64zeros_CID_data

end_if

end_body

procedure LoadGtoFibreChanPatterns
-------------------------------------------------------------------------------------------
-- Defined patterns are loaded into the GTO pattern memory.
-------------------------------------------------------------------------------------------
                                                                                                                                                
local
                                                                                                                                                
    lword               : sof_posn
    set[MAX_GTOS]       : GtoS_Pins
                                                                                                                                                
end_local
                                                                                                                                                
body
                                                                                                                                                
GtoS_Pins = inventory_all_chans("vx_gto")
                                                                                                                                                
println (stdout, "Loading the Fibre Channel GTO patterns into GTO memory .... ")
                                                                                                                                                
-- Load the GTO user defined patterns
    load vx_gto GtoS_Pins output pattern ONEZERO_data identified by "ONEZERO"
    load vx_gto GtoS_Pins output pattern TWOONEZERO_data identified by "TWOONEZERO"
    load vx_gto GtoS_Pins output pattern FOURONEZERO_data identified by "FOURONEZERO"
    load vx_gto GtoS_Pins output pattern FIVEONEZERO_data identified by "FIVEONEZERO"
    load vx_gto GtoS_Pins output pattern EIGHTONEZERO_data identified by "EIGHTONEZERO"
    load vx_gto GtoS_Pins output pattern TENONEZERO_data identified by "TENONEZERO"
    load vx_gto GtoS_Pins output pattern k28_7_array identified by "K28_7"
    load vx_gto GtoS_Pins output pattern k28_5_array identified by "K28_5"
    load vx_gto GtoS_Pins output pattern ALIGN_data identified by "ALIGN"
    load vx_gto GtoS_Pins output pattern CRPAT_data identified by "CRPAT"
    load vx_gto GtoS_Pins output pattern CJTPAT_data identified by "CJTPAT"
    load vx_gto GtoS_Pins output pattern PRBS_7_data identified by "PRBS7"
    load vx_gto GtoS_Pins output pattern D21_5_data identified by "D21_5"
    load vx_gto GtoS_Pins output pattern K28_7_data identified by "K28_7"
    load vx_gto GtoS_Pins output pattern K28_5_data identified by "K28_5"
    load vx_gto GtoS_Pins output pattern ALLONES_data identified by "ALLONES"
    load vx_gto GtoS_Pins output pattern ALLZEROS_data identified by "ALLZEROS"
    load vx_gto GtoS_Pins output pattern CDR_CID_data identified by "CDR_CID"
    load vx_gto GtoS_Pins output pattern CDR_CID_by2_data identified by "CDR_CIDby2"
    load vx_gto GtoS_Pins output pattern CID_160ones160zeros_data identified by "CID_160"
                                                                                                                                                
                                                                                                                                                
println (stdout, "GTO Fibre Channel pattern load complete.")
                                                                                                                                                
wait(0ms)   -- SET BREAKPOINT HERE
                                                                                                                                                
end_body


Procedure Define_FibreChannel_data
-----------------------------------------------------------------------------------------
-- Define the Fibre Channel data. These are the bulding blocks of the Fibre Channel Patterns
-- Typically built up from multiples of 4 x 10bits words
-- This is in the 10 bit format defined by the Fibre Channel Specification.


body

-- MSB first

awrite(Idle_prim[1:IDLE_LEN],16#0fa,16#2a2,16#2aa,16#2aa)
         
awrite(SOFn3[1:SOF_LEN],16#0fa,16#2aa,16#1a9,16#1a9)
 
awrite(RPAT[1:RPAT_LEN],16#21a,16#3a6,16#319,16#075,16#343,16#28d,16#32a,16#0b4,16#1e5,16#09e,16#2a9,16#265)
                
awrite(LDPAT[1:LDPAT_LEN],16#21c,16#1e3,16#21c,16#1e3)

awrite(LD2HDPAT[1:LD2HDPAT_LEN],16#21c,16#1e3,16#21c,16#0bc,16#1e3,16#34a,16#2aa,16#2aa)

awrite(HDPAT[1:HDPAT_LEN],16#2aa,16#2aa,16#2aa,16#2aa)

awrite(HD2LDPAT[1:HD2LDPAT_LEN],16#2aa,16#215,16#155,16#1e3,16#21c,16#1e3,16#21c,16#1e1)

awrite(CRPAT_CRC[1:CRC_LEN],16#1c8,16#319,16#2a5,16#1ab)
                                  
awrite(CJTPAT_CRC[1:CRC_LEN],16#2ae,16#1c9,16#1a1,16#2e6)
                 
awrite(EOFn[1:EOF_LEN],16#305,16#2aa,16#2a6,16#2a6)
                    

endbody

Procedure Define_CRPAT_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define the CRPAT data. This is in the 10 bit format defined by the Fibre Channel
-- Specification.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.
-- Create a match pattern for the digital subsystem which can be used for DUT Rx alignemnt.

in string[20]   : pat_name
in boolean      : create_trig_pat

local
    integer     : i,j,index
    lword       : GTO_array_size
    lword       : GTO_array[CRPAT_SIZE*CRPAT_GTO_MULT/32]
    lword       : sof_posn
end_local

body

                    
    CRPAT_data = 0
    index = 0

    for i = 1 to IDLE_RPT do
         CRPAT_data[index+1:index+IDLE_LEN]=Idle_prim[1:IDLE_LEN]
         index = index + IDLE_LEN
    end_for

    sof_posn = lword(index)*FC_WORD_SIZE+1
    CRPAT_data[index+1:index+SOF_LEN]=SOFn3[1:SOF_LEN]
    index = index + SOF_LEN
    

    for i = 1 to RPAT_RPT do
        CRPAT_data[index+1:index+RPAT_LEN]=RPAT[1:RPAT_LEN]
        index = index + RPAT_LEN
    end_for

    CRPAT_data[index+1:index+CRC_LEN]=CRPAT_CRC[1:CRC_LEN]
    index = index + CRC_LEN

    CRPAT_data[index+1:index+EOF_LEN]=EOFn[1:EOF_LEN]
    index = index + EOF_LEN


endbody

Procedure Define_CJTPAT_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define the CJTPAT data. This is in the 10 bit format defined by the Fibre Channel
-- Specification.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.
-- Create a match pattern for the digital subsystem which can be used for DUT Rx alignemnt.

in string[20]   : pat_name
in boolean      : create_trig_pat

local
    integer     : i,j,index
    lword       : GTO_array_size
    lword       : GTO_array[CJTPAT_SIZE*CJTPAT_GTO_MULT/32]
    lword       : sof_posn
end_local

body

    CJTPAT_data = 0
    index = 0

    for i = 1 to IDLE_RPT do
         CJTPAT_data[index+1:index+IDLE_LEN]=Idle_prim[1:IDLE_LEN]
         index = index + IDLE_LEN
    end_for

    sof_posn = lword(index)*FC_WORD_SIZE+1
    CJTPAT_data[index+1:index+SOF_LEN]=SOFn3[1:SOF_LEN]
    index = index + SOF_LEN
    
    for i = 1 to LDPAT_RPT do
         CJTPAT_data[index+1:index+LDPAT_LEN]=LDPAT[1:LDPAT_LEN]
         index = index + LDPAT_LEN
    end_for

    for i = 1 to LD2HDPAT_RPT do
         CJTPAT_data[index+1:index+LD2HDPAT_LEN]=LD2HDPAT[1:LD2HDPAT_LEN]
         index = index +LD2HDPAT_LEN
    end_for

    for i = 1 to HDPAT_RPT do
         CJTPAT_data[index+1:index+HDPAT_LEN]=HDPAT[1:HDPAT_LEN]
         index = index + HDPAT_LEN
    end_for

    for i = 1 to HD2LDPAT_RPT do
         CJTPAT_data[index+1:index+HD2LDPAT_LEN]=HD2LDPAT[1:HD2LDPAT_LEN]
         index = index + HD2LDPAT_LEN
    end_for

    CJTPAT_data[index+1:index+CRC_LEN]=CJTPAT_CRC[1:CRC_LEN]
    index = index + CRC_LEN

    CJTPAT_data[index+1:index+EOF_LEN]=EOFn[1:EOF_LEN]
    index = index + EOF_LEN


end_body

procedure Define_D21_5_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define simple 101010.. data.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    lword       : GTO_array[D21_5_SIZE*D21_5_GTO_MULT/32]
end_local

body

    D21_5_data[1] = 2#1010101010

end_body

Procedure Define_ALIGN_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define the ALIGN pattern data for the 640 bit pattern. This is in the 10 bit
-- format defined by the Fibre Channel Specification.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.

-- This pattern is a shortened CJTPAT with Idle Primitives at the end
-- 1: SOFn3
-- 1: Low Density Transition
-- 1: Transfering from Low to High
-- 1: Transfering from Low to High
-- 2: High Density Transition
-- 1: Transfering from High to Low
-- 1: Transfering from High to Low
-- 1: CRC (this is pattern dependent)
-- 1: EOFn
-- 6: Idle Primitive


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    integer     : i,j,index
    lword       : GTO_array_size
    lword       : GTO_array[ALIGN_GTO_SIZE]
    lword       : sof_posn
    lword       : num_bits
end_local

body

    ALIGN_data = 0
    index = 0

    sof_posn = lword(index)*FC_WORD_SIZE+1
    ALIGN_data[index+1:index+SOF_LEN]=SOFn3[1:SOF_LEN]
    index = index + SOF_LEN
    
    for i = 1 to 1 do
         ALIGN_data[index+1:index+LDPAT_LEN]=LDPAT[1:LDPAT_LEN]
         index = index + LDPAT_LEN
    end_for

    for i = 1 to 1 do
         ALIGN_data[index+1:index+LD2HDPAT_LEN]=LD2HDPAT[1:LD2HDPAT_LEN]
         index = index +LD2HDPAT_LEN
    end_for

    for i = 1 to 2 do
         ALIGN_data[index+1:index+HDPAT_LEN]=HDPAT[1:HDPAT_LEN]
         index = index + HDPAT_LEN
    end_for

    for i = 1 to 1 do
         ALIGN_data[index+1:index+HD2LDPAT_LEN]=HD2LDPAT[1:HD2LDPAT_LEN]
         index = index + HD2LDPAT_LEN
    end_for

    ALIGN_data[index+1:index+CRC_LEN]=CJTPAT_CRC[1:CRC_LEN]
    index = index + CRC_LEN

    ALIGN_data[index+1:index+EOF_LEN]=EOFn[1:EOF_LEN]
    index = index + EOF_LEN

    for i = 1 to IDLE_RPT do
         ALIGN_data[index+1:index+IDLE_LEN]=Idle_prim[1:IDLE_LEN]
         index = index + IDLE_LEN
    end_for


endbody

procedure Define_PRBS_7_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define the PRBS 2^7-1 data. This includes 10 bit codes that are not included in
-- the Fibre Channel Specification.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    lword       : GTO_array[PRBS7_SIZE*PRBS7_GTO_MULT/32]
    lword       : PAT_array[PRBS7_SIZE*10]
end_local

body

awrite(PRBS7_data[  1:  8],  1,1,1,0,1,1,1,0)
awrite(PRBS7_data[  9: 16],  0,1,1,0,0,1,0,1)
awrite(PRBS7_data[ 17: 24],  0,1,0,1,1,1,1,1)
awrite(PRBS7_data[ 25: 32],  1,1,0,0,0,0,0,0)
awrite(PRBS7_data[ 33: 40],  1,0,0,0,0,0,1,1)
awrite(PRBS7_data[ 41: 48],  0,0,0,0,1,0,1,0)
awrite(PRBS7_data[ 49: 56],  0,0,1,1,1,1,0,0)
awrite(PRBS7_data[ 57: 64],  1,0,0,0,1,0,1,1)
awrite(PRBS7_data[ 65: 72],  0,0,1,1,1,0,1,0)
awrite(PRBS7_data[ 73: 80],  1,0,0,1,1,1,1,1)
awrite(PRBS7_data[ 81: 88],  0,1,0,0,0,0,1,1)
awrite(PRBS7_data[ 89: 96],  1,0,0,0,1,0,0,1)
awrite(PRBS7_data[ 97:104],  0,0,1,1,0,1,1,0)
awrite(PRBS7_data[105:112],  1,0,1,1,0,1,1,1)
awrite(PRBS7_data[113:120],  1,0,1,1,0,0,0,1)
awrite(PRBS7_data[121:127],  1,0,1,0,0,1,0  )

end_body

procedure Define_K28_7_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define repeating 0011111000. data.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.

in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    lword       : GTO_array[K28_7_SIZE*K28_7_GTO_MULT/32]
end_local

body

    K28_7_data[1] = 2#0011111000

end_body

procedure Define_K28_5_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define repeating 0011111010 1100000101. data.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    lword       : GTO_array[K28_5_SIZE*K28_5_GTO_MULT/32]
end_local

body

    K28_5_data[1] = 2#0011111010
    K28_5_data[2] = 2#1100000101


end_body

procedure Define_ONEZERO_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define simple 101010.. data.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    word        : i, index
    lword       : GTO_array[ONEZERO_SIZE/32]
end_local

body


for i= 1 to 32 do
    index = 20*(i-1)
    awrite(ONEZERO_data[ index+1 : index+10],  1,0,1,0,1,0,1,0,1,0)
    awrite(ONEZERO_data[ index+11: index+20],  1,0,1,0,1,0,1,0,1,0)
end_for


end_body

procedure Define_TWOONEZERO_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define simple 1100.. data.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    word        : i, index
    lword       : GTO_array[TWOONEZERO_SIZE/32]
end_local

body


for i= 1 to 32 do
    index = 80*(i-1)
    awrite(TWOONEZERO_data[ index+1 : index+10],  1,1,0,0,1,1,0,0,1,1)
    awrite(TWOONEZERO_data[ index+11: index+20],  0,0,1,1,0,0,1,1,0,0)
end_for


end_body

procedure Define_FOURONEZERO_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define simple 11110000.. data.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    word        : i, index
    lword       : GTO_array[FOURONEZERO_SIZE/32]
end_local

body


for i= 1 to 16 do
    index = 40*(i-1)
    awrite(FOURONEZERO_data[ index+1 : index+10],  1,1,1,1,0,0,0,0,1,1)
    awrite(FOURONEZERO_data[ index+11: index+20],  1,1,0,0,0,0,1,1,1,1)
    awrite(FOURONEZERO_data[ index+21: index+30],  0,0,0,0,1,1,1,1,0,0)
    awrite(FOURONEZERO_data[ index+31: index+40],  0,0,1,1,1,1,0,0,0,0)
end_for


end_body

procedure Define_FIVEONEZERO_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define simple 1111100000.. data.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    word        : i, index
    lword       : GTO_array[FIVEONEZERO_SIZE/32]
end_local

body


for i= 1 to 32 do
    index = 20*(i-1)
    awrite(FIVEONEZERO_data[ index+1 : index+10],  1,1,1,1,1,0,0,0,0,0)
    awrite(FIVEONEZERO_data[ index+11: index+20],  1,1,1,1,1,0,0,0,0,0)
end_for


end_body

procedure Define_EIGHTONEZERO_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define simple 111111110000000.. data.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    word        : i, index
    lword       : GTO_array[EIGHTONEZERO_SIZE/32]
end_local

body


for i= 1 to 8 do
    index = 80*(i-1)
    awrite(EIGHTONEZERO_data[ index+1 : index+10],  1,1,1,1,1,1,1,1,0,0)
    awrite(EIGHTONEZERO_data[ index+11: index+20],  0,0,0,0,0,0,1,1,1,1)
    awrite(EIGHTONEZERO_data[ index+21: index+30],  1,1,1,1,0,0,0,0,0,0)
    awrite(EIGHTONEZERO_data[ index+31: index+40],  0,0,1,1,1,1,1,1,1,1)
    awrite(EIGHTONEZERO_data[ index+41: index+50],  0,0,0,0,0,0,0,0,1,1)
    awrite(EIGHTONEZERO_data[ index+51: index+60],  1,1,1,1,1,1,0,0,0,0)
    awrite(EIGHTONEZERO_data[ index+61: index+70],  0,0,0,0,1,1,1,1,1,1)
    awrite(EIGHTONEZERO_data[ index+71: index+80],  1,1,0,0,0,0,0,0,0,0)
end_for


end_body

procedure Define_TENONEZERO_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define simple 11111111110000000000.. data.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    word        : i, index
    lword       : GTO_array[TENONEZERO_SIZE/32]
end_local

body

--GTO_array_size = TENONEZERO_SIZE/32

for i= 1 to 32 do
    index = 20*(i-1)
    awrite(TENONEZERO_data[ index+1 : index+10],  1,1,1,1,1,1,1,1,1,1)
    awrite(TENONEZERO_data[ index+11: index+20],  0,0,0,0,0,0,0,0,0,0)
end_for


end_body

procedure Define_ALLZEROS_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define simple 000000.. data.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    word        : i, index
    lword       : GTO_array[ALLZEROS_SIZE/32]
end_local

body

for i= 1 to 64 do
    index = 10*(i-1)
    awrite(ALLZEROS_data[ index+1 : index+10], 0,0,0,0,0,0,0,0,0,0) 
end_for


end_body

procedure Define_ALLONES_data(pat_name,create_trig_pat)
-----------------------------------------------------------------------------------------
-- Define simple 11111.. data.
-- Create data which can be loaded into the gto for a looping pattern and save this to a file.


in string[20]   : pat_name
in boolean      : create_trig_pat

local
    lword       : GTO_array_size
    word        : i, index
    lword       : GTO_array[ALLONES_SIZE/32]
end_local

body

for i= 1 to 64 do
    index = 10*(i-1)
    awrite(ALLONES_data[ index+1 : index+10],  1,1,1,1,1,1,1,1,1,1)
end_for


end_body

procedure Define_CDR_CID_data
--------------------------------------------------------------------------------
--  

local

end_local

body

    awrite(CDR_CID_data[ 1: 8], 16#fe041851, 16#e459d4fa, 16#1c49b5bd, 16#8d2ee655, 16#fc0830a3, 16#c8b3a9f4, 16#38936b7b, 16#1a5dccab)
    awrite(CDR_CID_data[ 9: 16], 16#f8106147, 16#916753e8, 16#7126d6f6, 16#34bb9957, 16#f020c28f, 16#22cea7d0, 16#e24dadec, 16#697732af)
    awrite(CDR_CID_data[ 17: 24], 16#e041851e, 16#459d4fa1, 16#c49b5bd8, 16#d2ee655f, 16#c0830a3c, 16#8b3a9f43, 16#8936b7b1, 16#a5dccabf)
    awrite(CDR_CID_data[ 25: 32], 16#81061479, 16#16753e87, 16#126d6f63, 16#4bb9957f, 16#020c28f2, 16#2cea7d0e, 16#24dadec6, 16#97732afe)
    awrite(CDR_CID_data[ 33: 40], 16#041851e4, 16#59d4fa1c, 16#49b5bd8d, 16#2ee655fc, 16#0830a3c8, 16#b3a9f438, 16#936b7b1a, 16#5dccabf8)
    awrite(CDR_CID_data[ 41: 48], 16#10614791, 16#6753e871, 16#26d6f634, 16#bb9957f0, 16#20c28f22, 16#cea7d0e2, 16#4dadec69, 16#7732afe0)
    awrite(CDR_CID_data[ 49: 56], 16#41851e45, 16#9d4fa1c4, 16#9b5bd8d2, 16#ee655fc0, 16#830a3c8b, 16#3a9f4389, 16#36b7b1a5, 16#dccabf81)
    awrite(CDR_CID_data[ 57: 64], 16#06147916, 16#753e8712, 16#6d6f634b, 16#b9957f02, 16#0c28f22c, 16#ea7d0e24, 16#dadec697, 16#732affff)
    awrite(CDR_CID_data[ 65: 72], 16#ffffffff, 16#ffffffff, 16#fffff01f, 16#be7ae1ba, 16#62b05e3b, 16#64a4272d, 16#119aa03f, 16#7cf5c374)
    awrite(CDR_CID_data[ 73: 80], 16#c560bc76, 16#c9484e5a, 16#2335407e, 16#f9eb86e9, 16#8ac178ed, 16#92909cb4, 16#466a80fd, 16#f3d70dd3)
    awrite(CDR_CID_data[ 81: 88], 16#1582f1db, 16#25213968, 16#8cd501fb, 16#e7ae1ba6, 16#2b05e3b6, 16#4a4272d1, 16#19aa03f7, 16#cf5c374c)
    awrite(CDR_CID_data[ 89: 96], 16#560bc76c, 16#9484e5a2, 16#335407ef, 16#9eb86e98, 16#ac178ed9, 16#2909cb44, 16#66a80fdf, 16#3d70dd31)
    awrite(CDR_CID_data[ 97: 104], 16#582f1db2, 16#52139688, 16#cd501fbe, 16#7ae1ba62, 16#b05e3b64, 16#a4272d11, 16#9aa03f7c, 16#f5c374c5)
    awrite(CDR_CID_data[ 105: 112], 16#60bc76c9, 16#484e5a23, 16#35407ef9, 16#eb86e98a, 16#c178ed92, 16#909cb446, 16#6a80fdf3, 16#d70dd315)
    awrite(CDR_CID_data[ 113: 120], 16#82f1db25, 16#2139688c, 16#d501fbe7, 16#ae1ba62b, 16#05e3b64a, 16#4272d119, 16#aa03f7cf, 16#5c374c56)
    awrite(CDR_CID_data[ 121: 128], 16#0bc76c94, 16#84e5a233, 16#5407ef9e, 16#b86e98ac, 16#178ed929, 16#09cb4466, 16#a80fdf3d, 16#70dd3158)
    awrite(CDR_CID_data[ 129: 136], 16#2f1db252, 16#139688cd, 16#50000000, 16#00000000, 16#00000000, 16#00fe0418, 16#51e459d4, 16#fa1c49b5)
    awrite(CDR_CID_data[ 137: 144], 16#bd8d2ee6, 16#55fc0830, 16#a3c8b3a9, 16#f438936b, 16#7b1a5dcc, 16#abf81061, 16#47916753, 16#e87126d6)
    awrite(CDR_CID_data[ 145: 152], 16#f634bb99, 16#57f020c2, 16#8f22cea7, 16#d0e24dad, 16#ec697732, 16#afe04185, 16#1e459d4f, 16#a1c49b5b)
    awrite(CDR_CID_data[ 153: 160], 16#d8d2ee65, 16#5fc0830a, 16#3c8b3a9f, 16#438936b7, 16#b1a5dcca, 16#bf810614, 16#7916753e, 16#87126d6f)
    awrite(CDR_CID_data[ 161: 168], 16#634bb995, 16#7f020c28, 16#f22cea7d, 16#0e24dade, 16#c697732a, 16#fe041851, 16#e459d4fa, 16#1c49b5bd)
    awrite(CDR_CID_data[ 169: 176], 16#8d2ee655, 16#fc0830a3, 16#c8b3a9f4, 16#38936b7b, 16#1a5dccab, 16#f8106147, 16#916753e8, 16#7126d6f6)
    awrite(CDR_CID_data[ 177: 184], 16#34bb9957, 16#f020c28f, 16#22cea7d0, 16#e24dadec, 16#697732af, 16#e041851e, 16#459d4fa1, 16#c49b5bd8)
    awrite(CDR_CID_data[ 185: 192], 16#d2ee655f, 16#c0830a3c, 16#8b3a9f43, 16#8936b7b1, 16#a5dccabf, 16#81061479, 16#16753e87, 16#126d6f63)
    awrite(CDR_CID_data[ 193: 200], 16#4bb9957f, 16#020c28f2, 16#2cea7d0e, 16#24dadec6, 16#97732aff, 16#ffffffff, 16#ffffffff, 16#fffffff0)
    awrite(CDR_CID_data[ 201: 208], 16#1fbe7ae1, 16#ba62b05e, 16#3b64a427, 16#2d119aa0, 16#3f7cf5c3, 16#74c560bc, 16#76c9484e, 16#5a233540)
    awrite(CDR_CID_data[ 209: 216], 16#7ef9eb86, 16#e98ac178, 16#ed92909c, 16#b4466a80, 16#fdf3d70d, 16#d31582f1, 16#db252139, 16#688cd501)
    awrite(CDR_CID_data[ 217: 224], 16#fbe7ae1b, 16#a62b05e3, 16#b64a4272, 16#d119aa03, 16#f7cf5c37, 16#4c560bc7, 16#6c9484e5, 16#a2335407)
    awrite(CDR_CID_data[ 225: 232], 16#ef9eb86e, 16#98ac178e, 16#d92909cb, 16#4466a80f, 16#df3d70dd, 16#31582f1d, 16#b2521396, 16#88cd501f)
    awrite(CDR_CID_data[ 233: 240], 16#be7ae1ba, 16#62b05e3b, 16#64a4272d, 16#119aa03f, 16#7cf5c374, 16#c560bc76, 16#c9484e5a, 16#2335407e)
    awrite(CDR_CID_data[ 241: 248], 16#f9eb86e9, 16#8ac178ed, 16#92909cb4, 16#466a80fd, 16#f3d70dd3, 16#1582f1db, 16#25213968, 16#8cd501fb)
    awrite(CDR_CID_data[ 249: 256], 16#e7ae1ba6, 16#2b05e3b6, 16#4a4272d1, 16#19aa03f7, 16#cf5c374c, 16#560bc76c, 16#9484e5a2, 16#335407ef)
    awrite(CDR_CID_data[ 257: 264], 16#9eb86e98, 16#ac178ed9, 16#2909cb44, 16#66a80fdf, 16#3d70dd31, 16#582f1db2, 16#52139688, 16#cd500000)
    awrite(CDR_CID_data[ 265: 272], 16#00000000, 16#00000000, 16#0000fe04, 16#1851e459, 16#d4fa1c49, 16#b5bd8d2e, 16#e655fc08, 16#30a3c8b3)
    awrite(CDR_CID_data[ 273: 280], 16#a9f43893, 16#6b7b1a5d, 16#ccabf810, 16#61479167, 16#53e87126, 16#d6f634bb, 16#9957f020, 16#c28f22ce)
    awrite(CDR_CID_data[ 281: 288], 16#a7d0e24d, 16#adec6977, 16#32afe041, 16#851e459d, 16#4fa1c49b, 16#5bd8d2ee, 16#655fc083, 16#0a3c8b3a)
    awrite(CDR_CID_data[ 289: 296], 16#9f438936, 16#b7b1a5dc, 16#cabf8106, 16#14791675, 16#3e87126d, 16#6f634bb9, 16#957f020c, 16#28f22cea)
    awrite(CDR_CID_data[ 297: 304], 16#7d0e24da, 16#dec69773, 16#2afe0418, 16#51e459d4, 16#fa1c49b5, 16#bd8d2ee6, 16#55fc0830, 16#a3c8b3a9)
    awrite(CDR_CID_data[ 305: 312], 16#f438936b, 16#7b1a5dcc, 16#abf81061, 16#47916753, 16#e87126d6, 16#f634bb99, 16#57f020c2, 16#8f22cea7)
    awrite(CDR_CID_data[ 313: 320], 16#d0e24dad, 16#ec697732, 16#afe04185, 16#1e459d4f, 16#a1c49b5b, 16#d8d2ee65, 16#5fc0830a, 16#3c8b3a9f)
    awrite(CDR_CID_data[ 321: 328], 16#438936b7, 16#b1a5dcca, 16#bf810614, 16#7916753e, 16#87126d6f, 16#634bb995, 16#7f020c28, 16#f22cea7d)
    awrite(CDR_CID_data[ 329: 336], 16#0e24dade, 16#c697732a, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#f01fbe7a, 16#e1ba62b0, 16#5e3b64a4)
    awrite(CDR_CID_data[ 337: 344], 16#272d119a, 16#a03f7cf5, 16#c374c560, 16#bc76c948, 16#4e5a2335, 16#407ef9eb, 16#86e98ac1, 16#78ed9290)
    awrite(CDR_CID_data[ 345: 352], 16#9cb4466a, 16#80fdf3d7, 16#0dd31582, 16#f1db2521, 16#39688cd5, 16#01fbe7ae, 16#1ba62b05, 16#e3b64a42)
    awrite(CDR_CID_data[ 353: 360], 16#72d119aa, 16#03f7cf5c, 16#374c560b, 16#c76c9484, 16#e5a23354, 16#07ef9eb8, 16#6e98ac17, 16#8ed92909)
    awrite(CDR_CID_data[ 361: 368], 16#cb4466a8, 16#0fdf3d70, 16#dd31582f, 16#1db25213, 16#9688cd50, 16#1fbe7ae1, 16#ba62b05e, 16#3b64a427)
    awrite(CDR_CID_data[ 369: 376], 16#2d119aa0, 16#3f7cf5c3, 16#74c560bc, 16#76c9484e, 16#5a233540, 16#7ef9eb86, 16#e98ac178, 16#ed92909c)
    awrite(CDR_CID_data[ 377: 384], 16#b4466a80, 16#fdf3d70d, 16#d31582f1, 16#db252139, 16#688cd501, 16#fbe7ae1b, 16#a62b05e3, 16#b64a4272)
    awrite(CDR_CID_data[ 385: 392], 16#d119aa03, 16#f7cf5c37, 16#4c560bc7, 16#6c9484e5, 16#a2335407, 16#ef9eb86e, 16#98ac178e, 16#d92909cb)
    awrite(CDR_CID_data[ 393: 400], 16#4466a80f, 16#df3d70dd, 16#31582f1d, 16#b2521396, 16#88cd5000, 16#00000000, 16#00000000, 16#000000fe)
    awrite(CDR_CID_data[ 401: 408], 16#041851e4, 16#59d4fa1c, 16#49b5bd8d, 16#2ee655fc, 16#0830a3c8, 16#b3a9f438, 16#936b7b1a, 16#5dccabf8)
    awrite(CDR_CID_data[ 409: 416], 16#10614791, 16#6753e871, 16#26d6f634, 16#bb9957f0, 16#20c28f22, 16#cea7d0e2, 16#4dadec69, 16#7732afe0)
    awrite(CDR_CID_data[ 417: 424], 16#41851e45, 16#9d4fa1c4, 16#9b5bd8d2, 16#ee655fc0, 16#830a3c8b, 16#3a9f4389, 16#36b7b1a5, 16#dccabf81)
    awrite(CDR_CID_data[ 425: 432], 16#06147916, 16#753e8712, 16#6d6f634b, 16#b9957f02, 16#0c28f22c, 16#ea7d0e24, 16#dadec697, 16#732afe04)
    awrite(CDR_CID_data[ 433: 440], 16#1851e459, 16#d4fa1c49, 16#b5bd8d2e, 16#e655fc08, 16#30a3c8b3, 16#a9f43893, 16#6b7b1a5d, 16#ccabf810)
    awrite(CDR_CID_data[ 441: 448], 16#61479167, 16#53e87126, 16#d6f634bb, 16#9957f020, 16#c28f22ce, 16#a7d0e24d, 16#adec6977, 16#32afe041)
    awrite(CDR_CID_data[ 449: 456], 16#851e459d, 16#4fa1c49b, 16#5bd8d2ee, 16#655fc083, 16#0a3c8b3a, 16#9f438936, 16#b7b1a5dc, 16#cabf8106)
    awrite(CDR_CID_data[ 457: 464], 16#14791675, 16#3e87126d, 16#6f634bb9, 16#957f020c, 16#28f22cea, 16#7d0e24da, 16#dec69773, 16#2affffff)
    awrite(CDR_CID_data[ 465: 472], 16#ffffffff, 16#ffffffff, 16#fff01fbe, 16#7ae1ba62, 16#b05e3b64, 16#a4272d11, 16#9aa03f7c, 16#f5c374c5)
    awrite(CDR_CID_data[ 473: 480], 16#60bc76c9, 16#484e5a23, 16#35407ef9, 16#eb86e98a, 16#c178ed92, 16#909cb446, 16#6a80fdf3, 16#d70dd315)
    awrite(CDR_CID_data[ 481: 488], 16#82f1db25, 16#2139688c, 16#d501fbe7, 16#ae1ba62b, 16#05e3b64a, 16#4272d119, 16#aa03f7cf, 16#5c374c56)
    awrite(CDR_CID_data[ 489: 496], 16#0bc76c94, 16#84e5a233, 16#5407ef9e, 16#b86e98ac, 16#178ed929, 16#09cb4466, 16#a80fdf3d, 16#70dd3158)
    awrite(CDR_CID_data[ 497: 504], 16#2f1db252, 16#139688cd, 16#501fbe7a, 16#e1ba62b0, 16#5e3b64a4, 16#272d119a, 16#a03f7cf5, 16#c374c560)
    awrite(CDR_CID_data[ 505: 512], 16#bc76c948, 16#4e5a2335, 16#407ef9eb, 16#86e98ac1, 16#78ed9290, 16#9cb4466a, 16#80fdf3d7, 16#0dd31582)
    awrite(CDR_CID_data[ 513: 520], 16#f1db2521, 16#39688cd5, 16#01fbe7ae, 16#1ba62b05, 16#e3b64a42, 16#72d119aa, 16#03f7cf5c, 16#374c560b)
    awrite(CDR_CID_data[ 521: 528], 16#c76c9484, 16#e5a23354, 16#07ef9eb8, 16#6e98ac17, 16#8ed92909, 16#cb4466a8, 16#0fdf3d70, 16#dd31582f)
    awrite(CDR_CID_data[ 529: 536], 16#1db25213, 16#9688cd50, 16#00000000, 16#00000000, 16#00000000, 16#fe041851, 16#e459d4fa, 16#1c49b5bd)
    awrite(CDR_CID_data[ 537: 544], 16#8d2ee655, 16#fc0830a3, 16#c8b3a9f4, 16#38936b7b, 16#1a5dccab, 16#f8106147, 16#916753e8, 16#7126d6f6)
    awrite(CDR_CID_data[ 545: 552], 16#34bb9957, 16#f020c28f, 16#22cea7d0, 16#e24dadec, 16#697732af, 16#e041851e, 16#459d4fa1, 16#c49b5bd8)
    awrite(CDR_CID_data[ 553: 560], 16#d2ee655f, 16#c0830a3c, 16#8b3a9f43, 16#8936b7b1, 16#a5dccabf, 16#81061479, 16#16753e87, 16#126d6f63)
    awrite(CDR_CID_data[ 561: 568], 16#4bb9957f, 16#020c28f2, 16#2cea7d0e, 16#24dadec6, 16#97732afe, 16#041851e4, 16#59d4fa1c, 16#49b5bd8d)
    awrite(CDR_CID_data[ 569: 576], 16#2ee655fc, 16#0830a3c8, 16#b3a9f438, 16#936b7b1a, 16#5dccabf8, 16#10614791, 16#6753e871, 16#26d6f634)
    awrite(CDR_CID_data[ 577: 584], 16#bb9957f0, 16#20c28f22, 16#cea7d0e2, 16#4dadec69, 16#7732afe0, 16#41851e45, 16#9d4fa1c4, 16#9b5bd8d2)
    awrite(CDR_CID_data[ 585: 592], 16#ee655fc0, 16#830a3c8b, 16#3a9f4389, 16#36b7b1a5, 16#dccabf81, 16#06147916, 16#753e8712, 16#6d6f634b)
    awrite(CDR_CID_data[ 593: 600], 16#b9957f02, 16#0c28f22c, 16#ea7d0e24, 16#dadec697, 16#732affff, 16#ffffffff, 16#ffffffff, 16#fffff01f)
    awrite(CDR_CID_data[ 601: 608], 16#be7ae1ba, 16#62b05e3b, 16#64a4272d, 16#119aa03f, 16#7cf5c374, 16#c560bc76, 16#c9484e5a, 16#2335407e)
    awrite(CDR_CID_data[ 609: 616], 16#f9eb86e9, 16#8ac178ed, 16#92909cb4, 16#466a80fd, 16#f3d70dd3, 16#1582f1db, 16#25213968, 16#8cd501fb)
    awrite(CDR_CID_data[ 617: 624], 16#e7ae1ba6, 16#2b05e3b6, 16#4a4272d1, 16#19aa03f7, 16#cf5c374c, 16#560bc76c, 16#9484e5a2, 16#335407ef)
    awrite(CDR_CID_data[ 625: 632], 16#9eb86e98, 16#ac178ed9, 16#2909cb44, 16#66a80fdf, 16#3d70dd31, 16#582f1db2, 16#52139688, 16#cd501fbe)
    awrite(CDR_CID_data[ 633: 640], 16#7ae1ba62, 16#b05e3b64, 16#a4272d11, 16#9aa03f7c, 16#f5c374c5, 16#60bc76c9, 16#484e5a23, 16#35407ef9)
    awrite(CDR_CID_data[ 641: 648], 16#eb86e98a, 16#c178ed92, 16#909cb446, 16#6a80fdf3, 16#d70dd315, 16#82f1db25, 16#2139688c, 16#d501fbe7)
    awrite(CDR_CID_data[ 649: 656], 16#ae1ba62b, 16#05e3b64a, 16#4272d119, 16#aa03f7cf, 16#5c374c56, 16#0bc76c94, 16#84e5a233, 16#5407ef9e)
    awrite(CDR_CID_data[ 657: 664], 16#b86e98ac, 16#178ed929, 16#09cb4466, 16#a80fdf3d, 16#70dd3158, 16#2f1db252, 16#139688cd, 16#50000000)
    awrite(CDR_CID_data[ 665: 672], 16#00000000, 16#00000000, 16#00fe0418, 16#51e459d4, 16#fa1c49b5, 16#bd8d2ee6, 16#55fc0830, 16#a3c8b3a9)
    awrite(CDR_CID_data[ 673: 680], 16#f438936b, 16#7b1a5dcc, 16#abf81061, 16#47916753, 16#e87126d6, 16#f634bb99, 16#57f020c2, 16#8f22cea7)
    awrite(CDR_CID_data[ 681: 688], 16#d0e24dad, 16#ec697732, 16#afe04185, 16#1e459d4f, 16#a1c49b5b, 16#d8d2ee65, 16#5fc0830a, 16#3c8b3a9f)
    awrite(CDR_CID_data[ 689: 696], 16#438936b7, 16#b1a5dcca, 16#bf810614, 16#7916753e, 16#87126d6f, 16#634bb995, 16#7f020c28, 16#f22cea7d)
    awrite(CDR_CID_data[ 697: 704], 16#0e24dade, 16#c697732a, 16#fe041851, 16#e459d4fa, 16#1c49b5bd, 16#8d2ee655, 16#fc0830a3, 16#c8b3a9f4)
    awrite(CDR_CID_data[ 705: 712], 16#38936b7b, 16#1a5dccab, 16#f8106147, 16#916753e8, 16#7126d6f6, 16#34bb9957, 16#f020c28f, 16#22cea7d0)
    awrite(CDR_CID_data[ 713: 720], 16#e24dadec, 16#697732af, 16#e041851e, 16#459d4fa1, 16#c49b5bd8, 16#d2ee655f, 16#c0830a3c, 16#8b3a9f43)
    awrite(CDR_CID_data[ 721: 728], 16#8936b7b1, 16#a5dccabf, 16#81061479, 16#16753e87, 16#126d6f63, 16#4bb9957f, 16#020c28f2, 16#2cea7d0e)
    awrite(CDR_CID_data[ 729: 736], 16#24dadec6, 16#97732aff, 16#ffffffff, 16#ffffffff, 16#fffffff0, 16#1fbe7ae1, 16#ba62b05e, 16#3b64a427)
    awrite(CDR_CID_data[ 737: 744], 16#2d119aa0, 16#3f7cf5c3, 16#74c560bc, 16#76c9484e, 16#5a233540, 16#7ef9eb86, 16#e98ac178, 16#ed92909c)
    awrite(CDR_CID_data[ 745: 752], 16#b4466a80, 16#fdf3d70d, 16#d31582f1, 16#db252139, 16#688cd501, 16#fbe7ae1b, 16#a62b05e3, 16#b64a4272)
    awrite(CDR_CID_data[ 753: 760], 16#d119aa03, 16#f7cf5c37, 16#4c560bc7, 16#6c9484e5, 16#a2335407, 16#ef9eb86e, 16#98ac178e, 16#d92909cb)
    awrite(CDR_CID_data[ 761: 768], 16#4466a80f, 16#df3d70dd, 16#31582f1d, 16#b2521396, 16#88cd501f, 16#be7ae1ba, 16#62b05e3b, 16#64a4272d)
    awrite(CDR_CID_data[ 769: 776], 16#119aa03f, 16#7cf5c374, 16#c560bc76, 16#c9484e5a, 16#2335407e, 16#f9eb86e9, 16#8ac178ed, 16#92909cb4)
    awrite(CDR_CID_data[ 777: 784], 16#466a80fd, 16#f3d70dd3, 16#1582f1db, 16#25213968, 16#8cd501fb, 16#e7ae1ba6, 16#2b05e3b6, 16#4a4272d1)
    awrite(CDR_CID_data[ 785: 792], 16#19aa03f7, 16#cf5c374c, 16#560bc76c, 16#9484e5a2, 16#335407ef, 16#9eb86e98, 16#ac178ed9, 16#2909cb44)
    awrite(CDR_CID_data[ 793: 800], 16#66a80fdf, 16#3d70dd31, 16#582f1db2, 16#52139688, 16#cd500000, 16#00000000, 16#00000000, 16#0000fe04)
    awrite(CDR_CID_data[ 801: 808], 16#1851e459, 16#d4fa1c49, 16#b5bd8d2e, 16#e655fc08, 16#30a3c8b3, 16#a9f43893, 16#6b7b1a5d, 16#ccabf810)
    awrite(CDR_CID_data[ 809: 816], 16#61479167, 16#53e87126, 16#d6f634bb, 16#9957f020, 16#c28f22ce, 16#a7d0e24d, 16#adec6977, 16#32afe041)
    awrite(CDR_CID_data[ 817: 824], 16#851e459d, 16#4fa1c49b, 16#5bd8d2ee, 16#655fc083, 16#0a3c8b3a, 16#9f438936, 16#b7b1a5dc, 16#cabf8106)
    awrite(CDR_CID_data[ 825: 832], 16#14791675, 16#3e87126d, 16#6f634bb9, 16#957f020c, 16#28f22cea, 16#7d0e24da, 16#dec69773, 16#2afe0418)
    awrite(CDR_CID_data[ 833: 840], 16#51e459d4, 16#fa1c49b5, 16#bd8d2ee6, 16#55fc0830, 16#a3c8b3a9, 16#f438936b, 16#7b1a5dcc, 16#abf81061)
    awrite(CDR_CID_data[ 841: 848], 16#47916753, 16#e87126d6, 16#f634bb99, 16#57f020c2, 16#8f22cea7, 16#d0e24dad, 16#ec697732, 16#afe04185)
    awrite(CDR_CID_data[ 849: 856], 16#1e459d4f, 16#a1c49b5b, 16#d8d2ee65, 16#5fc0830a, 16#3c8b3a9f, 16#438936b7, 16#b1a5dcca, 16#bf810614)
    awrite(CDR_CID_data[ 857: 864], 16#7916753e, 16#87126d6f, 16#634bb995, 16#7f020c28, 16#f22cea7d, 16#0e24dade, 16#c697732a, 16#ffffffff)
    awrite(CDR_CID_data[ 865: 872], 16#ffffffff, 16#ffffffff, 16#f01fbe7a, 16#e1ba62b0, 16#5e3b64a4, 16#272d119a, 16#a03f7cf5, 16#c374c560)
    awrite(CDR_CID_data[ 873: 880], 16#bc76c948, 16#4e5a2335, 16#407ef9eb, 16#86e98ac1, 16#78ed9290, 16#9cb4466a, 16#80fdf3d7, 16#0dd31582)
    awrite(CDR_CID_data[ 881: 888], 16#f1db2521, 16#39688cd5, 16#01fbe7ae, 16#1ba62b05, 16#e3b64a42, 16#72d119aa, 16#03f7cf5c, 16#374c560b)
    awrite(CDR_CID_data[ 889: 896], 16#c76c9484, 16#e5a23354, 16#07ef9eb8, 16#6e98ac17, 16#8ed92909, 16#cb4466a8, 16#0fdf3d70, 16#dd31582f)
    awrite(CDR_CID_data[ 897: 904], 16#1db25213, 16#9688cd50, 16#1fbe7ae1, 16#ba62b05e, 16#3b64a427, 16#2d119aa0, 16#3f7cf5c3, 16#74c560bc)
    awrite(CDR_CID_data[ 905: 912], 16#76c9484e, 16#5a233540, 16#7ef9eb86, 16#e98ac178, 16#ed92909c, 16#b4466a80, 16#fdf3d70d, 16#d31582f1)
    awrite(CDR_CID_data[ 913: 920], 16#db252139, 16#688cd501, 16#fbe7ae1b, 16#a62b05e3, 16#b64a4272, 16#d119aa03, 16#f7cf5c37, 16#4c560bc7)
    awrite(CDR_CID_data[ 921: 928], 16#6c9484e5, 16#a2335407, 16#ef9eb86e, 16#98ac178e, 16#d92909cb, 16#4466a80f, 16#df3d70dd, 16#31582f1d)
    awrite(CDR_CID_data[ 929: 936], 16#b2521396, 16#88cd5000, 16#00000000, 16#00000000, 16#000000fe, 16#041851e4, 16#59d4fa1c, 16#49b5bd8d)
    awrite(CDR_CID_data[ 937: 944], 16#2ee655fc, 16#0830a3c8, 16#b3a9f438, 16#936b7b1a, 16#5dccabf8, 16#10614791, 16#6753e871, 16#26d6f634)
    awrite(CDR_CID_data[ 945: 952], 16#bb9957f0, 16#20c28f22, 16#cea7d0e2, 16#4dadec69, 16#7732afe0, 16#41851e45, 16#9d4fa1c4, 16#9b5bd8d2)
    awrite(CDR_CID_data[ 953: 960], 16#ee655fc0, 16#830a3c8b, 16#3a9f4389, 16#36b7b1a5, 16#dccabf81, 16#06147916, 16#753e8712, 16#6d6f634b)
    awrite(CDR_CID_data[ 961: 968], 16#b9957f02, 16#0c28f22c, 16#ea7d0e24, 16#dadec697, 16#732afe04, 16#1851e459, 16#d4fa1c49, 16#b5bd8d2e)
    awrite(CDR_CID_data[ 969: 976], 16#e655fc08, 16#30a3c8b3, 16#a9f43893, 16#6b7b1a5d, 16#ccabf810, 16#61479167, 16#53e87126, 16#d6f634bb)
    awrite(CDR_CID_data[ 977: 984], 16#9957f020, 16#c28f22ce, 16#a7d0e24d, 16#adec6977, 16#32afe041, 16#851e459d, 16#4fa1c49b, 16#5bd8d2ee)
    awrite(CDR_CID_data[ 985: 992], 16#655fc083, 16#0a3c8b3a, 16#9f438936, 16#b7b1a5dc, 16#cabf8106, 16#14791675, 16#3e87126d, 16#6f634bb9)
    awrite(CDR_CID_data[ 993: 1000], 16#957f020c, 16#28f22cea, 16#7d0e24da, 16#dec69773, 16#2affffff, 16#ffffffff, 16#ffffffff, 16#fff01fbe)
    awrite(CDR_CID_data[ 1001: 1008], 16#7ae1ba62, 16#b05e3b64, 16#a4272d11, 16#9aa03f7c, 16#f5c374c5, 16#60bc76c9, 16#484e5a23, 16#35407ef9)
    awrite(CDR_CID_data[ 1009: 1016], 16#eb86e98a, 16#c178ed92, 16#909cb446, 16#6a80fdf3, 16#d70dd315, 16#82f1db25, 16#2139688c, 16#d501fbe7)
    awrite(CDR_CID_data[ 1017: 1024], 16#ae1ba62b, 16#05e3b64a, 16#4272d119, 16#aa03f7cf, 16#5c374c56, 16#0bc76c94, 16#84e5a233, 16#5407ef9e)
    awrite(CDR_CID_data[ 1025: 1032], 16#b86e98ac, 16#178ed929, 16#09cb4466, 16#a80fdf3d, 16#70dd3158, 16#2f1db252, 16#139688cd, 16#501fbe7a)
    awrite(CDR_CID_data[ 1033: 1040], 16#e1ba62b0, 16#5e3b64a4, 16#272d119a, 16#a03f7cf5, 16#c374c560, 16#bc76c948, 16#4e5a2335, 16#407ef9eb)
    awrite(CDR_CID_data[ 1041: 1048], 16#86e98ac1, 16#78ed9290, 16#9cb4466a, 16#80fdf3d7, 16#0dd31582, 16#f1db2521, 16#39688cd5, 16#01fbe7ae)
    awrite(CDR_CID_data[ 1049: 1056], 16#1ba62b05, 16#e3b64a42, 16#72d119aa, 16#03f7cf5c, 16#374c560b, 16#c76c9484, 16#e5a23354, 16#07ef9eb8)
    awrite(CDR_CID_data[ 1057: 1064], 16#6e98ac17, 16#8ed92909, 16#cb4466a8, 16#0fdf3d70, 16#dd31582f, 16#1db25213, 16#9688cd50, 16#00000000)
    awrite(CDR_CID_data[ 1065: 1072], 16#00000000, 16#00000000, 16#fe041851, 16#e459d4fa, 16#1c49b5bd, 16#8d2ee655, 16#fc0830a3, 16#c8b3a9f4)
    awrite(CDR_CID_data[ 1073: 1080], 16#38936b7b, 16#1a5dccab, 16#f8106147, 16#916753e8, 16#7126d6f6, 16#34bb9957, 16#f020c28f, 16#22cea7d0)
    awrite(CDR_CID_data[ 1081: 1088], 16#e24dadec, 16#697732af, 16#e041851e, 16#459d4fa1, 16#c49b5bd8, 16#d2ee655f, 16#c0830a3c, 16#8b3a9f43)
    awrite(CDR_CID_data[ 1089: 1096], 16#8936b7b1, 16#a5dccabf, 16#81061479, 16#16753e87, 16#126d6f63, 16#4bb9957f, 16#020c28f2, 16#2cea7d0e)
    awrite(CDR_CID_data[ 1097: 1104], 16#24dadec6, 16#97732afe, 16#041851e4, 16#59d4fa1c, 16#49b5bd8d, 16#2ee655fc, 16#0830a3c8, 16#b3a9f438)
    awrite(CDR_CID_data[ 1105: 1112], 16#936b7b1a, 16#5dccabf8, 16#10614791, 16#6753e871, 16#26d6f634, 16#bb9957f0, 16#20c28f22, 16#cea7d0e2)
    awrite(CDR_CID_data[ 1113: 1120], 16#4dadec69, 16#7732afe0, 16#41851e45, 16#9d4fa1c4, 16#9b5bd8d2, 16#ee655fc0, 16#830a3c8b, 16#3a9f4389)
    awrite(CDR_CID_data[ 1121: 1128], 16#36b7b1a5, 16#dccabf81, 16#06147916, 16#753e8712, 16#6d6f634b, 16#b9957f02, 16#0c28f22c, 16#ea7d0e24)
    awrite(CDR_CID_data[ 1129: 1136], 16#dadec697, 16#732affff, 16#ffffffff, 16#ffffffff, 16#fffff01f, 16#be7ae1ba, 16#62b05e3b, 16#64a4272d)
    awrite(CDR_CID_data[ 1137: 1144], 16#119aa03f, 16#7cf5c374, 16#c560bc76, 16#c9484e5a, 16#2335407e, 16#f9eb86e9, 16#8ac178ed, 16#92909cb4)
    awrite(CDR_CID_data[ 1145: 1152], 16#466a80fd, 16#f3d70dd3, 16#1582f1db, 16#25213968, 16#8cd501fb, 16#e7ae1ba6, 16#2b05e3b6, 16#4a4272d1)
    awrite(CDR_CID_data[ 1153: 1160], 16#19aa03f7, 16#cf5c374c, 16#560bc76c, 16#9484e5a2, 16#335407ef, 16#9eb86e98, 16#ac178ed9, 16#2909cb44)
    awrite(CDR_CID_data[ 1161: 1168], 16#66a80fdf, 16#3d70dd31, 16#582f1db2, 16#52139688, 16#cd501fbe, 16#7ae1ba62, 16#b05e3b64, 16#a4272d11)
    awrite(CDR_CID_data[ 1169: 1176], 16#9aa03f7c, 16#f5c374c5, 16#60bc76c9, 16#484e5a23, 16#35407ef9, 16#eb86e98a, 16#c178ed92, 16#909cb446)
    awrite(CDR_CID_data[ 1177: 1184], 16#6a80fdf3, 16#d70dd315, 16#82f1db25, 16#2139688c, 16#d501fbe7, 16#ae1ba62b, 16#05e3b64a, 16#4272d119)
    awrite(CDR_CID_data[ 1185: 1192], 16#aa03f7cf, 16#5c374c56, 16#0bc76c94, 16#84e5a233, 16#5407ef9e, 16#b86e98ac, 16#178ed929, 16#09cb4466)
    awrite(CDR_CID_data[ 1193: 1200], 16#a80fdf3d, 16#70dd3158, 16#2f1db252, 16#139688cd, 16#50000000, 16#00000000, 16#00000000, 16#00fe0418)
    awrite(CDR_CID_data[ 1201: 1208], 16#51e459d4, 16#fa1c49b5, 16#bd8d2ee6, 16#55fc0830, 16#a3c8b3a9, 16#f438936b, 16#7b1a5dcc, 16#abf81061)
    awrite(CDR_CID_data[ 1209: 1216], 16#47916753, 16#e87126d6, 16#f634bb99, 16#57f020c2, 16#8f22cea7, 16#d0e24dad, 16#ec697732, 16#afe04185)
    awrite(CDR_CID_data[ 1217: 1224], 16#1e459d4f, 16#a1c49b5b, 16#d8d2ee65, 16#5fc0830a, 16#3c8b3a9f, 16#438936b7, 16#b1a5dcca, 16#bf810614)
    awrite(CDR_CID_data[ 1225: 1232], 16#7916753e, 16#87126d6f, 16#634bb995, 16#7f020c28, 16#f22cea7d, 16#0e24dade, 16#c697732a, 16#fe041851)
    awrite(CDR_CID_data[ 1233: 1240], 16#e459d4fa, 16#1c49b5bd, 16#8d2ee655, 16#fc0830a3, 16#c8b3a9f4, 16#38936b7b, 16#1a5dccab, 16#f8106147)
    awrite(CDR_CID_data[ 1241: 1248], 16#916753e8, 16#7126d6f6, 16#34bb9957, 16#f020c28f, 16#22cea7d0, 16#e24dadec, 16#697732af, 16#e041851e)
    awrite(CDR_CID_data[ 1249: 1256], 16#459d4fa1, 16#c49b5bd8, 16#d2ee655f, 16#c0830a3c, 16#8b3a9f43, 16#8936b7b1, 16#a5dccabf, 16#81061479)
    awrite(CDR_CID_data[ 1257: 1264], 16#16753e87, 16#126d6f63, 16#4bb9957f, 16#020c28f2, 16#2cea7d0e, 16#24dadec6, 16#97732aff, 16#ffffffff)
    awrite(CDR_CID_data[ 1265: 1272], 16#ffffffff, 16#fffffff0, 16#1fbe7ae1, 16#ba62b05e, 16#3b64a427, 16#2d119aa0, 16#3f7cf5c3, 16#74c560bc)
    awrite(CDR_CID_data[ 1273: 1280], 16#76c9484e, 16#5a233540, 16#7ef9eb86, 16#e98ac178, 16#ed92909c, 16#b4466a80, 16#fdf3d70d, 16#d31582f1)
    awrite(CDR_CID_data[ 1281: 1288], 16#db252139, 16#688cd501, 16#fbe7ae1b, 16#a62b05e3, 16#b64a4272, 16#d119aa03, 16#f7cf5c37, 16#4c560bc7)
    awrite(CDR_CID_data[ 1289: 1296], 16#6c9484e5, 16#a2335407, 16#ef9eb86e, 16#98ac178e, 16#d92909cb, 16#4466a80f, 16#df3d70dd, 16#31582f1d)
    awrite(CDR_CID_data[ 1297: 1304], 16#b2521396, 16#88cd501f, 16#be7ae1ba, 16#62b05e3b, 16#64a4272d, 16#119aa03f, 16#7cf5c374, 16#c560bc76)
    awrite(CDR_CID_data[ 1305: 1312], 16#c9484e5a, 16#2335407e, 16#f9eb86e9, 16#8ac178ed, 16#92909cb4, 16#466a80fd, 16#f3d70dd3, 16#1582f1db)
    awrite(CDR_CID_data[ 1313: 1320], 16#25213968, 16#8cd501fb, 16#e7ae1ba6, 16#2b05e3b6, 16#4a4272d1, 16#19aa03f7, 16#cf5c374c, 16#560bc76c)
    awrite(CDR_CID_data[ 1321: 1328], 16#9484e5a2, 16#335407ef, 16#9eb86e98, 16#ac178ed9, 16#2909cb44, 16#66a80fdf, 16#3d70dd31, 16#582f1db2)
    awrite(CDR_CID_data[ 1329: 1336], 16#52139688, 16#cd500000, 16#00000000, 16#00000000, 16#0000fe04, 16#1851e459, 16#d4fa1c49, 16#b5bd8d2e)
    awrite(CDR_CID_data[ 1337: 1344], 16#e655fc08, 16#30a3c8b3, 16#a9f43893, 16#6b7b1a5d, 16#ccabf810, 16#61479167, 16#53e87126, 16#d6f634bb)
    awrite(CDR_CID_data[ 1345: 1352], 16#9957f020, 16#c28f22ce, 16#a7d0e24d, 16#adec6977, 16#32afe041, 16#851e459d, 16#4fa1c49b, 16#5bd8d2ee)
    awrite(CDR_CID_data[ 1353: 1360], 16#655fc083, 16#0a3c8b3a, 16#9f438936, 16#b7b1a5dc, 16#cabf8106, 16#14791675, 16#3e87126d, 16#6f634bb9)
    awrite(CDR_CID_data[ 1361: 1368], 16#957f020c, 16#28f22cea, 16#7d0e24da, 16#dec69773, 16#2afe0418, 16#51e459d4, 16#fa1c49b5, 16#bd8d2ee6)
    awrite(CDR_CID_data[ 1369: 1376], 16#55fc0830, 16#a3c8b3a9, 16#f438936b, 16#7b1a5dcc, 16#abf81061, 16#47916753, 16#e87126d6, 16#f634bb99)
    awrite(CDR_CID_data[ 1377: 1384], 16#57f020c2, 16#8f22cea7, 16#d0e24dad, 16#ec697732, 16#afe04185, 16#1e459d4f, 16#a1c49b5b, 16#d8d2ee65)
    awrite(CDR_CID_data[ 1385: 1392], 16#5fc0830a, 16#3c8b3a9f, 16#438936b7, 16#b1a5dcca, 16#bf810614, 16#7916753e, 16#87126d6f, 16#634bb995)
    awrite(CDR_CID_data[ 1393: 1400], 16#7f020c28, 16#f22cea7d, 16#0e24dade, 16#c697732a, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#f01fbe7a)
    awrite(CDR_CID_data[ 1401: 1408], 16#e1ba62b0, 16#5e3b64a4, 16#272d119a, 16#a03f7cf5, 16#c374c560, 16#bc76c948, 16#4e5a2335, 16#407ef9eb)
    awrite(CDR_CID_data[ 1409: 1416], 16#86e98ac1, 16#78ed9290, 16#9cb4466a, 16#80fdf3d7, 16#0dd31582, 16#f1db2521, 16#39688cd5, 16#01fbe7ae)
    awrite(CDR_CID_data[ 1417: 1424], 16#1ba62b05, 16#e3b64a42, 16#72d119aa, 16#03f7cf5c, 16#374c560b, 16#c76c9484, 16#e5a23354, 16#07ef9eb8)
    awrite(CDR_CID_data[ 1425: 1432], 16#6e98ac17, 16#8ed92909, 16#cb4466a8, 16#0fdf3d70, 16#dd31582f, 16#1db25213, 16#9688cd50, 16#1fbe7ae1)
    awrite(CDR_CID_data[ 1433: 1440], 16#ba62b05e, 16#3b64a427, 16#2d119aa0, 16#3f7cf5c3, 16#74c560bc, 16#76c9484e, 16#5a233540, 16#7ef9eb86)
    awrite(CDR_CID_data[ 1441: 1448], 16#e98ac178, 16#ed92909c, 16#b4466a80, 16#fdf3d70d, 16#d31582f1, 16#db252139, 16#688cd501, 16#fbe7ae1b)
    awrite(CDR_CID_data[ 1449: 1456], 16#a62b05e3, 16#b64a4272, 16#d119aa03, 16#f7cf5c37, 16#4c560bc7, 16#6c9484e5, 16#a2335407, 16#ef9eb86e)
    awrite(CDR_CID_data[ 1457: 1464], 16#98ac178e, 16#d92909cb, 16#4466a80f, 16#df3d70dd, 16#31582f1d, 16#b2521396, 16#88cd5000, 16#00000000)
    awrite(CDR_CID_data[ 1465: 1472], 16#00000000, 16#000000fe, 16#041851e4, 16#59d4fa1c, 16#49b5bd8d, 16#2ee655fc, 16#0830a3c8, 16#b3a9f438)
    awrite(CDR_CID_data[ 1473: 1480], 16#936b7b1a, 16#5dccabf8, 16#10614791, 16#6753e871, 16#26d6f634, 16#bb9957f0, 16#20c28f22, 16#cea7d0e2)
    awrite(CDR_CID_data[ 1481: 1488], 16#4dadec69, 16#7732afe0, 16#41851e45, 16#9d4fa1c4, 16#9b5bd8d2, 16#ee655fc0, 16#830a3c8b, 16#3a9f4389)
    awrite(CDR_CID_data[ 1489: 1496], 16#36b7b1a5, 16#dccabf81, 16#06147916, 16#753e8712, 16#6d6f634b, 16#b9957f02, 16#0c28f22c, 16#ea7d0e24)
    awrite(CDR_CID_data[ 1497: 1504], 16#dadec697, 16#732afe04, 16#1851e459, 16#d4fa1c49, 16#b5bd8d2e, 16#e655fc08, 16#30a3c8b3, 16#a9f43893)
    awrite(CDR_CID_data[ 1505: 1512], 16#6b7b1a5d, 16#ccabf810, 16#61479167, 16#53e87126, 16#d6f634bb, 16#9957f020, 16#c28f22ce, 16#a7d0e24d)
    awrite(CDR_CID_data[ 1513: 1520], 16#adec6977, 16#32afe041, 16#851e459d, 16#4fa1c49b, 16#5bd8d2ee, 16#655fc083, 16#0a3c8b3a, 16#9f438936)
    awrite(CDR_CID_data[ 1521: 1528], 16#b7b1a5dc, 16#cabf8106, 16#14791675, 16#3e87126d, 16#6f634bb9, 16#957f020c, 16#28f22cea, 16#7d0e24da)
    awrite(CDR_CID_data[ 1529: 1536], 16#dec69773, 16#2affffff, 16#ffffffff, 16#ffffffff, 16#fff01fbe, 16#7ae1ba62, 16#b05e3b64, 16#a4272d11)
    awrite(CDR_CID_data[ 1537: 1544], 16#9aa03f7c, 16#f5c374c5, 16#60bc76c9, 16#484e5a23, 16#35407ef9, 16#eb86e98a, 16#c178ed92, 16#909cb446)
    awrite(CDR_CID_data[ 1545: 1552], 16#6a80fdf3, 16#d70dd315, 16#82f1db25, 16#2139688c, 16#d501fbe7, 16#ae1ba62b, 16#05e3b64a, 16#4272d119)
    awrite(CDR_CID_data[ 1553: 1560], 16#aa03f7cf, 16#5c374c56, 16#0bc76c94, 16#84e5a233, 16#5407ef9e, 16#b86e98ac, 16#178ed929, 16#09cb4466)
    awrite(CDR_CID_data[ 1561: 1568], 16#a80fdf3d, 16#70dd3158, 16#2f1db252, 16#139688cd, 16#501fbe7a, 16#e1ba62b0, 16#5e3b64a4, 16#272d119a)
    awrite(CDR_CID_data[ 1569: 1576], 16#a03f7cf5, 16#c374c560, 16#bc76c948, 16#4e5a2335, 16#407ef9eb, 16#86e98ac1, 16#78ed9290, 16#9cb4466a)
    awrite(CDR_CID_data[ 1577: 1584], 16#80fdf3d7, 16#0dd31582, 16#f1db2521, 16#39688cd5, 16#01fbe7ae, 16#1ba62b05, 16#e3b64a42, 16#72d119aa)
    awrite(CDR_CID_data[ 1585: 1592], 16#03f7cf5c, 16#374c560b, 16#c76c9484, 16#e5a23354, 16#07ef9eb8, 16#6e98ac17, 16#8ed92909, 16#cb4466a8)
    awrite(CDR_CID_data[ 1593: 1600], 16#0fdf3d70, 16#dd31582f, 16#1db25213, 16#9688cd50, 16#00000000, 16#00000000, 16#00000000, 16#fe041851)
    awrite(CDR_CID_data[ 1601: 1608], 16#e459d4fa, 16#1c49b5bd, 16#8d2ee655, 16#fc0830a3, 16#c8b3a9f4, 16#38936b7b, 16#1a5dccab, 16#f8106147)
    awrite(CDR_CID_data[ 1609: 1616], 16#916753e8, 16#7126d6f6, 16#34bb9957, 16#f020c28f, 16#22cea7d0, 16#e24dadec, 16#697732af, 16#e041851e)
    awrite(CDR_CID_data[ 1617: 1624], 16#459d4fa1, 16#c49b5bd8, 16#d2ee655f, 16#c0830a3c, 16#8b3a9f43, 16#8936b7b1, 16#a5dccabf, 16#81061479)
    awrite(CDR_CID_data[ 1625: 1632], 16#16753e87, 16#126d6f63, 16#4bb9957f, 16#020c28f2, 16#2cea7d0e, 16#24dadec6, 16#97732afe, 16#041851e4)
    awrite(CDR_CID_data[ 1633: 1640], 16#59d4fa1c, 16#49b5bd8d, 16#2ee655fc, 16#0830a3c8, 16#b3a9f438, 16#936b7b1a, 16#5dccabf8, 16#10614791)
    awrite(CDR_CID_data[ 1641: 1648], 16#6753e871, 16#26d6f634, 16#bb9957f0, 16#20c28f22, 16#cea7d0e2, 16#4dadec69, 16#7732afe0, 16#41851e45)
    awrite(CDR_CID_data[ 1649: 1656], 16#9d4fa1c4, 16#9b5bd8d2, 16#ee655fc0, 16#830a3c8b, 16#3a9f4389, 16#36b7b1a5, 16#dccabf81, 16#06147916)
    awrite(CDR_CID_data[ 1657: 1664], 16#753e8712, 16#6d6f634b, 16#b9957f02, 16#0c28f22c, 16#ea7d0e24, 16#dadec697, 16#732affff, 16#ffffffff)
    awrite(CDR_CID_data[ 1665: 1672], 16#ffffffff, 16#fffff01f, 16#be7ae1ba, 16#62b05e3b, 16#64a4272d, 16#119aa03f, 16#7cf5c374, 16#c560bc76)
    awrite(CDR_CID_data[ 1673: 1680], 16#c9484e5a, 16#2335407e, 16#f9eb86e9, 16#8ac178ed, 16#92909cb4, 16#466a80fd, 16#f3d70dd3, 16#1582f1db)
    awrite(CDR_CID_data[ 1681: 1688], 16#25213968, 16#8cd501fb, 16#e7ae1ba6, 16#2b05e3b6, 16#4a4272d1, 16#19aa03f7, 16#cf5c374c, 16#560bc76c)
    awrite(CDR_CID_data[ 1689: 1696], 16#9484e5a2, 16#335407ef, 16#9eb86e98, 16#ac178ed9, 16#2909cb44, 16#66a80fdf, 16#3d70dd31, 16#582f1db2)
    awrite(CDR_CID_data[ 1697: 1704], 16#52139688, 16#cd501fbe, 16#7ae1ba62, 16#b05e3b64, 16#a4272d11, 16#9aa03f7c, 16#f5c374c5, 16#60bc76c9)
    awrite(CDR_CID_data[ 1705: 1712], 16#484e5a23, 16#35407ef9, 16#eb86e98a, 16#c178ed92, 16#909cb446, 16#6a80fdf3, 16#d70dd315, 16#82f1db25)
    awrite(CDR_CID_data[ 1713: 1720], 16#2139688c, 16#d501fbe7, 16#ae1ba62b, 16#05e3b64a, 16#4272d119, 16#aa03f7cf, 16#5c374c56, 16#0bc76c94)
    awrite(CDR_CID_data[ 1721: 1728], 16#84e5a233, 16#5407ef9e, 16#b86e98ac, 16#178ed929, 16#09cb4466, 16#a80fdf3d, 16#70dd3158, 16#2f1db252)
    awrite(CDR_CID_data[ 1729: 1736], 16#139688cd, 16#50000000, 16#00000000, 16#00000000, 16#00fe0418, 16#51e459d4, 16#fa1c49b5, 16#bd8d2ee6)
    awrite(CDR_CID_data[ 1737: 1744], 16#55fc0830, 16#a3c8b3a9, 16#f438936b, 16#7b1a5dcc, 16#abf81061, 16#47916753, 16#e87126d6, 16#f634bb99)
    awrite(CDR_CID_data[ 1745: 1752], 16#57f020c2, 16#8f22cea7, 16#d0e24dad, 16#ec697732, 16#afe04185, 16#1e459d4f, 16#a1c49b5b, 16#d8d2ee65)
    awrite(CDR_CID_data[ 1753: 1760], 16#5fc0830a, 16#3c8b3a9f, 16#438936b7, 16#b1a5dcca, 16#bf810614, 16#7916753e, 16#87126d6f, 16#634bb995)
    awrite(CDR_CID_data[ 1761: 1768], 16#7f020c28, 16#f22cea7d, 16#0e24dade, 16#c697732a, 16#fe041851, 16#e459d4fa, 16#1c49b5bd, 16#8d2ee655)
    awrite(CDR_CID_data[ 1769: 1776], 16#fc0830a3, 16#c8b3a9f4, 16#38936b7b, 16#1a5dccab, 16#f8106147, 16#916753e8, 16#7126d6f6, 16#34bb9957)
    awrite(CDR_CID_data[ 1777: 1784], 16#f020c28f, 16#22cea7d0, 16#e24dadec, 16#697732af, 16#e041851e, 16#459d4fa1, 16#c49b5bd8, 16#d2ee655f)
    awrite(CDR_CID_data[ 1785: 1792], 16#c0830a3c, 16#8b3a9f43, 16#8936b7b1, 16#a5dccabf, 16#81061479, 16#16753e87, 16#126d6f63, 16#4bb9957f)
    awrite(CDR_CID_data[ 1793: 1800], 16#020c28f2, 16#2cea7d0e, 16#24dadec6, 16#97732aff, 16#ffffffff, 16#ffffffff, 16#fffffff0, 16#1fbe7ae1)
    awrite(CDR_CID_data[ 1801: 1808], 16#ba62b05e, 16#3b64a427, 16#2d119aa0, 16#3f7cf5c3, 16#74c560bc, 16#76c9484e, 16#5a233540, 16#7ef9eb86)
    awrite(CDR_CID_data[ 1809: 1816], 16#e98ac178, 16#ed92909c, 16#b4466a80, 16#fdf3d70d, 16#d31582f1, 16#db252139, 16#688cd501, 16#fbe7ae1b)
    awrite(CDR_CID_data[ 1817: 1824], 16#a62b05e3, 16#b64a4272, 16#d119aa03, 16#f7cf5c37, 16#4c560bc7, 16#6c9484e5, 16#a2335407, 16#ef9eb86e)
    awrite(CDR_CID_data[ 1825: 1832], 16#98ac178e, 16#d92909cb, 16#4466a80f, 16#df3d70dd, 16#31582f1d, 16#b2521396, 16#88cd501f, 16#be7ae1ba)
    awrite(CDR_CID_data[ 1833: 1840], 16#62b05e3b, 16#64a4272d, 16#119aa03f, 16#7cf5c374, 16#c560bc76, 16#c9484e5a, 16#2335407e, 16#f9eb86e9)
    awrite(CDR_CID_data[ 1841: 1848], 16#8ac178ed, 16#92909cb4, 16#466a80fd, 16#f3d70dd3, 16#1582f1db, 16#25213968, 16#8cd501fb, 16#e7ae1ba6)
    awrite(CDR_CID_data[ 1849: 1856], 16#2b05e3b6, 16#4a4272d1, 16#19aa03f7, 16#cf5c374c, 16#560bc76c, 16#9484e5a2, 16#335407ef, 16#9eb86e98)
    awrite(CDR_CID_data[ 1857: 1864], 16#ac178ed9, 16#2909cb44, 16#66a80fdf, 16#3d70dd31, 16#582f1db2, 16#52139688, 16#cd500000, 16#00000000)
    awrite(CDR_CID_data[ 1865: 1872], 16#00000000, 16#0000fe04, 16#1851e459, 16#d4fa1c49, 16#b5bd8d2e, 16#e655fc08, 16#30a3c8b3, 16#a9f43893)
    awrite(CDR_CID_data[ 1873: 1880], 16#6b7b1a5d, 16#ccabf810, 16#61479167, 16#53e87126, 16#d6f634bb, 16#9957f020, 16#c28f22ce, 16#a7d0e24d)
    awrite(CDR_CID_data[ 1881: 1888], 16#adec6977, 16#32afe041, 16#851e459d, 16#4fa1c49b, 16#5bd8d2ee, 16#655fc083, 16#0a3c8b3a, 16#9f438936)
    awrite(CDR_CID_data[ 1889: 1896], 16#b7b1a5dc, 16#cabf8106, 16#14791675, 16#3e87126d, 16#6f634bb9, 16#957f020c, 16#28f22cea, 16#7d0e24da)
    awrite(CDR_CID_data[ 1897: 1904], 16#dec69773, 16#2afe0418, 16#51e459d4, 16#fa1c49b5, 16#bd8d2ee6, 16#55fc0830, 16#a3c8b3a9, 16#f438936b)
    awrite(CDR_CID_data[ 1905: 1912], 16#7b1a5dcc, 16#abf81061, 16#47916753, 16#e87126d6, 16#f634bb99, 16#57f020c2, 16#8f22cea7, 16#d0e24dad)
    awrite(CDR_CID_data[ 1913: 1920], 16#ec697732, 16#afe04185, 16#1e459d4f, 16#a1c49b5b, 16#d8d2ee65, 16#5fc0830a, 16#3c8b3a9f, 16#438936b7)
    awrite(CDR_CID_data[ 1921: 1928], 16#b1a5dcca, 16#bf810614, 16#7916753e, 16#87126d6f, 16#634bb995, 16#7f020c28, 16#f22cea7d, 16#0e24dade)
    awrite(CDR_CID_data[ 1929: 1936], 16#c697732a, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#f01fbe7a, 16#e1ba62b0, 16#5e3b64a4, 16#272d119a)
    awrite(CDR_CID_data[ 1937: 1944], 16#a03f7cf5, 16#c374c560, 16#bc76c948, 16#4e5a2335, 16#407ef9eb, 16#86e98ac1, 16#78ed9290, 16#9cb4466a)
    awrite(CDR_CID_data[ 1945: 1952], 16#80fdf3d7, 16#0dd31582, 16#f1db2521, 16#39688cd5, 16#01fbe7ae, 16#1ba62b05, 16#e3b64a42, 16#72d119aa)
    awrite(CDR_CID_data[ 1953: 1960], 16#03f7cf5c, 16#374c560b, 16#c76c9484, 16#e5a23354, 16#07ef9eb8, 16#6e98ac17, 16#8ed92909, 16#cb4466a8)
    awrite(CDR_CID_data[ 1961: 1968], 16#0fdf3d70, 16#dd31582f, 16#1db25213, 16#9688cd50, 16#1fbe7ae1, 16#ba62b05e, 16#3b64a427, 16#2d119aa0)
    awrite(CDR_CID_data[ 1969: 1976], 16#3f7cf5c3, 16#74c560bc, 16#76c9484e, 16#5a233540, 16#7ef9eb86, 16#e98ac178, 16#ed92909c, 16#b4466a80)
    awrite(CDR_CID_data[ 1977: 1984], 16#fdf3d70d, 16#d31582f1, 16#db252139, 16#688cd501, 16#fbe7ae1b, 16#a62b05e3, 16#b64a4272, 16#d119aa03)
    awrite(CDR_CID_data[ 1985: 1992], 16#f7cf5c37, 16#4c560bc7, 16#6c9484e5, 16#a2335407, 16#ef9eb86e, 16#98ac178e, 16#d92909cb, 16#4466a80f)
    awrite(CDR_CID_data[ 1993: 2000], 16#df3d70dd, 16#31582f1d, 16#b2521396, 16#88cd5000, 16#00000000, 16#00000000, 16#000000fe, 16#041851e4)
    awrite(CDR_CID_data[ 2001: 2008], 16#59d4fa1c, 16#49b5bd8d, 16#2ee655fc, 16#0830a3c8, 16#b3a9f438, 16#936b7b1a, 16#5dccabf8, 16#10614791)
    awrite(CDR_CID_data[ 2009: 2016], 16#6753e871, 16#26d6f634, 16#bb9957f0, 16#20c28f22, 16#cea7d0e2, 16#4dadec69, 16#7732afe0, 16#41851e45)
    awrite(CDR_CID_data[ 2017: 2024], 16#9d4fa1c4, 16#9b5bd8d2, 16#ee655fc0, 16#830a3c8b, 16#3a9f4389, 16#36b7b1a5, 16#dccabf81, 16#06147916)
    awrite(CDR_CID_data[ 2025: 2032], 16#753e8712, 16#6d6f634b, 16#b9957f02, 16#0c28f22c, 16#ea7d0e24, 16#dadec697, 16#732afe04, 16#1851e459)
    awrite(CDR_CID_data[ 2033: 2040], 16#d4fa1c49, 16#b5bd8d2e, 16#e655fc08, 16#30a3c8b3, 16#a9f43893, 16#6b7b1a5d, 16#ccabf810, 16#61479167)
    awrite(CDR_CID_data[ 2041: 2048], 16#53e87126, 16#d6f634bb, 16#9957f020, 16#c28f22ce, 16#a7d0e24d, 16#adec6977, 16#32afe041, 16#851e459d)
    awrite(CDR_CID_data[ 2049: 2056], 16#4fa1c49b, 16#5bd8d2ee, 16#655fc083, 16#0a3c8b3a, 16#9f438936, 16#b7b1a5dc, 16#cabf8106, 16#14791675)
    awrite(CDR_CID_data[ 2057: 2064], 16#3e87126d, 16#6f634bb9, 16#957f020c, 16#28f22cea, 16#7d0e24da, 16#dec69773, 16#2affffff, 16#ffffffff)
    awrite(CDR_CID_data[ 2065: 2072], 16#ffffffff, 16#fff01fbe, 16#7ae1ba62, 16#b05e3b64, 16#a4272d11, 16#9aa03f7c, 16#f5c374c5, 16#60bc76c9)
    awrite(CDR_CID_data[ 2073: 2080], 16#484e5a23, 16#35407ef9, 16#eb86e98a, 16#c178ed92, 16#909cb446, 16#6a80fdf3, 16#d70dd315, 16#82f1db25)
    awrite(CDR_CID_data[ 2081: 2088], 16#2139688c, 16#d501fbe7, 16#ae1ba62b, 16#05e3b64a, 16#4272d119, 16#aa03f7cf, 16#5c374c56, 16#0bc76c94)
    awrite(CDR_CID_data[ 2089: 2096], 16#84e5a233, 16#5407ef9e, 16#b86e98ac, 16#178ed929, 16#09cb4466, 16#a80fdf3d, 16#70dd3158, 16#2f1db252)
    awrite(CDR_CID_data[ 2097: 2104], 16#139688cd, 16#501fbe7a, 16#e1ba62b0, 16#5e3b64a4, 16#272d119a, 16#a03f7cf5, 16#c374c560, 16#bc76c948)
    awrite(CDR_CID_data[ 2105: 2112], 16#4e5a2335, 16#407ef9eb, 16#86e98ac1, 16#78ed9290, 16#9cb4466a, 16#80fdf3d7, 16#0dd31582, 16#f1db2521)
    awrite(CDR_CID_data[ 2113: 2120], 16#39688cd5, 16#01fbe7ae, 16#1ba62b05, 16#e3b64a42, 16#72d119aa, 16#03f7cf5c, 16#374c560b, 16#c76c9484)
    awrite(CDR_CID_data[ 2121: 2128], 16#e5a23354, 16#07ef9eb8, 16#6e98ac17, 16#8ed92909, 16#cb4466a8, 16#0fdf3d70, 16#dd31582f, 16#1db25213)
    awrite(CDR_CID_data[ 2129: 2132], 16#9688cd50, 16#00000000, 16#00000000, 16#00000000)
    
    
    awrite(CDR_CID_by2_data[ 1: 8], 16#fffc0030, 16#03c03303, 16#fc3033c3, 16#f330ffcc, 16#03f030c3, 16#cf33cff3, 16#c0f30cfc, 16#fc3c3333)
    awrite(CDR_CID_by2_data[ 9: 16], 16#fff000c0, 16#0f00cc0f, 16#f0c0cf0f, 16#ccc3ff30, 16#0fc0c30f, 16#3ccf3fcf, 16#03cc33f3, 16#f0f0cccf)
    awrite(CDR_CID_by2_data[ 17: 24], 16#ffc00300, 16#3c03303f, 16#c3033c3f, 16#330ffcc0, 16#3f030c3c, 16#f33cff3c, 16#0f30cfcf, 16#c3c3333f)
    awrite(CDR_CID_by2_data[ 25: 32], 16#ff000c00, 16#f00cc0ff, 16#0c0cf0fc, 16#cc3ff300, 16#fc0c30f3, 16#ccf3fcf0, 16#3cc33f3f, 16#0f0cccff)
    awrite(CDR_CID_by2_data[ 33: 40], 16#fc003003, 16#c03303fc, 16#3033c3f3, 16#30ffcc03, 16#f030c3cf, 16#33cff3c0, 16#f30cfcfc, 16#3c3333ff)
    awrite(CDR_CID_by2_data[ 41: 48], 16#f000c00f, 16#00cc0ff0, 16#c0cf0fcc, 16#c3ff300f, 16#c0c30f3c, 16#cf3fcf03, 16#cc33f3f0, 16#f0cccfff)
    awrite(CDR_CID_by2_data[ 49: 56], 16#c003003c, 16#03303fc3, 16#033c3f33, 16#0ffcc03f, 16#030c3cf3, 16#3cff3c0f, 16#30cfcfc3, 16#c3333fff)
    awrite(CDR_CID_by2_data[ 57: 64], 16#000c00f0, 16#0cc0ff0c, 16#0cf0fccc, 16#3ff300fc, 16#0c30f3cc, 16#f3fcf03c, 16#c33f3f0f, 16#0cccfffc)
    awrite(CDR_CID_by2_data[ 65: 72], 16#003003c0, 16#3303fc30, 16#33c3f330, 16#ffcc03f0, 16#30c3cf33, 16#cff3c0f3, 16#0cfcfc3c, 16#3333fff0)
    awrite(CDR_CID_by2_data[ 73: 80], 16#00c00f00, 16#cc0ff0c0, 16#cf0fccc3, 16#ff300fc0, 16#c30f3ccf, 16#3fcf03cc, 16#33f3f0f0, 16#cccfffc0)
    awrite(CDR_CID_by2_data[ 81: 88], 16#03003c03, 16#303fc303, 16#3c3f330f, 16#fcc03f03, 16#0c3cf33c, 16#ff3c0f30, 16#cfcfc3c3, 16#333fff00)
    awrite(CDR_CID_by2_data[ 89: 96], 16#0c00f00c, 16#c0ff0c0c, 16#f0fccc3f, 16#f300fc0c, 16#30f3ccf3, 16#fcf03cc3, 16#3f3f0f0c, 16#ccfffc00)
    awrite(CDR_CID_by2_data[ 97: 104], 16#3003c033, 16#03fc3033, 16#c3f330ff, 16#cc03f030, 16#c3cf33cf, 16#f3c0f30c, 16#fcfc3c33, 16#33fff000)
    awrite(CDR_CID_by2_data[ 105: 112], 16#c00f00cc, 16#0ff0c0cf, 16#0fccc3ff, 16#300fc0c3, 16#0f3ccf3f, 16#cf03cc33, 16#f3f0f0cc, 16#cfffc003)
    awrite(CDR_CID_by2_data[ 113: 120], 16#003c0330, 16#3fc3033c, 16#3f330ffc, 16#c03f030c, 16#3cf33cff, 16#3c0f30cf, 16#cfc3c333, 16#3fff000c)
    awrite(CDR_CID_by2_data[ 121: 128], 16#00f00cc0, 16#ff0c0cf0, 16#fccc3ff3, 16#00fc0c30, 16#f3ccf3fc, 16#f03cc33f, 16#3f0f0ccc, 16#ffffffff)
    awrite(CDR_CID_by2_data[ 129: 136], 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ff0003ff, 16#cffc3fcc, 16#fc03cfcc)
    awrite(CDR_CID_by2_data[ 137: 144], 16#3c0ccf00, 16#33fc0fcf, 16#3c30cc30, 16#0c3f0cf3, 16#0303c3cc, 16#cc000fff, 16#3ff0ff33, 16#f00f3f30)
    awrite(CDR_CID_by2_data[ 145: 152], 16#f0333c00, 16#cff03f3c, 16#f0c330c0, 16#30fc33cc, 16#0c0f0f33, 16#30003ffc, 16#ffc3fccf, 16#c03cfcc3)
    awrite(CDR_CID_by2_data[ 153: 160], 16#c0ccf003, 16#3fc0fcf3, 16#c30cc300, 16#c3f0cf30, 16#303c3ccc, 16#c000fff3, 16#ff0ff33f, 16#00f3f30f)
    awrite(CDR_CID_by2_data[ 161: 168], 16#0333c00c, 16#ff03f3cf, 16#0c330c03, 16#0fc33cc0, 16#c0f0f333, 16#0003ffcf, 16#fc3fccfc, 16#03cfcc3c)
    awrite(CDR_CID_by2_data[ 169: 176], 16#0ccf0033, 16#fc0fcf3c, 16#30cc300c, 16#3f0cf303, 16#03c3cccc, 16#000fff3f, 16#f0ff33f0, 16#0f3f30f0)
    awrite(CDR_CID_by2_data[ 177: 184], 16#333c00cf, 16#f03f3cf0, 16#c330c030, 16#fc33cc0c, 16#0f0f3330, 16#003ffcff, 16#c3fccfc0, 16#3cfcc3c0)
    awrite(CDR_CID_by2_data[ 185: 192], 16#ccf0033f, 16#c0fcf3c3, 16#0cc300c3, 16#f0cf3030, 16#3c3cccc0, 16#00fff3ff, 16#0ff33f00, 16#f3f30f03)
    awrite(CDR_CID_by2_data[ 193: 200], 16#33c00cff, 16#03f3cf0c, 16#330c030f, 16#c33cc0c0, 16#f0f33300, 16#03ffcffc, 16#3fccfc03, 16#cfcc3c0c)
    awrite(CDR_CID_by2_data[ 201: 208], 16#cf0033fc, 16#0fcf3c30, 16#cc300c3f, 16#0cf30303, 16#c3cccc00, 16#0fff3ff0, 16#ff33f00f, 16#3f30f033)
    awrite(CDR_CID_by2_data[ 209: 216], 16#3c00cff0, 16#3f3cf0c3, 16#30c030fc, 16#33cc0c0f, 16#0f333000, 16#3ffcffc3, 16#fccfc03c, 16#fcc3c0cc)
    awrite(CDR_CID_by2_data[ 217: 224], 16#f0033fc0, 16#fcf3c30c, 16#c300c3f0, 16#cf30303c, 16#3cccc000, 16#fff3ff0f, 16#f33f00f3, 16#f30f0333)
    awrite(CDR_CID_by2_data[ 225: 232], 16#c00cff03, 16#f3cf0c33, 16#0c030fc3, 16#3cc0c0f0, 16#f3330003, 16#ffcffc3f, 16#ccfc03cf, 16#cc3c0ccf)
    awrite(CDR_CID_by2_data[ 233: 240], 16#0033fc0f, 16#cf3c30cc, 16#300c3f0c, 16#f30303c3, 16#cccc000f, 16#ff3ff0ff, 16#33f00f3f, 16#30f0333c)
    awrite(CDR_CID_by2_data[ 241: 248], 16#00cff03f, 16#3cf0c330, 16#c030fc33, 16#cc0c0f0f, 16#3330003f, 16#fcffc3fc, 16#cfc03cfc, 16#c3c0ccf0)
    awrite(CDR_CID_by2_data[ 249: 256], 16#033fc0fc, 16#f3c30cc3, 16#00c3f0cf, 16#30303c3c, 16#ccc000ff, 16#f3ff0ff3, 16#3f00f3f3, 16#0f0333c0)
    awrite(CDR_CID_by2_data[ 257: 264], 16#0cff03f3, 16#cf0c330c, 16#030fc33c, 16#c0c0f0f3, 16#33000000, 16#00000000, 16#00000000, 16#00000000)
    awrite(CDR_CID_by2_data[ 265: 272], 16#00000000, 16#00000000, 16#0000fffc, 16#003003c0, 16#3303fc30, 16#33c3f330, 16#ffcc03f0, 16#30c3cf33)
    awrite(CDR_CID_by2_data[ 273: 280], 16#cff3c0f3, 16#0cfcfc3c, 16#3333fff0, 16#00c00f00, 16#cc0ff0c0, 16#cf0fccc3, 16#ff300fc0, 16#c30f3ccf)
    awrite(CDR_CID_by2_data[ 281: 288], 16#3fcf03cc, 16#33f3f0f0, 16#cccfffc0, 16#03003c03, 16#303fc303, 16#3c3f330f, 16#fcc03f03, 16#0c3cf33c)
    awrite(CDR_CID_by2_data[ 289: 296], 16#ff3c0f30, 16#cfcfc3c3, 16#333fff00, 16#0c00f00c, 16#c0ff0c0c, 16#f0fccc3f, 16#f300fc0c, 16#30f3ccf3)
    awrite(CDR_CID_by2_data[ 297: 304], 16#fcf03cc3, 16#3f3f0f0c, 16#ccfffc00, 16#3003c033, 16#03fc3033, 16#c3f330ff, 16#cc03f030, 16#c3cf33cf)
    awrite(CDR_CID_by2_data[ 305: 312], 16#f3c0f30c, 16#fcfc3c33, 16#33fff000, 16#c00f00cc, 16#0ff0c0cf, 16#0fccc3ff, 16#300fc0c3, 16#0f3ccf3f)
    awrite(CDR_CID_by2_data[ 313: 320], 16#cf03cc33, 16#f3f0f0cc, 16#cfffc003, 16#003c0330, 16#3fc3033c, 16#3f330ffc, 16#c03f030c, 16#3cf33cff)
    awrite(CDR_CID_by2_data[ 321: 328], 16#3c0f30cf, 16#cfc3c333, 16#3fff000c, 16#00f00cc0, 16#ff0c0cf0, 16#fccc3ff3, 16#00fc0c30, 16#f3ccf3fc)
    awrite(CDR_CID_by2_data[ 329: 336], 16#f03cc33f, 16#3f0f0ccc, 16#fffc0030, 16#03c03303, 16#fc3033c3, 16#f330ffcc, 16#03f030c3, 16#cf33cff3)
    awrite(CDR_CID_by2_data[ 337: 344], 16#c0f30cfc, 16#fc3c3333, 16#fff000c0, 16#0f00cc0f, 16#f0c0cf0f, 16#ccc3ff30, 16#0fc0c30f, 16#3ccf3fcf)
    awrite(CDR_CID_by2_data[ 345: 352], 16#03cc33f3, 16#f0f0cccf, 16#ffc00300, 16#3c03303f, 16#c3033c3f, 16#330ffcc0, 16#3f030c3c, 16#f33cff3c)
    awrite(CDR_CID_by2_data[ 353: 360], 16#0f30cfcf, 16#c3c3333f, 16#ff000c00, 16#f00cc0ff, 16#0c0cf0fc, 16#cc3ff300, 16#fc0c30f3, 16#ccf3fcf0)
    awrite(CDR_CID_by2_data[ 361: 368], 16#3cc33f3f, 16#0f0cccff, 16#fc003003, 16#c03303fc, 16#3033c3f3, 16#30ffcc03, 16#f030c3cf, 16#33cff3c0)
    awrite(CDR_CID_by2_data[ 369: 376], 16#f30cfcfc, 16#3c3333ff, 16#f000c00f, 16#00cc0ff0, 16#c0cf0fcc, 16#c3ff300f, 16#c0c30f3c, 16#cf3fcf03)
    awrite(CDR_CID_by2_data[ 377: 384], 16#cc33f3f0, 16#f0cccfff, 16#c003003c, 16#03303fc3, 16#033c3f33, 16#0ffcc03f, 16#030c3cf3, 16#3cff3c0f)
    awrite(CDR_CID_by2_data[ 385: 392], 16#30cfcfc3, 16#c3333fff, 16#000c00f0, 16#0cc0ff0c, 16#0cf0fccc, 16#3ff300fc, 16#0c30f3cc, 16#f3fcf03c)
    awrite(CDR_CID_by2_data[ 393: 400], 16#c33f3f0f, 16#0cccffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffff00)
    awrite(CDR_CID_by2_data[ 401: 408], 16#03ffcffc, 16#3fccfc03, 16#cfcc3c0c, 16#cf0033fc, 16#0fcf3c30, 16#cc300c3f, 16#0cf30303, 16#c3cccc00)
    awrite(CDR_CID_by2_data[ 409: 416], 16#0fff3ff0, 16#ff33f00f, 16#3f30f033, 16#3c00cff0, 16#3f3cf0c3, 16#30c030fc, 16#33cc0c0f, 16#0f333000)
    awrite(CDR_CID_by2_data[ 417: 424], 16#3ffcffc3, 16#fccfc03c, 16#fcc3c0cc, 16#f0033fc0, 16#fcf3c30c, 16#c300c3f0, 16#cf30303c, 16#3cccc000)
    awrite(CDR_CID_by2_data[ 425: 432], 16#fff3ff0f, 16#f33f00f3, 16#f30f0333, 16#c00cff03, 16#f3cf0c33, 16#0c030fc3, 16#3cc0c0f0, 16#f3330003)
    awrite(CDR_CID_by2_data[ 433: 440], 16#ffcffc3f, 16#ccfc03cf, 16#cc3c0ccf, 16#0033fc0f, 16#cf3c30cc, 16#300c3f0c, 16#f30303c3, 16#cccc000f)
    awrite(CDR_CID_by2_data[ 441: 448], 16#ff3ff0ff, 16#33f00f3f, 16#30f0333c, 16#00cff03f, 16#3cf0c330, 16#c030fc33, 16#cc0c0f0f, 16#3330003f)
    awrite(CDR_CID_by2_data[ 449: 456], 16#fcffc3fc, 16#cfc03cfc, 16#c3c0ccf0, 16#033fc0fc, 16#f3c30cc3, 16#00c3f0cf, 16#30303c3c, 16#ccc000ff)
    awrite(CDR_CID_by2_data[ 457: 464], 16#f3ff0ff3, 16#3f00f3f3, 16#0f0333c0, 16#0cff03f3, 16#cf0c330c, 16#030fc33c, 16#c0c0f0f3, 16#330003ff)
    awrite(CDR_CID_by2_data[ 465: 472], 16#cffc3fcc, 16#fc03cfcc, 16#3c0ccf00, 16#33fc0fcf, 16#3c30cc30, 16#0c3f0cf3, 16#0303c3cc, 16#cc000fff)
    awrite(CDR_CID_by2_data[ 473: 480], 16#3ff0ff33, 16#f00f3f30, 16#f0333c00, 16#cff03f3c, 16#f0c330c0, 16#30fc33cc, 16#0c0f0f33, 16#30003ffc)
    awrite(CDR_CID_by2_data[ 481: 488], 16#ffc3fccf, 16#c03cfcc3, 16#c0ccf003, 16#3fc0fcf3, 16#c30cc300, 16#c3f0cf30, 16#303c3ccc, 16#c000fff3)
    awrite(CDR_CID_by2_data[ 489: 496], 16#ff0ff33f, 16#00f3f30f, 16#0333c00c, 16#ff03f3cf, 16#0c330c03, 16#0fc33cc0, 16#c0f0f333, 16#0003ffcf)
    awrite(CDR_CID_by2_data[ 497: 504], 16#fc3fccfc, 16#03cfcc3c, 16#0ccf0033, 16#fc0fcf3c, 16#30cc300c, 16#3f0cf303, 16#03c3cccc, 16#000fff3f)
    awrite(CDR_CID_by2_data[ 505: 512], 16#f0ff33f0, 16#0f3f30f0, 16#333c00cf, 16#f03f3cf0, 16#c330c030, 16#fc33cc0c, 16#0f0f3330, 16#003ffcff)
    awrite(CDR_CID_by2_data[ 513: 520], 16#c3fccfc0, 16#3cfcc3c0, 16#ccf0033f, 16#c0fcf3c3, 16#0cc300c3, 16#f0cf3030, 16#3c3cccc0, 16#00fff3ff)
    awrite(CDR_CID_by2_data[ 521: 528], 16#0ff33f00, 16#f3f30f03, 16#33c00cff, 16#03f3cf0c, 16#330c030f, 16#c33cc0c0, 16#f0f33300, 16#00000000)
    awrite(CDR_CID_by2_data[ 529: 536], 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#fffc0030, 16#03c03303, 16#fc3033c3)
    awrite(CDR_CID_by2_data[ 537: 544], 16#f330ffcc, 16#03f030c3, 16#cf33cff3, 16#c0f30cfc, 16#fc3c3333, 16#fff000c0, 16#0f00cc0f, 16#f0c0cf0f)
    awrite(CDR_CID_by2_data[ 545: 552], 16#ccc3ff30, 16#0fc0c30f, 16#3ccf3fcf, 16#03cc33f3, 16#f0f0cccf, 16#ffc00300, 16#3c03303f, 16#c3033c3f)
    awrite(CDR_CID_by2_data[ 553: 560], 16#330ffcc0, 16#3f030c3c, 16#f33cff3c, 16#0f30cfcf, 16#c3c3333f, 16#ff000c00, 16#f00cc0ff, 16#0c0cf0fc)
    awrite(CDR_CID_by2_data[ 561: 568], 16#cc3ff300, 16#fc0c30f3, 16#ccf3fcf0, 16#3cc33f3f, 16#0f0cccff, 16#fc003003, 16#c03303fc, 16#3033c3f3)
    awrite(CDR_CID_by2_data[ 569: 576], 16#30ffcc03, 16#f030c3cf, 16#33cff3c0, 16#f30cfcfc, 16#3c3333ff, 16#f000c00f, 16#00cc0ff0, 16#c0cf0fcc)
    awrite(CDR_CID_by2_data[ 577: 584], 16#c3ff300f, 16#c0c30f3c, 16#cf3fcf03, 16#cc33f3f0, 16#f0cccfff, 16#c003003c, 16#03303fc3, 16#033c3f33)
    awrite(CDR_CID_by2_data[ 585: 592], 16#0ffcc03f, 16#030c3cf3, 16#3cff3c0f, 16#30cfcfc3, 16#c3333fff, 16#000c00f0, 16#0cc0ff0c, 16#0cf0fccc)
    awrite(CDR_CID_by2_data[ 593: 600], 16#3ff300fc, 16#0c30f3cc, 16#f3fcf03c, 16#c33f3f0f, 16#0cccfffc, 16#003003c0, 16#3303fc30, 16#33c3f330)
    awrite(CDR_CID_by2_data[ 601: 608], 16#ffcc03f0, 16#30c3cf33, 16#cff3c0f3, 16#0cfcfc3c, 16#3333fff0, 16#00c00f00, 16#cc0ff0c0, 16#cf0fccc3)
    awrite(CDR_CID_by2_data[ 609: 616], 16#ff300fc0, 16#c30f3ccf, 16#3fcf03cc, 16#33f3f0f0, 16#cccfffc0, 16#03003c03, 16#303fc303, 16#3c3f330f)
    awrite(CDR_CID_by2_data[ 617: 624], 16#fcc03f03, 16#0c3cf33c, 16#ff3c0f30, 16#cfcfc3c3, 16#333fff00, 16#0c00f00c, 16#c0ff0c0c, 16#f0fccc3f)
    awrite(CDR_CID_by2_data[ 625: 632], 16#f300fc0c, 16#30f3ccf3, 16#fcf03cc3, 16#3f3f0f0c, 16#ccfffc00, 16#3003c033, 16#03fc3033, 16#c3f330ff)
    awrite(CDR_CID_by2_data[ 633: 640], 16#cc03f030, 16#c3cf33cf, 16#f3c0f30c, 16#fcfc3c33, 16#33fff000, 16#c00f00cc, 16#0ff0c0cf, 16#0fccc3ff)
    awrite(CDR_CID_by2_data[ 641: 648], 16#300fc0c3, 16#0f3ccf3f, 16#cf03cc33, 16#f3f0f0cc, 16#cfffc003, 16#003c0330, 16#3fc3033c, 16#3f330ffc)
    awrite(CDR_CID_by2_data[ 649: 656], 16#c03f030c, 16#3cf33cff, 16#3c0f30cf, 16#cfc3c333, 16#3fff000c, 16#00f00cc0, 16#ff0c0cf0, 16#fccc3ff3)
    awrite(CDR_CID_by2_data[ 657: 664], 16#00fc0c30, 16#f3ccf3fc, 16#f03cc33f, 16#3f0f0ccc, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff)
    awrite(CDR_CID_by2_data[ 665: 672], 16#ffffffff, 16#ffffffff, 16#ff0003ff, 16#cffc3fcc, 16#fc03cfcc, 16#3c0ccf00, 16#33fc0fcf, 16#3c30cc30)
    awrite(CDR_CID_by2_data[ 673: 680], 16#0c3f0cf3, 16#0303c3cc, 16#cc000fff, 16#3ff0ff33, 16#f00f3f30, 16#f0333c00, 16#cff03f3c, 16#f0c330c0)
    awrite(CDR_CID_by2_data[ 681: 688], 16#30fc33cc, 16#0c0f0f33, 16#30003ffc, 16#ffc3fccf, 16#c03cfcc3, 16#c0ccf003, 16#3fc0fcf3, 16#c30cc300)
    awrite(CDR_CID_by2_data[ 689: 696], 16#c3f0cf30, 16#303c3ccc, 16#c000fff3, 16#ff0ff33f, 16#00f3f30f, 16#0333c00c, 16#ff03f3cf, 16#0c330c03)
    awrite(CDR_CID_by2_data[ 697: 704], 16#0fc33cc0, 16#c0f0f333, 16#0003ffcf, 16#fc3fccfc, 16#03cfcc3c, 16#0ccf0033, 16#fc0fcf3c, 16#30cc300c)
    awrite(CDR_CID_by2_data[ 705: 712], 16#3f0cf303, 16#03c3cccc, 16#000fff3f, 16#f0ff33f0, 16#0f3f30f0, 16#333c00cf, 16#f03f3cf0, 16#c330c030)
    awrite(CDR_CID_by2_data[ 713: 720], 16#fc33cc0c, 16#0f0f3330, 16#003ffcff, 16#c3fccfc0, 16#3cfcc3c0, 16#ccf0033f, 16#c0fcf3c3, 16#0cc300c3)
    awrite(CDR_CID_by2_data[ 721: 728], 16#f0cf3030, 16#3c3cccc0, 16#00fff3ff, 16#0ff33f00, 16#f3f30f03, 16#33c00cff, 16#03f3cf0c, 16#330c030f)
    awrite(CDR_CID_by2_data[ 729: 736], 16#c33cc0c0, 16#f0f33300, 16#03ffcffc, 16#3fccfc03, 16#cfcc3c0c, 16#cf0033fc, 16#0fcf3c30, 16#cc300c3f)
    awrite(CDR_CID_by2_data[ 737: 744], 16#0cf30303, 16#c3cccc00, 16#0fff3ff0, 16#ff33f00f, 16#3f30f033, 16#3c00cff0, 16#3f3cf0c3, 16#30c030fc)
    awrite(CDR_CID_by2_data[ 745: 752], 16#33cc0c0f, 16#0f333000, 16#3ffcffc3, 16#fccfc03c, 16#fcc3c0cc, 16#f0033fc0, 16#fcf3c30c, 16#c300c3f0)
    awrite(CDR_CID_by2_data[ 753: 760], 16#cf30303c, 16#3cccc000, 16#fff3ff0f, 16#f33f00f3, 16#f30f0333, 16#c00cff03, 16#f3cf0c33, 16#0c030fc3)
    awrite(CDR_CID_by2_data[ 761: 768], 16#3cc0c0f0, 16#f3330003, 16#ffcffc3f, 16#ccfc03cf, 16#cc3c0ccf, 16#0033fc0f, 16#cf3c30cc, 16#300c3f0c)
    awrite(CDR_CID_by2_data[ 769: 776], 16#f30303c3, 16#cccc000f, 16#ff3ff0ff, 16#33f00f3f, 16#30f0333c, 16#00cff03f, 16#3cf0c330, 16#c030fc33)
    awrite(CDR_CID_by2_data[ 777: 784], 16#cc0c0f0f, 16#3330003f, 16#fcffc3fc, 16#cfc03cfc, 16#c3c0ccf0, 16#033fc0fc, 16#f3c30cc3, 16#00c3f0cf)
    awrite(CDR_CID_by2_data[ 785: 792], 16#30303c3c, 16#ccc000ff, 16#f3ff0ff3, 16#3f00f3f3, 16#0f0333c0, 16#0cff03f3, 16#cf0c330c, 16#030fc33c)
    awrite(CDR_CID_by2_data[ 793: 800], 16#c0c0f0f3, 16#33000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#0000fffc)
    awrite(CDR_CID_by2_data[ 801: 808], 16#003003c0, 16#3303fc30, 16#33c3f330, 16#ffcc03f0, 16#30c3cf33, 16#cff3c0f3, 16#0cfcfc3c, 16#3333fff0)
    awrite(CDR_CID_by2_data[ 809: 816], 16#00c00f00, 16#cc0ff0c0, 16#cf0fccc3, 16#ff300fc0, 16#c30f3ccf, 16#3fcf03cc, 16#33f3f0f0, 16#cccfffc0)
    awrite(CDR_CID_by2_data[ 817: 824], 16#03003c03, 16#303fc303, 16#3c3f330f, 16#fcc03f03, 16#0c3cf33c, 16#ff3c0f30, 16#cfcfc3c3, 16#333fff00)
    awrite(CDR_CID_by2_data[ 825: 832], 16#0c00f00c, 16#c0ff0c0c, 16#f0fccc3f, 16#f300fc0c, 16#30f3ccf3, 16#fcf03cc3, 16#3f3f0f0c, 16#ccfffc00)
    awrite(CDR_CID_by2_data[ 833: 840], 16#3003c033, 16#03fc3033, 16#c3f330ff, 16#cc03f030, 16#c3cf33cf, 16#f3c0f30c, 16#fcfc3c33, 16#33fff000)
    awrite(CDR_CID_by2_data[ 841: 848], 16#c00f00cc, 16#0ff0c0cf, 16#0fccc3ff, 16#300fc0c3, 16#0f3ccf3f, 16#cf03cc33, 16#f3f0f0cc, 16#cfffc003)
    awrite(CDR_CID_by2_data[ 849: 856], 16#003c0330, 16#3fc3033c, 16#3f330ffc, 16#c03f030c, 16#3cf33cff, 16#3c0f30cf, 16#cfc3c333, 16#3fff000c)
    awrite(CDR_CID_by2_data[ 857: 864], 16#00f00cc0, 16#ff0c0cf0, 16#fccc3ff3, 16#00fc0c30, 16#f3ccf3fc, 16#f03cc33f, 16#3f0f0ccc, 16#fffc0030)
    awrite(CDR_CID_by2_data[ 865: 872], 16#03c03303, 16#fc3033c3, 16#f330ffcc, 16#03f030c3, 16#cf33cff3, 16#c0f30cfc, 16#fc3c3333, 16#fff000c0)
    awrite(CDR_CID_by2_data[ 873: 880], 16#0f00cc0f, 16#f0c0cf0f, 16#ccc3ff30, 16#0fc0c30f, 16#3ccf3fcf, 16#03cc33f3, 16#f0f0cccf, 16#ffc00300)
    awrite(CDR_CID_by2_data[ 881: 888], 16#3c03303f, 16#c3033c3f, 16#330ffcc0, 16#3f030c3c, 16#f33cff3c, 16#0f30cfcf, 16#c3c3333f, 16#ff000c00)
    awrite(CDR_CID_by2_data[ 889: 896], 16#f00cc0ff, 16#0c0cf0fc, 16#cc3ff300, 16#fc0c30f3, 16#ccf3fcf0, 16#3cc33f3f, 16#0f0cccff, 16#fc003003)
    awrite(CDR_CID_by2_data[ 897: 904], 16#c03303fc, 16#3033c3f3, 16#30ffcc03, 16#f030c3cf, 16#33cff3c0, 16#f30cfcfc, 16#3c3333ff, 16#f000c00f)
    awrite(CDR_CID_by2_data[ 905: 912], 16#00cc0ff0, 16#c0cf0fcc, 16#c3ff300f, 16#c0c30f3c, 16#cf3fcf03, 16#cc33f3f0, 16#f0cccfff, 16#c003003c)
    awrite(CDR_CID_by2_data[ 913: 920], 16#03303fc3, 16#033c3f33, 16#0ffcc03f, 16#030c3cf3, 16#3cff3c0f, 16#30cfcfc3, 16#c3333fff, 16#000c00f0)
    awrite(CDR_CID_by2_data[ 921: 928], 16#0cc0ff0c, 16#0cf0fccc, 16#3ff300fc, 16#0c30f3cc, 16#f3fcf03c, 16#c33f3f0f, 16#0cccffff, 16#ffffffff)
    awrite(CDR_CID_by2_data[ 929: 936], 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffff00, 16#03ffcffc, 16#3fccfc03, 16#cfcc3c0c)
    awrite(CDR_CID_by2_data[ 937: 944], 16#cf0033fc, 16#0fcf3c30, 16#cc300c3f, 16#0cf30303, 16#c3cccc00, 16#0fff3ff0, 16#ff33f00f, 16#3f30f033)
    awrite(CDR_CID_by2_data[ 945: 952], 16#3c00cff0, 16#3f3cf0c3, 16#30c030fc, 16#33cc0c0f, 16#0f333000, 16#3ffcffc3, 16#fccfc03c, 16#fcc3c0cc)
    awrite(CDR_CID_by2_data[ 953: 960], 16#f0033fc0, 16#fcf3c30c, 16#c300c3f0, 16#cf30303c, 16#3cccc000, 16#fff3ff0f, 16#f33f00f3, 16#f30f0333)
    awrite(CDR_CID_by2_data[ 961: 968], 16#c00cff03, 16#f3cf0c33, 16#0c030fc3, 16#3cc0c0f0, 16#f3330003, 16#ffcffc3f, 16#ccfc03cf, 16#cc3c0ccf)
    awrite(CDR_CID_by2_data[ 969: 976], 16#0033fc0f, 16#cf3c30cc, 16#300c3f0c, 16#f30303c3, 16#cccc000f, 16#ff3ff0ff, 16#33f00f3f, 16#30f0333c)
    awrite(CDR_CID_by2_data[ 977: 984], 16#00cff03f, 16#3cf0c330, 16#c030fc33, 16#cc0c0f0f, 16#3330003f, 16#fcffc3fc, 16#cfc03cfc, 16#c3c0ccf0)
    awrite(CDR_CID_by2_data[ 985: 992], 16#033fc0fc, 16#f3c30cc3, 16#00c3f0cf, 16#30303c3c, 16#ccc000ff, 16#f3ff0ff3, 16#3f00f3f3, 16#0f0333c0)
    awrite(CDR_CID_by2_data[ 993: 1000], 16#0cff03f3, 16#cf0c330c, 16#030fc33c, 16#c0c0f0f3, 16#330003ff, 16#cffc3fcc, 16#fc03cfcc, 16#3c0ccf00)
    awrite(CDR_CID_by2_data[ 1001: 1008], 16#33fc0fcf, 16#3c30cc30, 16#0c3f0cf3, 16#0303c3cc, 16#cc000fff, 16#3ff0ff33, 16#f00f3f30, 16#f0333c00)
    awrite(CDR_CID_by2_data[ 1009: 1016], 16#cff03f3c, 16#f0c330c0, 16#30fc33cc, 16#0c0f0f33, 16#30003ffc, 16#ffc3fccf, 16#c03cfcc3, 16#c0ccf003)
    awrite(CDR_CID_by2_data[ 1017: 1024], 16#3fc0fcf3, 16#c30cc300, 16#c3f0cf30, 16#303c3ccc, 16#c000fff3, 16#ff0ff33f, 16#00f3f30f, 16#0333c00c)
    awrite(CDR_CID_by2_data[ 1025: 1032], 16#ff03f3cf, 16#0c330c03, 16#0fc33cc0, 16#c0f0f333, 16#0003ffcf, 16#fc3fccfc, 16#03cfcc3c, 16#0ccf0033)
    awrite(CDR_CID_by2_data[ 1033: 1040], 16#fc0fcf3c, 16#30cc300c, 16#3f0cf303, 16#03c3cccc, 16#000fff3f, 16#f0ff33f0, 16#0f3f30f0, 16#333c00cf)
    awrite(CDR_CID_by2_data[ 1041: 1048], 16#f03f3cf0, 16#c330c030, 16#fc33cc0c, 16#0f0f3330, 16#003ffcff, 16#c3fccfc0, 16#3cfcc3c0, 16#ccf0033f)
    awrite(CDR_CID_by2_data[ 1049: 1056], 16#c0fcf3c3, 16#0cc300c3, 16#f0cf3030, 16#3c3cccc0, 16#00fff3ff, 16#0ff33f00, 16#f3f30f03, 16#33c00cff)
    awrite(CDR_CID_by2_data[ 1057: 1064], 16#03f3cf0c, 16#330c030f, 16#c33cc0c0, 16#f0f33300, 16#00000000, 16#00000000, 16#00000000, 16#00000000)
    awrite(CDR_CID_by2_data[ 1065: 1072], 16#00000000, 16#00000000, 16#fffc0030, 16#03c03303, 16#fc3033c3, 16#f330ffcc, 16#03f030c3, 16#cf33cff3)
    awrite(CDR_CID_by2_data[ 1073: 1080], 16#c0f30cfc, 16#fc3c3333, 16#fff000c0, 16#0f00cc0f, 16#f0c0cf0f, 16#ccc3ff30, 16#0fc0c30f, 16#3ccf3fcf)
    awrite(CDR_CID_by2_data[ 1081: 1088], 16#03cc33f3, 16#f0f0cccf, 16#ffc00300, 16#3c03303f, 16#c3033c3f, 16#330ffcc0, 16#3f030c3c, 16#f33cff3c)
    awrite(CDR_CID_by2_data[ 1089: 1096], 16#0f30cfcf, 16#c3c3333f, 16#ff000c00, 16#f00cc0ff, 16#0c0cf0fc, 16#cc3ff300, 16#fc0c30f3, 16#ccf3fcf0)
    awrite(CDR_CID_by2_data[ 1097: 1104], 16#3cc33f3f, 16#0f0cccff, 16#fc003003, 16#c03303fc, 16#3033c3f3, 16#30ffcc03, 16#f030c3cf, 16#33cff3c0)
    awrite(CDR_CID_by2_data[ 1105: 1112], 16#f30cfcfc, 16#3c3333ff, 16#f000c00f, 16#00cc0ff0, 16#c0cf0fcc, 16#c3ff300f, 16#c0c30f3c, 16#cf3fcf03)
    awrite(CDR_CID_by2_data[ 1113: 1120], 16#cc33f3f0, 16#f0cccfff, 16#c003003c, 16#03303fc3, 16#033c3f33, 16#0ffcc03f, 16#030c3cf3, 16#3cff3c0f)
    awrite(CDR_CID_by2_data[ 1121: 1128], 16#30cfcfc3, 16#c3333fff, 16#000c00f0, 16#0cc0ff0c, 16#0cf0fccc, 16#3ff300fc, 16#0c30f3cc, 16#f3fcf03c)
    awrite(CDR_CID_by2_data[ 1129: 1136], 16#c33f3f0f, 16#0cccfffc, 16#003003c0, 16#3303fc30, 16#33c3f330, 16#ffcc03f0, 16#30c3cf33, 16#cff3c0f3)
    awrite(CDR_CID_by2_data[ 1137: 1144], 16#0cfcfc3c, 16#3333fff0, 16#00c00f00, 16#cc0ff0c0, 16#cf0fccc3, 16#ff300fc0, 16#c30f3ccf, 16#3fcf03cc)
    awrite(CDR_CID_by2_data[ 1145: 1152], 16#33f3f0f0, 16#cccfffc0, 16#03003c03, 16#303fc303, 16#3c3f330f, 16#fcc03f03, 16#0c3cf33c, 16#ff3c0f30)
    awrite(CDR_CID_by2_data[ 1153: 1160], 16#cfcfc3c3, 16#333fff00, 16#0c00f00c, 16#c0ff0c0c, 16#f0fccc3f, 16#f300fc0c, 16#30f3ccf3, 16#fcf03cc3)
    awrite(CDR_CID_by2_data[ 1161: 1168], 16#3f3f0f0c, 16#ccfffc00, 16#3003c033, 16#03fc3033, 16#c3f330ff, 16#cc03f030, 16#c3cf33cf, 16#f3c0f30c)
    awrite(CDR_CID_by2_data[ 1169: 1176], 16#fcfc3c33, 16#33fff000, 16#c00f00cc, 16#0ff0c0cf, 16#0fccc3ff, 16#300fc0c3, 16#0f3ccf3f, 16#cf03cc33)
    awrite(CDR_CID_by2_data[ 1177: 1184], 16#f3f0f0cc, 16#cfffc003, 16#003c0330, 16#3fc3033c, 16#3f330ffc, 16#c03f030c, 16#3cf33cff, 16#3c0f30cf)
    awrite(CDR_CID_by2_data[ 1185: 1192], 16#cfc3c333, 16#3fff000c, 16#00f00cc0, 16#ff0c0cf0, 16#fccc3ff3, 16#00fc0c30, 16#f3ccf3fc, 16#f03cc33f)
    awrite(CDR_CID_by2_data[ 1193: 1200], 16#3f0f0ccc, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ff0003ff)
    awrite(CDR_CID_by2_data[ 1201: 1208], 16#cffc3fcc, 16#fc03cfcc, 16#3c0ccf00, 16#33fc0fcf, 16#3c30cc30, 16#0c3f0cf3, 16#0303c3cc, 16#cc000fff)
    awrite(CDR_CID_by2_data[ 1209: 1216], 16#3ff0ff33, 16#f00f3f30, 16#f0333c00, 16#cff03f3c, 16#f0c330c0, 16#30fc33cc, 16#0c0f0f33, 16#30003ffc)
    awrite(CDR_CID_by2_data[ 1217: 1224], 16#ffc3fccf, 16#c03cfcc3, 16#c0ccf003, 16#3fc0fcf3, 16#c30cc300, 16#c3f0cf30, 16#303c3ccc, 16#c000fff3)
    awrite(CDR_CID_by2_data[ 1225: 1232], 16#ff0ff33f, 16#00f3f30f, 16#0333c00c, 16#ff03f3cf, 16#0c330c03, 16#0fc33cc0, 16#c0f0f333, 16#0003ffcf)
    awrite(CDR_CID_by2_data[ 1233: 1240], 16#fc3fccfc, 16#03cfcc3c, 16#0ccf0033, 16#fc0fcf3c, 16#30cc300c, 16#3f0cf303, 16#03c3cccc, 16#000fff3f)
    awrite(CDR_CID_by2_data[ 1241: 1248], 16#f0ff33f0, 16#0f3f30f0, 16#333c00cf, 16#f03f3cf0, 16#c330c030, 16#fc33cc0c, 16#0f0f3330, 16#003ffcff)
    awrite(CDR_CID_by2_data[ 1249: 1256], 16#c3fccfc0, 16#3cfcc3c0, 16#ccf0033f, 16#c0fcf3c3, 16#0cc300c3, 16#f0cf3030, 16#3c3cccc0, 16#00fff3ff)
    awrite(CDR_CID_by2_data[ 1257: 1264], 16#0ff33f00, 16#f3f30f03, 16#33c00cff, 16#03f3cf0c, 16#330c030f, 16#c33cc0c0, 16#f0f33300, 16#03ffcffc)
    awrite(CDR_CID_by2_data[ 1265: 1272], 16#3fccfc03, 16#cfcc3c0c, 16#cf0033fc, 16#0fcf3c30, 16#cc300c3f, 16#0cf30303, 16#c3cccc00, 16#0fff3ff0)
    awrite(CDR_CID_by2_data[ 1273: 1280], 16#ff33f00f, 16#3f30f033, 16#3c00cff0, 16#3f3cf0c3, 16#30c030fc, 16#33cc0c0f, 16#0f333000, 16#3ffcffc3)
    awrite(CDR_CID_by2_data[ 1281: 1288], 16#fccfc03c, 16#fcc3c0cc, 16#f0033fc0, 16#fcf3c30c, 16#c300c3f0, 16#cf30303c, 16#3cccc000, 16#fff3ff0f)
    awrite(CDR_CID_by2_data[ 1289: 1296], 16#f33f00f3, 16#f30f0333, 16#c00cff03, 16#f3cf0c33, 16#0c030fc3, 16#3cc0c0f0, 16#f3330003, 16#ffcffc3f)
    awrite(CDR_CID_by2_data[ 1297: 1304], 16#ccfc03cf, 16#cc3c0ccf, 16#0033fc0f, 16#cf3c30cc, 16#300c3f0c, 16#f30303c3, 16#cccc000f, 16#ff3ff0ff)
    awrite(CDR_CID_by2_data[ 1305: 1312], 16#33f00f3f, 16#30f0333c, 16#00cff03f, 16#3cf0c330, 16#c030fc33, 16#cc0c0f0f, 16#3330003f, 16#fcffc3fc)
    awrite(CDR_CID_by2_data[ 1313: 1320], 16#cfc03cfc, 16#c3c0ccf0, 16#033fc0fc, 16#f3c30cc3, 16#00c3f0cf, 16#30303c3c, 16#ccc000ff, 16#f3ff0ff3)
    awrite(CDR_CID_by2_data[ 1321: 1328], 16#3f00f3f3, 16#0f0333c0, 16#0cff03f3, 16#cf0c330c, 16#030fc33c, 16#c0c0f0f3, 16#33000000, 16#00000000)
    awrite(CDR_CID_by2_data[ 1329: 1336], 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#0000fffc, 16#003003c0, 16#3303fc30, 16#33c3f330)
    awrite(CDR_CID_by2_data[ 1337: 1344], 16#ffcc03f0, 16#30c3cf33, 16#cff3c0f3, 16#0cfcfc3c, 16#3333fff0, 16#00c00f00, 16#cc0ff0c0, 16#cf0fccc3)
    awrite(CDR_CID_by2_data[ 1345: 1352], 16#ff300fc0, 16#c30f3ccf, 16#3fcf03cc, 16#33f3f0f0, 16#cccfffc0, 16#03003c03, 16#303fc303, 16#3c3f330f)
    awrite(CDR_CID_by2_data[ 1353: 1360], 16#fcc03f03, 16#0c3cf33c, 16#ff3c0f30, 16#cfcfc3c3, 16#333fff00, 16#0c00f00c, 16#c0ff0c0c, 16#f0fccc3f)
    awrite(CDR_CID_by2_data[ 1361: 1368], 16#f300fc0c, 16#30f3ccf3, 16#fcf03cc3, 16#3f3f0f0c, 16#ccfffc00, 16#3003c033, 16#03fc3033, 16#c3f330ff)
    awrite(CDR_CID_by2_data[ 1369: 1376], 16#cc03f030, 16#c3cf33cf, 16#f3c0f30c, 16#fcfc3c33, 16#33fff000, 16#c00f00cc, 16#0ff0c0cf, 16#0fccc3ff)
    awrite(CDR_CID_by2_data[ 1377: 1384], 16#300fc0c3, 16#0f3ccf3f, 16#cf03cc33, 16#f3f0f0cc, 16#cfffc003, 16#003c0330, 16#3fc3033c, 16#3f330ffc)
    awrite(CDR_CID_by2_data[ 1385: 1392], 16#c03f030c, 16#3cf33cff, 16#3c0f30cf, 16#cfc3c333, 16#3fff000c, 16#00f00cc0, 16#ff0c0cf0, 16#fccc3ff3)
    awrite(CDR_CID_by2_data[ 1393: 1400], 16#00fc0c30, 16#f3ccf3fc, 16#f03cc33f, 16#3f0f0ccc, 16#fffc0030, 16#03c03303, 16#fc3033c3, 16#f330ffcc)
    awrite(CDR_CID_by2_data[ 1401: 1408], 16#03f030c3, 16#cf33cff3, 16#c0f30cfc, 16#fc3c3333, 16#fff000c0, 16#0f00cc0f, 16#f0c0cf0f, 16#ccc3ff30)
    awrite(CDR_CID_by2_data[ 1409: 1416], 16#0fc0c30f, 16#3ccf3fcf, 16#03cc33f3, 16#f0f0cccf, 16#ffc00300, 16#3c03303f, 16#c3033c3f, 16#330ffcc0)
    awrite(CDR_CID_by2_data[ 1417: 1424], 16#3f030c3c, 16#f33cff3c, 16#0f30cfcf, 16#c3c3333f, 16#ff000c00, 16#f00cc0ff, 16#0c0cf0fc, 16#cc3ff300)
    awrite(CDR_CID_by2_data[ 1425: 1432], 16#fc0c30f3, 16#ccf3fcf0, 16#3cc33f3f, 16#0f0cccff, 16#fc003003, 16#c03303fc, 16#3033c3f3, 16#30ffcc03)
    awrite(CDR_CID_by2_data[ 1433: 1440], 16#f030c3cf, 16#33cff3c0, 16#f30cfcfc, 16#3c3333ff, 16#f000c00f, 16#00cc0ff0, 16#c0cf0fcc, 16#c3ff300f)
    awrite(CDR_CID_by2_data[ 1441: 1448], 16#c0c30f3c, 16#cf3fcf03, 16#cc33f3f0, 16#f0cccfff, 16#c003003c, 16#03303fc3, 16#033c3f33, 16#0ffcc03f)
    awrite(CDR_CID_by2_data[ 1449: 1456], 16#030c3cf3, 16#3cff3c0f, 16#30cfcfc3, 16#c3333fff, 16#000c00f0, 16#0cc0ff0c, 16#0cf0fccc, 16#3ff300fc)
    awrite(CDR_CID_by2_data[ 1457: 1464], 16#0c30f3cc, 16#f3fcf03c, 16#c33f3f0f, 16#0cccffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff)
    awrite(CDR_CID_by2_data[ 1465: 1472], 16#ffffffff, 16#ffffff00, 16#03ffcffc, 16#3fccfc03, 16#cfcc3c0c, 16#cf0033fc, 16#0fcf3c30, 16#cc300c3f)
    awrite(CDR_CID_by2_data[ 1473: 1480], 16#0cf30303, 16#c3cccc00, 16#0fff3ff0, 16#ff33f00f, 16#3f30f033, 16#3c00cff0, 16#3f3cf0c3, 16#30c030fc)
    awrite(CDR_CID_by2_data[ 1481: 1488], 16#33cc0c0f, 16#0f333000, 16#3ffcffc3, 16#fccfc03c, 16#fcc3c0cc, 16#f0033fc0, 16#fcf3c30c, 16#c300c3f0)
    awrite(CDR_CID_by2_data[ 1489: 1496], 16#cf30303c, 16#3cccc000, 16#fff3ff0f, 16#f33f00f3, 16#f30f0333, 16#c00cff03, 16#f3cf0c33, 16#0c030fc3)
    awrite(CDR_CID_by2_data[ 1497: 1504], 16#3cc0c0f0, 16#f3330003, 16#ffcffc3f, 16#ccfc03cf, 16#cc3c0ccf, 16#0033fc0f, 16#cf3c30cc, 16#300c3f0c)
    awrite(CDR_CID_by2_data[ 1505: 1512], 16#f30303c3, 16#cccc000f, 16#ff3ff0ff, 16#33f00f3f, 16#30f0333c, 16#00cff03f, 16#3cf0c330, 16#c030fc33)
    awrite(CDR_CID_by2_data[ 1513: 1520], 16#cc0c0f0f, 16#3330003f, 16#fcffc3fc, 16#cfc03cfc, 16#c3c0ccf0, 16#033fc0fc, 16#f3c30cc3, 16#00c3f0cf)
    awrite(CDR_CID_by2_data[ 1521: 1528], 16#30303c3c, 16#ccc000ff, 16#f3ff0ff3, 16#3f00f3f3, 16#0f0333c0, 16#0cff03f3, 16#cf0c330c, 16#030fc33c)
    awrite(CDR_CID_by2_data[ 1529: 1536], 16#c0c0f0f3, 16#330003ff, 16#cffc3fcc, 16#fc03cfcc, 16#3c0ccf00, 16#33fc0fcf, 16#3c30cc30, 16#0c3f0cf3)
    awrite(CDR_CID_by2_data[ 1537: 1544], 16#0303c3cc, 16#cc000fff, 16#3ff0ff33, 16#f00f3f30, 16#f0333c00, 16#cff03f3c, 16#f0c330c0, 16#30fc33cc)
    awrite(CDR_CID_by2_data[ 1545: 1552], 16#0c0f0f33, 16#30003ffc, 16#ffc3fccf, 16#c03cfcc3, 16#c0ccf003, 16#3fc0fcf3, 16#c30cc300, 16#c3f0cf30)
    awrite(CDR_CID_by2_data[ 1553: 1560], 16#303c3ccc, 16#c000fff3, 16#ff0ff33f, 16#00f3f30f, 16#0333c00c, 16#ff03f3cf, 16#0c330c03, 16#0fc33cc0)
    awrite(CDR_CID_by2_data[ 1561: 1568], 16#c0f0f333, 16#0003ffcf, 16#fc3fccfc, 16#03cfcc3c, 16#0ccf0033, 16#fc0fcf3c, 16#30cc300c, 16#3f0cf303)
    awrite(CDR_CID_by2_data[ 1569: 1576], 16#03c3cccc, 16#000fff3f, 16#f0ff33f0, 16#0f3f30f0, 16#333c00cf, 16#f03f3cf0, 16#c330c030, 16#fc33cc0c)
    awrite(CDR_CID_by2_data[ 1577: 1584], 16#0f0f3330, 16#003ffcff, 16#c3fccfc0, 16#3cfcc3c0, 16#ccf0033f, 16#c0fcf3c3, 16#0cc300c3, 16#f0cf3030)
    awrite(CDR_CID_by2_data[ 1585: 1592], 16#3c3cccc0, 16#00fff3ff, 16#0ff33f00, 16#f3f30f03, 16#33c00cff, 16#03f3cf0c, 16#330c030f, 16#c33cc0c0)
    awrite(CDR_CID_by2_data[ 1593: 1600], 16#f0f33300, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#fffc0030)
    awrite(CDR_CID_by2_data[ 1601: 1608], 16#03c03303, 16#fc3033c3, 16#f330ffcc, 16#03f030c3, 16#cf33cff3, 16#c0f30cfc, 16#fc3c3333, 16#fff000c0)
    awrite(CDR_CID_by2_data[ 1609: 1616], 16#0f00cc0f, 16#f0c0cf0f, 16#ccc3ff30, 16#0fc0c30f, 16#3ccf3fcf, 16#03cc33f3, 16#f0f0cccf, 16#ffc00300)
    awrite(CDR_CID_by2_data[ 1617: 1624], 16#3c03303f, 16#c3033c3f, 16#330ffcc0, 16#3f030c3c, 16#f33cff3c, 16#0f30cfcf, 16#c3c3333f, 16#ff000c00)
    awrite(CDR_CID_by2_data[ 1625: 1632], 16#f00cc0ff, 16#0c0cf0fc, 16#cc3ff300, 16#fc0c30f3, 16#ccf3fcf0, 16#3cc33f3f, 16#0f0cccff, 16#fc003003)
    awrite(CDR_CID_by2_data[ 1633: 1640], 16#c03303fc, 16#3033c3f3, 16#30ffcc03, 16#f030c3cf, 16#33cff3c0, 16#f30cfcfc, 16#3c3333ff, 16#f000c00f)
    awrite(CDR_CID_by2_data[ 1641: 1648], 16#00cc0ff0, 16#c0cf0fcc, 16#c3ff300f, 16#c0c30f3c, 16#cf3fcf03, 16#cc33f3f0, 16#f0cccfff, 16#c003003c)
    awrite(CDR_CID_by2_data[ 1649: 1656], 16#03303fc3, 16#033c3f33, 16#0ffcc03f, 16#030c3cf3, 16#3cff3c0f, 16#30cfcfc3, 16#c3333fff, 16#000c00f0)
    awrite(CDR_CID_by2_data[ 1657: 1664], 16#0cc0ff0c, 16#0cf0fccc, 16#3ff300fc, 16#0c30f3cc, 16#f3fcf03c, 16#c33f3f0f, 16#0cccfffc, 16#003003c0)
    awrite(CDR_CID_by2_data[ 1665: 1672], 16#3303fc30, 16#33c3f330, 16#ffcc03f0, 16#30c3cf33, 16#cff3c0f3, 16#0cfcfc3c, 16#3333fff0, 16#00c00f00)
    awrite(CDR_CID_by2_data[ 1673: 1680], 16#cc0ff0c0, 16#cf0fccc3, 16#ff300fc0, 16#c30f3ccf, 16#3fcf03cc, 16#33f3f0f0, 16#cccfffc0, 16#03003c03)
    awrite(CDR_CID_by2_data[ 1681: 1688], 16#303fc303, 16#3c3f330f, 16#fcc03f03, 16#0c3cf33c, 16#ff3c0f30, 16#cfcfc3c3, 16#333fff00, 16#0c00f00c)
    awrite(CDR_CID_by2_data[ 1689: 1696], 16#c0ff0c0c, 16#f0fccc3f, 16#f300fc0c, 16#30f3ccf3, 16#fcf03cc3, 16#3f3f0f0c, 16#ccfffc00, 16#3003c033)
    awrite(CDR_CID_by2_data[ 1697: 1704], 16#03fc3033, 16#c3f330ff, 16#cc03f030, 16#c3cf33cf, 16#f3c0f30c, 16#fcfc3c33, 16#33fff000, 16#c00f00cc)
    awrite(CDR_CID_by2_data[ 1705: 1712], 16#0ff0c0cf, 16#0fccc3ff, 16#300fc0c3, 16#0f3ccf3f, 16#cf03cc33, 16#f3f0f0cc, 16#cfffc003, 16#003c0330)
    awrite(CDR_CID_by2_data[ 1713: 1720], 16#3fc3033c, 16#3f330ffc, 16#c03f030c, 16#3cf33cff, 16#3c0f30cf, 16#cfc3c333, 16#3fff000c, 16#00f00cc0)
    awrite(CDR_CID_by2_data[ 1721: 1728], 16#ff0c0cf0, 16#fccc3ff3, 16#00fc0c30, 16#f3ccf3fc, 16#f03cc33f, 16#3f0f0ccc, 16#ffffffff, 16#ffffffff)
    awrite(CDR_CID_by2_data[ 1729: 1736], 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ff0003ff, 16#cffc3fcc, 16#fc03cfcc, 16#3c0ccf00)
    awrite(CDR_CID_by2_data[ 1737: 1744], 16#33fc0fcf, 16#3c30cc30, 16#0c3f0cf3, 16#0303c3cc, 16#cc000fff, 16#3ff0ff33, 16#f00f3f30, 16#f0333c00)
    awrite(CDR_CID_by2_data[ 1745: 1752], 16#cff03f3c, 16#f0c330c0, 16#30fc33cc, 16#0c0f0f33, 16#30003ffc, 16#ffc3fccf, 16#c03cfcc3, 16#c0ccf003)
    awrite(CDR_CID_by2_data[ 1753: 1760], 16#3fc0fcf3, 16#c30cc300, 16#c3f0cf30, 16#303c3ccc, 16#c000fff3, 16#ff0ff33f, 16#00f3f30f, 16#0333c00c)
    awrite(CDR_CID_by2_data[ 1761: 1768], 16#ff03f3cf, 16#0c330c03, 16#0fc33cc0, 16#c0f0f333, 16#0003ffcf, 16#fc3fccfc, 16#03cfcc3c, 16#0ccf0033)
    awrite(CDR_CID_by2_data[ 1769: 1776], 16#fc0fcf3c, 16#30cc300c, 16#3f0cf303, 16#03c3cccc, 16#000fff3f, 16#f0ff33f0, 16#0f3f30f0, 16#333c00cf)
    awrite(CDR_CID_by2_data[ 1777: 1784], 16#f03f3cf0, 16#c330c030, 16#fc33cc0c, 16#0f0f3330, 16#003ffcff, 16#c3fccfc0, 16#3cfcc3c0, 16#ccf0033f)
    awrite(CDR_CID_by2_data[ 1785: 1792], 16#c0fcf3c3, 16#0cc300c3, 16#f0cf3030, 16#3c3cccc0, 16#00fff3ff, 16#0ff33f00, 16#f3f30f03, 16#33c00cff)
    awrite(CDR_CID_by2_data[ 1793: 1800], 16#03f3cf0c, 16#330c030f, 16#c33cc0c0, 16#f0f33300, 16#03ffcffc, 16#3fccfc03, 16#cfcc3c0c, 16#cf0033fc)
    awrite(CDR_CID_by2_data[ 1801: 1808], 16#0fcf3c30, 16#cc300c3f, 16#0cf30303, 16#c3cccc00, 16#0fff3ff0, 16#ff33f00f, 16#3f30f033, 16#3c00cff0)
    awrite(CDR_CID_by2_data[ 1809: 1816], 16#3f3cf0c3, 16#30c030fc, 16#33cc0c0f, 16#0f333000, 16#3ffcffc3, 16#fccfc03c, 16#fcc3c0cc, 16#f0033fc0)
    awrite(CDR_CID_by2_data[ 1817: 1824], 16#fcf3c30c, 16#c300c3f0, 16#cf30303c, 16#3cccc000, 16#fff3ff0f, 16#f33f00f3, 16#f30f0333, 16#c00cff03)
    awrite(CDR_CID_by2_data[ 1825: 1832], 16#f3cf0c33, 16#0c030fc3, 16#3cc0c0f0, 16#f3330003, 16#ffcffc3f, 16#ccfc03cf, 16#cc3c0ccf, 16#0033fc0f)
    awrite(CDR_CID_by2_data[ 1833: 1840], 16#cf3c30cc, 16#300c3f0c, 16#f30303c3, 16#cccc000f, 16#ff3ff0ff, 16#33f00f3f, 16#30f0333c, 16#00cff03f)
    awrite(CDR_CID_by2_data[ 1841: 1848], 16#3cf0c330, 16#c030fc33, 16#cc0c0f0f, 16#3330003f, 16#fcffc3fc, 16#cfc03cfc, 16#c3c0ccf0, 16#033fc0fc)
    awrite(CDR_CID_by2_data[ 1849: 1856], 16#f3c30cc3, 16#00c3f0cf, 16#30303c3c, 16#ccc000ff, 16#f3ff0ff3, 16#3f00f3f3, 16#0f0333c0, 16#0cff03f3)
    awrite(CDR_CID_by2_data[ 1857: 1864], 16#cf0c330c, 16#030fc33c, 16#c0c0f0f3, 16#33000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000)
    awrite(CDR_CID_by2_data[ 1865: 1872], 16#00000000, 16#0000fffc, 16#003003c0, 16#3303fc30, 16#33c3f330, 16#ffcc03f0, 16#30c3cf33, 16#cff3c0f3)
    awrite(CDR_CID_by2_data[ 1873: 1880], 16#0cfcfc3c, 16#3333fff0, 16#00c00f00, 16#cc0ff0c0, 16#cf0fccc3, 16#ff300fc0, 16#c30f3ccf, 16#3fcf03cc)
    awrite(CDR_CID_by2_data[ 1881: 1888], 16#33f3f0f0, 16#cccfffc0, 16#03003c03, 16#303fc303, 16#3c3f330f, 16#fcc03f03, 16#0c3cf33c, 16#ff3c0f30)
    awrite(CDR_CID_by2_data[ 1889: 1896], 16#cfcfc3c3, 16#333fff00, 16#0c00f00c, 16#c0ff0c0c, 16#f0fccc3f, 16#f300fc0c, 16#30f3ccf3, 16#fcf03cc3)
    awrite(CDR_CID_by2_data[ 1897: 1904], 16#3f3f0f0c, 16#ccfffc00, 16#3003c033, 16#03fc3033, 16#c3f330ff, 16#cc03f030, 16#c3cf33cf, 16#f3c0f30c)
    awrite(CDR_CID_by2_data[ 1905: 1912], 16#fcfc3c33, 16#33fff000, 16#c00f00cc, 16#0ff0c0cf, 16#0fccc3ff, 16#300fc0c3, 16#0f3ccf3f, 16#cf03cc33)
    awrite(CDR_CID_by2_data[ 1913: 1920], 16#f3f0f0cc, 16#cfffc003, 16#003c0330, 16#3fc3033c, 16#3f330ffc, 16#c03f030c, 16#3cf33cff, 16#3c0f30cf)
    awrite(CDR_CID_by2_data[ 1921: 1928], 16#cfc3c333, 16#3fff000c, 16#00f00cc0, 16#ff0c0cf0, 16#fccc3ff3, 16#00fc0c30, 16#f3ccf3fc, 16#f03cc33f)
    awrite(CDR_CID_by2_data[ 1929: 1936], 16#3f0f0ccc, 16#fffc0030, 16#03c03303, 16#fc3033c3, 16#f330ffcc, 16#03f030c3, 16#cf33cff3, 16#c0f30cfc)
    awrite(CDR_CID_by2_data[ 1937: 1944], 16#fc3c3333, 16#fff000c0, 16#0f00cc0f, 16#f0c0cf0f, 16#ccc3ff30, 16#0fc0c30f, 16#3ccf3fcf, 16#03cc33f3)
    awrite(CDR_CID_by2_data[ 1945: 1952], 16#f0f0cccf, 16#ffc00300, 16#3c03303f, 16#c3033c3f, 16#330ffcc0, 16#3f030c3c, 16#f33cff3c, 16#0f30cfcf)
    awrite(CDR_CID_by2_data[ 1953: 1960], 16#c3c3333f, 16#ff000c00, 16#f00cc0ff, 16#0c0cf0fc, 16#cc3ff300, 16#fc0c30f3, 16#ccf3fcf0, 16#3cc33f3f)
    awrite(CDR_CID_by2_data[ 1961: 1968], 16#0f0cccff, 16#fc003003, 16#c03303fc, 16#3033c3f3, 16#30ffcc03, 16#f030c3cf, 16#33cff3c0, 16#f30cfcfc)
    awrite(CDR_CID_by2_data[ 1969: 1976], 16#3c3333ff, 16#f000c00f, 16#00cc0ff0, 16#c0cf0fcc, 16#c3ff300f, 16#c0c30f3c, 16#cf3fcf03, 16#cc33f3f0)
    awrite(CDR_CID_by2_data[ 1977: 1984], 16#f0cccfff, 16#c003003c, 16#03303fc3, 16#033c3f33, 16#0ffcc03f, 16#030c3cf3, 16#3cff3c0f, 16#30cfcfc3)
    awrite(CDR_CID_by2_data[ 1985: 1992], 16#c3333fff, 16#000c00f0, 16#0cc0ff0c, 16#0cf0fccc, 16#3ff300fc, 16#0c30f3cc, 16#f3fcf03c, 16#c33f3f0f)
    awrite(CDR_CID_by2_data[ 1993: 2000], 16#0cccffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffff00, 16#03ffcffc)
    awrite(CDR_CID_by2_data[ 2001: 2008], 16#3fccfc03, 16#cfcc3c0c, 16#cf0033fc, 16#0fcf3c30, 16#cc300c3f, 16#0cf30303, 16#c3cccc00, 16#0fff3ff0)
    awrite(CDR_CID_by2_data[ 2009: 2016], 16#ff33f00f, 16#3f30f033, 16#3c00cff0, 16#3f3cf0c3, 16#30c030fc, 16#33cc0c0f, 16#0f333000, 16#3ffcffc3)
    awrite(CDR_CID_by2_data[ 2017: 2024], 16#fccfc03c, 16#fcc3c0cc, 16#f0033fc0, 16#fcf3c30c, 16#c300c3f0, 16#cf30303c, 16#3cccc000, 16#fff3ff0f)
    awrite(CDR_CID_by2_data[ 2025: 2032], 16#f33f00f3, 16#f30f0333, 16#c00cff03, 16#f3cf0c33, 16#0c030fc3, 16#3cc0c0f0, 16#f3330003, 16#ffcffc3f)
    awrite(CDR_CID_by2_data[ 2033: 2040], 16#ccfc03cf, 16#cc3c0ccf, 16#0033fc0f, 16#cf3c30cc, 16#300c3f0c, 16#f30303c3, 16#cccc000f, 16#ff3ff0ff)
    awrite(CDR_CID_by2_data[ 2041: 2048], 16#33f00f3f, 16#30f0333c, 16#00cff03f, 16#3cf0c330, 16#c030fc33, 16#cc0c0f0f, 16#3330003f, 16#fcffc3fc)
    awrite(CDR_CID_by2_data[ 2049: 2056], 16#cfc03cfc, 16#c3c0ccf0, 16#033fc0fc, 16#f3c30cc3, 16#00c3f0cf, 16#30303c3c, 16#ccc000ff, 16#f3ff0ff3)
    awrite(CDR_CID_by2_data[ 2057: 2064], 16#3f00f3f3, 16#0f0333c0, 16#0cff03f3, 16#cf0c330c, 16#030fc33c, 16#c0c0f0f3, 16#330003ff, 16#cffc3fcc)
    awrite(CDR_CID_by2_data[ 2065: 2072], 16#fc03cfcc, 16#3c0ccf00, 16#33fc0fcf, 16#3c30cc30, 16#0c3f0cf3, 16#0303c3cc, 16#cc000fff, 16#3ff0ff33)
    awrite(CDR_CID_by2_data[ 2073: 2080], 16#f00f3f30, 16#f0333c00, 16#cff03f3c, 16#f0c330c0, 16#30fc33cc, 16#0c0f0f33, 16#30003ffc, 16#ffc3fccf)
    awrite(CDR_CID_by2_data[ 2081: 2088], 16#c03cfcc3, 16#c0ccf003, 16#3fc0fcf3, 16#c30cc300, 16#c3f0cf30, 16#303c3ccc, 16#c000fff3, 16#ff0ff33f)
    awrite(CDR_CID_by2_data[ 2089: 2096], 16#00f3f30f, 16#0333c00c, 16#ff03f3cf, 16#0c330c03, 16#0fc33cc0, 16#c0f0f333, 16#0003ffcf, 16#fc3fccfc)
    awrite(CDR_CID_by2_data[ 2097: 2104], 16#03cfcc3c, 16#0ccf0033, 16#fc0fcf3c, 16#30cc300c, 16#3f0cf303, 16#03c3cccc, 16#000fff3f, 16#f0ff33f0)
    awrite(CDR_CID_by2_data[ 2105: 2112], 16#0f3f30f0, 16#333c00cf, 16#f03f3cf0, 16#c330c030, 16#fc33cc0c, 16#0f0f3330, 16#003ffcff, 16#c3fccfc0)
    awrite(CDR_CID_by2_data[ 2113: 2120], 16#3cfcc3c0, 16#ccf0033f, 16#c0fcf3c3, 16#0cc300c3, 16#f0cf3030, 16#3c3cccc0, 16#00fff3ff, 16#0ff33f00)
    awrite(CDR_CID_by2_data[ 2121: 2128], 16#f3f30f03, 16#33c00cff, 16#03f3cf0c, 16#330c030f, 16#c33cc0c0, 16#f0f33300, 16#00000000, 16#00000000)
    awrite(CDR_CID_by2_data[ 2129: 2132], 16#00000000, 16#00000000, 16#00000000, 16#00000000)

end_body

procedure Define_64ones64zeros_CID_data
--------------------------------------------------------------------------------

local

end_local

body

    awrite( CID_160ones160zeros_data [ 1: 5], 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff)
    awrite( CID_160ones160zeros_data [ 6: 10], 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000)
    awrite( CID_160ones160zeros_data [ 11: 15], 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff)
    awrite( CID_160ones160zeros_data [ 16: 20], 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000)

    awrite( CID_224ones224zeros_data [ 1: 7], 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff)
    awrite( CID_224ones224zeros_data [ 8: 14], 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000)
    awrite( CID_224ones224zeros_data [ 15: 21], 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff)
    awrite( CID_224ones224zeros_data [ 22: 28], 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000)

    awrite( CID_256ones256zeros_data [ 1: 8], 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff, 16#ffffffff)
    awrite( CID_256ones256zeros_data [ 9: 16], 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000, 16#00000000)

end_body

