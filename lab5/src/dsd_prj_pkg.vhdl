
--=============================================================================
-- @file dsd_prj_pkg.vhdl
--=============================================================================
-- Standard library
library ieee;
-- Standard packages
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--=============================================================================
--
-- dsd_prj_pkg
--
-- @brief This file specifies the parameters used for the VGA controller, pong and mandelbrot circuits
--
-- The parameters are given here http://tinyvga.com/vga-timing/1024x768@70Hz
-- with a more elaborate explanation at https://projectf.io/posts/video-timings-vga-720p-1080p/
--=============================================================================

package dsd_prj_pkg is

  -- Bitwidths for screen coordinate and colors
  constant COLOR_BW : natural := 4;
  constant COORD_BW : natural := 12;

  -- Horizontal timing parameters
  constant HS_DISPLAY     : natural   := 1024;
  constant HS_FRONT_PORCH : natural   := 24;
  constant HS_PULSE       : natural   := 136;
  constant HS_BACK_PORCH  : natural   := 144;
  constant HS_POLARITY    : std_logic := '0';

  -- Vertical timing parameters
  constant VS_DISPLAY     : natural   := 768;
  constant VS_FRONT_PORCH : natural   := 3;
  constant VS_PULSE       : natural   := 6;
  constant VS_BACK_PORCH  : natural   := 29;
  constant VS_POLARITY    : std_logic := '0';

end package dsd_prj_pkg;
