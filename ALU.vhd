library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity ALU is
    port (
        clk         	: in  std_logic;                        
        reset       	: in  std_logic;                        
        instruction 	: in  std_logic_vector(24 downto 0);
        rs1, rs2, rs3   : in std_logic_vector(127 downto 0);      
        rd         	    : inout std_logic_vector(127 downto 0);  
        we          	: in std_logic                         
    );
end ALU;

architecture structural of ALU is
	signal addr1, addr2, addr3, addrd : std_logic_vector(4 downto 0);
	signal opcode : std_logic_vector(3 downto 0); 
	signal code : std_logic_vector(2 downto 0);
	signal product32   : signed(31 downto 0):= (others => '0');  -- Initialize to zero
    signal result32    : signed(31 downto 0):= (others => '0');  -- Initialize to zero
	signal product64   : signed(63 downto 0):= (others => '0');  -- Initialize to zero
    signal result64   : signed(63 downto 0) := (others => '0');  -- Initialize to zero	
	signal immediate   : std_logic_vector(15 downto 0);
	signal load_in     : std_logic_vector(2 downto 0);
	signal temp_load   :std_logic_vector(127 downto 0);

	

--    component rf is
--        port(
--            rs1, rs2, rs3          : in  std_logic_vector(127 downto 0); 
--            addr1, addr2, addr3, addrd	   : in  std_logic_vector(4 downto 0);   
--            clk, reset        	   : in  std_logic;
--            rd                 	   : out std_logic_vector(127 downto 0); 
--            we                	   : in  std_logic 
--        );
--    end component;	
	
	 -- Function to count leading zeros in a 16-bit halfword
	function count_leading_zeros(data: std_logic_vector(15 downto 0)) return integer is
    		variable count: integer := 0;
	begin
    		for i in 15 downto 0 loop
	        if data(i) = '1' then
	            return count;
	        else
	            count := count + 1;
	        end if;
	    end loop;
	   return 16;  -- If no '1' was found, return 16
	end function;
	
	-- Rotate left function for 16-bit fields
    function rotate_left(data: std_logic_vector(15 downto 0); shift_amt: integer) return std_logic_vector is
    begin
        return data(15 - shift_amt downto 0) & data(15 downto 16 - shift_amt);
    end function; 
	
	-- Saturated function
	function Saturate(input: SIGNED(31 downto 0)) return SIGNED is
    constant MAX_VAL : SIGNED(31 downto 0) := to_signed(2**31 - 1, 32);  -- 2^31 - 1
    constant MIN_VAL : SIGNED(31 downto 0) := to_signed(-2**31, 32);      -- -2^31
begin
    if input > MAX_VAL then
        return MAX_VAL;
    elsif input < MIN_VAL then
        return MIN_VAL;
    else
        return input;
    end if;
end function;


