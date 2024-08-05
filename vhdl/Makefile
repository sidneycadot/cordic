
.PHONY : default clean

default:
	$(RM) work-obj08.cf
	ghdl -a --std=08 cordic_definitions.vhdl cordic_recursive.vhdl  cordic.vhdl cordic_tb.vhdl 
	ghdl -r --std=08 cordic_tb

clean:
	$(RM) work-obj08.cf
