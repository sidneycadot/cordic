
library ieee;

use ieee.std_logic_1164.all;
use ieee.fixed_pkg.all;

package cordic_definitions is

	constant NUMBER_OF_STAGES           : natural := 32; -- Number of CORDIC pipelining stages.
	constant ANGLE_BITS                 : natural := 32; -- Angle resolution.
	constant XY_SCALAR_DENOMINATOR_BITS : natural := 32; -- Determines sine/cosine resolution.

	-- Representation of positive and negative angles.

    subtype angle_type is sfixed(-1 downto -ANGLE_BITS);

    constant ZERO_ANGLE : angle_type := (others => '0');

    function to_angle(angle: in real) return angle_type;

    -- Representation of sine and cosine values.

    subtype xy_scalar_type is sfixed(1 downto -XY_SCALAR_DENOMINATOR_BITS);

    function to_xy_scalar(value: in real) return xy_scalar_type;

    constant ZERO_XY_SCALAR : xy_scalar_type := (others => '0');

    -- Representation of scaled (cosine, sine) vectors.

    type xy_vector_type is record
        	x : xy_scalar_type; -- Cosine
        	y : xy_scalar_type; -- Sine
        end record xy_vector_type;

    function to_xy_vector(x: in real; y: in real) return xy_vector_type;

    constant ZERO_XY_VECTOR : xy_vector_type := (x => ZERO_XY_SCALAR, y => ZERO_XY_SCALAR);

end package cordic_definitions;


package body cordic_definitions is

	function to_angle(angle: in real) return angle_type is
	begin
		return to_sfixed(angle, angle_type'high, angle_type'low);
	end function to_angle;

	function to_xy_scalar(value: in real) return xy_scalar_type is
	begin
		return to_sfixed(value, xy_scalar_type'high, xy_scalar_type'low);
	end function to_xy_scalar;

	function to_xy_vector(x: in real; y: in real) return xy_vector_type is
	begin
		return (to_xy_scalar(x), to_xy_scalar(y));
	end function to_xy_vector;

end package body cordic_definitions;
