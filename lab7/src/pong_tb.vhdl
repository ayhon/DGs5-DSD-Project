--=============================================================================
-- @file pong_fsm_tb.vhdl
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
-- pong_fsm_tb
--
-- @brief This file specifies the testbench of the pong finite state machine
--
-- We verify the following:
--  * The ball and plate start at the middle of the screen
--  * The change of states works as expected
--    - [ ] MainScreen → MainScreenLeave
--    - [ ] MainScreenLeave → UpRight or UpLeft, depending on VgaX and VgaY
--    - [ ] UpRight → UpLeft, DownLeft or DownRight
--    - [ ] UpLeft → UpRigth, DownRight or DownLeft
--    - [ ] DownLeft → UpRight, DownLeft, UpLeft or MainScreen
--    - [ ] DownRight → UpLeft, DownRight, UpRight or MainScreen
--  * It is only updated when the signal VSYNCxSO is high
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
-- ENTITY DECLARATION FOR pong_fsm_TB
--=============================================================================
entity pong_fsm_tb is
end entity pong_fsm_tb;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture tb of pong_fsm_tb is

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

  -- Controls from push buttons
  signal LeftxSI  : std_logic;
  signal RightxSI : std_logic;

  -- Coordinates from VGA
  signal VgaXxDI : unsigned(COORD_BW - 1 downto 0);
  signal VgaYxDI : unsigned(COORD_BW - 1 downto 0);

  -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
  signal VSYNCxSI : std_logic;

  -- Ball and plate coordinates
  signal BallXxDO  : unsigned(COORD_BW - 1 downto 0);
  signal BallYxDO  : unsigned(COORD_BW - 1 downto 0);
  signal PlateXxDO : unsigned(COORD_BW - 1 downto 0);

--=============================================================================
-- COMPONENT DECLARATIONS
--=============================================================================

  component pong_fsm is
    port (
	  CLKxCI : in std_logic;
	  RSTxRI : in std_logic;

	  -- Controls from push buttons
	  LeftxSI  : in std_logic;
	  RightxSI : in std_logic;

	  -- Coordinate from VGA
	  VgaXxDI : in unsigned(COORD_BW - 1 downto 0);
	  VgaYxDI : in unsigned(COORD_BW - 1 downto 0);

	  -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
	  VSYNCxSI : in std_logic;

	  -- Ball and plate coordinates
	  BallXxDO  : out unsigned(COORD_BW - 1 downto 0);
	  BallYxDO  : out unsigned(COORD_BW - 1 downto 0);
	  PlateXxDO : out unsigned(COORD_BW - 1 downto 0)
    );
  end component pong_fsm;

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
  dut: pong_fsm
    port map (
      CLKxCI => CLKxCI,
      RSTxRI => RSTxRI,

	  LeftxSI => LeftxSI,
	  RightxSI => RightxSI,

	  -- Coordinate from VGA
	  VgaXxDI => VgaXxDI,
	  VgaYxDI => VgaYxDI,

	  -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
	  VSYNCxSI => VSYNCxSI,

	  -- Ball and plate coordinates
	  BallXxDO => BallXxDO,
	  BallYxDO => BallYxDO,
	  PlateXxDO => PlateXxDO   
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
-- UNIT UNDER TEST
-- Verifies that the state machine changes from states accordingly
--=============================================================================
  uut: process is
  begin
    -- Test game doesn't start until Left and Right are on {{{1
	VSYNCxSI <= '1';
    LeftxSI <= '1';
    RightxSI <= '0';
	wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;
    
    assert BallXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) and
           BallYxDO = to_unsigned(VS_DISPLAY/2,COORD_BW) and
           PlateXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW);

    LeftxSI <= '0';
    RightxSI <= '0';
	wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;

    assert BallXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) and
           BallYxDO = to_unsigned(VS_DISPLAY/2,COORD_BW) and
           PlateXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) 
           report "Game shouldn't have started. We haven't told it to";

    LeftxSI <= '0';
    RightxSI <= '1';
	wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;
    
    assert BallXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) and
           BallYxDO = to_unsigned(VS_DISPLAY/2,COORD_BW) and
           PlateXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW);

    LeftxSI <= '0';
    RightxSI <= '0';
	wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;

    assert BallXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) and
           BallYxDO = to_unsigned(VS_DISPLAY/2,COORD_BW) and
           PlateXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) 
           report "Game shouldn't have started. We haven't told it to";
    -- }}}1

    -- Test until the keys are released the game doesn't start {{{1
    LeftxSI <= '1';
    RightxSI <= '1';
	wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;
    
    assert BallXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) and
           BallYxDO = to_unsigned(VS_DISPLAY/2,COORD_BW) and
           PlateXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW);

	wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;

    assert BallXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) and
           BallYxDO = to_unsigned(VS_DISPLAY/2,COORD_BW) and
           PlateXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) 
           report "Game shouldn't have started. We haven't released Right and Left yet";
    -- }}}1

    -- Start the game so it goes UpLeft first {{{1
    LeftxSI <= '0';
    RightxSI <= '0';
    VgaXxDI <= (others => '0');
    VgaYxDI <= (others => '0');

	wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;
    -- It now finally is in UpLeft

    assert BallXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) and
           BallYxDO = to_unsigned(VS_DISPLAY/2,COORD_BW) and
           PlateXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW);

	wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;
    -- We must have moved towards (0,0)

    assert BallXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) - BALL_STEP_X and
           BallYxDO = to_unsigned(VS_DISPLAY/2,COORD_BW) - BALL_STEP_Y and
           PlateXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW);
    -- }}}1

    -- Move the paddle once to the rigth {{{1
    LeftxSI <= '0';
    RightxSI <= '1';
	wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;
    -- We must have moved towards (0,0)

    assert BallXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) - 2*BALL_STEP_X and
           BallYxDO = to_unsigned(VS_DISPLAY/2,COORD_BW) - 2*BALL_STEP_Y and
           PlateXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) + PLATE_STEP_X
           report "The paddle hasn't moved to the right";
    -- }}}1

    -- Move the paddle once to the left {{{1
    LeftxSI <= '1';
    RightxSI <= '0';
	wait until CLKxCI'event and CLKxCI = '1' and RSTxRI = '0';
    wait for CLK_STIM;
    -- We must have moved towards (0,0)

    assert BallXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW) - 3*BALL_STEP_X and
           BallYxDO = to_unsigned(VS_DISPLAY/2,COORD_BW) - 3*BALL_STEP_Y and
           PlateXxDO = to_unsigned(HS_DISPLAY/2,COORD_BW)
           report "The paddle hasn't moved to the left";
    -- }}}1
  end process;
end architecture tb;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
-- vim: set fdm=marker sw=2 et: --