begin
    process(instruction)
    begin 
		if instruction(24) = '0' then
			load_in <= instruction(23 downto 21);
			immediate <= instruction (20 downto 5);
			addrd <= instruction(4 downto 0);
		elsif instruction(24 downto 23) = "11" then
			opcode <= instruction(18 downto 15);
	        addr2 <= instruction(14 downto 10);  
	        addr1 <= instruction(9 downto 5);    
	        addrd <= instruction(4 downto 0);
		elsif instruction(24 downto 23) = "10" then
			code <= instruction(22 downto 20);
	        addr3 <= instruction(19 downto 15); 
			addr2 <= instruction(14 downto 10);  
	        addr1 <= instruction(9 downto 5);    
	        addrd <= instruction(4 downto 0);
		end if;
    end process;

    --ALU Operations based on opcode
    process(opcode, rs1, rs2, clk, we, reset) --this process executes whenever any of these signals are changed.	   
		constant MAX_16BIT : integer := 32767;
   	 	constant MIN_16BIT : integer := -32768;	
		constant MAX_32BIT : signed(31 downto 0) := to_signed(2**31 - 1, 32);
    	constant MIN_32BIT : signed(31 downto 0) := to_signed(-2**31, 32);
		constant MAX_64BIT : signed(63 downto 0) := to_signed(2**63 - 1, 64);
   	    constant MIN_64BIT : signed(63 downto 0) := to_signed(-2**63, 64);
        variable result : integer;  -- Temporary variable for holding the result of each subtraction	
		variable temp_product32 : signed(31 downto 0) := (others => '0'); -- Initialize to zero
        variable temp_result32 : signed(31 downto 0) := (others => '0');  -- Initialize to zero		   
		variable temp_product64 : signed(63 downto 0) := (others => '0'); -- Initialize to zero
        variable temp_result64 : signed(63 downto 0) := (others => '0');  -- Initialize to zero
		variable count : unsigned(4 downto 0) := (others => '0');
        variable count_ext : std_logic_vector(15 downto 0) := (others => '0');
		
    begin
    if reset = '1' then
    	rd <= (others => '0');
	elsif ((rising_edge(clk)) and (we = '1')) then	--the operations are performed simultaneously the values for rs1 and rs2
		--are stored into the correct place in the vector. 
		
	-- Check if bits [24:23] of the instruction are "10"
        if instruction(24 downto 23) = "10" then
            case instruction(22 downto 20) is
                -- 16-bit Multiply-Add Low with Saturation
			   
				-- Signed Integer Multiply-Add Low with Saturation
				when "000" =>  
					temp_product32 := signed(rs2(15 downto 0)) * signed(rs3(15 downto 0));	
               	 	product32 <= temp_product32;
					temp_result32 := signed(rs1(31 downto 0)) + temp_product32;	 
					result32 <= temp_result32;
					
				--saturation test
					if result32 > MAX_32BIT then
            			rd(31 downto 0) <= std_logic_vector(MAX_32BIT);
       				elsif result32 < MIN_32BIT then
            			rd(31 downto 0) <= std_logic_vector(MIN_32BIT);
      				else
            			rd(31 downto 0) <= std_logic_vector(temp_result32);
        			end if;
				  
				-- Signed Integer Multiply-Add High with Saturation: 
				when "001" =>  	 
					temp_product32 := signed(rs2(31 downto 16)) * signed(rs3(31 downto 16));	
              	    product32 <= temp_product32;
					temp_result32 := signed(rs1(31 downto 0)) + temp_product32;	 
					result32 <= temp_result32;
				
				--saturation test
					if result32 > MAX_32BIT then
            			rd(31 downto 0) <= std_logic_vector(MAX_32BIT);
       				elsif result32 < MIN_32BIT then
            			rd(31 downto 0) <= std_logic_vector(MIN_32BIT);
      				else
            			rd(31 downto 0) <= std_logic_vector(temp_result32);
        			end if;
----					
			--   	-- Signed Integer Multiply-Subtract Low with Saturation
				when "010" =>  
					temp_product32 := signed(rs2(15 downto 0)) * signed(rs3(15 downto 0));	
              	    product32 <= temp_product32;
					temp_result32 := signed(rs1(31 downto 0)) - temp_product32;	 
					result32 <= temp_result32;
               		
				--saturation test
					if result32 > MAX_32BIT then
            			rd(31 downto 0) <= std_logic_vector(MAX_32BIT);
       				elsif result32 < MIN_32BIT then
            			rd(31 downto 0) <= std_logic_vector(MIN_32BIT);
      				else
            			rd(31 downto 0) <= std_logic_vector(temp_result32);
        			 end if;
					 
			 -- --Signed Integer Multiply-Subtract High with Saturation
			  when "011" =>  
				    temp_product32 := signed(rs2(31 downto 16)) * signed(rs3(31 downto 16));	
                	product32 <= temp_product32;
					temp_result32 := signed(rs1(31 downto 0)) - temp_product32;	 
					result32 <= temp_result32;
                		  
			--saturation test
					if result32 > MAX_32BIT then
            			rd(31 downto 0) <= std_logic_vector(MAX_32BIT);
       				elsif result32 < MIN_32BIT then
            			rd(31 downto 0) <= std_logic_vector(MIN_32BIT);
      				else
            			rd(31 downto 0) <= std_logic_vector(temp_result32);
        			end if;
