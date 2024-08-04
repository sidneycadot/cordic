
library ieee;

use ieee.std_logic_1164.all;
use ieee.math_real.all;
use ieee.math_complex.all;
use ieee.numeric_std.all;
use ieee.fixed_pkg.all;

use std.textio.all;

use work.cordic_definitions.all;

entity cordic_tb is
end entity cordic_tb;


architecture arch of cordic_tb is

signal CLK : std_logic := '0';

signal angle: angle_type;
signal angle_valid: std_logic;

signal xy       : xy_vector_type;
signal xy_valid : std_logic;

begin

    process is
    variable v : angle_type;
    begin
    	for cycle in 1 to 50 loop

        	wait for 10 ns;

        	if cycle >= 10 and cycle <= 34 then
        	    v := to_angle((real((cycle - 10) mod 24) / 24.0 + 0.5) mod 1.0 - 0.5);
        	    write(output, "[" & to_string(cycle) & "] request: " & " " & to_string(to_real(v)) & LF);
        	    angle <= v;
        	    angle_valid <= '1';
        	else
        	    angle <= INVALID_ANGLE;
        	    angle_valid <= '0';
        	end if;

        	CLK <= '1';

        	wait for 10 ns;

        	CLK <= '0';

        	if xy_valid = '1' then
    			write(output, "[" & to_string(cycle) & "] result: " & to_string(to_real(xy.x)) & " " & to_string(to_real(xy.y)) & LF);
    		end if;

        end loop;
        wait;
    end process;

    cordic_instance : entity work.cordic
        generic map (
            num_stages => 32
        )
        port map (
            CLK         => CLK,
            RESET       => '0',
            --
            IN_ANGLE    => angle,
            IN_VALID    => angle_valid,
            --
            OUT_XY      => xy,
            OUT_VALID   => xy_valid,
            OUT_READY   => '1'
        );

end architecture arch;
