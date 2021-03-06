library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sine_cordic_constants.all;

entity mult2 is
    generic (
        DATA_WIDTH  : integer := 8
    );
	port (
        clk     : in std_logic;
        reset   : in std_logic;
        dataa   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        datab   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        result  : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end mult2;

architecture mult2_arc of mult2 is

begin
    test : process(dataa, datab)
        constant MULT_RESULT_HIGH : integer := DATA_WIDTH*2 - 1 - Q_FORMAT_INTEGER_PLACES;
        constant MULT_RESULT_LOW : integer := MAX(MULT_RESULT_HIGH+1 - (DATA_WIDTH), 0);
        variable product   : std_logic_vector(DATA_WIDTH*2-1 downto 0);
    begin
        product := std_logic_vector(signed(dataa) * signed(datab));
        result <= product(MULT_RESULT_HIGH downto MULT_RESULT_LOW);
    end process;
	
end mult2_arc;