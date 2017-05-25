library ieee;
use ieee.std_logic_1164.ALL;
use ieee.numeric_std.ALL;

library UNISIM;
use UNISIM.Vcomponents.ALL;

entity reset is
  port (
    clk_i     : in  std_logic;
    async_i   : in  std_logic;

    reset_o   : out std_logic;
    reset_n_o : out std_logic
  );
end entity reset;

architecture BEHAVIORAL of reset is

  signal s_a : std_logic_vector (3 downto 0);
  signal s_q : std_logic;

  component SRL16
  generic
  (
    INIT : bit_vector := X"0000"
  );
  port
  (
    Q   : out STD_ULOGIC;

    A0  : in STD_ULOGIC;
    A1  : in STD_ULOGIC;
    A2  : in STD_ULOGIC;
    A3  : in STD_ULOGIC;
    CLK : in STD_ULOGIC;        
    D   : in STD_ULOGIC
  ); 
  end component SRL16;

begin

  s_a <= "1111";

  i_srl16 : SRL16
  generic map
  (
    INIT => X"000F"
  )
  port map
  (
    D   => async_i,
    CLK => clk_i,
    A0  => s_a(0),
    A1  => s_a(1),
    A2  => s_a(2),
    A3  => s_a(3),
    Q   => s_q
  );

  reset_o   <= s_q;
  reset_n_o <= not s_q;
  
end architecture BEHAVIORAL;

