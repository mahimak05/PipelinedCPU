library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU_tb is
end ALU_tb;

architecture testbench of ALU_tb is
    -- Signals to connect to the ALU
    signal clk          : std_logic := '0';
    signal reset        : std_logic := '0';
    signal instruction  : std_logic_vector(24 downto 0) := (others => '0');
    signal rs1, rs2, rs3 : std_logic_vector(127 downto 0) := (others => '0');
    signal rd           : std_logic_vector(127 downto 0) := (others => '0');
    signal we           : std_logic := '0';	  
	--signal temp_load    : std_logic_vector(127 downto 0);
    signal immediate    : std_logic_vector(15 downto 0);
    signal load_in      : std_logic_vector(2 downto 0);	 
	
	 -- Clock period definitions
    constant clk_period : time := 10 ns;

    -- Constants for saturation limits
    constant MAX_32BIT : std_logic_vector(31 downto 0) := std_logic_vector(to_signed(2**31 - 1, 32));
    constant MIN_32BIT : std_logic_vector(31 downto 0) := std_logic_vector(to_signed(-2**31, 32));
    constant MAX_64BIT : std_logic_vector(63 downto 0) := std_logic_vector(to_signed(2**63 - 1, 64));
    constant MIN_64BIT : std_logic_vector(63 downto 0) := std_logic_vector(to_signed(-2**63, 64));

    -- Instantiate the ALU component
    component ALU
        port (
            clk          : in  std_logic;
            reset        : in  std_logic;
            instruction  : in  std_logic_vector(24 downto 0);
            rs1, rs2, rs3 : in std_logic_vector(127 downto 0);
            rd           : inout std_logic_vector(127 downto 0);
            we           : in std_logic
        );
    end component;

