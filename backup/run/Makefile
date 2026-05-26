# 默认跑的基础 case 名称。可以在命令行通过 `make sim tc=你的case名` 来覆盖
tc ?= tc_basic

# 指向对应的 sim.cfg 文件
CFG_FILE = ../cases/$(tc)/sim.cfg

# 用 shell 命令提取 sim.cfg 里面的配置参数
# 改成管道串联，避免在 shell 函数里使用正则表达式的圆括号
SIM_ARGS = $(shell if [ -f $(CFG_FILE) ]; then grep -v '^[[:space:]]*//' $(CFG_FILE) | grep -v '^[[:space:]]*\#' | tr '\n' ' '; fi)

.PHONY: com sim verdi all regression

com:
	vcs -sverilog -ntb_opts uvm -full64 -f file.list -debug_access+all 2>&1 | tee compile.log

# 统一的仿真命令入口
sim:
	@if [ ! -f $(CFG_FILE) ]; then \
		echo "Error: Cannot find config file $(CFG_FILE)"; \
		exit 1; \
	fi
	@echo "--------------------------------------------------------"
	@echo "Running case : $(tc)"
	@echo "Config args  : $(SIM_ARGS)"
	@echo "--------------------------------------------------------"
	./simv $(SIM_ARGS) -l $(tc)_sim.log

verdi:
	verdi -sv -f file.list -ssf tb.fsdb &

all: com sim

# Discover all case directories under ../cases (basename only)
CASES := $(shell if [ -d ../cases ]; then for d in ../cases/*; do [ -d "$$d" ] && basename "$$d"; done; fi)

# Optional case list file (one case name per line). If present, regress will use it.
CASE_LIST := case.list

regression: com
	@echo "Starting regression (runner)..."
	@bash regress_runner.sh