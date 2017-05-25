--------------------------------------------------------------------------------
--
--                _     ___ ____        _          _                
--               | |   |_ _/ ___|      | |    __ _| |__   ___  _ __ 
--               | |    | |\___ \ _____| |   / _` | '_ \ / _ \| '__|
--               | |___ | | ___) |_____| |__| (_| | |_) | (_) | |   
--               |_____|___|____/      |_____\__,_|_.__/ \___/|_|   
--
--
--                               LIS - Laborübung
--
--------------------------------------------------------------------------------
--
--                              Copyright (C) 2005-2014
--
--                      ICT - Institute of Computer Technology    
--                    TU Vienna - Technical University of Vienna
--
--------------------------------------------------------------------------------
--
--  NAME:           LCD IP-Core
--  UNIT:           lcd_display
--  VHDL:           Architecture
--
--  Author:         nachtnebel
--
--------------------------------------------------------------------------------
--
--  Description:
--
--    Architecture of LCD Display Formatter.
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

architecture rtl of lcd_display is

  subtype t_char    is natural range 0 to 255;
  subtype t_text    is natural range 0 to 15;
  subtype t_states  is natural range 0 to 63;
  type    t_textmem is array (t_text) of t_char;

  constant C_START : natural := 63 - t_textmem'length;

  function to_ascii (constant v : in string) return t_textmem is
    variable t : t_textmem := (others => 16#20#);
    constant n : natural := t_textmem'length - v'length;
    constant d : integer := t'left - v'left;
  begin
    for i in v'range loop
      t(i+n+d) := character'pos(v(i));
    end loop;
    return t;
  end function to_ascii;
  
  constant C_TEXT : t_textmem := to_ascii ("Carrier Frq 1kHz");
  
  signal s_state     : t_states;
  signal s_lcd_cs    : std_logic;
  signal s_lcd_data  : std_logic_vector(7 downto 0);

begin

  p_generate_text: process (clk_i, reset_n_i)
  begin  -- process p_generate_text
    if reset_n_i = '0' then  		-- asynchronous reset (active low)

      s_state    <= 0;

      s_lcd_cs   <= '0';
      s_lcd_data <= "00000000";
      
    elsif clk_i'event and clk_i = '1' then  -- rising clock edge

      s_lcd_cs   <= '0';
      s_lcd_data <= "00000000";

      if s_state < t_states'high then
        s_state <= s_state + 1;
      end if;

      if s_state >= C_START and s_state < t_states'high then

	s_lcd_data <= std_logic_vector (to_unsigned (C_TEXT(s_state-C_START), 8));
	if C_TEXT(s_state-C_START) /= 16#00# then
	  s_lcd_cs <= '1';
	end if;

      end if;
    end if;
  end process p_generate_text;

  lcd_cs_o <= s_lcd_cs;
  lcd_data_o <= s_lcd_data;

end rtl;
