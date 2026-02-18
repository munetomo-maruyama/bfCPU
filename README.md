# bfCPU, a Turing-complete machine
The objective of this project is to design a **Turing-complete machine** for Tiny Tapeout. 

## Building the Turing-Complete bfCPU

One of the most famous examples of a simple, yet fully Turing-complete machine is the architecture proposed in 1993 by Urban Müller of Switzerland, known as Brainf*ck (where * is 'u') [[WikibfCPU]](https://en.wikipedia.org/wiki/Brainfuck). I have obscured one letter due to the somewhat indelicate nature of the name; in this project, I will refer to this CPU architecture as "bfCPU." The bfCPU is an 8-bit CPU with only eight commands. Remarkably, these few commands are sufficient to implement any arbitrary algorithm. We will actually design this CPU, implement it on an FPGA, and ultimately enjoy the process of turning it into silicon via Tiny Tapeout.

## The bfCPU Architecture

### The Profundity of bfCPU
Programs written for bfCPU have extremely low readability and writability, earning it a spot among "esoteric programming languages" (esolangs). Even performing a simple addition feels like solving a complex puzzle. When we write a program for bfCPU, we find ourselves inadvertently and mischievously grinning. Indeed, I found myself grinning as well when I first encountered bfCPU.

### Basic Architecture of bfCPU
The basic architecture of the bfCPU is shown in below.

<img src="doc/image/bfcpu_architecture.png" alt="Basic architecture of bfCPU" width="50%">

The internal resources of the bfCPU consist solely of a Program Counter (PC) and a Data Memory Pointer (PTR). The PC indicates the address of the instruction stored in the program memory. The CPU fetches the instruction from the program memory at the address pointed to by the PC, and according to that instruction, it either manipulates the Data Memory Pointer (PTR) or accesses the data at the address in the data memory pointed to by the PTR. Each address in the data memory stores 8-bit (byte-sized) data.

Furthermore, there is an I/O mechanism for interfacing with the outside world. In the bfCPU designed for this project, external input is handled as received data via a UART (Universal Asynchronous Receiver/Transmitter), and external output is handled as transmitted data from the UART. The structure of the bfCPU is as simple as that.

### bfCPU Instruction Set
The list of the bfCPU instruction set is shown in Table 1 below. The bfCPU originally features only eight instructions with opcodes (binary) from `0000` to `0111`. While 3 bits would suffice for eight instructions, the bfCPU designed here includes two additional instructions (`reset` and `nop`), resulting in a 4-bit instruction code length. All of these instruction codes consist only of an opcode indicating the operation; they have a simple structure with no operands to specify targets.

The original instruction notation for bfCPU consists of single characters shown in the "Symbol" column of the table below (`<`, `>`, `+`, `-`, etc.). A program is formed by lining up these characters without gaps, or with occasional spaces and line breaks, which is why it is called an esoteric language. As described later, I have developed an assembler and instruction simulator called **bfTool** for bfCPU program development. This assembler accepts the original single-character bfCPU instructions, allowing the use of the vast number of publicly available bfCPU programs. However, it also supports the "Mnemonic" descriptions to improve readability. The "C-Equivalent" column represents the operation of each instruction in the C language. Note that while the original bfCPU uses ASCII characters directly as the program, the bfCPU designed in this article replaces each instruction with a 4-bit instruction code.

**Table 1: bfCPU Instruction Set**
| Instruction Code (Hex) | Mnemonic | Symbol | C-Equivalent | Description |
| :--- | :--- | :---: | :--- | :--- |
| 0x0 | INC_PTR | `>` | `++ptr;` | Increment the data pointer. |
| 0x1 | DEC_PTR | `<` | `--ptr;` | Decrement the data pointer. |
| 0x2 | INC_DATA | `+` | `++*ptr;` | Increment the byte at the data pointer. |
| 0x3 | DEC_DATA | `-` | `--*ptr;` | Decrement the byte at the data pointer. |
| 0x4 | OUTPUT | `.` | `putchar(*ptr);` | Output the byte at the data pointer. |
| 0x5 | INPUT | `,` | `*ptr = getchar();` | Input a byte and store it at the data pointer. |
| 0x6 | JMP_FWD | `[` | `while (*ptr) {` | Jump forward past `]` if the byte at the pointer is 0. |
| 0x7 | JMP_BACK | `]` | `}` | Jump back to the command after `[` if the byte at the pointer is non-zero. |
| 0x8 | NOP | - | - | No operation. |
| 0xF | RESET | - | - | Reset the CPU state. |

The following sections explain the operation of each instruction. After a reset, the bfCPU clears all contents of the data memory to zero, resets the PTR and PC to zero, and begins execution from the instruction at address 0 in the program memory.

#### 【>】 (pinc/p++)
Increments the data pointer (PTR) by one. The PTR will now point to the data memory cell immediately to the right. After executing this instruction, the PC is incremented by one to proceed to the next instruction.

#### 【<】 (pdec/p--)
Decrements the data pointer (PTR) by one. The PTR will now point to the data memory cell immediately to the left. After executing this instruction, the PC is incremented by one to proceed to the next instruction.

#### 【+】 (inc)
Reads the data memory at the location pointed to by the PTR, adds 1, and writes the result back to the same location. In other words, it increments the content of the data memory pointed to by the PTR. After execution, the PC is incremented by one. The PTR remains unchanged.

#### 【-】 (dec)
Reads the data memory at the location pointed to by the PTR, subtracts 1, and writes the result back to the same location. In other words, it decrements the content of the data memory pointed to by the PTR. After execution, the PC is incremented by one. The PTR remains unchanged.

#### 【.】 (out)
Reads the data memory at the location pointed to by the PTR and outputs one byte of data to the external interface. In this bfCPU design, it transmits one byte via UART. A wait state is automatically inserted until the UART transmission buffer becomes empty. After execution, the PC is incremented by one.

#### 【,】 (in)
Inputs one byte of data from the external interface and writes it to the data memory location pointed to by the PTR. In this bfCPU design, it receives one byte via UART. A wait state is automatically inserted until data is received in the UART buffer. After execution, the PC is incremented by one.

#### 【[】 (begin)
If the data in the memory pointed to by the PTR is zero, the CPU jumps to the instruction following the corresponding `end` (]) command at the same nesting depth, instead of proceeding to the next instruction (without incrementing the PC). If the data is non-zero, the PC is incremented by one, and execution proceeds to the next instruction. In other words, if the data is non-zero when the `begin` ([) command is executed, the instructions between this `begin` and its corresponding `end` (]) will be repeated.

