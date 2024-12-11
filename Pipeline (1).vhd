library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity Pipeline is
    Port (
        clk : in std_logic;
        reset : in std_logic
    );
end Pipeline;

architecture Behavioral of Pipeline is

    -- Component declarations
    component ALU
        Port (
            clk          : in std_logic;
            reset        : in std_logic;
            instruction  : in std_logic_vector(24 downto 0);
            rs1          : in std_logic_vector(127 downto 0);
            rs2          : in std_logic_vector(127 downto 0);
            rs3          : in std_logic_vector(127 downto 0);
            rd           : out std_logic_vector(127 downto 0);
            we           : in std_logic
        );
    end component;

    component InstructionBuffer
        Port (
            clk           : in std_logic;
            rst           : in std_logic;
            pc            : in std_logic_vector(5 downto 0);
            instruction_out : in std_logic_vector(24 downto 0)
        );
    end component;

    component Register_File
        Port (
            clk          : in std_logic;
            reset        : in std_logic;
            read_addr1   : in std_logic_vector(4 downto 0);
            read_addr2   : in std_logic_vector(4 downto 0);
            read_addr3   : in std_logic_vector(4 downto 0);
            write_addr   : in std_logic_vector(4 downto 0);
            write_data   : in std_logic_vector(127 downto 0);
            write_enable : in std_logic;
            read_data1   : out std_logic_vector(127 downto 0);
            read_data2   : out std_logic_vector(127 downto 0);
            read_data3   : out std_logic_vector(127 downto 0)
        );
    end component;

    component Forwarding_Unit
        Port (
            EXE_MEM_RegWrite : in std_logic;
            MEM_WB_RegWrite  : in std_logic;
            EXE_MEM_Rd       : in std_logic_vector(127 downto 0);
            MEM_WB_Rd        : in std_logic_vector(127 downto 0);
            ID_EXE_Rs1       : in std_logic_vector(127 downto 0);
            ID_EXE_Rs2       : in std_logic_vector(127 downto 0);
            ForwardA         : out std_logic_vector(1 downto 0);
            ForwardB         : out std_logic_vector(1 downto 0)
        );
    end component;

    -- Signal declarations
    signal IF_ID_instr      : std_logic_vector(24 downto 0);
    signal IF_ID_pc         : std_logic_vector(5 downto 0);

    signal ID_EXE_instr     : std_logic_vector(24 downto 0);
    signal ID_EXE_rs1       : std_logic_vector(127 downto 0);
    signal ID_EXE_rs2       : std_logic_vector(127 downto 0);
    signal ID_EXE_rs3       : std_logic_vector(127 downto 0);

    signal EXE_MEM_instr    : std_logic_vector(24 downto 0);
    signal EXE_MEM_result   : std_logic_vector(127 downto 0); -- Actual result from ALU
    signal EXE_MEM_dest_loc : std_logic_vector(4 downto 0);   -- Location of rd
    signal EXE_MEM_RegWrite : std_logic;

    signal MEM_WB_instr     : std_logic_vector(24 downto 0);
    signal MEM_WB_Rd        : std_logic_vector(127 downto 0); -- Actual value of rd
    signal MEM_WB_dest_loc  : std_logic_vector(4 downto 0);   -- Location of rd
    signal MEM_WB_RegWrite  : std_logic;

    signal regfile_out1     : std_logic_vector(127 downto 0);
    signal regfile_out2     : std_logic_vector(127 downto 0);
    signal regfile_out3     : std_logic_vector(127 downto 0);
    signal alu_result       : std_logic_vector(127 downto 0);
    signal we               : std_logic;
    signal ForwardA         : std_logic_vector(1 downto 0);
    signal ForwardB         : std_logic_vector(1 downto 0);

    -- Conditional Signals for Register File
    signal read_addr1, read_addr2, read_addr3, write_addr : std_logic_vector(4 downto 0);

