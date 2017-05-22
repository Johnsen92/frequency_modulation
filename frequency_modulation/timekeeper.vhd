library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

use work.sine_cordic_constants.all;

entity timekeeper is
    generic (
        DATA_WIDTH              : integer := 8;
        CLK_FREQ                : integer := 50_000_000 -- in Hz
    );
	port (
        clk     : in std_logic;
        reset   : in std_logic;
        t       : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end timekeeper;

architecture timekeeper_arc of timekeeper is

constant FIXED_PI : std_logic_vector := float_to_fixed(MATH_PI, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);
constant INCREMENT : real := 2.0**(-(DATA_WIDTH - Q_FORMAT_INTEGER_PLACES));
constant CLK_PER_INCREMENT : integer := integer(round(real(CLK_FREQ)*INCREMENT));

signal t_int : std_logic_vector(DATA_WIDTH-1 downto 0);
signal count : integer range 0 to CLK_PER_INCREMENT-1;

begin

t <= t_int;

sync : process(reset, clk)
begin
    if(rising_edge(clk)) then
        if(reset = '1') then
            t_int  <= (others => '0');
            count <= 0;
        else
            if (count = CLK_PER_INCREMENT-1) then
                count <= 0;
                if(signed(t_int) >= signed(FIXED_PI)) then
                    t_int <= std_logic_vector(-(signed(t_int)) + 1);
                else
                    t_int <= std_logic_vector(signed(t_int) + 1);
                end if;
            else
                count <= count + 1;
            end if;
        end if;
    end if;
end process;
	
end architecture;
