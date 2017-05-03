library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

use work.sine_cordic_constants.all;

entity testbench is
end testbench;

architecture beh of testbench is

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

    constant CLK_PERIOD : time := 2 ps;
    constant INPUT_DATA_WIDTH : integer := 8;
    constant OUTPUT_DATA_WIDTH : integer := 8;
    constant ITERATION_COUNT : integer := 12;
    constant INTERNAL_DATA_WIDTH : integer := MAX(INPUT_DATA_WIDTH, OUTPUT_DATA_WIDTH) + 6;
    type testcase_array is array(18 downto 0) of real;
    constant testcases : testcase_array := (
        0.0,
        MATH_PI*2.0**(-1),
        -MATH_PI*2.0**(-1),
        MATH_PI*3.0**(-1),
        -MATH_PI*3.0**(-1),
        MATH_PI*4.0**(-1),
        -MATH_PI*4.0**(-1),
        MATH_PI*6.0**(-1),
        -MATH_PI*6.0**(-1),
        MATH_PI,
        -MATH_PI,
        1.0,
        -1.0,
        1.23,
        -1.23,
        0.01,
        -0.01,
        2.5,
        -2.5
    );

    signal clk, reset : std_logic;
    signal beta : std_logic_vector(INPUT_DATA_WIDTH-1 downto 0);
    signal start, done : std_logic;
    signal result : std_logic_vector(OUTPUT_DATA_WIDTH-1 downto 0);
    
    signal result_converted : real;
    signal testcase : real;
    signal comparison : real;

begin
    result_converted <= fixed_to_float(result, OUTPUT_DATA_WIDTH - Q_FORMAT_INTEGER_PLACES);

    top_inst : sine_cordic
        generic map (
            INPUT_DATA_WIDTH    => INPUT_DATA_WIDTH,
            OUTPUT_DATA_WIDTH   => OUTPUT_DATA_WIDTH,
            INTERNAL_DATA_WIDTH => INTERNAL_DATA_WIDTH,
            ITERATION_COUNT     => ITERATION_COUNT
        )
        port map (
            reset   => reset,
            clk     => clk,
            beta    => beta,
            start   => start,
            done    => done,
            result  => result
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
        beta <= (others => '0');
        wait until falling_edge(reset);
        wait until rising_edge(clk);

        for i in testcases'high downto testcases'low loop
            wait until rising_edge(clk);
            testcase <= testcases(i);
            beta <= float_to_fixed(testcases(i), INPUT_DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, INPUT_DATA_WIDTH);
            start <= '1';
            
            data(2) := testcases(i);
            data(1) := 0.0;
            data(0) := 1.0;
            for j in 1 to ITERATION_COUNT loop
                data := compute_cordic_step(data, j-1);
            end loop;
            data(2) := data(2)*fixed_to_float(cumulative_product_k(ITERATION_COUNT, INTERNAL_DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, INTERNAL_DATA_WIDTH), INTERNAL_DATA_WIDTH - Q_FORMAT_INTEGER_PLACES);
            data(1) := data(1)*fixed_to_float(cumulative_product_k(ITERATION_COUNT, INTERNAL_DATA_WIDTH - Q_FORMAT_INTEGER_PLACES, INTERNAL_DATA_WIDTH), INTERNAL_DATA_WIDTH - Q_FORMAT_INTEGER_PLACES);
            
            wait until rising_edge(clk);
            start <= '0';
            wait until rising_edge(done);
            comparison <= sin(testcases(i));
            wait until rising_edge(clk);
            report "###########################################" & lf & "sin(" & real'image(testcases(i)) & "): " & lf & " hw_cordic_sin: " & real'image(result_converted) & lf & " sw_cordic_sin: " & real'image(data(1)) & lf & "sw_control_sin: " & real'image(sin(testcases(i)));
        end loop;
        
        wait;
    end process;

end beh;
