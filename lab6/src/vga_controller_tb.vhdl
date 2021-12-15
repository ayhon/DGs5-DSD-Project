--=============================================================================
-- @file vga_controller_tb.vhdl
--=============================================================================
-- Standard library
library ieee;
library std;
-- Standard packages
use std.env.all;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- vga_controller_tb
--
-- @brief This file specifies the testbench of the VGA controller
--
-- We verify the following:
--  * The width of the sync pulses
--  * The length of the horizontal line
--  * The duration of a frame
--
-- Note that until the first vertical sync is observed, the measured length is
-- most likely not correct (but this is okay!).
--
-- We verify based on the number of clock cycles, but we also print the expected
-- and observed time in nanoseconds.
--
-- The testbench contains golden values.
--
-- For the timing parameters, see http://tinyvga.com/vga-timing/1024x768@70Hz
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR VGA_CONTROLLER_TB
--=============================================================================
entity vga_controller_tb is
end entity vga_controller_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of vga_controller_tb is

--=============================================================================
-- TYPE AND CONSTANT DECLARATIONS
--=============================================================================
  constant CLK_HIGH : time := 6.667 ns; -- Clock is 75 MHz, approximate with 6.667 ns, 74.996 MHz
  constant CLK_LOW  : time := 6.667 ns;
  constant CLK_PER  : time := CLK_LOW + CLK_HIGH;
  constant CLK_STIM : time := 1 ns;

--=============================================================================
-- SIGNAL DECLARATIONS
--=============================================================================

  signal CLKxCI : std_logic := '0';
  signal RSTxRI : std_logic := '1';

  signal XCoordxDO : unsigned(COORD_BW - 1 downto 0);
  signal YCoordxDO : unsigned(COORD_BW - 1 downto 0);

  signal HSxSO : std_logic;
  signal VSxSO : std_logic;

  signal RedxSO   : std_logic_VECTOR(COLOR_BW - 1 downto 0);
  signal GreenxSO : std_logic_VECTOR(COLOR_BW - 1 downto 0);
  signal BluexSO  : std_logic_VECTOR(COLOR_BW - 1 downto 0);

--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================

  component vga_controller is
    port (
      CLKxCI : in std_logic;
      RSTxRI : in std_logic;

      -- Data/color input
      RedxSI   : in std_logic_VECTOR(COLOR_BW - 1 downto 0);
      GreenxSI : in std_logic_VECTOR(COLOR_BW - 1 downto 0);
      BluexSI  : in std_logic_VECTOR(COLOR_BW - 1 downto 0);

      -- Coordinate output
      XCoordxDO : out unsigned(COORD_BW - 1 downto 0);
      YCoordxDO : out unsigned(COORD_BW - 1 downto 0);

      -- Timing output
      HSxSO : out std_logic;
      VSxSO : out std_logic;

      -- Data/color output
      RedxSO   : out std_logic_VECTOR(COLOR_BW - 1 downto 0);
      GreenxSO : out std_logic_VECTOR(COLOR_BW - 1 downto 0);
      BluexSO  : out std_logic_VECTOR(COLOR_BW - 1 downto 0)
    );
  end component vga_controller;

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin

--=============================================================================
-- COMPONENT INSTANTIATIONS
--=============================================================================
-------------------------------------------------------------------------------
-- The design under test
-------------------------------------------------------------------------------
  dut: vga_controller
    port map (
      CLKxCI => CLKxCI,
      RSTxRI => RSTxRI,

      RedxSI   => "1111",
      GreenxSI => "1111",
      BluexSI  => "1111",

      HSxSO => HSxSO,
      VSxSO => VSxSO,

      XCoordxDO => XCoordxDO,
      YCoordxDO => YCoordxDO,

      RedxSO   => RedxSO,
      GreenxSO => GreenxSO,
      BluexSO  => BluexSO
    );

--=============================================================================
-- CLOCK PROCESS
-- Process for generating the clock signal
--=============================================================================
  p_CLK: process is
  begin
    CLKxCI <= '0';
    wait for CLK_LOW;
    CLKxCI <= '1';
    wait for CLK_HIGH;
  end process p_CLK;

--=============================================================================
-- RESET PROCESS
-- Process for generating initial reset
--=============================================================================
  p_RST: process is
  begin
    RSTxRI <= '1';
    wait until CLKxCI'event and CLKxCI = '1'; -- Align to clock
    wait for (2*CLK_PER + CLK_STIM);
    RSTxRI <= '0';
    wait;
  end process p_RST;

