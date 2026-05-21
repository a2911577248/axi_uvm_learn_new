.PHONY: com sim all clean

com:
	vcs -sverilog -ntb_opts uvm -full64 -f file.list -debug_access+all

sim_bad:
	./simv +UVM_TESTNAME=test_axi_violation

sim:
	./simv

all: com sim