--		   
			-- Signed Long Integer Multiply-Add Low with Saturation
			when "100" =>  
					temp_product64 := signed(rs2(31 downto 0)) * signed(rs3(31 downto 0));	
              	    product64 <= temp_product64;
					temp_result64 := signed(rs1(63 downto 0)) + temp_product64 ;	 
					result64 <= temp_result64;	
				
	--			saturation test
					if result64 > MAX_64BIT then
            			rd(63 downto 0) <= std_logic_vector(MAX_64BIT);
       				elsif result64 < MIN_64BIT then
            			rd(63 downto 0) <= std_logic_vector(MIN_64BIT);
      				else
            			rd(63 downto 0) <= std_logic_vector(temp_result64);
        			end if;
					
			when "101" =>  
				  	temp_product64 := signed(rs2(63 downto 32)) * signed(rs3(63 downto 32));	
              	    product64 <= temp_product64;
					temp_result64 := signed(rs1(63 downto 0)) + temp_product64 ;	 
					result64 <= temp_result64;	
				
	--			saturation test
					if result64 > MAX_64BIT then
            			rd(63 downto 0) <= std_logic_vector(MAX_64BIT);
       				elsif result64 < MIN_64BIT then
            			rd(63 downto 0) <= std_logic_vector(MIN_64BIT);
      				else
            			rd(63 downto 0) <= std_logic_vector(temp_result64);
        			end if;
					
			when "110" =>  
				  	temp_product64 := signed(rs2(31 downto 0)) * signed(rs3(31 downto 0));	
              	    product64 <= temp_product64;
					temp_result64 := signed(rs1(63 downto 0)) - temp_product64;	 
					result64 <= temp_result64;	
--				
	--			saturation test
					if result64 > MAX_64BIT then
            			rd(63 downto 0) <= std_logic_vector(MAX_64BIT);
       				elsif result64 < MIN_64BIT then
            			rd(63 downto 0) <= std_logic_vector(MIN_64BIT);
      				else
            			rd(63 downto 0) <= std_logic_vector(temp_result64);
      			   end if;  
					
--					
			when "111" =>  
				 	temp_product64 := signed(rs2(63 downto 32)) * signed(rs3(63 downto 32));	
              	    product64 <= temp_product64;
					temp_result64 := signed(rs1(63 downto 0)) - temp_product64 ;	 
					result64 <= temp_result64;	
--				
--	--			saturation test
					if result64 > MAX_64BIT then
            			rd(63 downto 0) <= std_logic_vector(MAX_64BIT);
       				elsif result64 < MIN_64BIT then
            			rd(63 downto 0) <= std_logic_vector(MIN_64BIT);
      				else
           			rd(63 downto 0) <= std_logic_vector(temp_result64);
       			end if;
					
			  when others =>
                rd <= (others => '0'); 
			end case;
			
