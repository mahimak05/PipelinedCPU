library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL; 
use work.all;

entity Register_File_tb is
end Register_File_tb;

architecture Behavioral of Register_File_tb is
    -- Signals to connect to Register_File
    signal clk : STD_LOGIC := '0';
    signal reset : STD_LOGIC := '0';
    signal read_addr1, read_addr2, read_addr3 : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    signal write_addr : STD_LOGIC_VECTOR(4 downto 0) := (others => '0');
    signal write_data : STD_LOGIC_VECTOR(127 downto 0) := (others => '0');
    signal write_enable : STD_LOGIC := '0';
    signal read_data1, read_data2, read_data3 : STD_LOGIC_VECTOR(127 downto 0);

    -- Clock generation process
    constant clk_period : time := 10 ns;

begin

    -- Instantiate the Register_File
    uut: entity Register_File
        port map (
            clk => clk,
            reset => reset,
            read_addr1 => read_addr1,
            read_addr2 => read_addr2,
            read_addr3 => read_addr3,
            write_addr => write_addr,
            write_data => write_data,
            write_enable => write_enable,
            read_data1 => read_data1,
            read_data2 => read_data2,
            read_data3 => read_data3
        );

    -- Clock process to generate a clock signal
    clk_process: process
    begin
        while True loop
            clk <= '0';
            wait for clk_period / 2;
            clk <= '1';
            wait for clk_period / 2;
        end loop;
    end process;

    -- Test process
    test_process: process
    begin
        -- Reset all registers
        reset <= '1';
        wait for clk_period;
        reset <= '0';

        -- Write data to register 1
        write_addr <= "00001";
        write_data <= X"0123456789ABCDEF0123456789ABCDEF";
        write_enable <= '1';
        wait for clk_period;

        -- Disable write and read from register 1
        write_enable <= '0';
        read_addr1 <= "00001";
        wait for clk_period;

        -- Check read_data1 output
        assert read_data1 = X"0123456789ABCDEF0123456789ABCDEF"
        report "Error: Data read from register 1 is incorrect!" severity error;

        -- Write data to another register (e.g., register 2)
        write_addr <= "00010";
        write_data <= X"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF";
        write_enable <= '1';
        wait for clk_period;

        -- Disable write and read from registers 1 and 2
        write_enable <= '0';
        read_addr1 <= "00001";
        read_addr2 <= "00010";
        wait for clk_period;

        -- Check read_data1 and read_data2 outputs
        assert read_data1 = X"0123456789ABCDEF0123456789ABCDEF"
        report "Error: Data read from register 1 is incorrect after write to register 2!" severity error;
        assert read_data2 = X"FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"
        report "Error: Data read from register 2 is incorrect!" severity error;

        -- Read from a register that has not been written to
        read_addr3 <= "00011";
        wait for clk_period;

        -- Check read_data3 output
        assert read_data3 = (127 downto 0 => '0')
		report "Error: Data read from unused register is not zero!" severity error;


        -- Finish simulation
        wait for 10 * clk_period;
        report "Testbench completed successfully!" severity note;
        wait;
    end process;

end Behavioral;
