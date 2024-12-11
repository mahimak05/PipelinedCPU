library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.all;

entity Register_File is
    Port (
        clk : in STD_LOGIC;                    -- Clock signal
        reset : in STD_LOGIC;                  -- Reset signal
        read_addr1 : in STD_LOGIC_VECTOR(4 downto 0); -- Read address 1 (5-bit for 32 registers)
        read_addr2 : in STD_LOGIC_VECTOR(4 downto 0); -- Read address 2
        read_addr3 : in STD_LOGIC_VECTOR(4 downto 0); -- Read address 3
        write_addr : in STD_LOGIC_VECTOR(4 downto 0); -- Write address
        write_data : inout STD_LOGIC_VECTOR(127 downto 0); -- Data to write
        write_enable : in STD_LOGIC;           -- Enable write operation
        read_data1 : out STD_LOGIC_VECTOR(127 downto 0); -- Data output 1
        read_data2 : out STD_LOGIC_VECTOR(127 downto 0); -- Data output 2
        read_data3 : out STD_LOGIC_VECTOR(127 downto 0)  -- Data output 3
    );
end Register_File;

architecture Behavioral of Register_File is
    -- 32 registers, each 128 bits wide
    type reg_array is array (0 to 31) of STD_LOGIC_VECTOR(127 downto 0);
    signal registers : reg_array := (others => (others => '0'));

begin

    -- Write process: Synchronous write
    process(clk, reset, write_enable)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                -- Reset all registers to zero
                registers <= (others => (others => '0'));
            elsif write_enable = '1' then
                -- Write data to the specified register
                registers(to_integer(unsigned(write_addr))) <= write_data;
			else 
		        read_data1 <= registers(to_integer(unsigned(read_addr1)));
		        read_data2 <= registers(to_integer(unsigned(read_addr2)));
		        read_data3 <= registers(to_integer(unsigned(read_addr3)));
				write_data <= registers(to_integer(unsigned(write_data)));
            end if;
        end if;
    end process;

end Behavioral;
