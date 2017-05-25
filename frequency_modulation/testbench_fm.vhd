library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.sine_cordic_constants.all;

entity testbench_fm is
end testbench_fm;

architecture beh of testbench_fm is

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
    
    component frequency_modulation is
    generic (
        TIME_PRECISION      : integer := 19;
        INTERNAL_DATA_WIDTH : integer := 16;
        INPUT_DATA_WIDTH    : integer := 14;
        OUTPUT_DATA_WIDTH   : integer := 12;
        CLK_FREQ            : real := 50_000_000.0; -- in Hz
        BAUD_RATE           : real := 44_000.0;
        CARRIER_FREQ        : real := 1_000.0;
        FREQUENCY_DEV_KHZ   : real := 0.5
    );
	port (
        clk             : in std_logic;
        reset           : in std_logic;
        input           : in std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
        --input_valid     : in std_logic;
        output_valid    : out std_logic;
        output          : out std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0)
	);
    end component;

    constant CLK_PERIOD             : time := 20 ns;
    constant CLK_FREQ               : real := 50_000_000.0; -- CAUTION: compare with above
    constant TIME_PRECISION         : integer := 19;
    constant INTERNAL_DATA_WIDTH    : integer := 16;
    constant INPUT_DATA_WIDTH       : integer := 14;
    constant OUTPUT_DATA_WIDTH      : integer := 12;
    constant BAUD_RATE              : real := 44_000.0;
    constant CARRIER_FREQ           : real := 1_000.0;
    constant FREQUENCY_DEV_KHZ      : real := 0.75;
    
    constant INPUT_FREQ : real := 1000.0; -- used to drive input sine wave
    
    constant INCREMENT : real := 2.0**(-(INTERNAL_DATA_WIDTH - Q_FORMAT_INTEGER_PLACES));
    constant CLK_PER_INCREMENT : integer := integer(round(CLK_FREQ*INCREMENT));
    constant CLK_PER_SAMPLE_INTERVAL : integer := integer(round(CLK_FREQ/BAUD_RATE));

    signal clk, reset : std_logic;
    signal phi : std_logic_vector(TIME_PRECISION-1 downto 0);
    signal phi_r : real;
    signal sig_in : std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
    signal sig_out : std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
    signal in_r, out_r : real;

begin
    phi_r <= fixed_to_float(phi, TIME_PRECISION - Q_FORMAT_INTEGER_PLACES);
    in_r <= sin(phi_r);
    --in_r <= 0.0;
    sig_in <= float_to_fixed(in_r, INPUT_DATA_WIDTH - 1, INPUT_DATA_WIDTH);
    out_r <= fixed_to_float(sig_out, OUTPUT_DATA_WIDTH - Q_FORMAT_INTEGER_PLACES);
    
    
    tk_input_gen : timekeeper
        generic map (
            DATA_WIDTH      => TIME_PRECISION,
            CLK_FREQ        => CLK_FREQ/INPUT_FREQ,
            BAUD_RATE       => BAUD_RATE
        )
        port map (
            reset   	=> reset,
            clk     	=> clk,
            sample      => open,
            phi         => phi
        );
    
    fm : frequency_modulation
        generic map (
            TIME_PRECISION      => TIME_PRECISION,
            INTERNAL_DATA_WIDTH => INTERNAL_DATA_WIDTH,
            INPUT_DATA_WIDTH    => INPUT_DATA_WIDTH,
            CLK_FREQ            => CLK_FREQ,
            BAUD_RATE           => BAUD_RATE,
            CARRIER_FREQ        => CARRIER_FREQ,
            FREQUENCY_DEV_KHZ   => FREQUENCY_DEV_KHZ
        )
        port map (
            clk         => clk,
            reset       => reset,
            input       => sig_in,
            output      => sig_out
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
        report "initiating test sequence!" severity note;
        wait until falling_edge(reset);
        wait until rising_edge(clk);

        wait;
    end process;

end beh;