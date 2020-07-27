------------------------------------------------------------------------------------------- 
-- Filename:
--     lib_array_fileio.mod
--
-- Routines:
--     lib_Save_float_array
--     lib_Save_binary_array
--     lib_Save_string_array
--     lib_Read_float_array
--
------------------------------------------------------------------------------------------- 

function lib_Save_array_to_file(float_array,int_array,path,format) : boolean

in_out  float       : float_array[?]   -- input, array of floats to be saved in ascii format
in_out  float       : int_array[?]   -- input, array of floats to be saved in ascii format
in      string[255] : path          -- input, string containing the full pathname to the file
in      string[10]  : format        -- how you want the data presented in the ascii file.
                                    -- format options are:
                                    -- "float" eg. 12345.123456
                                    -- "integer" eg. 123456
                                    -- "binary" eg. 10110001110
                                    -- "hex"    eg. A0F9

------------------------------------------------------------------------------------------- 
-- Description:
-- Saves a one dimensional array of floats as a list of ascii floating point values to a 
-- specified filename.
-- Works with variable array sizes.
--
-- Global variable usage:
--     none
--
-- Operator variable usage:
--     none
--
------------------------------------------------------------------------------------------- 

local 
    integer : size 
    integer : f_num    , i
    lword   : error_num 
    word    : data_type   -- 0=float, 1=integer, 2=binary, 3=hex
end_local 

 
body 
 
    -- enumerate type into data_type
    if format = "float" then 
        data_type = 0
    else_if format = "integer" then 
        data_type = 1
    else_if format = "binary" then 
        data_type = 2
    else_if format = "hex" then 
        data_type = 3
    else
        println(stdout," ") 
        println(stdout,"Error: lib_Save_array_to_file: Unknown format '", format, "'") 
        return(FALSE)
    end_if

    if format = "float" then 
        size = dimsize(float_array,1) 
    else
        size = dimsize(int_array,1) 
    end_if
    
    open(f_num,path,"w") 
 
    error_num = io_errnum 
    
    if error_num > 0 then 
        close(f_num) 
        println(stdout," ") 
        println(stdout,"opening file '",path,"' failed !! -- from Open_file") 
        return (FALSE) 
    else
        print (stdout, "Saving data in file ", path, " ... ")
    end_if 
 
 

    for i = 1 to size do 
        if      data_type = 0 then 
            println (f_num,int_array[i]:12:6) -- float data
        else_if data_type = 1 then 
            println (f_num,int_array[i]:12)   -- integer data
        else_if data_type = 2 then
            println (f_num,integer(int_array[i])!b:12) -- unsigned binary data
        else_if data_type = 3 then 
            println (f_num,integer(int_array[i])!h:12) -- unsigned hex data
        end_if
    end_for 
  
    close (f_num) 

    println (stdout, " OK", "@n")

    return (TRUE) 
 
end_body



function lib_Save_float_array(in_array,path) : boolean

in_out  float       : in_array[?]   -- input, array of floats to be saved in ascii format
in      string[255] : path          -- input, string containing the full pathname to the file

------------------------------------------------------------------------------------------- 
-- Description:
-- Saves a one dimensional array of floats as a list of ascii floating point values to a 
-- specified filename.
-- Works with variable array sizes.
--
-- Global variable usage:
--     none
--
-- Operator variable usage:
--     none
--
------------------------------------------------------------------------------------------- 

local 
    integer : size 
    integer : f_num    , i 
    lword   : error_num 
end_local 
 
body 
 
    size = dimsize(in_array,1) 
    
    open(f_num,path,"w") 
 
    error_num = io_errnum 
    
    if error_num > 0 then 
        close(f_num) 
        println(stdout," ") 
        println(stdout,"opening file '",path,"' failed !! -- from Open_file") 
        return (FALSE) 
    else
        print (stdout, "Saving data in file ", path, " ... ")
    end_if 
 
 
    for i = 1 to size do 
        println (f_num,in_array[i]:12:6)
    end_for 
  
    close (f_num) 

    println (stdout, " OK", "@n")

    return (TRUE) 
 
end_body
 
function lib_Save_binary_array(in_array,path) : boolean

in_out  integer     : in_array[?]      -- input, array of integers to be saved in ascii format
in      string[255] : path             -- input, string containing the full pathname to the file
 
------------------------------------------------------------------------------------------- 
-- Description:
-- Saves a one dimensional array of integers as a list of ascii format binary values to a 
-- specified filename.
-- Works with variable array sizes.
--
-- Global variables:
--     none
--
-- Operator variable usage:
--     none
--
------------------------------------------------------------------------------------------- 
 
local 
    integer : size 
    integer : f_num    , i 
    lword   : error_num 
end_local 
 
