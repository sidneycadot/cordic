
library ieee;

use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.fixed_pkg.all;

use std.textio.all;

use work.cordic_definitions.all;

entity cordic is
    port (
        CLK       : in  std_logic;
        RESET     : in  std_logic;
        --
        IN_ANGLE  : in  angle_type;
        IN_VALID  : in  std_logic;
        IN_READY  : out std_logic;
        --
        OUT_XY    : out xy_vector_type;
        OUT_VALID : out std_logic;
        OUT_READY : in  std_logic
    );

end entity cordic;


architecture arch of cordic is

function cordic_initial_radius(n: in natural) return real is

-- Each stage of the CORDIC has a gain equal to 1 / cos(arctan(0.5 ** k)), where k is the stage order.
-- This gain is > 1. In order to end up with a vector on the unit circle, we need to start with a vector
-- that is closer to the origin. This function calculates the radius of that initial vector.

variable product : real := 1.0;
variable q : real := 1.0;

begin
    for k in 0 to n - 1 loop
        product := product * (1.0 + q);
        q := q * 0.25;
    end loop;
    return 1.0 / sqrt(product);
end function cordic_initial_radius;

constant initial_radius : real := cordic_initial_radius(NUMBER_OF_STAGES);

type StateType is record
        in_ready            : std_logic;
        --
        buf_angle           : angle_type;
        --
        out_angle_remaining : angle_type;
        out_xy              : xy_vector_type;
        out_valid           : std_logic;
    end record StateType;

constant reset_state : StateType := (
        in_ready            => '1',
        --
        buf_angle           => ZERO_ANGLE,
        --
        out_angle_remaining => ZERO_ANGLE,
        out_xy              => ZERO_XY_VECTOR,
        out_valid           => '0'
    );

function next_state(
        current_state : in StateType;
        P_RESET       : in std_logic;
        P_IN_VALID    : in std_logic;
        P_IN_ANGLE    : in angle_type;
        P_OUT_READY   : in std_logic
    ) return StateType is

variable state : StateType := current_state;

begin

    if P_RESET = '1' then
        state := reset_state;
    else

        -- Handle input.

        if state.in_ready = '1' and P_IN_VALID = '1' then
            state.buf_angle := P_IN_ANGLE;
            state.in_ready := '0';
        end if;

        -- Handle output.

        if state.out_valid = '1' and P_OUT_READY = '1' then
            state.out_valid := '0';
        end if;

        -- Process buffered value if/when we can push it out.

        if state.in_ready = '0' and state.out_valid = '0' then

            if state.buf_angle >= 0.0 then
                -- Angle is positive or zero.
                state.out_xy := to_xy_vector(0.0, +initial_radius);
                state.out_angle_remaining := resize(state.buf_angle - 0.25, state.out_angle_remaining);
            else
                -- Angle is negative.
                state.out_xy := to_xy_vector(0.0, -initial_radius);
                state.out_angle_remaining := resize(state.buf_angle + 0.25, state.out_angle_remaining);
            end if;

            state.in_ready := '1';
            state.out_valid := '1';
        end if;

    end if;

    return state;

end function next_state;

signal current_state : StateType := reset_state;

signal cordic_recursive_instance_in_ready : std_logic;

begin

    current_state <= next_state(current_state, RESET, IN_VALID, IN_ANGLE, cordic_recursive_instance_in_ready) when rising_edge(CLK);

    cordic_recursive_instance : entity work.cordic_recursive
        generic map (
            stage => 0
        )
        port map (
            CLK                 => CLK,
            RESET               => RESET,
            --
            IN_ANGLE_REMAINING  => current_state.out_angle_remaining,
            IN_XY               => current_state.out_xy,
            IN_VALID            => current_state.out_valid,
            IN_READY            => cordic_recursive_instance_in_ready,
            --
            OUT_ANGLE_REMAINING => open,
            OUT_XY              => OUT_XY,
            OUT_VALID           => OUT_VALID,
            OUT_READY           => OUT_READY
        );

end architecture arch;
