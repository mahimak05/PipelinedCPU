library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
Use work.all;

entity Forwarding_Unit is
    Port (
        EXE_MEM_RegWrite : in STD_LOGIC;          -- RegWrite signal from EXE/MEM stage
        MEM_WB_RegWrite  : in STD_LOGIC;          -- RegWrite signal from MEM/WB stage
        EXE_MEM_Rd       : in STD_LOGIC_VECTOR(127 downto 0); -- Destination register from EXE/MEM stage
        MEM_WB_Rd        : in STD_LOGIC_VECTOR(127 downto 0); -- Destination register from MEM/WB stage
        ID_EXE_Rs1       : in STD_LOGIC_VECTOR(127 downto 0); -- Source register Rs1 in ID/EXE stage
        ID_EXE_Rs2       : in STD_LOGIC_VECTOR(127 downto 0); -- Source register Rs2 in ID/EXE stage
        ForwardA         : out STD_LOGIC_VECTOR(1 downto 0); -- Forwarding signal for operand A
        ForwardB         : out STD_LOGIC_VECTOR(1 downto 0)  -- Forwarding signal for operand B
    );
end Forwarding_Unit;

architecture Behavioral of Forwarding_Unit is
begin
    process(EXE_MEM_RegWrite, MEM_WB_RegWrite, EXE_MEM_Rd, MEM_WB_Rd, ID_EXE_Rs1, ID_EXE_Rs2)
    begin
        -- Default forwarding values (no forwarding)
        ForwardA <= "00";
        ForwardB <= "00";

        -- Check for forwarding conditions for operand A
        if (EXE_MEM_RegWrite = '1' and EXE_MEM_Rd /= "00000" and EXE_MEM_Rd = ID_EXE_Rs1) then
            ForwardA <= "10"; -- Forward from EXE/MEM stage
        elsif (MEM_WB_RegWrite = '1' and MEM_WB_Rd /= "00000" and MEM_WB_Rd = ID_EXE_Rs1) then
            ForwardA <= "01"; -- Forward from MEM/WB stage
        end if;

        -- Check for forwarding conditions for operand B
        if (EXE_MEM_RegWrite = '1' and EXE_MEM_Rd /= "00000" and EXE_MEM_Rd = ID_EXE_Rs2) then
            ForwardB <= "10"; -- Forward from EXE/MEM stage
        elsif (MEM_WB_RegWrite = '1' and MEM_WB_Rd /= "00000" and MEM_WB_Rd = ID_EXE_Rs2) then
            ForwardB <= "01"; -- Forward from MEM/WB stage
        end if;
    end process;
end Behavioral;
