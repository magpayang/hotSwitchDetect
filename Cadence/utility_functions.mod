


function GrayToLword(UsrVal) :   lword
in lword   : UsrVal

local
  integer : i
  lword   : RetVal, MaskVal
end_local

body

  RetVal = UsrVal
  MaskVal = UsrVal >> 1
  while MaskVal <> 0 do
    RetVal = RetVal % MaskVal
    MaskVal = MaskVal >> 1
  endwhile
  
  return(RetVal)

end_body   --  GrayToLword






function ConvertGrayCode (Gray_data) :    word
--------------------------------------------------------------------------------
--  converts 8 bit Gray-coded input data to decimal

in  word : Gray_data

local
    word   : output_value
    word : bit_num, counts, mask_val
end_local

body

        --msb of Gray and normal are always same
        output_value = Gray_data & 0x80
        
        bit_num = 7
        
        for counts = 0 to 6 by 1  do
            bit_num = bit_num - 1
            mask_val = 0x1 << (bit_num + 1)
            if  Gray_data & (1 << bit_num) = 0  then
                --if current bit is 0, concatenate previous bit
                output_value = output_value | ((output_value & mask_val) >> 1)
            else
                --else concatenate invert of previous bit
                if (((output_value & mask_val) >> (1+bit_num))) = 0  then
                    output_value = output_value | (mask_val >> 1)
                else
                    --do nothing
                end_if
            end_if
        
        end_for


    return(output_value)
end_body   -- ConvertGrayCode









function ConvertGrayCodeMsite (Gray_data) :   multisite lword
--------------------------------------------------------------------------------
--  converts 8 bit Gray-coded input data to decimal

in multisite lword : Gray_data
local

    multisite lword   : output_value
    lword : bit_num, counts, mask_val
    word list[MAX_SITES] : active_sites    
    word              : csite, sIdx, sites

end_local

body

    active_sites = get_active_sites()
    sites = word(len(active_sites))
    
    for sIdx = 1 to sites do
        csite = active_sites[sIdx]

        --msb of Gray and normal are always same
        output_value[csite] = Gray_data[csite] & 0x80
        
        bit_num = 7
        
        for counts = 0 to 6 by 1  do
            bit_num = bit_num - 1
            mask_val = 0x1 << (bit_num + 1)
            if  Gray_data[csite] & (1 << bit_num) = 0  then
                --if current bit is 0, concatenate previous bit
                output_value[csite] = output_value[csite] | ((output_value[csite] & mask_val) >> 1)
            else
                --else concatenate invert of previous bit
                if (((output_value[csite] & mask_val) >> (1+bit_num))) = 0  then
                    output_value[csite] = output_value[csite] | (mask_val >> 1)
                else
                    --do nothing
                end_if
            end_if
        
        end_for
        
        
        
    end_for

    return(output_value)
end_body   -- ConvertGrayCodeMsite