body 
 
    size = dimsize(in_array,1) 
 
    
    open(f_num,path,"w") 
 
    error_num = io_errnum 
 
    
    if error_num > 0 then 
        close(f_num) 
        println(stdout," ") 
        println(stdout,"opening file '",path,"' failed !! -- from Open_file") 
        return(FALSE)
    else
        print (stdout, "Saving data in file ", path, " ... ")
    end_if 
 
 
    for i = 1 to size do 
        println (f_num,in_array[i]!b)
    end_for 
 
    close (f_num) 

    println (stdout, " OK", "@n")
 
   return(TRUE)

end_body
 
function lib_Save_string_array(in_array,path) : boolean

in      string[255]  : in_array[?]     -- input, array of strings to be saved in ascii format
in      string[255] : path             -- input, string containing the full pathname to the file
 
------------------------------------------------------------------------------------------- 
-- Description:
-- Saves a one dimensional array of strings to a specified filename.
-- Works with variable array sizes.
-- String sizes up to 255 characters.
--
-- Global variables:
--     none
--
-- Operator variable usage:
--     none
--
------------------------------------------------------------------------------------------- 
 
local 
    integer : size 
    integer : f_num    , i 
    lword   : error_num
     
end_local 
 
body 
 
    size = dimsize(in_array,1) 
 
    
    open(f_num,path,"w") 
 
    error_num = io_errnum 
 
    
    if error_num > 0 then 
        close(f_num) 
        println(stdout," ") 
        println(stdout,"opening file '",path,"' failed !! -- from Open_file") 
        return(FALSE)
    else
        print (stdout, "Saving data in file ", path, " ... ")
    end_if 
 
 
    for i = 1 to size do
        println (f_num,in_array[i])
    end_for 
  
 
    close (f_num) 

    println (stdout, " OK", "@n")
  
    return(TRUE)
 
end_body
 
 
function lib_Read_float_array(f_data, path) : boolean

in_out  float       : f_data[?]        -- output, array of floats to be read from an ascii file
in      string[255] : path             -- input, string containing the full pathname to the file

------------------------------------------------------------------------------------------- 
-- Description:
-- Saves a one dimensional array of strings to a specified filename.
-- Works with variable array sizes.
-- String sizes up to 255 characters.
--
-- Global variables:
--     none
--
-- Operator variable usage:
--     none
--
------------------------------------------------------------------------------------------- 
 
 
local 
    integer     : f_num ,i, size 
    lword       : error_num 
    string[255] : line_str
    string[2]   : comment_str
end_local 
 
body 
 
    size = dimsize(f_data,1) 
    i = 0
 
    open(f_num,path,"r") 
 
    error_num = io_errnum 
 
    if error_num > 0 then 
        close(f_num) 
        println(stdout," ") 
        println(stdout,"opening file '",path,"' failed !! -- from Open_file") 
        return(FALSE)
    else
        print (stdout, "Reading ASCII external file ", path, " into array ... ")
    end_if 
 
    while (inquire(f_num) > 0 ) do

        input (f_num, line_str!L ) -- Read up to EOL

        if (io_errnum <> 0)  then
            println (stdout)
            println (stdout, "@nERROR: Unable to read ASCII file.")
            println (stdout, "       File name: ", path)

            close (f_num)

            return (FALSE)
        end_if

        sinput (line_str, comment_str)

        if (comment_str <> "--" and comment_str <> "") then
            i = i + 1

            if (lword(i) > lword(size)) then
                println (stdout)
                println (stdout, "@nERROR: Array size too small to load input file.")
                println (stdout, "       File name: ", path)

                close (f_num)

                return (FALSE)
            end_if

            f_data[i] = float(line_str)

        end_if

    end_while
 
    close (f_num) 

    println (stdout, " OK", "@n")

    return(TRUE)
 
end_body 

function lib_Ascii_hex_to_dec (in_str): lword
out string: in_str
--------------------------------------------------------------------------------

--  This function converts the ASCII hex data into a lword decimal number.  

local
    lword:      dec, x
    integer:    k, power
end_local

body

    dec   = 0
    power = len(in_str)

    for k=1 to power do

        x = lword (asc (in_str[k]))

        if      (in_str[k] >= "A" and in_str[k] <= "F") then
            x = x - 55        
        else_if (in_str[k] >= "a" and in_str[k] <= "f") then 
            x = x - 87
        else_if (in_str[k] >= "0" and in_str[k] <= "9") then 
            x = x - 48
        else
            println (stdout, "Illegal hex digit ... aborting!")
            return (0)
        end_if

        dec = dec + x*16^(lword(power-k))
       
    end_for

    return (dec)

end_body


function Ascii_Binary_To_Dec (in_str): integer
out string: in_str
--------------------------------------------------------------------------------

--  This function converts the ASCII binary data into an integer.  

local
    integer:    dec, x, k, power
end_local

body

    dec   = 0
    power = len(in_str)

    for k=1 to power do

        if (in_str[k] <> "0" and in_str[k] <> "1") then
            println (stdout, "Illegal binary digit ... Aborting!")
            return (0)
        end_if

        x   = integer (asc (in_str[k])) - 48
        dec = dec + x*2^(power-k)        
       
    end_for

    return (dec)

end_body


