library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use std.textio.ALL; -- For file operations
use work.all;

entity tb_InstructionBuffer is
end tb_InstructionBuffer;

architecture Behavioral of tb_InstructionBuffer is
    -- Signals for connecting to the DUT
    signal clk : std_logic := '0';
    signal rst : std_logic := '0';
    signal pc : std_logic_vector(5 downto 0) := (others => '0');
    signal instruction_out : std_logic_vector(24 downto 0);

    -- Clock period constant
    constant clk_period : time := 10 ns;

    -- File for logging results
    file result_file : text open write_mode is "simulation_results.txt";

begin
    -- Instantiate the DUT (Device Under Test)
    uut: entity work.InstructionBuffer
        port map (
            clk => clk,
            rst => rst,
            pc => pc,
            instruction_out => instruction_out
        );

    -- Clock generation process
    clk_process: process
    begin
        while true loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Stimulus process
    stimulus: process
        variable line : line;
    begin
        -- Apply reset
        rst <= '1';
        wait for 2 * clk_period;
        rst <= '0';
        wait for clk_period;

        -- Simulate program counter values and capture output
        for i in 0 to 63 loop
            pc <= std_logic_vector(to_unsigned(i, pc'length));
            wait for clk_period;

            -- Log PC and instruction output to the result file
            write(line, string'("PC = "));
            write(line, integer'image(to_integer(unsigned(pc))));
            write(line, string'(", Instruction = "));
            for j in instruction_out'range loop
                if instruction_out(j) = '1' then
                    write(line, string'("1"));
                else
                    write(line, string'("0"));
                end if;
            end loop;
            writeline(result_file, line);
        end loop;

        -- End simulation
        wait;
    end process;
end Behavioral;
