
library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.fixed_pkg.all;

package cordic_definitions is

	-- Type and operations for "angle".

	constant ANGLE_BITS : natural := 32;

    subtype angle_type is sfixed(-1 downto -ANGLE_BITS);

    constant INVALID_ANGLE : angle_type := (others => '0');

    function to_angle(angle: in real) return angle_type;

    subtype xy_component_type is sfixed(2 downto -32);

    function to_xy_component(value: in real) return xy_component_type;

    constant INVALID_XY_VALUE : xy_component_type := (others => '0');

    type xy_vector_type is record
        	x : xy_component_type;
        	y : xy_component_type;
        end record xy_vector_type;

    function to_xy_vector(x: in real; y: in real) return xy_vector_type;

    constant INVALID_XY_VECTOR : xy_vector_type := (x => INVALID_XY_VALUE, y => INVALID_XY_VALUE);

end package cordic_definitions;


package body cordic_definitions is

	function to_angle(angle: in real) return angle_type is
	begin
		return to_sfixed(angle, angle_type'high, angle_type'low);
	end function to_angle;

	function to_xy_component(value: in real) return xy_component_type is
	begin
		return to_sfixed(value, xy_component_type'high, xy_component_type'low);
	end function to_xy_component;

	function to_xy_vector(x: in real; y: in real) return xy_vector_type is
	begin
		return (to_xy_component(x), to_xy_component(y));
	end function to_xy_vector;

end package body cordic_definitions;