begin
    -- Instantiate ALU
    uut: ALU
        port map (
            clk => clk,
            reset => reset,
            instruction => instruction,
            rs1 => rs1,
            rs2 => rs2,
            rs3 => rs3,
            rd => rd,
            we => we
        );

      -- Clock process
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period / 2;
        clk <= '1';
        wait for clk_period / 2;
    end process;

    -- Test process
    stimulus_process: process
    begin
        -- Apply reset
        reset <= '1';
        wait for 20 ns;
        reset <= '0';

         --Test Case 1: Signed Integer Multiply-Add Low (16-bit) with Saturation
        instruction <= "1000000000000000000000000"; -- Code "000" for Signed Integer Multiply-Add Low
        rs1(31 downto 0) <= std_logic_vector(to_signed(5, 32));
        rs2(15 downto 0) <= std_logic_vector(to_signed(3, 16));
        rs3(15 downto 0) <= std_logic_vector(to_signed(4, 16));
        we <= '1';
           wait for clk_period;

       
       
         --Test Case 2: Signed Integer Multiply-Add High (16-bit) with Saturation
        instruction <= "1000100000000000000000000"; -- Opcode "001" for Signed Integer Multiply-Add High
        rs1(31 downto 0) <= std_logic_vector(to_signed(3, 32));
        rs2(31 downto 16) <= std_logic_vector(to_signed(4, 16));
        rs3(31 downto 16) <= std_logic_vector(to_signed(5, 16));
        we <= '1';
          wait for clk_period; wait for 20 ns;



        -- Test Case 3: Signed Integer Multiply-Subtract Low (16-bit) with Saturation
        instruction <= "1001000000000000000000000"; -- Opcode "010" for Signed Integer Multiply-Subtract Low
        rs1(31 downto 0) <= std_logic_vector(to_signed(15, 32));
        rs2(15 downto 0) <= std_logic_vector(to_signed(2, 16));
        rs3(15 downto 0) <= std_logic_vector(to_signed(5, 16));
        we <= '1';
           wait for clk_period;


        -- Test Case 4: Signed Integer Multiply-Subtract High (16-bit) with Saturation
        instruction <= "1001100000000000000000000"; -- Opcode "011" for Signed Integer Multiply-Subtract High
        rs1(31 downto 0) <= std_logic_vector(to_signed(50, 32));
        rs2(31 downto 16) <= std_logic_vector(to_signed(9, 16));
        rs3(31 downto 16) <= std_logic_vector(to_signed(6, 16));
        we <= '1';
          wait for clk_period;

        -- Test Case 5: Signed Long Integer Multiply-Add Low (32-bit) with Saturation
        instruction <= "1010000000000000000000000"; -- Opcode "100" for Signed Long Integer Multiply-Add Low
        rs1(63 downto 0) <= std_logic_vector(to_signed(3, 64));
        rs2(31 downto 0) <= std_logic_vector(to_signed(2, 32));
        rs3(31 downto 0) <= std_logic_vector(to_signed(10, 32));
        we <= '1';
           wait for clk_period;

      

        -- Test Case 6: Signed Long Integer Multiply-Add High (32-bit) with Saturation
        instruction <= "1010100000000000000000000"; -- Opcode "101" for Signed Long Integer Multiply-Add High
        rs1(63 downto 0) <= std_logic_vector(to_signed(5, 64));
        rs2(63 downto 32) <= std_logic_vector(to_signed(8, 32));
        rs3(63 downto 32) <= std_logic_vector(to_signed(30, 32));
        we <= '1';
         wait for clk_period;


        -- Test Case 7: Signed Long Integer Multiply-Subtract Low (32-bit) with Saturation
        instruction <= "1011000000000000000000000"; -- Opcode "110" for Signed Long Integer Multiply-Subtract Low
        rs1(63 downto 0) <= std_logic_vector(to_signed(40, 64));
        rs2(31 downto 0) <= std_logic_vector(to_signed(3, 32));
        rs3(31 downto 0) <= std_logic_vector(to_signed(10, 32));
        we <= '1';
           wait for clk_period;


               -- Test Case 8: Signed Long Integer Multiply-Subtract High (32-bit) with Saturation
        instruction <= "1011100000000000000000000"; -- Opcode "111" for Signed Long Integer Multiply-Subtract High
        rs1(63 downto 0) <= std_logic_vector(to_signed(90, 64));
        rs2(63 downto 32) <= std_logic_vector(to_signed(12, 32));
        rs3(63 downto 32) <= std_logic_vector(to_signed(6, 32));
        we <= '1';
           wait for clk_period;


        -- Test each instruction:
        -- Use rs1 and rs2 with distinct values for easier verification of operations.

        -- Test NOP
        instruction <= "1100000000000000000000000"; -- opcode = "0000"
        wait for clk_period;

        -- Test SLHI
        rs1 <= x"00010002000300040005000600070008"; -- Arbitrary halfword values
        instruction <= "1100000001101000011000000"; -- opcode = "0001", shift amount in addr2
        wait for clk_period;

        -- Test AU (Add unsigned)
        rs1 <= x"00010002000300040005000600070008";
        rs2 <= x"00080007000600050004000300020001";
        instruction <= "1100100000000000000000000"; -- opcode = "0010"
        wait for clk_period;

        -- Test CNT1H (Count ones in each halfword)
        rs1 <= x"FFFF0000FFFF0000FFFF0000FFFF0000"; -- Halfwords with ones to count
        instruction <= "1100110000000000000000000"; -- opcode = "0011"
        wait for clk_period;

        -- Test AHS (Add Halfword Saturated)
        rs1 <= x"7FFF7FFF7FFF7FFF7FFF7FFF7FFF7FFF"; -- Max positive halfword values
        rs2 <= x"00010001000100010001000100010001"; -- Small values to add
        instruction <= "1101000000000000000000000"; -- opcode = "0100"
        wait for clk_period;

        -- Test AND (Bitwise logical AND)
        rs1 <= x"FFFF0000FFFF0000FFFF0000FFFF0000";
        rs2 <= x"0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F";
        instruction <= "1101010000000000000000000"; -- opcode = "0101"
        wait for clk_period;

        -- Test BCW (Broadcast word)
        rs1 <= x"00000000000000000000000000000001"; -- Only the rightmost word has a non-zero value
        instruction <= "1101100000000000000000000"; -- opcode = "0110"
        wait for clk_period;

        -- Test MAXWS (Max signed word)
        rs1 <= x"7FFFFFFF800000007FFFFFFF80000000"; -- Mixed max and min signed values
        rs2 <= x"800000007FFFFFFF800000007FFFFFFF";
        instruction <= "1101110000000000000000000"; -- opcode = "0111"
        wait for clk_period;

        -- Test MINWS (Min signed word)
        instruction <= "1110000000000000000000000"; -- opcode = "1000"
        wait for clk_period;

        -- Test MLHU (Multiply low unsigned)
        rs1 <= x"00010002000300040005000600070008"; -- Sample values in each halfword
        rs2 <= x"00080007000600050004000300020001";
        instruction <= "1110010000000000000000000"; -- opcode = "1001"
        wait for clk_period;
		
        -- Test MLHCU (Multiply low by constant unsigned)
        rs1 <= x"00010102003300040005000600070008"; -- Sample values in each halfword
        instruction <= "1100001010011011101000101"; -- opcode = "1010"
        wait for clk_period;

		-- Test OR (Bitwise logical OR)
        rs1 <= x"FFFF0000FFFF0000FFFF0000FFFF0000";
        rs2 <= x"0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F0F";
        instruction <= "1110110000000000000000000"; -- opcode = "1011"
        wait for clk_period;
	
        -- Test Count Leading Zeros (CLZH)
        rs1 <= x"0000FFFF0000FFFF0000FFFF0000FFFF"; -- Alternating halfwords
		instruction <= "1111000000000000000000000"; -- opcode = "1100"
        wait for clk_period;
	
        -- Test Rotate Left Halfwords (RLH)
        rs1 <= x"00010002000300040005000600070008"; -- Halfword values
        rs2 <= x"00010001000100010001000100010001"; -- Shift amounts per halfword
		instruction <= "1111010000000000000000000"; -- opcode = "1101"
		wait for clk_period;

        -- Test Subtract from Word Unsigned
        rs1 <= x"00010002000300040005000600070008"; -- Minuends
        rs2 <= x"00080007000600050004000300020001"; -- Subtrahends
        instruction <= "1111100000000000000000000"; -- opcode = "1110"
        wait for clk_period;

        -- Test Subtract from Halfword Saturated (SFHS)
        rs1 <= x"80008000800080008000800080008000"; -- Large negative halfwords
        rs2 <= x"00010001000100010001000100010001"; -- Small positive halfwords
        instruction <= "1111110000000000000000000"; -- opcode = "1111"
        wait for clk_period;


        -- End of all test cases, stop simulation
        report "All test cases completed successfully." severity note;
        wait;
    end process stimulus_process;
	 process
    begin
         -- Initialize
        instruction <= "0000000000000000000000000";
        
        -- Test Case 1
        immediate <= "0000000000000001"; -- Test value for immediate
        load_in <= "000"; -- Load into rd(15 downto 0)
         wait for clk_period;
        
        -- Test Case 2
        load_in <= "001"; -- Load into rd(31 downto 16)
        wait for clk_period;
        
        -- Test Case 3
        load_in <= "010"; -- Load into rd(47 downto 32)
         wait for clk_period;

        -- Test Case 4
        load_in <= "011"; -- Load into rd(63 downto 48)
         wait for clk_period;

        -- Test Case 5
        load_in <= "100"; -- Load into rd(79 downto 64)
        wait for clk_period;

        -- Test Case 6
        load_in <= "101"; -- Load into rd(95 downto 80)
         wait for clk_period;

        -- Test Case 7
        load_in <= "110"; -- Load into rd(111 downto 96)
         wait for clk_period;

        -- Test Case 8
        load_in <= "111"; -- Load into rd(127 downto 112)
         wait for clk_period;

        -- End of simulation
        wait;
    end process;
end architecture testbench;