--	elsif instruction(24 downto 23) = "11" then
--        case opcode is	
--			
--		when "0000" =>  -- NOP
--            null;
--
--        when "0001" => -- SLHI (Shift left halfword immediate)
--            for i in 0 to 7 loop
--                rd((i * 16 + 15) downto i * 16) <= std_logic_vector(unsigned(rs1((i * 16 + 15) downto i * 16)) sll to_integer(unsigned(addr2(3 downto 0))));
--            end loop;
--
--        when "0010" => -- AU (Add unsigned)
--            for i in 0 to 3 loop
--                rd((i*32 + 31) downto i*32) <= std_logic_vector(unsigned(rs1((i*32 + 31) downto i*32)) + unsigned(rs2((i*32 + 31) downto i*32)));
--            end loop;
--
--		when "0011" => -- CNT1H (Count ones in each halfword)
--            for i in 0 to 7 loop
--                count := (others => '0');
--                count_ext := (others => '0');
--                for j in 0 to 15 loop
--                    if rs1(i * 16 + j) = '1' then
--                        count := count + 1;
--                    end if;
--                end loop;
--                count_ext(4 downto 0) := std_logic_vector(count);
--                count_ext(15 downto 5) := (others => '0');
--                rd((i + 1) * 16 - 1 downto i * 16) <= count_ext;
--            end loop;
--
--        when "0100" => -- AHS (Add Halfword Saturated)
--            for i in 0 to 7 loop
--            	rd((i*16 + 15) downto i*16) <= std_logic_vector(signed(rs1((i*16 + 15) downto i*16)) + signed(rs2((i*16 + 15) downto i*16)));
--        	end loop;
--
--        when "0101" => -- AND (Bitwise logical AND)
--        	rd <= rs1 and rs2;
--
--       	 when "0110" => -- BCW (Broadcast word)
--        	for i in 0 to 3 loop
--            	rd((i*32 + 31) downto i*32) <= rs1(31 downto 0);
--            end loop;
--
--		 when "0111" => -- MAXWS (Max signed word)
--		    for i in 0 to 3 loop
--		        if signed(rs1((i*32 + 31) downto i*32)) > signed(rs2((i*32 + 31) downto i*32)) then
--		            rd((i*32 + 31) downto i*32) <= std_logic_vector(signed(rs1((i*32 + 31) downto i*32)));
--		        else
--		            rd((i*32 + 31) downto i*32) <= std_logic_vector(signed(rs2((i*32 + 31) downto i*32)));
--		        end if;
--		    end loop;
--		
--		 when "1000" => -- MINWS (Min signed word)
--			    for i in 0 to 3 loop
--			        if signed(rs1((i*32 + 31) downto i*32)) < signed(rs2((i*32 + 31) downto i*32)) then
--			            rd((i*32 + 31) downto i*32) <= std_logic_vector(signed(rs1((i*32 + 31) downto i*32)));
--			        else
--			            rd((i*32 + 31) downto i*32) <= std_logic_vector(signed(rs2((i*32 + 31) downto i*32)));
--			        end if;
--			    end loop;
--	
--
--	      when "1001" => -- MLHU (Multiply low unsigned)
--	         	for i in 0 to 3 loop
--	            	rd((i*32 + 31) downto i*32) <= std_logic_vector(unsigned(rs1((i*32 + 15) downto i*32)) * unsigned(rs2((i*32 + 15) downto i*32)));
--	            end loop;
--			
--		  when "1010" =>  -- Multiply low by constant unsigned
--    				rd(31 downto 0)   <= std_logic_vector(unsigned(rs1(15 downto 0)) * unsigned(rs2(15 downto 0)));
--    				rd(63 downto 32)  <= std_logic_vector(unsigned(rs1(47 downto 32)) * unsigned(rs2(47 downto 32)));
--				rd(95 downto 64)  <= std_logic_vector(unsigned(rs1(79 downto 64)) * unsigned(rs2(79 downto 64)));
--    				rd(127 downto 96) <= std_logic_vector(unsigned(rs1(111 downto 96)) * unsigned(rs2(111 downto 96)));	
--		  
--		  when "1011" => -- Bitwise logical or
--		 		rd <= rs1 or rs2;  
--		  
--		  when "1100" =>  -- Count leading zeros in halfwords
--    				rd(127 downto 112) <= std_logic_vector(to_unsigned(count_leading_zeros(rs1(127 downto 112)), 16));
--   				rd(111 downto 96)  <= std_logic_vector(to_unsigned(count_leading_zeros(rs1(111 downto 96)), 16));
--    				rd(95 downto 80)   <= std_logic_vector(to_unsigned(count_leading_zeros(rs1(95 downto 80)), 16));
--    				rd(79 downto 64)   <= std_logic_vector(to_unsigned(count_leading_zeros(rs1(79 downto 64)), 16));
--    				rd(63 downto 48)   <= std_logic_vector(to_unsigned(count_leading_zeros(rs1(63 downto 48)), 16));
--    				rd(47 downto 32)   <= std_logic_vector(to_unsigned(count_leading_zeros(rs1(47 downto 32)), 16));
--    				rd(31 downto 16)   <= std_logic_vector(to_unsigned(count_leading_zeros(rs1(31 downto 16)), 16));
--    				rd(15 downto 0)    <= std_logic_vector(to_unsigned(count_leading_zeros(rs1(15 downto 0)), 16));
--
--			when "1101" => -- Rotate left bits in half words
--				  rd(127 downto 112) <= rotate_left(rs1(127 downto 112), to_integer(unsigned(rs2(115 downto 112))));
--                    rd(111 downto 96)  <= rotate_left(rs1(111 downto 96), to_integer(unsigned(rs2(111 downto 96))));
--                    rd(95 downto 80)   <= rotate_left(rs1(95 downto 80), to_integer(unsigned(rs2(95 downto 80))));
--                    rd(79 downto 64)   <= rotate_left(rs1(79 downto 64), to_integer(unsigned(rs2(79 downto 64))));
--                    rd(63 downto 48)   <= rotate_left(rs1(63 downto 48), to_integer(unsigned(rs2(63 downto 48))));
--                    rd(47 downto 32)   <= rotate_left(rs1(47 downto 32), to_integer(unsigned(rs2(47 downto 32))));
--                    rd(31 downto 16)   <= rotate_left(rs1(31 downto 16), to_integer(unsigned(rs2(31 downto 16))));
--                    rd(15 downto 0)    <= rotate_left(rs1(15 downto 0), to_integer(unsigned(rs2(15 downto 0))));
--			
--			when "1110" =>  -- Subtract from word unsigned
--                    rd(127 downto 96) <= std_logic_vector(unsigned(rs2(127 downto 96)) - unsigned(rs1(127 downto 96)));
--                    rd(95 downto 64)  <= std_logic_vector(unsigned(rs2(95 downto 64)) - unsigned(rs1(95 downto 64)));
--                    rd(63 downto 32)  <= std_logic_vector(unsigned(rs2(63 downto 32)) - unsigned(rs1(63 downto 32)));
--                    rd(31 downto 0)   <= std_logic_vector(unsigned(rs2(31 downto 0)) - unsigned(rs1(31 downto 0)));	
--            
--			 when "1111" =>  -- SFHS: Subtract from halfword saturated
--                    for i in 0 to 7 loop
--                        -- Extract 16-bit segments, convert to signed, perform subtraction
--                        result := to_integer(signed(rs2((i*16+15) downto i*16))) - to_integer(signed(rs1((i*16+15) downto i*16)));
--                        
--                        -- Apply saturation limits
--                        if result > MAX_16BIT then
--                            rd((i*16+15) downto i*16) <= std_logic_vector(to_signed(MAX_16BIT, 16));
--                        elsif result < MIN_16BIT then
--                            rd((i*16+15) downto i*16) <= std_logic_vector(to_signed(MIN_16BIT, 16));
--                        else
--                            rd((i*16+15) downto i*16) <= std_logic_vector(to_signed(result, 16));
--                        end if;
--                    end loop;
--					
--			when others =>
--                rd <= (others => '0'); 
--        end case;
--		elsif instruction(24) = '0' then
--			--Load Immediate based on index
--			temp_load <= rd;
--			
--			case load_in is										 
--			when "000" =>
--				rd(15 downto 0)<= immediate(15 downto 0);
--			when "001" =>
--				rd(31 downto 16)<= immediate(15 downto 0); 
--			when "010" =>
--				rd(47 downto 32)<= immediate(15 downto 0);
--			when "011" =>
--				rd(63 downto 48)<= immediate(15 downto 0);
--			when "100" =>
--				rd(79 downto 64)<= immediate(15 downto 0);
--			when "101" =>
--				rd(95 downto 80)<= immediate(15 downto 0); 
--			when "110" =>
--				rd(111 downto 96)<= immediate(15 downto 0);
--			when "111" =>
--				rd(127 downto 112)<= immediate(15 downto 0); 
--			when others =>
--				rd <= std_logic_vector(to_unsigned(11, 128));
--			end case; 
--		
--	end if;
		end if;
    end process; --Don't actually use this process, nothing in this process actually works yet.

end structural;