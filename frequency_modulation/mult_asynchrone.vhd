library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sine_cordic_constants.all;

entity mult_async is
    	generic (
        	DATA_WIDTH  : integer := 8
    	);
	port (
        	dataa   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        	datab   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        	result  : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end mult_async;

architecture mult_async_arc of mult_async is

	signal product   : std_logic_vector(DATA_WIDTH*2-1 downto 0);
    	constant MULT_RESULT_HIGH : integer := DATA_WIDTH*2 - Q_FORMAT_INTEGER_PLACES;
    	constant MULT_RESULT_LOW : integer := MAX(MULT_RESULT_HIGH+1 - (DATA_WIDTH), 0);
begin
	output : process(dataa, datab)
	begin
    		result <= (std_logic_vector(signed(dataa) * signed(datab)))(MULT_RESULT_HIGH downto MULT_RESULT_LOW);
	end process;
	
end mult_async_arc;