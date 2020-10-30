library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity buffer_line is
	Port ( 
		Clk : in  STD_LOGIC;
		-- cdb
		cdb_valid : in  STD_LOGIC;
		cdb_Q : in  STD_LOGIC_VECTOR (4 downto 0);
		cdb_V : in  STD_LOGIC_VECTOR (31 downto 0);
		-- issue
		Ri_in : in  STD_LOGIC_VECTOR (4 downto 0);
		Fu_type_in : in  STD_LOGIC_VECTOR (1 downto 0);
		-- exception
		Exception_out : out  STD_LOGIC;
		PC_entolhs : in  STD_LOGIC_VECTOR (31 downto 0);
		PC_out : out  STD_LOGIC_VECTOR (31 downto 0);
		-- pros control
		Fu_type_out : out  STD_LOGIC_VECTOR (1 downto 0);
		valid_out : out  STD_LOGIC;
		done_out : out  STD_LOGIC;
		-- apo control
		delete : in  STD_LOGIC;
		issue : in  STD_LOGIC;
		-- kataxwrhtes anagnwshs. Gia forward
		Rj : in  STD_LOGIC_VECTOR (4 downto 0);
		Rk : in  STD_LOGIC_VECTOR (4 downto 0);
		-- tag gia forward
		tag : in  STD_LOGIC_VECTOR (4 downto 0);
		tag_out : out  STD_LOGIC_VECTOR (4 downto 0);
		-- flags gia forward. pros control
		j_equal : out  STD_LOGIC;
		k_equal : out  STD_LOGIC;
		-- eksodos gia commit
		Ri_out : out  STD_LOGIC_VECTOR (4 downto 0);
		V_out : out  STD_LOGIC_VECTOR (31 downto 0));
end buffer_line;

architecture Behavioral of buffer_line is

-- gia fu_type
COMPONENT Reg2BitR
	port(
		Clk,WrEn,Reset : in std_logic;
		Din : in  STD_LOGIC_VECTOR (1 downto 0);
		Dout : out std_logic_VECTOR (1 downto 0)); 
END COMPONENT;

-- gia tag
COMPONENT Reg5BitR
	port(
		Clk,WrEn,Reset : in std_logic;
		Din : in  STD_LOGIC_VECTOR (4 downto 0);
		Dout : out std_logic_VECTOR (4 downto 0)); 
END COMPONENT;

-- gia value
COMPONENT Reg32BitR
	port(
		Clk,WrEn,Reset : in std_logic;
		Din : in  STD_LOGIC_VECTOR (31 downto 0);
		Dout : out std_logic_VECTOR (31 downto 0)); 
END COMPONENT;
	
COMPONENT mux32Bit
port
(sel : in  STD_LOGIC;
 A : in  STD_LOGIC_VECTOR (31 downto 0);
 B : in  STD_LOGIC_VECTOR (31 downto 0);
 Outt : out  STD_LOGIC_VECTOR (31 downto 0));
END COMPONENT;

-- gia valid kai done kai ecxeption
COMPONENT Reg1BitR
port
(Clk,WrEn,Din,Reset : in std_logic;
 Dout : out std_logic);
END COMPONENT;

signal valid, done, comparator, valid_reg_WrEn, done_reg_WrEn : std_logic;
signal value_reg_out : STD_LOGIC_VECTOR (31 downto 0);
signal tag_match_Q, exception_reg_Din : STD_LOGIC;
signal Ri : STD_LOGIC_VECTOR (4 downto 0);
begin

-- valid. allazei otan mpainei kainourgia entolh h diagrafetai
valid_reg_WrEn <= delete or issue;

valid_reg : Reg1BitR
port map(
	Clk => Clk,
	WrEn => valid_reg_WrEn,
	Din => issue,
	Reset => '0',
	Dout => valid);

valid_out <= valid;

-- done
done_reg_WrEn <= comparator or issue;

done_reg : Reg1BitR
port map(
	Clk => Clk,
	WrEn => done_reg_WrEn,
	Din => comparator,
	Reset => '0',
	Dout => done);

done_out <= done;

-- Ri
Ri_reg : Reg5BitR
port map(
	Clk => Clk,
	WrEn => issue,
	Din => Ri_in,
	Reset => '0',
	Dout => Ri);
	
Ri_out <= Ri;

-- value	
Value_reg : Reg32BitR
port map(
	Clk => Clk,
	WrEn => comparator,
	Din => CDB_V,
	Reset => '0',
	Dout => value_reg_out);	
	
-- forward apo cdb
V_out <= 
	CDB_V when comparator = '1'
	else value_reg_out;

-- Fu_type
Fu_type0 : Reg1BitR
port map(
	Clk => Clk,
	WrEn => issue,
	Din => Fu_type_in(0),
	Reset => '0',
	Dout => Fu_type_out(0));

Fu_type1 : Reg1BitR
port map(
	Clk => Clk,
	WrEn => issue,
	Din => Fu_type_in(1),
	Reset => '0',
	Dout => Fu_type_out(1));
	
-- exception
-- apagoreuoume na grapsei ston kataxwrhth 31. An kata to issue, Ri_in = 31 tote 8a xei exception
exception_reg_Din <= '1' when Ri_in = "11111" else '0';

exception_reg : Reg1BitR
port map(
	Clk => Clk,
	WrEn => issue,
	Din => exception_reg_Din,
	Reset => '0',
	Dout => Exception_out);
	
PC_reg : Reg32BitR
port map(
	Clk => Clk,
	WrEn => issue,
	Din => PC_entolhs,
	Reset => '0',
	Dout => PC_out);
	
-- ginetai 1 otan iparxei simfwnia metaksu tag kai Q apo to cdb
tag_match_Q <= (cdb_Q(0) XNOR tag(0)) AND 
					(cdb_Q(1) XNOR tag(1)) AND 
					(cdb_Q(2) XNOR tag(2)) AND 
					(cdb_Q(3) XNOR tag(3)) AND 
					(cdb_Q(4) XNOR tag(4));
					
-- comparator
-- deixnei otan hr8e to apotelesma pou perimene o buffer
comparator <= '1' 
	when cdb_valid = '1' and tag_match_Q = '1' and valid = '1' and done = '0'
	else '0';
	
-- flags gia forward. Deixnei an to Ri tou einai kataxwrhths phghs ths entolhs pou diavazei Rj h Rk
j_equal <= ((Rj(0) XNOR Ri(0)) AND 
				(Rj(1) XNOR Ri(1)) AND 
				(Rj(2) XNOR Ri(2)) AND 
				(Rj(3) XNOR Ri(3)) AND 
				(Rj(4) XNOR Ri(4)))AND
				valid;
	
k_equal <= ((Rk(0) XNOR Ri(0)) AND 
				(Rk(1) XNOR Ri(1)) AND 
				(Rk(2) XNOR Ri(2)) AND 
				(Rk(3) XNOR Ri(3)) AND 
				(Rk(4) XNOR Ri(4)))AND
				valid;
	
-- midenizetai otan exei swsta apotelesmata h grammh.
-- to (NOT (done OR comparator)) ginetai 0 otan exei ta swsta apotelesmata h erxontai se auton ton kuklo
-- etsi an diavastoun kai ta dedomena einai egkura tha bgei tag 0
tag_out <= (tag(4) AND valid AND (NOT (done OR comparator))) &
			  (tag(3) AND valid AND (NOT (done OR comparator))) &
			  (tag(2) AND valid AND (NOT (done OR comparator))) &
			  (tag(1) AND valid AND (NOT (done OR comparator))) &
			  (tag(0) AND valid AND (NOT (done OR comparator)));

end Behavioral;