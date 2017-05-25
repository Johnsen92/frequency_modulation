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
--  VHDL:           Entity
--
--  Author:         nachtnebel
--
--------------------------------------------------------------------------------
--
--  Description:
--
--    Entity of LCD Display Formatter.
--
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity lcd_display is
  
  port (
    clk_i          : in  std_logic;
    reset_n_i      : in  std_logic;

    lcd_cs_o       : out std_logic;
    lcd_data_o     : out std_logic_vector (7 downto 0)
  );

end lcd_display;
