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
--  VHDL:           Architecture
--
--  Author:         nachtnebel
--
--------------------------------------------------------------------------------
--
--  Description:
--
--    Top level architecture used for laboratory designs.
--
--    Instantiiert das Design und die LCD Anzeige.
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.comp_pack.all;

use work.sine_cordic_constants.all;

architecture struc of top is

    signal reset_n_i   : std_logic;

    signal s_clk       : std_logic;
    signal s_reset_n   : std_logic;
    signal s_reset     : std_logic;

    signal s_lcd_valid : std_logic;
    signal s_lcd_data  : std_logic_vector (7 downto 0);

    signal s_lcd_db    : std_logic_vector (7 downto 0);
    signal s_lcd_rs    : std_logic;
    signal s_lcd_en    : std_logic;
    signal s_lcd_rw    : std_logic;

    signal s_counter   : unsigned (26 downto 0);
    signal s_amp_delay : unsigned (18 downto 0);
    signal s_amp_val   : std_logic_vector (3 downto 0);

    signal s_adc_ch1       : std_logic_vector (13 downto 0);
    signal s_adc_ch1_valid : std_logic;

    signal s_adc_ch2       : std_logic_vector (13 downto 0);
    signal s_adc_ch2_valid : std_logic;

    signal s_dac_ch1       : std_logic_vector (11 downto 0);
    signal s_dac_ch1_valid : std_logic;

    signal s_dac_ch2       : std_logic_vector (11 downto 0);
    signal s_dac_ch2_valid : std_logic;

    signal s_dac_ch3       : std_logic_vector (11 downto 0);
    signal s_dac_ch3_valid : std_logic;

    signal s_dac_ch4       : std_logic_vector (11 downto 0);
    signal s_dac_ch4_valid : std_logic;
    
    signal output, output_intermediate    : std_logic_vector(12-1 downto 0);
    
    attribute keep : string;
    attribute keep of s_dac_ch1 : signal is "true";
    attribute keep of s_dac_ch1_valid : signal is "true";
    
begin

    -----------------------------------------------------------------------------
    -- CLOCK and RESET
    -----------------------------------------------------------------------------

    i_reset : reset
        port map
        (
            clk_i     => s_clk,
            async_i   => rot_center_i,
            reset_o   => open,
            reset_n_o => reset_n_i
        );

    H1 : BUFG
        port map
        (
            I => reset_n_i,
            O => s_reset_n
        );

    H2 : BUFG
        port map
        (
            I => sysclk_i,
            O => s_clk
        );

    -----------------------------------------------------------------------------
    -- LCD Display
    -----------------------------------------------------------------------------

    i_hello_word : lcd_display
        port map 
        (
            clk_i        => s_clk,
            reset_n_i    => s_reset_n,

            lcd_cs_o     => s_lcd_valid,
            lcd_data_o   => s_lcd_data
        );

    i_lcd_core : lcd_core
        port map
        (
            clk_i      => s_clk,
            reset_n_i  => s_reset_n,

            lcd_cs_i   => s_lcd_valid,
            lcd_data_i => s_lcd_data,

            lcd_data_o => s_lcd_db,
            lcd_rs_o   => s_lcd_rs,
            lcd_en_o   => s_lcd_en,
            lcd_rw_o   => s_lcd_rw
        );

    lcd_db_io <= s_lcd_db when (s_lcd_rw = '0') else (others => 'Z');
    lcd_rs_o  <= s_lcd_rs;
    lcd_en_o  <= s_lcd_en;
    lcd_rw_o  <= s_lcd_rw;

    -----------------------------------------------------------------------------
    -- SPI Core
    -----------------------------------------------------------------------------
    
    s_amp_val <= "0001";
    
    i_spi_ifc : spi_ifc
        port map
        (
            clk_i           => s_clk,
            reset_n_i       => s_reset_n,

            -- Managed Interface
            adc_ch1_o       => s_adc_ch1,
            adc_ch1_valid_o => s_adc_ch1_valid,

            adc_ch2_o       => s_adc_ch2,
            adc_ch2_valid_o => s_adc_ch2_valid,

            dac_ch1_i       => s_dac_ch1,
            dac_ch1_valid_i => s_dac_ch1_valid,

            dac_ch2_i       => s_dac_ch2,
            dac_ch2_valid_i => s_dac_ch2_valid,

            dac_ch3_i       => s_dac_ch3,
            dac_ch3_valid_i => s_dac_ch3_valid,

            dac_ch4_i       => s_dac_ch4,
            dac_ch4_valid_i => s_dac_ch4_valid,

            dac_ready_o     => open,

            amp_ch1_i       => s_amp_val,
            amp_ch2_i       => s_amp_val,

            -- SPI Interface
            spi_clk_o       => spi_clk_o,
            spi_dat_o       => spi_dat_o,

            ad_conv_o       => ad_conv_o,
            adc_dat_i       => adc_dat_i,

            dac_clr_n_o     => dac_clr_n_o,
            dac_cs_n_o      => dac_cs_n_o,
            dac_dat_i       => dac_dat_i,

            amp_shdn_o      => amp_shdn_o,
            amp_cs_n_o      => amp_cs_n_o,
            amp_dat_i       => amp_dat_i
        );
        
    --BLAH
    s_reset <= not s_reset_n;
    
    --output_intermediate <= std_logic_vector(signed(output) + signed(float_to_fixed(1.0, 12 - 3, 12)));
    --s_dac_ch1 <= output_intermediate(12-2 downto 0) & "0";
    
    frequency_modulation_inst : frequency_modulation
        generic map (
            TIME_PRECISION      => 19,
            INTERNAL_DATA_WIDTH => 16,
            INPUT_DATA_WIDTH    => 14,
            OUTPUT_DATA_WIDTH   => 12,
            CLK_FREQ            => 50_000_000.0,
            BAUD_RATE           => 44_000.0,
            CARRIER_FREQ        => 1_000.0,
            FREQUENCY_DEV_KHZ   => 0.5
        )
	    port map (
            clk             => s_clk,
            reset           => s_reset,
            input           => s_adc_ch1,
            --input_valid   => 
            output_valid    => s_dac_ch1_valid,
            output          => s_dac_ch1
	    );

    led_o <= std_logic_vector(s_counter (s_counter'high downto s_counter'high-7));

end struc;
