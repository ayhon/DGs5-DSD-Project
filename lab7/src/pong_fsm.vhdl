--=============================================================================
-- @file pong_fsm.vhdl
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
-- pong_fsm
--
-- @brief This file specifies a basic circuit for the pong game. Note that coordinates are counted
-- from the upper left corner of the screen.
--
--=============================================================================

--=============================================================================
-- ENTITY DECLARATION FOR PONG_FSM
--=============================================================================
entity pong_fsm is
  port (
    CLKxCI : in std_logic;
    RSTxRI : in std_logic;

    -- Controls from push buttons
    LeftxSI  : in std_logic;
    RightxSI : in std_logic;

    -- Coordinates from VGA
    VgaXxDI : in unsigned(COORD_BW - 1 downto 0);
    VgaYxDI : in unsigned(COORD_BW - 1 downto 0);

    -- Signals from video interface to synchronize (HIGH for 1 CC, when vertical sync starts)
    VSYNCxSI : in std_logic;

    -- Ball and plate coordinates
    BallXxDO  : out unsigned(COORD_BW - 1 downto 0);
    BallYxDO  : out unsigned(COORD_BW - 1 downto 0);
    PlateXxDO : out unsigned(COORD_BW - 1 downto 0)
  );
end pong_fsm;

--=============================================================================
-- ARCHITECTURE DECLARATION
--=============================================================================
architecture rtl of pong_fsm is
	type PongState is (MainScreen, MainScreenLeave, UpLeft, UpRight, DownLeft, DownRight);
	signal StatexDP, StatexDN : PongState;
	signal BallXxDP, BallXxDN : unsigned(COORD_BW - 1 downto 0);
	signal BallYxDP, BallYxDN : unsigned(COORD_BW - 1 downto 0);
	signal PlateXxDP, PlateXxDN : unsigned(COORD_BW - 1 downto 0);
	signal AbovePlatexS : std_logic;
	signal SumOfVgaCoordinatesxD : std_logic_vector(COORD_BW - 1 downto 0);
    -- TODO: Use constants as boundaries, instead of having HS_DISPLAY - BALL_WIDTH/2 all over the code

    constant BALL_X_MAX : natural := HS_DISPLAY - BALL_WIDTH/2; -- 1019
    constant BALL_X_MIN : natural := BALL_WIDTH/2; -- 5

    constant BALL_Y_MAX : natural := VS_DISPLAY - PLATE_HEIGHT - BALL_HEIGHT/2; -- 753
    constant BALL_Y_MIN : natural := BALL_HEIGHT/2; -- 5

    constant PLATE_X_MAX : natural := HS_DISPLAY - PLATE_WIDTH/2; -- 989
    constant PLATE_X_MIN : natural := PLATE_WIDTH/2; -- 35

