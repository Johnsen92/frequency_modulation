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
        CLK_FREQ                : integer := 50_000_000 -- in Hz
        );
        port (
            clk     : in std_logic;
            reset   : in std_logic;
            t       : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;

    constant CLK_PERIOD : time := 20 ns;
    constant CLK_FREQ   : integer := 50_000_000; --CAUTION: compare with above
    constant DATA_WIDTH : integer := 19;
    
    constant INCREMENT : real := 2.0**(-(DATA_WIDTH - Q_FORMAT_INTEGER_PLACES));
    constant CLK_PER_INCREMENT : integer := integer(round(real(CLK_FREQ)*INCREMENT));
    constant MAX_FREQ   : integer := CLK_FREQ/CLK_PER_INCREMENT;

    signal clk, reset : std_logic;
    signal t : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal t_r : real;

begin
    t_r <= fixed_to_float(t, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES);
    
    tk : timekeeper
        generic map (
            DATA_WIDTH  => DATA_WIDTH,
            CLK_FREQ    => CLK_FREQ
        )
        port map (
            reset   	=> reset,
            clk     	=> clk,
            t           => t
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
        report "Maximum Freq: " & integer'image(MAX_FREQ) & "Hz";
        wait until rising_edge(clk);

        wait;
    end process;

end beh;