#### 【]】 (end)
If the data in the memory pointed to by the PTR is non-zero, the CPU jumps back to the instruction following the corresponding `begin` ([) command at the same nesting depth, instead of proceeding to the next instruction. If the data is zero, the PC is incremented by one, and execution proceeds to the next instruction.

Note that the `end` (]) command does not strictly need to check the data; it could simply jump back to the corresponding `begin` ([) command every time. However, in that case, if the data were zero, the CPU would jump back only to immediately jump forward again, causing unnecessary processing cycles. Therefore, this design of the `end` command also checks the data memory content.

#### (reset)
Resets the bfCPU. It clears all data memory to zero, resets the PTR and PC to zero, and starts execution from address 0 in the program memory.

#### (nop)
Performs no operation. The PC is incremented by one to proceed to the next instruction.

### How do the `begin` ([) and `end` (]) Instructions Handle Jumping?
In a typical CPU, an instruction code consists of an "opcode," which indicates what the instruction does, and "operands," which specify the target of the operation—such as a memory address for data transfer, a constant value for addition, or the target address for a branch instruction. However, the 4-bit instruction code of the bfCPU contains only the opcode. Since the bfCPU only operates on the Data Pointer (PTR) and data memory, opcodes alone might seem sufficient. However, the lack of operands to define the branch targets for the `begin` ([) and `end` (]) instructions poses a challenge.

If we were to increase the bit length of the bfCPU instruction codes to include branch target information, an assembler or compiler could determine the corresponding addresses of nested `begin` and `end` pairs when generating machine code. However, for the sake of simplicity in this project, we have opted to keep all instruction codes within 4 bits. Consequently, the branch instructions (begin and end) do not contain any destination information.

So, how do the `begin` and `end` instructions find their branch targets? The answer lies in **searching the program memory**.

When a `begin` ([) instruction triggers a jump to the instruction following the corresponding `end` (]), the execution logic clears an internal register called `INDENT` to zero and then searches through the program memory by incrementing the PC. If another `begin` ([) is encountered, the CPU assumes the nesting has deepened and increments `INDENT`. If an `end` (]) is found while `INDENT` is greater than zero, it means this `end` does not correspond to the initial `begin`, so the CPU decrements `INDENT` and continues the search. Finally, when an `end` (]) is found while `INDENT` is zero, the CPU identifies it as the matching pair and resumes execution from the following instruction.

Conversely, when an `end` (]) instruction triggers a jump back to the instruction following the corresponding `begin` ([), the execution logic clears the `INDENT` register and searches the program memory by decrementing the PC. If another `end` (]) is encountered, it increments `INDENT`. If a `begin` ([) is found while `INDENT` is greater than zero, it decrements `INDENT` and continues searching. When a `begin` ([) is finally found while `INDENT` is zero, it is identified as the matching pair, and execution resumes from the instruction immediately following that `begin`.

As described, since the `begin` and `end` instructions cannot jump to their destinations in a single cycle, searching through program memory stored in a relatively slow QSPI SRAM is a performance disadvantage. However, as will be discussed later, by equipping the CPU with an **instruction cache**, we minimize the need to access the external QSPI SRAM during these searches, thereby keeping performance degradation to a minimum.

### Important Notes on bfCPU Programs
The `begin` ([) and `end` (]) instructions can be nested to any depth, but they must always be correctly paired. Additionally, while the data width of each cell in the data memory is 8 bits (one byte), the values wrap around: adding 1 to `0xFF` results in `0x00`, and subtracting 1 from `0x00` results in `0xFF`. There are no flags to indicate the occurrence of a carry, borrow, or overflow.