--=============================================================================
-- ARCHITECTURE BEGIN
--=============================================================================
begin
	registers: process (CLKxCI, RSTxRI) is -- {{{
	begin
	  if RSTxRI = '1' then
	    StatexDP <= MainScreen;
		BallXxDP <= to_unsigned(HS_DISPLAY/2,COORD_BW);
		PlateXxDP <= to_unsigned(HS_DISPLAY/2,COORD_BW);
		BallYxDP <= to_unsigned(VS_DISPLAY/2,COORD_BW);
	  elsif CLKxCI'event and CLKxCI = '1' then
	    StatexDP <= StatexDN;
		BallXxDP <= BallXxDN;
		BallYxDP <= BallYxDN;
		PlateXxDP <= PlateXxDN;
	  end if;
	end process; -- }}}

	next_state: process (all) is -- {{{
	begin
        -- Default values {{{2
        StatexDN <= StatexDP;
        BallXxDN <= BallXxDP;
        BallYxDN <= BallYxDP;
        PlateXxDN <= PlateXxDP;
        -- }}}2
		if VSYNCxSI = '1' then
			-- Check if the ball is above the plate -- {{{2
            
            -- TODO: To not use -, pass to the other side of the equation
			AbovePlatexS <= '1' when PlateXxDP <= BallXxDP + PLATE_WIDTH/2  and BallXxDP <= PlateXxDP + PLATE_WIDTH/2 else 
						   '0';
			-- }}}2
			-- Calculate plate's next position, depending on the values of the Left and Right signals -- {{{2
            PlateXxDN <= to_unsigned(HS_DISPLAY/2,COORD_BW) when StatexDP = MainScreen or StatexDP = MainScreenLeave else 
                         PlateXxDP + PLATE_STEP_X           when LeftxSI = '0' and RightxSI = '1' and PlateXxDP <= PLATE_X_MAX else
                         PlateXxDP - PLATE_STEP_X           when LeftxSI = '1' and RightxSI = '0' and PlateXxDP >= PLATE_X_MIN else
                         PlateXxDP;
            -- }}}2
			-- Calculate the next State and Balls' position depending on state -- {{{2
			SumOfVgaCoordinatesxD <= std_logic_vector(VgaXxDI + VgaYxDI);
			case StatexDP is
			  when MainScreen => -- {{{3
				BallXxDN <= to_unsigned(HS_DISPLAY/2,COORD_BW);
				BallYxDN <= to_unsigned(VS_DISPLAY/2,COORD_BW);
			  
				StatexDN <= MainScreenLeave when RightxSI = '1' and LeftxSI = '1' else
							MainScreen;
			  -- }}}3
			  when MainScreenLeave => -- {{{3
                StatexDN <= UpRight when RightxSI = '0' and LeftxSI = '0' and SumOfVgaCoordinatesxD(0) = '0' else
							UpLeft  when RightxSI = '0' and LeftxSI = '0' and SumOfVgaCoordinatesxD(0) = '1' else
							MainScreenLeave;
			  -- }}}3
			  when UpLeft => -- {{{3
				BallXxDN <= BallXxDP - BALL_STEP_X;
				BallYxDN <= BallYxDP - BALL_STEP_Y;

				StatexDN <= DownRight when BallXxDN <= BALL_X_MIN and BallYxDN <= BALL_Y_MIN else
							UpRight when BallXxDN <= BALL_X_MIN else
							DownLeft when BallYxDN <= BALL_Y_MIN else
							UpLeft;
			  -- }}}3
			  when UpRight => -- {{{3
				BallXxDN <= BallXxDP + BALL_STEP_X;
				BallYxDN <= BallYxDP - BALL_STEP_Y;

				StatexDN <= DownLeft when BallXxDN >= BALL_X_MAX and BallYxDN <= BALL_Y_MIN else
							UpLeft when BallXxDN >= BALL_X_MAX else
							DownRight when BallYxDN <= BALL_Y_MIN else
							UpRight;
			  -- }}}3
			  when DownLeft => -- {{{3
				BallXxDN <= BallXxDP - BALL_STEP_X;
				BallYxDN <= BallYxDP + BALL_STEP_Y;

				StatexDN <= MainScreen when AbovePlatexS = '0' and BallYxDN >= BALL_Y_MAX else
                            UpRight    when AbovePlatexS = '1' and BallYxDN >= BALL_Y_MAX and BallXxDN <= BALL_X_MIN else
							UpLeft     when AbovePlatexS = '1' and BallYxDN >= BALL_Y_MAX else
							DownRight  when BallXxDN <= BALL_X_MIN else
							DownLeft;
			  -- }}}3
			  when DownRight => -- {{{3
				BallXxDN <= BallXxDP + BALL_STEP_X;
				BallYxDN <= BallYxDP + BALL_STEP_Y;

				StatexDN <= MainScreen when AbovePlatexS = '0' and BallYxDN >= BALL_Y_MAX else
                            UpLeft     when AbovePlatexS = '1' and BallYxDN >= BALL_Y_MAX and BallXxDN >= BALL_X_MAX else 
							UpRight    when AbovePlatexS = '1' and BallYxDN >= BALL_Y_MAX else
							DownLeft   when BallXxDN >= BALL_X_MAX else
							DownRight;
			  -- }}}3
			end case; -- }}}2
		end if;
	end process; -- }}}

	-- Expose register values {{{
    BallXxDO <= BallXxDP;
    BallYxDO <= BallYxDP;
    PlateXxDO <= PlateXxDP;
	-- }}}
end rtl;
--=============================================================================
-- ARCHITECTURE END
--=============================================================================
-- vim: set fdm=marker sw=2 et: --