--=============================================================================
-- HSYNC VERIFICATION PROCESSS
-- Verifies the length of the pulse and line
--=============================================================================
  p_verify_hsync: process is

    variable ClockCNT : integer := 0;

    variable HSyncPulsePrev : std_logic := '0';

    variable HSyncCCHighPrev : integer := 0; -- Cycle where output went high
    variable HSyncCCLow      : integer := 0; -- Cycle where output went low

    variable HSyncPulseWCC : integer := 0;
    variable HLineWCC      : integer := 0;

    variable HSyncPulseWSec : time := 0 ns;
    variable HLineWSec      : time := 0 ns;

    variable HSyncPulseWCCGOLDEN : integer := HS_PULSE; -- 136
    variable HLineWCCGOLDEN      : integer := HS_DISPLAY + HS_FRONT_PORCH + HS_PULSE + HS_BACK_PORCH; -- 1328

    -- 136/(75 MHz)*1ns = 1813.333333 ns but sim time resolution too low, so we get 136*(2*6.667 ns) = 1813.424 ns
    -- 1328/(75 MHz)*1ns = 17706.666666667 ns but sim time resolution too low, so we get 1328*(2*6.667 ns) = 17707.552 ns
    variable HSyncPulseWSecGOLDEN : time := 1813.424 ns;
    variable HLineWSecGOLDEN      : time := 17707.552 ns;

    variable HSyncPulseWidthERRORS : integer := 0;
    variable HLineWidthERRORS      : integer := 0;

    variable HSyncPulseWidthCORRECT : integer := 0;
    variable HLineWidthCORRECT      : integer := 0;

  begin

    wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;

    -- Save prev pulse and wait 1 CC, then check if falling/rising edges
    while now < 50 ms loop

      HSyncPulsePrev := HSxSO;

      wait until CLKxCI'event and CLKxCI = '1';
      ClockCNT := ClockCNT + 1;
      wait for CLK_STIM;

      -- Falling edge of HSxSO
      if HSxSO = '0' and HSyncPulsePrev = '1' then
        HSyncCCLow := ClockCNT;
      end if;

      -- Rising edge of HSxSO
      if HSxSO = '1' and HSyncPulsePrev = '0' then

        HSyncPulseWCC  := ClockCNT - HSyncCCLow;
        HLineWCC       := ClockCNT - HSyncCCHighPrev;
        HSyncPulseWSec := HSyncPulseWCC  * CLK_PER;
        HLineWSec      := HLineWCC * CLK_PER;

        if HSyncPulseWCC /= HSyncPulseWCCGOLDEN then
          report
            LF & "Horz sync pulse width is " & integer'image(HSyncPulseWCC) & " CC, expected " & integer'image(HSyncPulseWCCGOLDEN) &
            LF & "Horz sync pulse width is " & time'image(HSyncPulseWSec) & ", expected (approx) " & time'image(HSyncPulseWSecGOLDEN) &
            LF
          severity warning;

          HSyncPulseWidthERRORS := HSyncPulseWidthERRORS + 1;
        else
          HSyncPulseWidthCORRECT := HSyncPulseWidthCORRECT + 1;
        end if;

        if HLineWCC /= HLineWCCGOLDEN then
          report
            LF & "Horz line width is " & integer'image(HLineWCC) & " CC, expected " & integer'image(HLineWCCGOLDEN) &
            LF & "Horz line width is " & time'image(HLineWSec) & ", expected (approx) " & time'image(HLineWSecGOLDEN) &
            LF
          severity warning;

          HLineWidthERRORS := HLineWidthERRORS + 1;
          else
          HLineWidthCORRECT := HLineWidthCORRECT + 1;
        end if;

        HSyncCCHighPrev := ClockCNT;
      end if;
    end loop;

    report
      LF & "********************************************************************" &
      LF & "HORIZONTAL SYNC CHECK COMPLETE" &
      LF & "    Got " & integer'image(HSyncPulseWidthERRORS) & " errors for horz pulse width (1 is okay initially)" &
      LF & "    Got " & integer'image(HLineWidthERRORS) & " errors for horz line width (1 is okay initially)" &
      LF & "    Got " & integer'image(HSyncPulseWidthCORRECT) & " correct for horz pulse width" &
      LF & "    Got " & integer'image(HLineWidthCORRECT) & " correct for horz line width" &
      LF & "********************************************************************" &
      LF;

    wait for 1 ms;
    stop(0);

  end process p_verify_hsync;

