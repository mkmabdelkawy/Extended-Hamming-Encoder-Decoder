library ieee;
use ieee.std_logic_1164.all;
-------------------------------------------------------------------------
-------------------------------------------------------------------------
----------------------------Hamming(8,4)---------------------------------
-------------------------------------------------------------------------
-------------------------------------------------------------------------
entity FSL is
  port (
out_lfsr             :out std_logic_vector (3 downto 0);
out_generator        :out std_logic_vector (7 downto 0);
out_corrected        :out std_logic_vector (0 to 7);
out_decoded          :out std_logic_vector (3 downto 0);
out_parity_check     :out std_logic_vector (3 downto 0);
compare_single_error :out std_logic;
compare_double_error :out std_logic;
enable               :in  std_logic;      -- Enable counting
clk                  :in  std_logic;      -- Input clock
reset                :in  std_logic       -- Input reset
  );
end entity;

architecture behavioral of FSL is
signal count           :std_logic_vector (3 downto 0);
signal count_reverse   :std_logic_vector (0 to 3);
signal linear_feedback :std_logic;
signal i,j             :std_logic;
signal error           :std_logic_vector (7 downto 0);
signal index_error     :integer;
signal temp            :std_logic_vector (7 downto 0);
signal temp_out        :std_logic_vector (3 downto 0);


type G_MATRIX is array (0 to 7 , 0 to 3) of std_logic;
signal G : G_MATRIX;
signal temp_G: G_MATRIX;
signal Y               :std_logic_vector (7 downto 0);


type H_MATRIX is array (0 to 3 , 0 to 7) of std_logic;
signal H : H_MATRIX;
signal temp_H: H_MATRIX;
signal F               :std_logic_vector (3 downto 0);

type R_MATRIX is array (0 to 3 , 0 to 7) of std_logic;
signal R : R_MATRIX;
signal temp_R: R_MATRIX;
signal O               :std_logic_vector (3 downto 0);

---------
--LFSR (polynomial maximal length for 4 bit)
---------

begin
linear_feedback <= not(count(3) xor count(2));


process (clk, reset) begin
	if (reset = '1') then
		count <= (others=>'0');
	elsif (rising_edge(clk)) then
		if (enable = '1') then
			count <= (count(2) & count(1) & count(0) & linear_feedback);
		end if;
	end if;
	count_reverse <= count; --Reverse of bits
	out_lfsr <= count; --Output of LFSR


---------
--Generator G Matrix
---------

G <= ("1101","1011","1000","0111","0100","0010","0001","1110");
	
for i in 0 to 7 loop
for j in 0 to 3 loop
	temp_G(i,j) <= G(i,j) and count_reverse(j);
end loop;
	Y(i) <= temp_G(i,0) xor temp_G(i,1) xor temp_G(i,2) xor temp_G(i,3) ;
end loop;

out_generator <= Y; --Output Generator Matrix (Data 4 bits + Parity 3 bits + Parity extended 1 bit)

---------
--Channel Errors
---------

--Y(0) <= '1'; --Error manual
--Y(1) <= '1'; --Error manual
--Y(2) <= '1'; --Error manual 
--Y(3) <= '1'; --Error manual
--Y(4) <= '1'; --Error manual
--Y(5) <= '1'; --Error manual
--Y(6) <= '1'; --Error manual
Y(7) <= '1'; --Error manual

---------
--Parity Check H Matrix
---------


H <= ("10101010","01100110","00011110","11111111");

for i in 0 to 3 loop
for j in 0 to 7 loop
	temp_H(i,j) <= H(i,j) and Y(j);
end loop;
	F(i) <= temp_H(i,0) xor temp_H(i,1) xor temp_H(i,2) xor temp_H(i,3) xor temp_H(i,4) xor temp_H(i,5) xor temp_H(i,6) xor temp_H(i,7);
end loop;

out_parity_check <= F; --Output Parity Check H Matrix (Parity 3 bits + Parity extended 1 bit)


---------
--Error Correction
---------

case F is
when "1001" => index_error <= 0;
temp <= Y;
temp(index_error) <= not Y(index_error);
when "1010" => index_error <= 1;
temp <= Y;
temp(index_error) <= not Y(index_error);
when "1011" => index_error <= 2;
temp <= Y;
temp(index_error) <= not Y(index_error);
when "1100" => index_error <= 3;
temp <= Y;
temp(index_error) <= not Y(index_error);
when "1101" => index_error <= 4;
temp <= Y;
temp(index_error) <= not Y(index_error);
when "1110" => index_error <= 5;
temp <= Y;
temp(index_error) <= not Y(index_error);
when "1111" => index_error <= 6;
temp <= Y;
temp(index_error) <= not Y(index_error);
when "1000" => index_error <= 7;
temp <= Y;
temp(index_error) <= not Y(index_error);
when others => temp <= Y;
end case;


--Finding codeword 8 bits processeded in correction
	if ( temp = Y) then
		compare_single_error <= '0'; --Error single free
	else compare_single_error <= '1'; --Error detected and may be corrected
end if ;

if ((F > "0111") and (not F = "0000")) then
		compare_double_error <= '0'; --Error double free
	else compare_double_error <= '1'; --Errors detected only
end if ;

out_corrected <= temp; --Output Corrected 8 bits






---------
--Decoeding R Matrix
---------

R <= ("00100000","00001000","00000100","00000010");

for i in 0 to 3 loop
for j in 0 to 7 loop
	temp_R(i,j) <= R(i,j) and temp(j);
end loop;
	O(i) <= temp_R(i,0) xor temp_R(i,1) xor temp_R(i,2) xor temp_R(i,3) xor temp_R(i,4) xor temp_R(i,5) xor temp_R(i,6) xor temp_R(i,7);
end loop;

temp_out <= O;
out_decoded <= temp_out; --Output Decoded 8 bits

---------
---------

end process;
end architecture;
