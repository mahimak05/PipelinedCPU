library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL; 	 
use std.textio.all;  -- For file I/O
use IEEE.STD_LOGIC_TEXTIO.ALL; 	
use work.all;



-- Top-level testbench entity for the entire pipeline
entity pipeline_testbench is
end pipeline_testbench;

architecture tb of pipeline_testbench is

    -- Signals for the 4-stage pipeline
    signal clk                : std_logic := '0';
    signal reset              : std_logic := '1';
    signal IF_ID_instr        : std_logic_vector(24 downto 0);
	signal IF_ID_pc : std_logic_vector(5 downto 0) := (others => '0');
    
    signal ID_EXE_instr       : std_logic_vector(24 downto 0) := (others => '0');
    signal ID_EXE_rs1         : std_logic_vector(127 downto 0) := (others => '0');
    signal ID_EXE_rs2         : std_logic_vector(127 downto 0) := (others => '0');
    signal ID_EXE_rs3         : std_logic_vector(127 downto 0) := (others => '0');

    signal EXE_WB_instr       : std_logic_vector(24 downto 0) := (others => '0');
    signal EXE_WB_result      : std_logic_vector(127 downto 0) := (others => '0');
    
    signal EXE_MEM_RegWrite   : std_logic := '0';
    signal EXE_MEM_Rd         : std_logic_vector(127 downto 0) := (others => '0');
    
    signal MEM_WB_RegWrite    : std_logic := '0';    
    signal MEM_WB_Rd          : std_logic_vector(127 downto 0) := (others => '0');

    -- Registers for control and forwarding
    signal regfile_out1       : std_logic_vector(127 downto 0) := (others => '0');
    signal regfile_out2       : std_logic_vector(127 downto 0) := (others => '0');
    signal regfile_out3       : std_logic_vector(127 downto 0) := (others => '0');
    signal alu_result         : std_logic_vector(127 downto 0) := (others => '0');
    signal write_back_data    : std_logic_vector(127 downto 0) := (others => '0');
    signal write_enable       : std_logic;	
	signal ForwardA      : std_logic_vector(1 downto 0) := (others => '0');
    signal ForwardB      : std_logic_vector(1 downto 0) := (others => '0');
    
    -- File reading signals
    file input_file  : text open read_mode is "C:\Users\mahim\OneDrive\Documents\School Notes\Junior Year\ESE 345\ProjectFull\Project Presentation\Project_Full\Project_Full\src\machine_code.txt";  -- Input instructions file
    file output_file : text open write_mode is "results.txt";  -- Output results file
   
    -- Clock generation
    constant clk_period : time := 10 ns;

begin

    -- Clock generation process
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

stimulus: process
    -- Variables declared inside the process
    variable line_in : line;
    variable instruction : std_logic_vector(24 downto 0);
    variable result : std_logic_vector(127 downto 0);
    variable result_str : string(1 to 128);  -- String to store the result for file writing
    variable line_out : line;  -- Variable to hold the line to write to file
begin
    -- Apply reset at the start
    reset <= '1';
    wait for 20 ns;
    reset <= '0';  -- Release reset
    wait for 20 ns;

    -- Read instructions from input file
    while not endfile(input_file) loop
        -- Read a line (32 bits per instruction)
        readline(input_file, line_in);
        read(line_in, instruction);

        -- Load instruction into pipeline IF/ID stage
        IF_ID_instr <= instruction(24 downto 0);
		
		ID_EXE_instr <= IF_ID_instr;
		
--		ID_EXE_rs1 <= IF_ID_instr(9 downto 5);
--		ID_EXE_rs2 <= IF_ID_instr(14 downto 10);
--		ID_EXE_rs3 <= IF_ID_instr(19 downto 15);

		EXE_WB_instr <= ID_EXE_instr;
        IF_ID_pc <= std_logic_vector(unsigned(IF_ID_pc) + 1);
		EXE_WB_result <= alu_result; 

        -- Simulate for 5 clock cycles to process the instruction
        wait for 50 ns;  -- Processing the pipeline for a few cycles

        -- Read the result from EXE/WB
        result := write_back_data;  -- Assuming the result is ready after 5 cycles

        -- Convert the result to string for writing to the file
        for i in 0 to 127 loop
            if result(i) = '1' then
                result_str(i + 1) := '1';
            else
                result_str(i + 1) := '0';
            end if;
        end loop;

        -- Associate the result_str string with the line_out variable
        write(line_out, result_str);  -- Write the result string to line_out
        writeline(output_file, line_out);  -- Write the line to the output file

        wait for 10 ns;  -- Small delay between instructions
    end loop;
	
    -- End simulation
    wait for 50 ns;
    assert false report "End of simulation" severity failure;
end process;


    -- Instruction Fetch (IF Stage)
    instruction_fetch: entity InstructionBuffer
        port map (
            clk => clk,
            rst => reset,
            pc => IF_ID_pc,
            instruction_out => IF_ID_instr
        );
		
--		ID_EXE_rs1 <= IF_ID_instr(9 downto 5);
--		ID_EXE_rs2 <= IF_ID_instr(14 downto 10);
--		ID_EXE_rs1 <= IF_ID_instr(19 downto 5);
--		
--
--     Register File
--    register_file_inst : entity work.Register_File
--        port map (
--            clk => clk,
--            reset => reset,
--            read_addr1 => ID_EXE_rs1,
--            read_addr2 => ID_EXE_rs2,
--            read_addr3 => ID_EXE_rs3,
--            write_addr => MEM_WB_dest_loc,  Write to correct register
--            write_data => MEM_WB_Rd,       Write the actual rd value
--            write_enable => MEM_WB_RegWrite,
--            read_data1 => regfile_out1,
--            read_data2 => regfile_out2,
--            read_data3 => regfile_out3
--        );

    -- Forwarding Unit
    forwarding_unit: entity Forwarding_Unit
        port map (
            EXE_MEM_RegWrite => EXE_MEM_RegWrite,
            MEM_WB_RegWrite => MEM_WB_RegWrite,
            EXE_MEM_Rd => EXE_MEM_Rd,
            MEM_WB_Rd => MEM_WB_Rd,
            ID_EXE_Rs1 => ID_EXE_rs1,
            ID_EXE_Rs2 => ID_EXE_rs2,
            ForwardA => ForwardA,
            ForwardB => ForwardB
        );

    -- ALU (Execution Stage)
    alu: entity ALU
        port map (    
            clk => clk,
            reset => reset,
            we => write_enable,
            instruction => IF_ID_instr,
            rs1 => regfile_out1,
            rs2 => regfile_out2,
            rs3 => regfile_out3,
            rd => alu_result
        );

    -- Write Back (WB Stage)
    write_back_process: process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                write_enable <= '0';
                write_back_data <= (others => '0');
				EXE_MEM_RegWrite <= '0';
				MEM_WB_RegWrite <= EXE_MEM_RegWrite;
            else
				EXE_MEM_RegWrite <= '1';
                write_enable <= '1';  -- Enable write-back
                write_back_data <= alu_result;
				MEM_WB_RegWrite <= EXE_MEM_RegWrite;
            end if;
        end if;
    end process;

end tb;