begin

    -- Instruction Fetch
    instruction_buffer_inst : entity work.InstructionBuffer
        port map (
            clk => clk,
            rst => reset,
            pc => IF_ID_pc,
            instruction_out => IF_ID_instr
        );

    -- Conditional Port Mapping for Register File
    process (IF_ID_instr)
    begin
        if IF_ID_instr(24) = '0' then
            write_addr <= IF_ID_instr(4 downto 0);
            read_addr1 <= (others => '0'); -- Not used in this case
            read_addr2 <= (others => '0');
            read_addr3 <= (others => '0');
        elsif IF_ID_instr(24 downto 23) = "10" then
            write_addr <= IF_ID_instr(4 downto 0);
            read_addr1 <= IF_ID_instr(9 downto 5);
            read_addr2 <= IF_ID_instr(14 downto 10);
            read_addr3 <= IF_ID_instr(19 downto 15);
        elsif IF_ID_instr(24 downto 23) = "11" then
            write_addr <= IF_ID_instr(4 downto 0);
            read_addr1 <= IF_ID_instr(9 downto 5);
            read_addr2 <= IF_ID_instr(14 downto 10);
            read_addr3 <= (others => '0'); -- Not used in this case
        else
            -- Default values
            write_addr <= (others => '0');
            read_addr1 <= (others => '0');
            read_addr2 <= (others => '0');
            read_addr3 <= (others => '0');
        end if;
    end process;

    -- Register File
    register_file_inst : entity work.Register_File
        port map (
            clk => clk,
            reset => reset,
            read_addr1 => read_addr1,
            read_addr2 => read_addr2,
            read_addr3 => read_addr3,
            write_addr => MEM_WB_dest_loc, -- Write to correct register
            write_data => MEM_WB_Rd,      -- Write the actual rd value
            write_enable => MEM_WB_RegWrite,
            read_data1 => regfile_out1,
            read_data2 => regfile_out2,
            read_data3 => regfile_out3
        );


    -- ALU
    alu_inst : entity work.ALU
        port map (
            clk => clk,
            reset => reset,
            instruction => IF_ID_instr,
            rs1 => regfile_out1,
            rs2 => regfile_out2,
            rs3 => regfile_out3,
            rd => alu_result,
            we => we
        );

    -- EX to MEM Stage
    process (clk, reset)
    begin
        if reset = '1' then
            EXE_MEM_instr <= (others => '0');
            EXE_MEM_result <= (others => '0');
            EXE_MEM_dest_loc <= (others => '0'); -- Location of rd
            EXE_MEM_RegWrite <= '0';
        elsif rising_edge(clk) then
            EXE_MEM_instr <= ID_EXE_instr;
            EXE_MEM_result <= alu_result;       -- Actual value of rd
            EXE_MEM_dest_loc <= ID_EXE_instr(4 downto 0); -- Location of rd
            EXE_MEM_RegWrite <= '1';           -- Enable write-back
        end if;
    end process;

    -- MEM to WB Stage
    process (clk, reset)
    begin
        if reset = '1' then
            MEM_WB_instr <= (others => '0');
            MEM_WB_Rd <= (others => '0');        -- Reset actual value of rd
            MEM_WB_dest_loc <= (others => '0'); -- Reset location of rd
            MEM_WB_RegWrite <= '0';
        elsif rising_edge(clk) then
            MEM_WB_instr <= EXE_MEM_instr;
            MEM_WB_Rd <= EXE_MEM_result;        -- Forward actual rd value
            MEM_WB_dest_loc <= EXE_MEM_dest_loc; -- Forward location of rd
            MEM_WB_RegWrite <= EXE_MEM_RegWrite;
        end if;
    end process;

    -- Forwarding Unit
    forwarding_unit_inst : entity work.Forwarding_Unit
        port map (
            EXE_MEM_RegWrite => EXE_MEM_RegWrite,
            MEM_WB_RegWrite => MEM_WB_RegWrite,
            EXE_MEM_Rd => EXE_MEM_result, -- Actual rd value
            MEM_WB_Rd => MEM_WB_Rd,      -- Actual rd value from WB
            ID_EXE_Rs1 => ID_EXE_Rs1,
            ID_EXE_Rs2 => ID_EXE_Rs1,
            ForwardA => ForwardA,
            ForwardB => ForwardB
        );

end Behavioral;
