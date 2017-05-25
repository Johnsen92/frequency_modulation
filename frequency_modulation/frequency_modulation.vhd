library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

use work.sine_cordic_constants.all;

entity frequency_modulation is
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
end frequency_modulation;

architecture frequency_modulation_arc of frequency_modulation is
    component modulator is
        generic (
            DATA_WIDTH          : integer := 8;
            MAX_AMPLITUDE       : real := 1.0;
            MIN_AMPLITUDE       : real := -1.0;
            FREQUENCY_DEV_KHZ   : real := 0.5
        );
        port (
            clk                 : in std_logic;
            reset               : in std_logic;
            start               : in std_logic;
            done                : out std_logic;
            signal_in           : in std_logic_vector(DATA_WIDTH-1 downto 0);
            frq_deviation_khz   : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;
    
    component signal_generator is
        generic (
            DATA_WIDTH  : integer := 8;
            BAUD_RATE   : real := 44000.0
        );
        port (
            clk         : in std_logic;	
            reset       : in std_logic;
            start       : in std_logic;
            frequency   : in std_logic_vector(DATA_WIDTH-1 downto 0);
            amplitude   : in std_logic_vector(DATA_WIDTH-1 downto 0);
            done        : out std_logic;
            sine_signal : out std_logic_vector(DATA_WIDTH-1 downto 0)
        );
    end component;

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
    
    ----------------------------------------
    --             CONSTANTS              --
    ----------------------------------------
    constant FIXED_PI : std_logic_vector := float_to_fixed(MATH_PI, INTERNAL_DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, INTERNAL_DATA_WIDTH);
    constant FIXED_CARRIER_FREQ_KHZ : std_logic_vector := float_to_fixed(CARRIER_FREQ/1000.0, INTERNAL_DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, INTERNAL_DATA_WIDTH);
    
    ----------------------------------------
    --          INTERNAL SIGNALS          --
    ----------------------------------------
    signal mod_start, mod_done, siggen_start, siggen_done, sample_flag : std_logic;
    signal input_int, mod_frq_deviation, siggen_frequency_in, sine_signal : std_logic_vector(INTERNAL_DATA_WIDTH-1 downto 0);
	
	--attribute keep : boolean;
	--attribute keep of sine_signal_tmp : signal is true;
	--attribute keep of siggen_done : signal is true;
    
begin

    ----------------------------------------
    --      COMPONENT INSTANTIATIONS      --
    ----------------------------------------
    modulator_inst : modulator
        generic map (
            DATA_WIDTH      => INTERNAL_DATA_WIDTH,
	    FREQUENCY_DEV_KHZ => FREQUENCY_DEV_KHZ
        )
        port map (
            clk                 => clk,
            reset               => reset,
            start               => mod_start,
            done                => mod_done,
            signal_in           => input_int,
            frq_deviation_khz   => mod_frq_deviation
        );

    signal_generator_inst : signal_generator
        generic map (
            DATA_WIDTH      => INTERNAL_DATA_WIDTH,
            BAUD_RATE       => BAUD_RATE
        )
        port map (
            clk         => clk,
            reset       => reset,
            start       => siggen_start,
            frequency   => siggen_frequency_in,
            amplitude   => float_to_fixed(1.0, INTERNAL_DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, INTERNAL_DATA_WIDTH),
			done        => siggen_done,
            sine_signal => sine_signal
        );

    timekeeper_inst : timekeeper
        generic map (
            DATA_WIDTH      => TIME_PRECISION,
            CLK_FREQ        => CLK_FREQ,
            BAUD_RATE       => BAUD_RATE
        )
        port map (
            clk     => clk,
            reset   => reset,
            sample  => sample_flag,
            phi     => open
        );
		
	----------------------------------------
    --        COMBINATIONAL LOGIC         --
    ----------------------------------------
    -- input_int <= std_logic_vector(resize(signed(input), INTERNAL_DATA_WIDTH));
    input_int <= std_logic_vector(resize(signed(input), INTERNAL_DATA_WIDTH));
    mod_start <= sample_flag;
    siggen_start <= mod_done;
    -- siggen_frequency_in <= std_logic_vector(signed(FIXED_CARRIER_FREQ_KHZ) + signed(mod_frq_deviation));
    siggen_frequency_in <= mod_frq_deviation;
	
	output <= sine_signal(INTERNAL_DATA_WIDTH-1 downto INTERNAL_DATA_WIDTH - OUTPUT_DATA_WIDTH);
	output_valid <= siggen_done;

   
	
end architecture;
