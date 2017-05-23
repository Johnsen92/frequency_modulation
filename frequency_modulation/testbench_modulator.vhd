library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.sine_cordic_constants.all;

entity testbench_modulator is
end testbench_modulator;

architecture beh of testbench_modulator is

    component modulator is
	    generic (
	        DATA_WIDTH  		: integer := 8;
		MAX_AMPLITUDE		: real := 1.0;
		MIN_AMPLITUDE		: real := -1.0;
		FREQUENCY_DEV_KHZ 	: real := 0.5
	    );
	    port (
	        clk     		: in std_logic;
	        reset   		: in std_logic;
		start			: in std_logic;
		done			: out std_logic;
	        signal_in   		: in std_logic_vector(DATA_WIDTH-1 downto 0);
	        frq_deviation_khz  	: out std_logic_vector(DATA_WIDTH-1 downto 0)
	    );
    end component;

    constant CLK_PERIOD : time := 20 ns;
    constant DATA_WIDTH : integer := 16;

    signal clk, reset : std_logic;
    signal start, done : std_logic;
    signal result : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal frequency : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal amplitude : std_logic_vector(DATA_WIDTH-1 downto 0);
    signal signal_in : std_logic_vector(DATA_WIDTH-1 downto 0);
    
    signal result_converted : real;
    signal current_angle_converted : real;
    signal testcase : real;
    signal comparison : real;
    signal cps : integer;

begin
    result_converted <= fixed_to_float(result, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES);
    frequency <= float_to_fixed(0.5, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);
    amplitude <= float_to_fixed(1.0, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);


    uut : modulator
        generic map (
            	DATA_WIDTH    => 16,
	    	MAX_AMPLITUDE => 1.0,
	    	MIN_AMPLITUDE => -1.0,
		FREQUENCY_DEV_KHZ => 0.5
        )
        port map (
            reset   	=> reset,
            clk     	=> clk,
            start   	=> start,
            done   	=> done,
            signal_in	=> signal_in,
	    frq_deviation_khz => result
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
	
	signal_in <= float_to_fixed(1.0, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);
	start <= '1';
	wait for 40 ns;
	start <= '0';
	wait for 120 ns;

	signal_in <= float_to_fixed(0.5, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);
	start <= '1';
	wait for 40 ns;
	start <= '0';
	wait for 120 ns;

	signal_in <= float_to_fixed(0.0, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);
	start <= '1';
	wait for 40 ns;
	start <= '0';
	wait for 120 ns;

	signal_in <= float_to_fixed(-0.5, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);
	start <= '1';
	wait for 40 ns;
	start <= '0';
	wait for 120 ns;
	
	signal_in <= float_to_fixed(-1.0, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);
	start <= '1';
	wait for 40 ns;
	start <= '0';
	wait for 120 ns;	

        wait;
    end process;

end beh;