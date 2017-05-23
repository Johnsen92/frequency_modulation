library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sine_cordic_constants.all;

entity div is
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
end div;

architecture div_arc of div is

signal quotient   : std_logic_vector(DATA_WIDTH*2-1 downto 0);

begin

output : process(dataa, datab)
begin
    quotient <= std_logic_vector(signed(dataa) * signed(datab));
end process;

sync : process(reset, clk)
    constant DIV_RESULT_HIGH : integer := DATA_WIDTH*2 - Q_FORMAT_INTEGER_PLACES;
    constant DIV_RESULT_LOW : integer := MAX(DIV_RESULT_HIGH+1 - (DATA_WIDTH), 0);
begin
    if(rising_edge(clk)) then
        if(reset = '1') then
            result  <= (others => '0');
        else
            result <= quotient(DIV_RESULT_HIGH downto DIV_RESULT_LOW);
        end if;
    end if;
end process;
	
end div_arc;