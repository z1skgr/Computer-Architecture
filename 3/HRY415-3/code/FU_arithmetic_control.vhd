library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity FU_arithmetic_control is
    Port ( grant : in  STD_LOGIC;
           request : out  STD_LOGIC;
           stage1_enable : out  STD_LOGIC;
           stage2_enable: out  STD_LOGIC;
           ready : out  STD_LOGIC;
           tag_start : in  STD_LOGIC_VECTOR (4 downto 0);
           tag_mid : in  STD_LOGIC_VECTOR (4 downto 0));
end FU_arithmetic_control;

architecture Behavioral of FU_arithmetic_control is

begin
	
	process (tag_start, tag_mid, grant)
	begin
	
		if not(tag_start = "00000") then
			-- exoun kai ta duo epipeda kataxwrhtwn egkurh entolh
			if not(tag_mid = "00000") then
				request <= '1';
				if grant = '1' then
					ready <= '1';
					stage1_enable <= '1';
					stage2_enable <= '1';
				-- den pernei grant kai blockarei olo to pipeline tou
				else
					ready <= '0';
					stage1_enable <= '0';
					stage2_enable <= '0';
				end if;
			-- exei mono to prwto epipedo kataxwrhtwn egkurh entolh
			else
				request <= '0';
				stage1_enable <= '1';
				stage2_enable <= '1';
				ready <= '1';
			end if;
		
		else
			-- exei mono to deutero epipedo entolh, ara to prwto einai panta dia8esimo
			if not(tag_mid = "00000") then
				request <= '1';
				ready <= '1';
				stage1_enable <= '1';
				if grant = '1' then
					stage2_enable <= '1';
				-- den pernei grant kai blockarei mono to deutero epipedo kataxwrhtwn.
				else 
					stage2_enable <= '0';
				end if;
				
			-- den exei kanena epipedo entolh
			else
				request <= '0';
				ready <= '1';
				stage1_enable <= '1';
				stage2_enable <= '1';
			end if;
		end if;
			
	end process;
	
end Behavioral;

