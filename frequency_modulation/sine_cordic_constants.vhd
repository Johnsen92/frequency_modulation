library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use ieee.math_real.all;

package sine_cordic_constants is
    
    type CORDIC_DATA_TYPE is array(2 downto 0) of real;
    
    constant Q_FORMAT_INTEGER_PLACES : integer := 3;
    
    function MIN(a, b : integer) return integer;
    function MAX(a, b : integer) return integer;
    function compute_cordic_step(data_in : CORDIC_DATA_TYPE; i : integer) return CORDIC_DATA_TYPE;
    function float_to_fixed(x : real; b : integer; w : integer) return std_logic_vector;
    function fixed_to_float(x : std_logic_vector; b : integer) return real;
    function cumulative_product_k(n : integer; b : integer; w : integer) return std_logic_vector;
    
end package;
    
package body sine_cordic_constants is
    
    function MIN(a, b : integer) return integer
    is
    begin
        if a < b then
            return a;
        else
            return b;
        end if;
    end function;
    
    function MAX(a, b : integer) return integer
    is
    begin
        if a > b then
            return a;
        else
            return b;
        end if;
    end function;
    
    function compute_cordic_step(data_in : CORDIC_DATA_TYPE; i : integer) return CORDIC_DATA_TYPE
    is
        variable alpha : real := arctan(2.0**(-i));
        variable cosine : real := data_in(0);
        variable sine : real := data_in(1);
        variable beta : real := data_in(2);
        variable sigma : integer := 1;
        variable factor : real := 1.0 ;
        variable data_out : CORDIC_DATA_TYPE := (0.0, 0.0, 0.0);
    begin
        if beta < -MATH_PI*2.0**(-1.0) or beta > MATH_PI*2.0**(-1.0) then
            if beta < 0.0 then
                beta := beta + MATH_PI;
            else
                beta := beta - MATH_PI;
            end if;
            cosine := -cosine;
            sine := -sine;
        end if;
        
        if beta < 0.0 then
            sigma := -1;
        else
            sigma := 1;
        end if;
        
        factor := real(sigma)*(2.0**(-i));
        data_out(0) := cosine - factor*sine;
        data_out(1) := factor*cosine + sine;
        data_out(2) := beta - real(sigma)*alpha;
        
        return data_out;
    end function;
    
    function float_to_fixed(x : real; b : integer; w : integer) return std_logic_vector
    is
    begin
        return std_logic_vector(to_signed(integer(round(x*2.0**b)), w));
    end function;
    
    function fixed_to_float(x : std_logic_vector; b : integer) return real
    is
    begin
        return real(to_integer(signed(x))) / 2.0**b;
    end function;

    function cumulative_product_k(n : integer; b : integer; w : integer) return std_logic_vector
    is
        variable product : real;
    begin
        product := 1.0;
        for i in 0 to n-1 loop
            product := product*(1.0/sqrt(1.0 + 2.0**(2*(-i))));
        end loop;
        
        return float_to_fixed(product, b, w);
    end function;

end package body;