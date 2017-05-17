library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.sine_cordic_constants.all;

entity testbench is
end testbench;

architecture beh of testbench is

    component signal_generator is
        generic (
		DATA_WIDTH  : integer := 8;
       		BAUD_RATE   : real := 44000.0
    	);
	port (
		clk         : in std_logic;	
		reset	    : in std_logic;
		start	    : in std_logic;
		frequency   : in std_logic_vector(DATA_WIDTH-1 downto 0);
		amplitude   : in std_logic_vector(DATA_WIDTH-1 downto 0);
		done	    : out std_logic;
		sine_signal : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
    end component;

    constant CLK_PERIOD : time := 20 ns;
    constant DATA_WIDTH : integer := 16;

    signal clk, reset : std_logic;
    signal beta : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal start, done : std_logic;
    signal result : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal frequency : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal amplitude : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal sine_signal : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    signal result_converted : real;
    signal current_angle_converted : real;
    signal testcase : real;
    signal comparison : real;
    signal cps : integer;

begin
    result_converted <= fixed_to_float(result, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES);
    frequency <= float_to_fixed(1000.0, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);
    amplitude <= float_to_fixed(1.0, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);


    uut : signal_generator
        generic map (
            DATA_WIDTH    => 16,
	    BAUD_RATE    => 44000.0
        )
        port map (
            reset   	=> reset,
            clk     	=> clk,
            frequency   => frequency,
            amplitude   => amplitude,
            done    	=> done,
	    start	=> start,
            sine_signal	=> sine_signal
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
        variable data : CORDIC_DATA_TYPE;
    begin  -- process input
        start <= '0';
        wait until falling_edge(reset);
        wait until rising_edge(clk);
	start <= '1';
	
        wait;
    end process;

end beh;