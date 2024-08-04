
library ieee;

use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

use work.cordic_definitions.all;


entity cordic_recursive is

    generic (
        stage : natural;
        num_stages : natural
    );
    port (
        CLK                 : in  std_logic;
        RESET               : in  std_logic;
        --
        IN_ANGLE_REMAINING  : in  angle_type;
        IN_XY               : in  xy_vector_type;
        IN_VALID            : in  std_logic;
        IN_READY            : out std_logic;
        --
        OUT_ANGLE_REMAINING : out angle_type;
        OUT_XY              : out xy_vector_type;
        OUT_VALID           : out std_logic;
        OUT_READY           : in  std_logic
    );

end entity cordic_recursive;


architecture arch of cordic_recursive is

constant angle_step : angle_type := to_angle(arctan(0.5 ** stage) / MATH_2_PI);

type StateType is record
        in_ready            : std_logic;
        --
        buf_angle_remaining : angle_type;
        buf_xy              : xy_vector_type;
        --
        out_angle_remaining : angle_type;
        out_xy              : xy_vector_type;
        out_valid           : std_logic;
    end record StateType;

constant reset_state : StateType := (
        in_ready            => '1',
        --
        buf_angle_remaining => INVALID_ANGLE,
        buf_xy              => INVALID_XY_VECTOR,
        --
        out_angle_remaining => INVALID_ANGLE,
        out_xy              => INVALID_XY_VECTOR,
        out_valid           => '0'
    );

function next_state(
            current_state        : in StateType;
            P_RESET              : in std_logic;
            P_IN_VALID           : in std_logic;
            P_IN_ANGLE_REMAINING : in angle_type;
            P_XY                 : in xy_vector_type;
            P_OUT_READY          : in std_logic
        ) return StateType is

variable state : StateType := current_state;


begin

    if P_RESET = '1' then
        state := reset_state;
    else

        -- If input is available (VALID), and we have signaled our willingness to accept (READY),
        --   we accept the input.
        -- Note that we immediately process the input to the values that we want to output, to
        --   minimize combinatorial logic.
        -- The result is stored in the 'state.buf_angle_remaining' and 'state.buf_xy' variables.

        if state.in_ready = '1' and P_IN_VALID = '1' then

            if P_IN_ANGLE_REMAINING >= 0.0 then
                -- Angle remaining is zero or positive. Rotate counter-clockwise.
                state.buf_angle_remaining := resize(P_IN_ANGLE_REMAINING - angle_step, state.buf_angle_remaining);
                state.buf_xy := (
                    x => resize(P_XY.x - scalb(P_XY.y, -stage), state.buf_xy.x),
                    y => resize(P_XY.y + scalb(P_XY.x, -stage), state.buf_xy.y)
                );
            else
                -- Angle remaining is negative. Rotate clockwise.
                state.buf_angle_remaining := resize(P_IN_ANGLE_REMAINING + angle_step, state.buf_angle_remaining);
                state.buf_xy := (
                    x => resize(P_XY.x + scalb(P_XY.y, -stage), state.buf_xy.x),
                    y => resize(P_XY.y - scalb(P_XY.x, -stage), state.buf_xy.y)
                );
            end if;

            state.in_ready := '0';
        end if;

        -- Handle confirmed output.

        if state.out_valid = '1' and P_OUT_READY = '1' then
            state.out_valid := '0';
        end if;

        -- Publish buffered result if possible.

        if state.in_ready = '0' and state.out_valid = '0' then
            state.out_angle_remaining := state.buf_angle_remaining;
            state.out_xy := state.buf_xy;
            state.in_ready := '1';
            state.out_valid := '1';
        end if;

    end if;

    return state;

end function next_state;

signal current_state : StateType := reset_state;

signal client_ready : std_logic;

begin

    current_state <= next_state(current_state, RESET, IN_VALID, IN_ANGLE_REMAINING, IN_XY, client_ready) when rising_edge(CLK);

    IN_READY <= current_state.in_ready;

    gen: if stage = num_stages - 1 generate
        begin

            -- We have a single stage.
            -- Publish the output signals of the stage as outputs.
            -- The "client_ready" signal to the stage logic is provided by the incoming entity signal OUT_READY.

            OUT_ANGLE_REMAINING <= current_state.out_angle_remaining;
            OUT_XY              <= current_state.out_xy;
            OUT_VALID           <= current_state.out_valid;

            client_ready <= OUT_READY;
        end;
    else generate
        begin

            -- Our stage's output recursively connects to a smaller 'cordic_recursive' instance.

            recursive_instance : entity work.cordic_recursive
                generic map (
                    stage      => stage + 1,
                    num_stages => num_stages
                )
                port map (
                    CLK                 => CLK,
                    RESET               => RESET,
                    --
                    IN_ANGLE_REMAINING  => current_state.out_angle_remaining,
                    IN_XY               => current_state.out_xy,
                    IN_VALID            => current_state.out_valid,
                    IN_READY            => client_ready,
                    --
                    OUT_ANGLE_REMAINING => OUT_ANGLE_REMAINING,
                    OUT_XY              => OUT_XY,
                    OUT_VALID           => OUT_VALID,
                    OUT_READY           => OUT_READY
                );

        end;
    end generate gen;


end architecture arch;
