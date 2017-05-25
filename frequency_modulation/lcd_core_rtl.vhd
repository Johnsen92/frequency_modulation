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
--  UNIT:           Top
--  VHDL:           Architecture
--
--  Author:         nachtnebel
--
--------------------------------------------------------------------------------
--
--  Description:
--
--    A simple LCD display driver.  Make's a data rate conversion to correctly
--    drive a HD44780U LCD controller or compatible chips.  8-bit interface.
--    Requires a 50 MHz clock.
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.comp_pack.all;

architecture rtl of lcd_core is

  subtype t_wait is natural range 0 to 1048575;

  subtype t_fifo_state  is natural range 0 to 10;
  subtype t_write_state is natural range 0 to 14;

  subtype t_byte is std_logic_vector (7 downto 0);
  subtype t_addr is unsigned (6 downto 0);

  signal s_fifo_rd     : std_logic;
  signal s_fifo_empty  : std_logic;
  signal s_fifo_data   : t_byte;

  signal s_cmd         : std_logic;
  signal s_chr         : std_logic;
  signal s_wait        : t_wait;
  signal s_lcd_data    : t_byte;
  signal s_lcd_pos     : t_addr;

  signal s_fifo_state  : t_fifo_state;
  signal s_write_state : t_write_state;

  constant C_HT : t_byte := x"09";
  constant C_LF : t_byte := x"0A";
  constant C_VT : t_byte := x"0B";
  constant C_FF : t_byte := x"0C";
  constant C_CR : t_byte := x"0D";
  
begin

  -- input fifo
  i_lcd_fifo : lcd_fifo
  port map (
    clk    => clk_i,
    rst_n  => reset_n_i,
    
    wr_en  => lcd_cs_i,
    din    => lcd_data_i,

    rd_en  => s_fifo_rd,
    dout   => s_fifo_data,

    full   => open,
    empty  => s_fifo_empty
  );

  -- LCD state machine
  p_lcd_ctrl : process (clk_i, reset_n_i)
    variable v_lcd_pos : t_addr;
  begin
    if reset_n_i = '0' then

      s_wait       <= 0;
      s_fifo_state <= 0;

      s_cmd        <= '0';
      s_chr        <= '0';
      s_fifo_rd    <= '0';

      s_lcd_data   <= (others => '0');
      s_lcd_pos    <= (others => '0');
      
    elsif clk_i'event and clk_i = '1' then

      -- Reset single shot signals
      s_cmd     <= '0';
      s_chr     <= '0';
      s_fifo_rd <= '0';

      -- Hold state machine as long as the wait timer runs
      if s_wait /= 0 then
	s_wait <= s_wait - 1;
      else

	-- Automatically go to next state
	if s_fifo_state < t_fifo_state'high then
	  s_fifo_state <= s_fifo_state + 1;
	end if;

	v_lcd_pos := s_lcd_pos;
	case s_fifo_state is

	  -- LCD init sequence
	  when 0 => s_wait <= 750000;
	  when 1 => s_wait <= 205000;  s_cmd <= '1';  s_lcd_data <= x"38";
	  when 2 => s_wait <=   5000;  s_cmd <= '1';  s_lcd_data <= x"38";
	  when 3 => s_wait <=   2000;  s_cmd <= '1';  s_lcd_data <= x"38";
	  when 4 => s_wait <=   2000;  s_cmd <= '1';  s_lcd_data <= x"38";
	  when 5 => s_wait <=   2000;  s_cmd <= '1';  s_lcd_data <= x"06";
	  when 6 => s_wait <=   2000;  s_cmd <= '1';  s_lcd_data <= x"0C";
	  when 7 => s_wait <=  82000;  s_cmd <= '1';  s_lcd_data <= x"01";

	  -- Fetch a character from FIFO
	  when 8 => if s_fifo_empty = '0' then
		      s_fifo_rd <= '1';
		    else
		      s_fifo_state <= 8;
		    end if;

	  -- LCD character display
	  when 10 => s_fifo_state <= 8;

		    -- Horizontal Tabulator (send cursor to next multiple of 4)
		    if s_fifo_data = C_HT then
		      v_lcd_pos := (v_lcd_pos + "100") and "1111100";
		      s_wait <= 2000;  s_cmd <= '1';  s_lcd_data <= t_byte('1' & v_lcd_pos);

		      -- Line Feed (send cursor to same column on next line)
		    elsif s_fifo_data = C_LF then
		      v_lcd_pos := v_lcd_pos or "1000000";
		      s_wait <= 2000;  s_cmd <= '1';  s_lcd_data <= t_byte('1' & v_lcd_pos);

		    -- Vertical Tabulator (send cursor to upper left corner)
		    elsif s_fifo_data = C_VT then
		      v_lcd_pos := "0000000";
		      s_wait <= 2000;  s_cmd <= '1';  s_lcd_data <= x"02";

		    -- Form Feed (clear display)
		    elsif s_fifo_data = C_FF then
		      v_lcd_pos := "0000000";
		      s_wait <= 82000; s_cmd <= '1';  s_lcd_data <= x"01";

		    -- Carriage Return (cursor to 1st column on same line)
		    elsif s_fifo_data = C_CR then
		      v_lcd_pos := v_lcd_pos(6) & "000000";
		      s_wait <= 2000;  s_cmd <= '1';  s_lcd_data <= t_byte('1' & v_lcd_pos);

		    -- ASCII Character
		    else
		      v_lcd_pos := v_lcd_pos + "1";
		      s_wait <= 2000;  s_chr <= '1';  s_lcd_data <= s_fifo_data;
		    end if;

	  when others => null;
	end case;
	s_lcd_pos <= v_lcd_pos;
      
      end if;
    end if;
  end process p_lcd_ctrl;

  -- Assure LCD write timing
  p_lcd_write : process (clk_i, reset_n_i)
  begin
    if reset_n_i = '0' then

      s_write_state <= 0;
      
      lcd_data_o <= (others => '0');
      lcd_rs_o   <= '0';
      lcd_en_o   <= '0';
      lcd_rw_o   <= '0';

    elsif clk_i'event and clk_i = '1' then

      if s_write_state < t_write_state'high then
	s_write_state <= s_write_state + 1;
      end if;

      case s_write_state is
	when  0 => if s_cmd = '1' or s_chr = '1' then
		     lcd_data_o <= s_lcd_data;
		     lcd_rs_o   <= s_chr;
		   else
		     lcd_data_o <= (others => '0');
		     lcd_rs_o   <= '0';
		     s_write_state <= 0;
		   end if;
	when  2 => lcd_en_o <= '1';
	when 14 => lcd_en_o <= '0';
		   s_write_state <= 0;

	when others => null;
      end case;
      
    end if;
  end process p_lcd_write;

end rtl;
