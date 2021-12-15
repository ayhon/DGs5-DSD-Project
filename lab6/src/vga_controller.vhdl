--=============================================================================
-- @file vga_controller.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Packages
library work;
use work.dsd_prj_pkg.all;

--=============================================================================
--
-- vga_controller
--
-- @brief This file specifies a VGA controller circuit
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR VGA_CONTROLLER
--=============================================================================
entity vga_controller is -- {{{
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    -- Data/color input
    RedxSI   : in std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSI : in std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSI  : in std_logic_vector(COLOR_BW - 1 downto 0);

    -- Coordinate output
    XCoordxDO : out unsigned(COORD_BW - 1 downto 0);
    YCoordxDO : out unsigned(COORD_BW - 1 downto 0);

    -- Timing output
    HSxSO : out std_logic;
    VSxSO : out std_logic;

    -- Data/color output
    RedxSO   : out std_logic_vector(COLOR_BW - 1 downto 0);
    GreenxSO : out std_logic_vector(COLOR_BW - 1 downto 0);
    BluexSO  : out std_logic_vector(COLOR_BW - 1 downto 0)
  );
end vga_controller; -- }}}

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of vga_controller is 
	-- Declarations {{{
	component vga_controller_updater is -- {{{2
      generic (
        BW : natural;

        TOP : natural;
        FRONT_PORCH : natural;
        PULSE : natural;
        BACK_PORCH : natural;
        POLARITY : std_logic
      );
      port (
        CLKxCI : in std_logic;
        RSTxRI : in std_logic;

        EnablexSI : in std_logic;
        CountxDI : in unsigned(BW-1 downto 0);
      
        SyncxSO : out std_logic;
        RecoveryxSO : out std_logic;
        LoopCompletedxSO : out std_logic;
        CountxDO : out unsigned(BW-1 downto 0)
      );
	end component;  -- }}}2

    -- Auxiliary signals
	signal HRxS, VRxS : std_logic;
    signal PixelLoopCompletedxS : std_logic;

    -- Register signals
    signal HSxSN, HSxSP  : std_logic;
    signal VSxSN, VSxSP  : std_logic;
    signal XCoordxDN, XCoordxDP  : unsigned(COORD_BW - 1 downto 0);
    signal YCoordxDN, YCoordxDP  : unsigned(COORD_BW - 1 downto 0);
    signal RedxSN, RedxSP : std_logic_vector(COLOR_BW - 1 downto 0);
    signal GreenxSN, GreenxSP : std_logic_vector(COLOR_BW - 1 downto 0);
    signal BluexSN, BluexSP : std_logic_vector(COLOR_BW - 1 downto 0);
	-- }}}

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin
  registers: process (CLKxCI, RSTxRI) is -- {{{
  begin
    if RSTxRI = '1' then
      HSxSP <= not HS_POLARITY;
      VSxSP <= not VS_POLARITY;

      XCoordxDP  <= (others => '0');
      YCoordxDP  <= (others => '0');

      RedxSP <= (others => '0');
      BluexSP <= (others => '0');
      GreenxSP <= (others => '0');
    elsif CLKxCI'event and CLKxCI = '1' then
      HSxSP <= HSxSN;
      VSxSP <= VSxSN;

      XCoordxDP  <= XCoordxDN;
      YCoordxDP  <= YCoordxDN;

      RedxSP <= RedxSN;
      BluexSP <= BluexSN;
      GreenxSP <= GreenxSN;
    end if;
  end process; -- }}}

  PixelUpdater: vga_controller_updater -- {{{
  generic map (
	BW => COORD_BW,
	TOP => HS_DISPLAY,
	FRONT_PORCH => HS_FRONT_PORCH,
	PULSE => HS_PULSE,
	BACK_PORCH => HS_BACK_PORCH,
	POLARITY => HS_POLARITY
  )
  port map (
	CLKxCI => CLKxCI,
	RSTxRI => RSTxRI,

    EnablexSI => '1',
    CountxDI => XCoordxDP,

	CountxDO => XCoordxDN,
	RecoveryxSO => HRxS,
	SyncxSO => HSxSN,
    LoopCompletedxSO => PixelLoopCompletedxS
  ); -- }}}

  LineUpdater: vga_controller_updater -- {{{
  generic map (
	BW => COORD_BW,
	TOP => VS_DISPLAY,
	FRONT_PORCH => VS_FRONT_PORCH,
	PULSE => VS_PULSE,
	BACK_PORCH => VS_BACK_PORCH,
	POLARITY => VS_POLARITY
  )
  port map (
	CLKxCI => CLKxCI,
	RSTxRI => RSTxRI,

    EnablexSI => PixelLoopCompletedxS,
    CountxDI => YCoordxDP,

	CountxDO => YCoordxDN,
	RecoveryxSO => VRxS,
	SyncxSO => VSxSN
  ); -- }}}

  update_color_channels: process (all) is -- {{{
  begin
	  if VRxS = '1' or HRxS = '1' then
		RedxSN <= (others => '0');
		GreenxSN <= (others => '0');
		BluexSN <= (others => '0');
	  else
		RedxSN <= RedxSI;
		GreenxSN <= GreenxSI;
		BluexSN <= BluexSI;
	  end if;
  end process; -- }}}

  -- Expose register values {{{
  XCoordxDO  <= XCoordxDP;
  YCoordxDO  <= YCoordxDP;

  HSxSO <= HSxSP;
  VSxSO <= VSxSP;

  RedxSO <= RedxSP;
  GreenxSO <= GreenxSP;
  BluexSO <= BluexSP;
  -- }}}
end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
