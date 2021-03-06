library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.sine_cordic_constants.all;

entity testbench_timekeeper is
end testbench_timekeeper;

architecture beh of testbench_timekeeper is

    component timekeeper is
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
    end component;

    constant CLK_PERIOD     : time := 20 ns;
    constant CLK_FREQ       : real := 50_000_000.0; --CAUTION: compare with above
    constant DATA_WIDTH     : integer := 19;
    constant BAUD_RATE      : real := 44_000.0;
    
    constant INCREMENT : real := 2.0**(-(DATA_WIDTH - Q_FORMAT_INTEGER_PLACES));
constant CLK_PER_INCREMENT : integer := integer(round(CLK_FREQ*INCREMENT));
constant CLK_PER_SAMPLE_INTERVAL : integer := integer(round(CLK_FREQ/BAUD_RATE));

    signal clk, reset : std_logic;
    signal phi : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal phi_r : real;

begin
    phi_r <= fixed_to_float(phi, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES);
    
    tk : timekeeper
        generic map (
            DATA_WIDTH  => DATA_WIDTH,
            CLK_FREQ    => CLK_FREQ,
            BAUD_RATE   => BAUD_RATE
        )
        port map (
            reset   	=> reset,
            clk     	=> clk,
            sample      => open,
            phi         => phi
        );
 
    -- Generates the clock signal
    clkgen : process
    begin
        clk <= '0';
        wait for CLK_PERIOD/2;
        clk <= '1';
        wait for CLK_PERIOD/2;
    end process clkgen;

    -- Generates the reset signal
    resetgen : process
    begin  -- process reset
        reset <= '1';
        wait for 2*CLK_PERIOD;
        reset <= '0';
        wait;
    end process;

    -- Generates the input
    input : process
    begin  -- process input
        wait until falling_edge(reset);
        wait until rising_edge(clk);

        wait;
    end process;

end beh;