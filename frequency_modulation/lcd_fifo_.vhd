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
--  NAME:           LCD Fifo (synchronous)
--  UNIT:           lcd_fifo
--  VHDL:           Entity
--
--  Author:         nachtnebel
--
--------------------------------------------------------------------------------
--
--  Description:
--
--    Entity of a simple synchronous fifo memory.
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity lcd_fifo is
  port (
    clk    : in  std_logic;
    rst_n  : in  std_logic;
    
    wr_en  : in  std_logic;
    din    : in  std_logic_vector (7 downto 0);

    rd_en  : in  std_logic;
    dout   : out std_logic_vector (7 downto 0);

    full   : out std_logic;
    empty  : out std_logic
  );
end lcd_fifo;