--=============================================================================
-- VSYNC VERIFICATION PROCESSS
-- Verifies the length of the pulse and frame
--=============================================================================
  p_verify_vsync: process is

    variable ClockCNT : integer := 0;

    variable VSyncPulsePrev : std_logic := '0';

    variable VSyncCCHighPrev : integer := 0; -- Cycle where output went high
    variable VSyncCCLow      : integer := 0; -- Cycle where output went low

    variable VSyncPulseWCC : integer := 0;
    variable VFrameWCC     : integer := 0;

    variable VSyncPulseWSec : time := 0 ns;
    variable VFrameWSec     : time := 0 ns;

    variable VSyncPulseWCCGOLDEN : integer := 7968; -- See http : //tinyvga.com/vga-timing/1024x768@70Hz
    variable VFrameWCCGOLDEN     : integer := 1070368;

    -- 7968/(75 MHz)*1ns = 106240 ns but sim time resolution too low, so we get 7968*(2*6.667) = 106245.312 ns
    -- 1070368/(75 MHz)*1ns = 14271573.333333 ns but sim time resolution too low, so we get 1070368*(2*6.667 ns) = 14272286.912 ns
    variable VSyncPulseWSecGOLDEN : time := 106245.312 ns;
    variable VFrameWSecGOLDEN     : time := 14272286.912 ns;

    variable VSyncPulseWidthERRORS : integer := 0;
    variable VFrameWidthERRORS     : integer := 0;

    variable VSyncPulseWidthCORRECT : integer := 0;
    variable VFrameWidthCORRECT     : integer := 0;

  begin

    wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;

    while now < 50 ms loop

      VSyncPulsePrev := VSxSO;

      wait until CLKxCI'event and CLKxCI = '1';
      ClockCNT := ClockCNT + 1;
      wait for CLK_STIM;

      -- Falling edge
      if VSxSO = '0' and VSyncPulsePrev = '1' then
        VSyncCCLow := ClockCNT;
      end if;

      -- RISing edge
      if VSxSO = '1' and VSyncPulsePrev = '0' then

        VSyncPulseWCC  := ClockCNT - VSyncCCLow;
        VFrameWCC      := ClockCNT - VSyncCCHighPrev;
        VSyncPulseWSec := VSyncPulseWCC  * CLK_PER;
        VFrameWSec     := VFrameWCC * CLK_PER;

        if VSyncPulseWCC /= VSyncPulseWCCGOLDEN then
          report
            LF & "Vert sync pulse width is " & integer'image(VSyncPulseWCC) & " CC, expected " & integer'image(VSyncPulseWCCGOLDEN) &
            LF & "Vert sync pulse width is " & time'image(VSyncPulseWSec) & ", expected (approx) " & time'image(VSyncPulseWSecGOLDEN) &
            LF
          severity warning;

          VSyncPulseWidthERRORS := VSyncPulseWidthERRORS + 1;
        else
          VSyncPulseWidthCORRECT := VSyncPulseWidthCORRECT + 1;
        end if;

        if VFrameWCC /= VFrameWCCGOLDEN then
          report
            LF & "Vert frame width is " & integer'image(VFrameWCC) & " CC, expected " & integer'image(VFrameWCCGOLDEN) &
            LF & "Vert frame width is " & time'image(VFrameWSec) & ", expected (approx) " & time'image(VFrameWSecGOLDEN) &
            LF
          severity warning;

          VFrameWidthERRORS := VFrameWidthERRORS + 1;
        else
          VFrameWidthCORRECT := VFrameWidthCORRECT + 1;
        end if;

        VSyncCCHighPrev := ClockCNT;
      end if;
    end loop;

    report
      LF & "********************************************************************" &
      LF & "VERTICAL SYNC CHECK COMPLETE" &
      LF & "    Got " & integer'image(VSyncPulseWidthERRORS) & " errors for vert pulse width (1 is okay initially)" &
      LF & "    Got " & integer'image(VFrameWidthERRORS) & " errors for vert frame width (1 is okay initially)" &
      LF & "    Got " & integer'image(VSyncPulseWidthCORRECT) & " correct for vert pulse width" &
      LF & "    Got " & integer'image(VFrameWidthCORRECT) & " correct for vert frame width" &
      LF & "********************************************************************" &
      LF;

    wait for 1 ms;
    stop(0);

  end process p_verify_vsync;

end architecture tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
