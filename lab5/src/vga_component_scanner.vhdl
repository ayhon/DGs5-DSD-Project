--=============================================================================
-- @file vga_component_scanner.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity vga_component_scanner is
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
  
	CountxDO : out unsigned(BW-1 downto 0);
	RecoveryxSO : out std_logic;
	SyncxSO : out std_logic;
    LoopCompletedxSO : out std_logic
  );
end vga_component_scanner;

architecture rtl of vga_component_scanner is
  -- Declarations {{{
  signal SyncxSN, SyncxSP : std_logic;
  signal RecoveryxSN, RecoveryxSP : std_logic;
  signal LoopCompletedxSN, LoopCompletedxSP : std_logic;
  signal CountxDN, CountxDP : unsigned(BW-1 downto 0);
  -- }}}
begin
  Registers: process (CLKxCI, RSTxRI) is -- {{{
  begin
    if RSTxRI = '1' then
      CountxDP <= (others => '0');

      SyncxSP <= not POLARITY;
      RecoveryxSP <= '0';
      LoopCompletedxSP <= '0';
    elsif CLKxCI'event and CLKxCI = '1' then
      CountxDP <= CountxDN;

      SyncxSP <=SyncxSN;
      RecoveryxSP <=RecoveryxSN;
      LoopCompletedxSP <=LoopCompletedxSN;
    end if;
  end process; -- }}}

  calculate_next_states: process (all) is -- {{{
  begin
    LoopCompletedxSN <= '1' when CountxDP + 1 /= TOP + FRONT_PORCH + PULSE + BACK_PORCH else
                        '0';
    CountxDN <= CountxDP + 1 when LoopCompletedxSN = '1' else
                (others => '0');
    RecoveryxSN <= '1' when CountxDN >= TOP else 
                   '0';
    SyncxSN <= not POLARITY when CountxDN < TOP + FRONT_PORCH or CountxDN >= TOP + FRONT_PORCH + PULSE else
               POLARITY;
  end process;
  -- }}}

  -- Expose stored values {{{
  CountxDO <= CountxDP;
  RecoveryxSO <= RecoveryxSP;
  SyncxSO <= SyncxSP;
  LoopCompletedxSO <= LoopCompletedxSP;
  -- }}}
end rtl;
