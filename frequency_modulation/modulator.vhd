library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.sine_cordic_constants.all;

entity modulator is
    generic (
        DATA_WIDTH  		: integer := 8;
	    MAX_AMPLITUDE		: real := 1.0;
	    MIN_AMPLITUDE		: real := -1.0;
	    FREQUENCY_DEV_KHZ	: real := 0.5;
	    CARRIER_FREQUENCY_KHZ	: real := 1.0
    );
    port (
        clk     		: in std_logic;
        reset   		: in std_logic;
	    start			: in std_logic;
	    done			: out std_logic;
        signal_in   		: in std_logic_vector(DATA_WIDTH-1 downto 0);
        frq_deviation_khz  	: out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end modulator;

architecture modulator_arc of modulator is

	-- multiplication component
	component mult2 is
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
    	end component;

	-- modulator state type
	type signal_generator_state_type is (MODULATOR_STATE_READY,
				  --MODULATOR_STATE_CONVERT_TO_FIXED,
                                  MODULATOR_STATE_CALCULATE_RELATIVE_AMPLITUDE_DEVIATION,
				  MODULATOR_STATE_SCALE,
				  MODULATOR_STATE_ADD_CARRIER_FRQ,
				  MODULATOR_STATE_WRITE_OUTPUT);

	-- state signals
	signal state 		: signal_generator_state_type; 
	signal state_next 	: signal_generator_state_type; 

	-- internal signals
	signal signal_int		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal signal_int_next		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal deviation_int		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal deviation_int_next	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal deviation_scaled_int	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal deviation_scaled_int_next: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal carrier_frq_int		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal carrier_frq_int_next	: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal frq_deviation_khz_next	: std_logic_vector(DATA_WIDTH-1 downto 0);
    signal frq_deviation_khz_int : std_logic_vector(DATA_WIDTH-1 downto 0);
	signal done_next		: std_logic;
	signal scaling_result		: std_logic_vector(DATA_WIDTH-1 downto 0);
	signal wait_for_mult		: std_logic;
	signal wait_for_mult_next	: std_logic;
	
	-- constants
	constant MEDIUM_AMPLITUDE : real := (MAX_AMPLITUDE + MIN_AMPLITUDE)/2.0;

begin

	-- multiplier instance
	scaling_mult : mult2
        generic map (
            DATA_WIDTH  => DATA_WIDTH
        )
        port map (
            clk     => clk,
            reset   => reset,
            dataa   => deviation_int,
            datab   => float_to_fixed(FREQUENCY_DEV_KHZ, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH),
            result  => scaling_result
        );

	-- state transition process
	state_transition : process(start, state, wait_for_mult)
	begin

		state_next <= state;
		case state is
			when MODULATOR_STATE_READY =>
				if start = '1' then
					state_next <= MODULATOR_STATE_CALCULATE_RELATIVE_AMPLITUDE_DEVIATION;
				end if;
			when MODULATOR_STATE_CALCULATE_RELATIVE_AMPLITUDE_DEVIATION =>
				state_next <= MODULATOR_STATE_SCALE;
			when MODULATOR_STATE_SCALE =>
				if wait_for_mult = '1' then
					state_next <= MODULATOR_STATE_ADD_CARRIER_FRQ;
				end if;
			when MODULATOR_STATE_ADD_CARRIER_FRQ =>
				state_next <= MODULATOR_STATE_WRITE_OUTPUT;
			when MODULATOR_STATE_WRITE_OUTPUT =>
				state_next <= MODULATOR_STATE_READY;
		end case;

	end process state_transition;

	-- state output process
	state_output : process(signal_int, deviation_int, deviation_scaled_int, carrier_frq_int, signal_in,
        scaling_result, state, frq_deviation_khz_int)
	begin
    		signal_int_next <= signal_int;
		deviation_int_next <= deviation_int;
		deviation_scaled_int_next <= deviation_scaled_int;
		done_next <= '0';
		wait_for_mult_next <= '0';
		carrier_frq_int_next <= carrier_frq_int;
        frq_deviation_khz_next <= frq_deviation_khz_int;

		case state is
			when MODULATOR_STATE_READY =>
				signal_int_next <= signal_in;
			when MODULATOR_STATE_CALCULATE_RELATIVE_AMPLITUDE_DEVIATION =>
				deviation_int_next <= std_logic_vector(signed(signal_int) + signed(float_to_fixed(MEDIUM_AMPLITUDE, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH)));
			when MODULATOR_STATE_SCALE =>
				wait_for_mult_next <= '1';
				deviation_scaled_int_next <= scaling_result;
			when MODULATOR_STATE_ADD_CARRIER_FRQ =>
				carrier_frq_int_next <= std_logic_vector(signed(deviation_scaled_int) + signed(float_to_fixed(CARRIER_FREQUENCY_KHZ, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH)));
			when MODULATOR_STATE_WRITE_OUTPUT =>
				frq_deviation_khz_next <= carrier_frq_int;
				done_next <= '1';
		end case;
	end process;

    frq_deviation_khz <= frq_deviation_khz_int;
	
	-- sync process
	sync : process(clk, reset)
	begin
		if reset = '1' then
			state <= MODULATOR_STATE_READY;
			done <= '0';
			signal_int <= (others => '0');
			deviation_int <= (others => '0');
			deviation_scaled_int <= (others => '0');
			frq_deviation_khz_int <= (others => '0');
			wait_for_mult <= '0';
			carrier_frq_int <= float_to_fixed(CARRIER_FREQUENCY_KHZ, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH);
		else
			if rising_edge(clk) then
				state <= state_next;
				signal_int <= signal_int_next;
				deviation_int <= deviation_int_next;
				deviation_scaled_int <= deviation_scaled_int_next;
				frq_deviation_khz_int <= frq_deviation_khz_next;
				wait_for_mult <= wait_for_mult_next;
				carrier_frq_int <= carrier_frq_int_next;
				done <= done_next;
			end if;
		end if;
	end process sync;
	
end modulator_arc;
