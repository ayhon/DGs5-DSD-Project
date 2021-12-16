--=============================================================================
-- @file vga_controller_updater.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_controller_updater is -- {{{
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
    LoopCompletedxSO : out std_logic; -- TODO: Independent from enable
	CountxDO : out unsigned(BW-1 downto 0)
  );
end vga_controller_updater; -- }}}

architecture rtl of vga_controller_updater is
  -- Declarations {{{
  signal SyncxS : std_logic; -- TODO: Redundant, use SyncxSO
  signal RecoveryxS : std_logic; -- TODO: Redudant, use RecoveryxSO
  signal LoopCompletedxS : std_logic;
  signal CountxD : unsigned(BW-1 downto 0);
  -- }}}
begin
  calculate_outputs: process (all) is -- {{{
  begin
    LoopCompletedxS <= '1' when CountxDI + 1 = TOP + FRONT_PORCH + PULSE + BACK_PORCH else
                       '0';
	CountxD <= (others => '0') when LoopCompletedxS = '1' else
			   CountxDI + 1 when EnablexSI = '1' else
               CountxDI;
    RecoveryxS <= '1' when CountxD >= TOP else 
                   '0';
    SyncxS <= not POLARITY when CountxD < TOP + FRONT_PORCH or CountxD >= TOP + FRONT_PORCH + PULSE else
               POLARITY;
  end process;
  -- }}}

  -- Expose stored values {{{ CountxDO <= CountxD;
  SyncxSO <= SyncxS;
  RecoveryxSO <= RecoveryxS;
  LoopCompletedxSO <= LoopCompletedxS;
  CountxDO <= CountxD;
  -- }}}
end rtl;
