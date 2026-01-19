//https://esolangs.org/wiki/brainfuck_algorithms#Input_a_decimal_number

[-]>[-]+    // Clear sum
[[-]                // Begin loop on first temp
>[-],               // Clear the inp buffer to detect leave on eof and input
    [
        +[                          // Check for minus one on eof
            -----------[            // Check for newline
                >[-]++++++[<------>-]       // Subtract 38 to get the char in zero to nine
                <--<<[->>++++++++++<<]      // Multiply the existing value by ten
                >>[-<<+>>]          // and add in the new char
            <+>]
        ]
    ]
<]
< // Current cell is the number input
//reset

// https://stackoverflow.com/questions/12569444/printing-a-number-in-brainfuck
//>+++++++++++[-<+++++++++++++++>] // initialize 165 at first cell
>
>++++++++++<<[->+>-[>+>>]>[+[-<+>]>+>>]<<<<<<]>>[-]>>>++++++++++<[->-[>+>>]>[+[-
<+>]>+>>]<<<<<]>[-]>>[>++++++[-<++++++++>]<.<<+>+>[-]]<[<[->-<]++++++[->++++++++
<]>.[-]]<<++++++[-<++++++++>]<.[-]<<[-<+>]
++++++++++.<
[+] // clear zero
reset
 
