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
--  NAME:           Top Level Design
--  UNIT:           Top
--  VHDL:           Entity
--
--  Author:         nachtnebel
--
--------------------------------------------------------------------------------
--
--  Description:
--
--    Top level entity used for laboratory designs.
--
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

entity top is
  port (
    sysclk_i        : in  std_logic;  	-- system clock, 50 MHz

    -- LCD Interface
    lcd_db_io       : inout std_logic_vector(7 downto 0);
    lcd_rs_o        : out std_logic;
    lcd_en_o        : out std_logic;
    lcd_rw_o        : out std_logic;

    -- Push Buttons
    btn_east_i      : in  std_logic;
    btn_north_i     : in  std_logic;
    btn_south_i     : in  std_logic;
    btn_west_i      : in  std_logic;

    -- Rotary Knob (ROT)
    rot_center_i    : in  std_logic;
    rot_a_i         : in  std_logic;
    rot_b_i         : in  std_logic;

    -- Mechanical Switches
    switch_i        : in  std_logic_vector(3 downto 0);

    -- LEDs
    led_o           : out std_logic_vector(7 downto 0);

    -- External SPI Interface to ADC, DAC and Amplifier
    spi_clk_o       : out std_logic;
    spi_dat_o       : out std_logic;
    
    ad_conv_o       : out std_logic;
    adc_dat_i       : in  std_logic;

    dac_clr_n_o     : out std_logic;
    dac_cs_n_o      : out std_logic;
    dac_dat_i       : in  std_logic;

    amp_shdn_o      : out std_logic;
    amp_cs_n_o      : out std_logic;
    amp_dat_i       : in  std_logic
  );
end top;
