library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.sine_cordic_constants.all;

-- This component is used to convert an angle beta to a value between -pi/2 and pi/2.
-- The number format used - Q(3, Y) - restricts possible inputs so that only an
-- addition/subtraction operation is needed.
-- As per the CORDIC algorithm, the sine/cosine values of the initial estimate are
-- negated to reflect this shift.

entity cordic_init is
	generic (
        	DATA_WIDTH  : integer := 8
    	);
	port (
		beta_in     : in std_logic_vector(DATA_WIDTH-1 downto 0);
		sine_in     : in std_logic_vector(DATA_WIDTH-1 downto 0);
		cosine_in   : in std_logic_vector(DATA_WIDTH-1 downto 0);
		beta_out    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		sine_out    : out std_logic_vector(DATA_WIDTH-1 downto 0);
		cosine_out  : out std_logic_vector(DATA_WIDTH-1 downto 0)
	);
end cordic_init;

architecture cordic_init_arc of cordic_init is

signal sine_int 	: std_logic_vector(DATA_WIDTH-1 downto 0);
signal cosine_int	: std_logic_vector(DATA_WIDTH-1 downto 0);
signal beta_int		: std_logic_vector(DATA_WIDTH-1 downto 0);

begin  -- cordic_init_arc

	input_alignment : process(beta_in, sine_in, cosine_in)
	begin
		if signed(beta_in) < signed(float_to_fixed(-MATH_PI_OVER_2, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH)) OR signed(beta_in) > signed(float_to_fixed(MATH_PI_OVER_2, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH)) then 
			if signed(beta_in) < 0 then
				beta_int <= std_logic_vector(signed(beta_in) + signed(float_to_fixed(MATH_PI, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH)));
			else
				beta_int <= std_logic_vector(signed(beta_in) - signed(float_to_fixed(MATH_PI, DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, DATA_WIDTH)));
			end if;
			cosine_int <= std_logic_vector(-(signed(cosine_in)));
			sine_int <=  std_logic_vector(-(signed(sine_in)));
		else
			beta_int <= beta_in;
			cosine_int <= cosine_in;
			sine_int <= sine_in;
		end if;
	end process input_alignment;
	
	cosine_out <= cosine_int;
	sine_out <= sine_int;
	beta_out <= beta_int;

end cordic_init_arc;