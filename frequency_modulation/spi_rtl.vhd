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
--  UNIT:           spi_rtl
--  VHDL:           Architecture
--
--  Author:         nachtnebel
--
--------------------------------------------------------------------------------
--
--  Description:
--
--    Hardware driver of Spartan3A Demo Board AD/DA interfaces.
--
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.comp_pack.all;

architecture rtl of spi_ifc is

  signal s_adc_ch1        : std_logic_vector (adc_ch1_o'range);
  signal s_adc_ch2        : std_logic_vector (adc_ch2_o'range);

  signal s_adc_valid      : std_logic_vector (1 downto 0);
  signal s_adc_running    : std_logic;
  signal s_ad_conv        : std_logic;

  signal s_ad_stay        : unsigned (2 downto 0);
  signal s_pickup         : unsigned (0 to 7);
    
  signal s_phase          : natural range 1 to 3;
  signal s_channel        : std_logic_vector(2 downto 0);
  signal s_channel_m1     : std_logic_vector(2 downto 0);
  signal s_channel_m2     : std_logic_vector(2 downto 0);

  signal s_dac_ch1        : std_logic_vector (dac_ch1_i'range);
  signal s_dac_ch2        : std_logic_vector (dac_ch2_i'range);
  signal s_dac_ch3        : std_logic_vector (dac_ch3_i'range);
  signal s_dac_ch4        : std_logic_vector (dac_ch4_i'range);
  signal s_next_dac_ch1   : std_logic_vector (dac_ch1_i'range);
  signal s_next_dac_ch2   : std_logic_vector (dac_ch2_i'range);
  signal s_next_dac_ch3   : std_logic_vector (dac_ch3_i'range);
  signal s_next_dac_ch4   : std_logic_vector (dac_ch4_i'range);

  signal s_dac_valid      : std_logic_vector (3 downto 0);
  signal s_next_dac_valid : std_logic_vector (3 downto 0);

  signal s_amp_ch1        : std_logic_vector (amp_ch1_i'range);
  signal s_amp_ch2        : std_logic_vector (amp_ch2_i'range);
  signal s_next_amp_ch1   : std_logic_vector (amp_ch1_i'range);
  signal s_next_amp_ch2   : std_logic_vector (amp_ch2_i'range);

  signal s_spi_data_out   : std_logic_vector (23 downto 0);
  signal s_spi_count_out  : unsigned (4 downto 0);

  signal s_spi_data_in    : std_logic_vector (34 downto 0);
  signal s_spi_count_in   : unsigned (5 downto 0);

  signal s_adc_dat        : std_logic;
  signal s_dac_dat        : std_logic;
  signal s_amp_dat        : std_logic;

  signal s_delay          : unsigned (7 downto 0);


  -- SPI clock, clock divider, internal sync stage and counter etc.
  signal s_spi_clk_next   : std_logic;
  signal s_spi_clk        : std_logic;    -- SPI clock
  signal s_spi_clk_sync   : std_logic;    -- set if a new SPI clock cycle begins
  signal s_spi_clk_samp   : std_logic;    -- SPI sampling sync signal
  signal s_spi_clk_slow   : std_logic;    -- request long SPI clock cycle period
  signal s_spi_clk_fast   : std_logic;    -- actual SPI clock cycle speed
  signal s_spi_clk_cnt    : unsigned (3 downto 0);

  signal s_spi_idle       : std_logic;

  constant C_SPI_FAST : unsigned (3 downto 0) := "0000";
  constant C_SPI_SLOW : unsigned (3 downto 0) := "0111";  

begin

  -- 
  --  Mode 1:  Amplifier Programming:  using slow SPI clock
  --  Mode 2:  AD/DA conversion:       using fast SPI clock
  --           AD and DA converter run independent from each other
  --           

  p_spi_clk : process (clk_i, reset_n_i)

    constant C_ZERO : unsigned (s_spi_clk_cnt'range) := (others => '0');

  begin
    if reset_n_i = '0' then

      s_spi_clk_cnt  <= (others => '0');

      s_spi_clk_sync <= '0';
      s_spi_clk_samp <= '0';      
      s_spi_clk_next <= '0';
      s_spi_clk_fast <= '0';
      s_spi_clk      <= '0';

    elsif clk_i'event and clk_i = '1' then

      -- reset oneshot signal
      s_spi_clk_sync <= '0';
      s_spi_clk_samp <= '0';

      -- let the clock divider run
      s_spi_clk_cnt <= s_spi_clk_cnt - "1";

      -- clock divider
      if s_spi_clk_cnt = C_ZERO then
        s_spi_clk_next <= not s_spi_clk_next;

        -- rearm timer
        if s_spi_clk_slow = '1' and s_adc_running = '0' then
	  s_spi_clk_cnt  <= C_SPI_SLOW;
	  s_spi_clk_fast <= '0';
        else
          s_spi_clk_cnt  <= C_SPI_FAST;
	  s_spi_clk_fast <= '1';
        end if;

	-- prepare next spi clock cycle
	s_spi_clk_sync <= s_spi_clk_next;
	s_spi_clk_samp <= not s_spi_clk_next;
      end if;

      -- spi clk is delayed by one clock cycle
      s_spi_clk <= s_spi_clk_next;

    end if;
  end process p_spi_clk;

  spi_clk_o <= s_spi_clk;


  p_spi_ctrl : process (clk_i, reset_n_i)

    variable v_dac_valid : std_logic_vector (s_dac_valid'range);

    -- Clock frequency change delay counter zero
    constant C_STABLE : unsigned (s_delay'range) := (others => '0');

    -- SPI bit counters zero
    constant C_DONE : unsigned (s_spi_count_out'range) := (others => '0');
    constant C_IDLE : std_logic_vector (s_dac_valid'range) := (others => '0');

  begin
    if reset_n_i = '0' then

      dac_ready_o <= '0';
      dac_cs_n_o  <= '1';
      amp_cs_n_o  <= '1';

      s_spi_idle     <= '1';
      s_spi_clk_slow <= '1';

      s_spi_data_out  <= (others => '0');
      s_spi_count_out <= (others => '0');

      s_amp_ch1      <= (others => '0');
      s_amp_ch2      <= (others => '0');
      s_next_amp_ch1 <= (others => '0');
      s_next_amp_ch2 <= (others => '0');

      s_dac_ch1      <= (others => '0');
      s_dac_ch2      <= (others => '0');
      s_dac_ch3      <= (others => '0');
      s_dac_ch4      <= (others => '0');
      s_next_dac_ch1 <= (others => '0');
      s_next_dac_ch2 <= (others => '0');
      s_next_dac_ch3 <= (others => '0');
      s_next_dac_ch4 <= (others => '0');

      s_dac_valid      <= (others => '0');
      s_next_dac_valid <= (others => '0');

      s_delay <= (others => '1');

    elsif clk_i'event and clk_i = '1' then

      dac_ready_o <= '0';

      -- when changing the clock frequency, wait a little bit
      if s_delay /= C_STABLE then
	s_delay <= s_delay - "1";

      -- synchronize everything with SPI clock
      elsif s_spi_clk_sync = '1' then

        -- next output bit
        s_spi_data_out(23 downto 1) <= s_spi_data_out(22 downto 0);
        s_spi_data_out(0) <= '0';

        -- handle timer
        if s_spi_count_out /= C_DONE then

          s_spi_count_out <= s_spi_count_out - "1";

        else

          -- everything transfered, disable chip selects
          dac_cs_n_o <= '1';
          amp_cs_n_o <= '1';
          s_spi_idle <= '1';

        end if;

        -- get next command into output register
        if s_spi_idle = '1' then

          -- check whether dac values are waiting in output register
          if s_dac_valid /= C_IDLE then

	    -- program output register
            s_spi_idle <= '0';
	    dac_cs_n_o <= '0';

            s_spi_count_out <= "10111";
	    s_spi_data_out <= (others => '0'); -- load register command
            v_dac_valid := s_dac_valid;
            if s_dac_valid(0) = '1' then
	      s_spi_data_out(19 downto 16) <= "0000";  -- address 0
	      s_spi_data_out(15 downto  4) <= s_dac_ch1;
              v_dac_valid(0) := '0';
            elsif s_dac_valid(1) = '1' then
	      s_spi_data_out(19 downto 16) <= "0001";  -- address 1
	      s_spi_data_out(15 downto  4) <= s_dac_ch2;
              v_dac_valid(1) := '0';
            elsif s_dac_valid(2) = '1' then
	      s_spi_data_out(19 downto 16) <= "0010";  -- address 2
	      s_spi_data_out(15 downto  4) <= s_dac_ch3;
              v_dac_valid(2) := '0';
            elsif s_dac_valid(3) = '1' then
	      s_spi_data_out(19 downto 16) <= "0011";  -- address 3 
	      s_spi_data_out(15 downto  4) <= s_dac_ch4;
              v_dac_valid(3) := '0';
            end if;
            if v_dac_valid = C_IDLE then
	      s_spi_data_out(23 downto 20) <= "0010";  -- load one reg and flush all dacs
	      dac_ready_o <= '1';
            end if;
            s_dac_valid <= v_dac_valid;

          -- check whether the amplifier must be reprogrammed
          elsif s_amp_ch1 /= s_next_amp_ch1 or
                s_amp_ch2 /= s_next_amp_ch2 then

            -- need low clock speed to program amplifiers
            s_spi_clk_slow <= '1';

            -- check if we are already on slow SPI clock speed
            if s_spi_clk_fast = '0' then
 
              -- program output register
              s_spi_idle <= '0';
              amp_cs_n_o <= '0';

              s_spi_count_out <= "00111";
	      s_spi_data_out(23 downto 20) <= s_next_amp_ch1;
              s_spi_data_out(19 downto 16) <= s_next_amp_ch2;

              -- remember the new amplifier state
              s_amp_ch1 <= s_next_amp_ch1;
              s_amp_ch2 <= s_next_amp_ch2;

	    else
	      s_delay <= (others => '1');
            end if;

          -- check for new DAC values
          elsif s_next_dac_valid /= C_IDLE then

            -- need high clock speed to program DAC's and ADC's
            s_spi_clk_slow <= '0';

            -- check if we are already on high SPI clock speed
            if s_spi_clk_fast = '1' then

              -- copy activation pattern
              s_dac_valid <= s_next_dac_valid;
              s_next_dac_valid <= C_IDLE;

              if s_next_dac_valid(0) = '1' then
                s_dac_ch1 <= s_next_dac_ch1;
              end if;

              if s_next_dac_valid(1) = '1' then
                s_dac_ch2 <= s_next_dac_ch2;
              end if;

              if s_next_dac_valid(2) = '1' then
                s_dac_ch3 <= s_next_dac_ch3;
              end if;

              if s_next_dac_valid(3) = '1' then
                s_dac_ch4 <= s_next_dac_ch4;
              end if;

	    else
	      s_delay <= (others => '1');
            end if;

          elsif s_adc_running = '0' then

            -- need high clock speed to program DAC's and ADC's
            s_spi_clk_slow <= '0';
            if s_spi_clk_fast = '0' then
	      s_delay <= (others => '1');
            end if;

	  end if;  -- channel arbiter

        end if;  -- next command

      end if;  -- spi clock sync

      -- input registers
      s_next_amp_ch1 <= amp_ch1_i;
      s_next_amp_ch2 <= amp_ch2_i;

      if dac_ch1_valid_i = '1' then
        s_next_dac_ch1 <= dac_ch1_i;
        s_next_dac_valid(0) <= '1';
      end if;

      if dac_ch2_valid_i = '1' then
        s_next_dac_ch2 <= dac_ch2_i;
        s_next_dac_valid(1) <= '1';
      end if;

      if dac_ch3_valid_i = '1' then
        s_next_dac_ch3 <= dac_ch3_i;
        s_next_dac_valid(2) <= '1';
      end if;

      if dac_ch4_valid_i = '1' then
        s_next_dac_ch4 <= dac_ch4_i;
        s_next_dac_valid(3) <= '1';
      end if;

    end if;
  end process p_spi_ctrl;

  spi_dat_o <= s_spi_data_out(s_spi_data_out'high);

  dac_clr_n_o <= reset_n_i;
  amp_shdn_o  <= not reset_n_i;

  
  p_adc_ctrl: process (clk_i, reset_n_i)

    -- Clock frequency change delay counter zero
    constant C_STABLE : unsigned (s_delay'range) := (others => '0');

    -- SPI bit counter zero
    constant C_DONE : unsigned(s_spi_count_in'range) := (others => '0');

    -- ADC middle value, for signed -> unsigned conversion
    constant C_MIDDLE : unsigned (s_adc_ch1'range) := (others => '0');

    -- ADC channel switch
    constant C_SWITCH : unsigned (s_ad_stay'range) := (others => '0');

    variable v_next : unsigned (s_spi_count_in'range);

  begin
    if reset_n_i = '0' then

      s_ad_conv      <= '0';
      s_ad_stay      <= (others => '1');

      s_adc_running  <= '0';
      s_adc_valid    <= (others => '0');

      s_pickup       <= (others => '0');
      s_phase        <= 1;

      s_channel      <= (others => '0');
      s_channel_m1   <= (others => '0');
      s_channel_m2   <= (others => '0');

      s_spi_count_in <= (others => '0');
      s_spi_data_in  <= (others => '0');

      s_adc_ch1 <= (others => '0');
      s_adc_ch2 <= (others => '0');

      s_adc_dat <= '0';
      s_dac_dat <= '0';
      s_amp_dat <= '0';
      
    elsif clk_i'event and clk_i = '1' then

      -- reset single shot signal
      s_adc_valid <= (others => '0');

      -- input registers sampled at rising clock edge
      if s_spi_clk_samp = '1' then
	s_adc_dat <= adc_dat_i;
	s_dac_dat <= dac_dat_i;
	s_amp_dat <= amp_dat_i;	
      end if;

      -- synchronize everything with SPI clock
      if s_spi_clk_sync = '1' then

	-- reset adc start trigger
	s_ad_conv <= '0';

	-- select next multiplexer channel
	if s_ad_conv = '1' then
	  s_ad_stay <= s_ad_stay - "1";
	  if s_ad_stay = C_SWITCH then
	    s_ad_stay <= "011";
	    s_pickup <= s_pickup + "1";
	    case s_pickup (2 to 7) is

	      when "000000" =>  case s_pickup (0 to 1) is
		                  when "00" => s_channel <= "000";
		                  when "01" => s_channel <= "101";
		                  when "10" => s_channel <= "110";
		                  when "11" => s_channel <= "111";
		                  when others => null;
			        end case;
				s_ad_stay <= "111";

	      when "111111" =>  s_channel <= "100";

	      when others   =>  case s_phase is
		                  when 1 => s_channel <= "001";  s_phase <= 2;
		                  when 2 => s_channel <= "010";  s_phase <= 3;
		                  when 3 => s_channel <= "011";  s_phase <= 1;
			        end case;
	    end case;	    
	  end if;
	  s_channel_m2 <= s_channel_m1;
	  s_channel_m1 <= s_channel;
	end if;

	-- check for running ADC conversion
	if s_spi_count_in /= C_DONE then
	  s_spi_data_in <= s_spi_data_in(s_spi_data_in'high-1 downto 0) & s_adc_dat;

	  v_next := s_spi_count_in - "1";
	  s_spi_count_in <= v_next;
	  if v_next = C_DONE then
	    s_adc_running <= '0';
	  end if;
	else
	  s_adc_ch1 <= std_logic_vector( C_MIDDLE - unsigned (s_spi_data_in(30 downto 17)) );
	  s_adc_ch2 <= std_logic_vector( C_MIDDLE - unsigned (s_spi_data_in(14 downto  1)) );

	  s_adc_valid(0) <= '1';
	  if s_ad_stay = "01" then
	    s_adc_valid(1) <= '1';
	  end if;
	end if;
	
	-- check whether we may start the next AD conversion
	if s_adc_running = '0' and s_spi_clk_fast = '1' and s_delay = C_STABLE then

	  s_ad_conv <= '1';
	  s_adc_running <= '1';
	  s_spi_count_in <= "100010";

	end if;

      end if;
      
    end if;
  end process p_adc_ctrl;

  adc_ch1_o <= s_adc_ch1;
  adc_ch2_o <= s_adc_ch2;

  adc_ch1_valid_o <= s_adc_valid(0);
  adc_ch2_valid_o <= s_adc_valid(1);

  ad_conv_o <= s_ad_conv;
  adc_ch2_ch_o <= s_channel_m2;

end rtl;
