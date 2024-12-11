library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.all;  -- For file I/O
use IEEE.STD_LOGIC_TEXTIO.ALL;  -- For reading std_logic_vector_comments
use work.all;

entity InstructionBuffer is
    Port (
        clk : in std_logic;  -- Clock signal
        rst : in std_logic;  -- Reset signal
        pc  : in std_logic_vector(5 downto 0);  -- Program Counter (6 bits for addressing 64 instructions)
        instruction_out : in std_logic_vector(24 downto 0)  -- 25-bit instruction output
    );
end InstructionBuffer;

architecture Behavioral of InstructionBuffer is
    type InstructionArray is array (0 to 63) of std_logic_vector(24 downto 0);
    signal instructions : InstructionArray := (others => (others => '0'));  -- Instruction memory
--    file instruction_file : text open read_mode is "C:\Users\mahim\OneDrive\Documents\School Notes\Junior Year\ESE 345\ProjectFull\Project Presentation\Project_Full\Project_Full\src\output.txt";  -- File containing instructions
begin

    -- Process to load instructions from file at simulation start
--    file_loader : process
--        variable line_text : line;
--        variable bin_value : std_logic_vector(24 downto 0);
--        variable index : integer := 0;
--    begin
--        while not endfile(instruction_file) loop
--            readline(instruction_file, line_text);
--            read(line_text, bin_value);
--            instructions(index) <= bin_value;
--            index := index + 1;
--        end loop;
--        wait;  -- Process finishes after loading the file
--    end process file_loader;

    -- Main clocked process for instruction output
    process (clk, rst)
    begin
        if rst = '1' then
            --instruction_out <= (others => '0');  -- Reset the output
        else
            -- Cast pc from std_logic_vector to unsigned for indexing
            instructions(to_integer(unsigned(pc))) <= instruction_out;
        end if;
    end process;

end Behavioral;
