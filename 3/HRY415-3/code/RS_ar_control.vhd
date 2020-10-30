library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity RS_arithmetic_control is
   Port ( 
		Clk : in  STD_LOGIC;
		IssueRs : in  STD_LOGIC;
		available : out  STD_LOGIC;
		RS_line_select : out  STD_LOGIC_VECTOR (1 downto 0);
		readyFU : in  STD_LOGIC;
		control_enable : out  STD_LOGIC_VECTOR (2 downto 0);
		busy_enable : out  STD_LOGIC_VECTOR (2 downto 0);
		ready_for_exec : in  STD_LOGIC_VECTOR (2 downto 0);
		busy_line : in  STD_LOGIC_VECTOR (2 downto 0));
end RS_arithmetic_control;

architecture Behavioral of RS_arithmetic_control is

type state is (RS_line_A, RS_line_B, RS_line_C, RS_line_0);
signal currentState, nextState: state;

signal busy_enable_in, busy_enable_out, control_enable_out : STD_LOGIC_VECTOR (2 downto 0);
signal line_select : STD_LOGIC_VECTOR (1 downto 0);

begin
	
	-- pia entolh 8a stal8ei gia ektelesh
	RS_line_select <= line_select;
	
	-- mhdenizetai otan den iparxou eleu8eres grammes kai den eleu8erwnetai kapia twra.
	available <= '0' when busy_line = "111" and busy_enable_out = "000" else '1';
	
	-- enable tou busy reg. Energopoieitai otan erxetai kainourgia entolh 'h diagrafetai.
	busy_enable <= busy_enable_in or busy_enable_out;
	
	-- enable twn ipoloipwn kataxwrhtwn. Energopoieitai otan diagrafetai h entolh.
	control_enable <= control_enable_out;

	-- eisodos entolwn
	eisodos_entolwn : process(IssueRs, busy_line, busy_enable_out)
	begin
		-- hr8e entolh
		if IssueRs = '1' then
			-- bazw thn entolh sth prwth grammh kataxwrhtwn
			if busy_line(0) = '0' or busy_enable_out(0) = '1' then
				control_enable_out <= "001";
				busy_enable_in <= "001";
			-- bazw thn entolh sth deuterh grammh kataxwrhtwn
			elsif busy_line(1) = '0' or busy_enable_out(1) = '1' then
				control_enable_out <= "010";
				busy_enable_in <= "010";
			-- bazw thn entolh sth trith grammh kataxwrhtwn
			elsif busy_line(2) = '0' or busy_enable_out(2) = '1' then
				control_enable_out <= "100";
				busy_enable_in <= "100";
			-- den mpainei h entolh pou8ena(gia ta latch)
			else
				control_enable_out <= "000";
				busy_enable_in <= "000";
			end if;
		-- den hr8e entolh
		else
			control_enable_out <= "000";
			busy_enable_in <= "000";
		end if;
	end process;

	-- apostolh entolwn sto FU
	apostolh_entolwn : process(ready_for_exec, readyFU, currentState)
	begin

		if readyFU = '1' then
			case ready_for_exec is
			
				-- xwris sigkrouseis
				when "100" =>
					busy_enable_out <= "100";
					line_select <= "10";
					
				when "010" =>				
					busy_enable_out <= "010";
					line_select <= "01";
					
				when "001" =>
					busy_enable_out <= "001";
					line_select <= "00";

				--	me sigkrouseis	
				when "011" =>
					if currentState = RS_line_B then
						busy_enable_out <= "001";
						line_select <= "00";		
					else 					
						busy_enable_out <= "010";
						line_select <= "01";			
					end if;
						
				when "101" =>
					if currentState = RS_line_A then 
						busy_enable_out <= "001";
						line_select <= "00";						
					else 
						busy_enable_out <= "100";
						line_select <= "10";				
					end if;
					
				when "110" =>
					if currentState = RS_line_A then 
						busy_enable_out <= "010";
						line_select <= "01";	
					else 
						busy_enable_out <= "100";
						line_select <= "10";		
					end if;
					
				when "111" =>
					if currentState = RS_line_A then 
						busy_enable_out <= "010";
						line_select <= "01";	
					elsif currentState = RS_line_B then
						busy_enable_out <= "001";
						line_select <= "00";			
					else 
						busy_enable_out <= "100";
						line_select <= "10";
					end if;
					
				--	kanenas	
				when others =>
					busy_enable_out <= "000";
					line_select <= "11";
			end case;	
		-- den einai to fu etoimo
		else
			line_select <= "11";
			busy_enable_out <= "000";
		end if;
	end process;

	-- 8imatai pios esteile sto fu ton proigoumeno kuklo
	round_robbing_mem: process (currentState, line_select, Clk)
	begin

		if  line_select = "00" then
			nextState <= RS_line_C;
		elsif line_select = "01" then
			nextState <= RS_line_B;
		elsif line_select = "10" then
			nextState <= RS_line_A;
		else 
			nextState <= RS_line_0;
		end if;

	end process;
	
	-- roloi
	FSM_CLOCK:  PROCESS (Clk)
	begin
		if (rising_edge(Clk)) then 
			currentState <= nextState;
		end if;
	end process;

end Behavioral;

