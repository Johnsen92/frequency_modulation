library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sine_cordic_constants.all;

entity mult is
    generic (
        DATA_WIDTH  : integer := 8
    );
	port (
        clk     : in std_logic;
        reset   : in std_logic;
        dataa   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        datab   : in std_logic_vector(DATA_WIDTH-1 downto 0);
        result  : out std_logic_vector(DATA_WIDTH*2-1 downto 0)
	);
end mult;

architecture mult_arc of mult is

signal product   : std_logic_vector(DATA_WIDTH*2-1 downto 0);

begin

output : process(dataa, datab)
begin
    product <= std_logic_vector(signed(dataa) * signed(datab));
end process;

sync : process(reset, clk)
begin
    if(rising_edge(clk)) then
        if(reset = '1') then
            result  <= (others => '0');
        else
            result <= product;
        end if;
    end if;
end process;
	
end mult_arc;
