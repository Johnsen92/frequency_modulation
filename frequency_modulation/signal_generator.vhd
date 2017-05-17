library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.sine_cordic_constants.all;

entity signal_generator is
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
end signal_generator;

architecture signal_generator_arc of signal_generator is

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

	-- cordic sine calculation unit component declaration
	component sine_cordic is
        generic (
            INPUT_DATA_WIDTH    : integer := 8;
            OUTPUT_DATA_WIDTH   : integer := 8;
            INTERNAL_DATA_WIDTH : integer := 14;
            ITERATION_COUNT     : integer := 12
        );
        port (
            reset               : in std_logic;
            clk                 : in std_logic;
            beta                : in std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
            start               : in std_logic;
            done                : out std_logic;
            result              : out std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0)
        );
    	end component;

	-- signal generator type
	type signal_generator_state_type is (SIGNAL_GENERATOR_STATE_READY,
                                  SIGNAL_GENERATOR_STATE_CALCULATE_SINE,
				  SIGNAL_GENERATOR_STATE_MULTIPLY_AMPLITUDE_AND_STEP_SIZE,
                                  SIGNAL_GENERATOR_STATE_WRITE_OUTPUT,
				  SIGNAL_GENERATOR_STATE_ADD_ANGLE);


	-- state signals
	signal state 	: signal_generator_state_type; 
	signal state_next : signal_generator_state_type; 

	-- internal signals
	signal current_angle_int	:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal current_angle_int_next	:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal amplitude_int 		:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal amplitude_int_next 	:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal frequency_int 		:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal frequency_int_next 	:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal sine_value_int 		:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal sine_value_int_next 	:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal cordic_start_int		:  std_logic;
	signal cordic_start_int_next	:  std_logic;
	signal cordic_done_int		:  std_logic;
	signal cordic_done_int_next	:  std_logic;
	signal step_size_int	 	:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal step_size_int_next	:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal sine_signal_next		:  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal done_next		:  std_logic;

	-- subcomponent wiring signals
	signal cordic_done	:  std_logic;
	signal cordic_result    :  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal amplitude_result :  std_logic_vector(DATA_WIDTH-1 downto 0);
	signal step_size_result :  std_logic_vector(DATA_WIDTH-1 downto 0);

begin  -- signal_generator_arc

	-- multiplier instance
	amplitude_mult : mult2
        generic map (
            DATA_WIDTH  => DATA_WIDTH
        )
        port map (
            clk     => clk,
            reset   => reset,
            dataa   => sine_value_int,
            datab   => amplitude_int,
            result  => amplitude_result
        );

	-- step size instance
	step_size_mult : mult2
        generic map (
            DATA_WIDTH  => DATA_WIDTH
        )
        port map (
            clk     => clk,
            reset   => reset,
            dataa   => float_to_fixed(2.0*MATH_PI/BAUD_RATE, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH),
            datab   => frequency_int,
            result  => step_size_result
        );

	-- cordic instance
	cordic_inst : sine_cordic
        generic map (
            INPUT_DATA_WIDTH	=> DATA_WIDTH,
            OUTPUT_DATA_WIDTH   => DATA_WIDTH,
            INTERNAL_DATA_WIDTH => DATA_WIDTH,
            ITERATION_COUNT     => 12
        )
        port map (
            clk     => clk,
            reset   => reset,
            beta    => current_angle_int,
            start   => cordic_start_int,
            done    => cordic_done,
	    result  => cordic_result
        );

	-- state transition process
	state_transition : process(cordic_done_int, start)
	begin

	case state is
		when SIGNAL_GENERATOR_STATE_READY =>
			if start = '1' then
				state_next <= SIGNAL_GENERATOR_STATE_CALCULATE_SINE;
			end if;
		when SIGNAL_GENERATOR_STATE_CALCULATE_SINE =>
			if cordic_done_int = '1' then
				state_next <= SIGNAL_GENERATOR_STATE_MULTIPLY_AMPLITUDE_AND_STEP_SIZE;
			end if;
		when SIGNAL_GENERATOR_STATE_MULTIPLY_AMPLITUDE_AND_STEP_SIZE =>
			state_next <= SIGNAL_GENERATOR_STATE_ADD_ANGLE;
		when SIGNAL_GENERATOR_STATE_ADD_ANGLE =>
			state_next <= SIGNAL_GENERATOR_STATE_WRITE_OUTPUT;
		when SIGNAL_GENERATOR_STATE_WRITE_OUTPUT =>
			state_next <= SIGNAL_GENERATOR_STATE_READY;
	end case;


	end process state_transition;

	-- state output process
	state_output : process(frequency, amplitude, cordic_done, cordic_result, step_size_result, amplitude_result)
	begin

	done_next <= '0';
	step_size_int_next <= step_size_int;
	amplitude_int_next <= amplitude_int;
	frequency_int_next <= frequency_int;
	sine_value_int_next <= sine_value_int;
	current_angle_int_next <= current_angle_int;
	cordic_start_int_next <= '0';

	case state is
		when SIGNAL_GENERATOR_STATE_READY =>
			amplitude_int_next <= amplitude;
			frequency_int_next <= frequency;
			cordic_start_int_next <= '1';
		when SIGNAL_GENERATOR_STATE_CALCULATE_SINE =>
			sine_value_int_next <= cordic_result;
		when SIGNAL_GENERATOR_STATE_MULTIPLY_AMPLITUDE_AND_STEP_SIZE =>
			step_size_int_next <= step_size_result;
			sine_signal_next <= amplitude_result;
		when SIGNAL_GENERATOR_STATE_ADD_ANGLE =>
			current_angle_int_next <= std_logic_vector(unsigned(current_angle_int) + unsigned(step_size_int));
		when SIGNAL_GENERATOR_STATE_WRITE_OUTPUT =>
			sine_signal_next <= sine_value_int;
			done_next <= '1';
	end case;

	end process state_output;

	
	-- sync process
	sync : process(clk, reset)
	begin
		if reset = '0' then
			state <= SIGNAL_GENERATOR_STATE_READY;
			done <= '0';
			cordic_start_int <= '0';
			step_size_int <= (others => '0');
			amplitude_int <= (others => '0');
			frequency_int <= (others => '0');
			sine_value_int <= (others => '0');
			sine_signal <= (others => '0');
			current_angle_int <= (others => '0');
		else
			if rising_edge(clk) then
				amplitude_int <= amplitude_int_next;
				frequency_int <= frequency_int_next;
				cordic_start_int <= cordic_start_int_next;
				sine_value_int <= sine_value_int_next;
				step_size_int <= step_size_int_next;
				current_angle_int <= current_angle_int_next;
				sine_signal <= sine_signal_next;
				state <= state_next;
			end if;
		end if;
	end process sync;
	
end signal_generator_arc;