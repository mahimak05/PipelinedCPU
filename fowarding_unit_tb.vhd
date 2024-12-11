library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_forwarding_unit is
end tb_forwarding_unit;

architecture behavior of tb_forwarding_unit is
    -- Signals for the inputs and outputs
    signal EXE_MEM_Rd : std_logic_vector(127 downto 0) := (others => '0');
    signal MEM_WB_Rd : std_logic_vector(127 downto 0) := (others => '0');
    signal ID_EXE_Rs1 : std_logic_vector(127 downto 0) := (others => '0');
    signal ID_EXE_Rs2 : std_logic_vector(127 downto 0) := (others => '0');
    signal EXE_MEM_RegWrite : std_logic := '0';
    signal MEM_WB_RegWrite : std_logic := '0';
    signal ForwardA : std_logic_vector(1 downto 0);
    signal ForwardB : std_logic_vector(1 downto 0);

begin
    -- Instantiate the forwarding unit
    uut: entity work.Forwarding_Unit
        port map (
            EXE_MEM_RegWrite => EXE_MEM_RegWrite,
            MEM_WB_RegWrite => MEM_WB_RegWrite,
            EXE_MEM_Rd => EXE_MEM_Rd,
            MEM_WB_Rd => MEM_WB_Rd,
            ID_EXE_Rs1 => ID_EXE_Rs1,
            ID_EXE_Rs2 => ID_EXE_Rs2,
            ForwardA => ForwardA,
            ForwardB => ForwardB
        );

    -- Test process
    process
    begin
        -- Test Case 1: No forwarding required
        EXE_MEM_Rd <= (others => '0'); -- Register doesn't match Rs1/Rs2
        MEM_WB_Rd <= (others => '0'); -- Register doesn't match Rs1/Rs2
        ID_EXE_Rs1 <= x"00000000000000000000000000000000";
        ID_EXE_Rs2 <= x"00000000000000000000000000000001";
        EXE_MEM_RegWrite <= '0';
        MEM_WB_RegWrite <= '0';
        wait for 10 ns;
        assert ForwardA = "00" and ForwardB = "00"
            report "Test Case 1 Failed" severity error;

        -- Test Case 2: Forward from EXE/MEM to Rs1
        EXE_MEM_Rd <= x"00000000000000000000000000000001";
        MEM_WB_Rd <= x"00000000000000000000000000000010";
        ID_EXE_Rs1 <= x"00000000000000000000000000000001";
        ID_EXE_Rs2 <= x"00000000000000000000000000000011";
        EXE_MEM_RegWrite <= '1';
        MEM_WB_RegWrite <= '0';
        wait for 10 ns;
        assert ForwardA = "10" and ForwardB = "00"
            report "Test Case 2 Failed" severity error;

        -- Test Case 3: Forward from MEM/WB to Rs2
        EXE_MEM_Rd <= x"00000000000000000000000000000100";
        MEM_WB_Rd <= x"00000000000000000000000000000011";
        ID_EXE_Rs1 <= x"00000000000000000000000000000100";
        ID_EXE_Rs2 <= x"00000000000000000000000000000011";
        EXE_MEM_RegWrite <= '0';
        MEM_WB_RegWrite <= '1';
        wait for 10 ns;
        assert ForwardA = "00" and ForwardB = "01"
            report "Test Case 3 Failed" severity error;

        -- Test Case 4: Forward from both EXE/MEM and MEM/WB
        EXE_MEM_Rd <= x"00000000000000000000000000000101";
        MEM_WB_Rd <= x"00000000000000000000000000000110";
        ID_EXE_Rs1 <= x"00000000000000000000000000000101";
        ID_EXE_Rs2 <= x"00000000000000000000000000000110";
        EXE_MEM_RegWrite <= '1';
        MEM_WB_RegWrite <= '1';
        wait for 10 ns;
        assert ForwardA = "10" and ForwardB = "01"
            report "Test Case 4 Failed" severity error;

        -- End of test
        wait;
    end process;
end behavior;
