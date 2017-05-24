library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

use work.sine_cordic_constants.all;

entity timekeeper is
    generic (
        DATA_WIDTH              : integer := 8;
        CLK_FREQ                : real := 50_000_000.0; -- in Hz
        BAUD_RATE               : real := 44_000.0
    );
	port (
        clk         : in std_logic;
        reset       : in std_logic;
        sample      : out std_logic;
        phi         : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end timekeeper;

architecture timekeeper_arc of timekeeper is

constant FIXED_PI : std_logic_vector := float_to_fixed(MATH_PI, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);
constant INCREMENT : real := 2.0**(-(DATA_WIDTH - Q_FORMAT_INTEGER_PLACES));
constant CLK_PER_INCREMENT : integer := integer(round(CLK_FREQ*INCREMENT));
constant CLK_PER_SAMPLE_INTERVAL : integer := integer(round(CLK_FREQ/BAUD_RATE));

signal phi_int : std_logic_vector(DATA_WIDTH-1 downto 0);
signal sample_int : std_logic;
signal increment_count : integer range 0 to CLK_PER_INCREMENT-1;
signal sample_count : integer range 0 to CLK_PER_SAMPLE_INTERVAL-1;

begin

phi <= phi_int;
sample <= sample_int;

sync : process(reset, clk)
begin
    if(rising_edge(clk)) then
        if(reset = '1') then
            phi_int  <= (others => '0');
            sample_int <= '0';
            increment_count <= 0;
            sample_count <= 0;
        else
            if (increment_count = CLK_PER_INCREMENT-1) then
                increment_count <= 0;
                if(signed(phi_int) >= signed(FIXED_PI)) then
                    phi_int <= std_logic_vector(-(signed(phi_int)) + 1);
                else
                    phi_int <= std_logic_vector(signed(phi_int) + 1);
                end if;
            else
                increment_count <= increment_count + 1;
            end if;
            
            if (sample_count = CLK_PER_SAMPLE_INTERVAL-1) then
                sample_count <= 0;
                sample_int <= '1';
            else
                sample_count <= sample_count + 1;
                sample_int <= '0';
            end if;
        end if;
    end if;
end process;
	
end architecture;
