NVIM ?= nvim
NVIM_TREESITTER ?= $(HOME)/.local/share/nvim/plugged/nvim-treesitter

# Needs network access, the tree-sitter CLI and a C compiler.
.PHONY: test
test:
	@tmp=$$(mktemp -d) && \
	NVIM_TREESITTER=$(NVIM_TREESITTER) \
	XDG_DATA_HOME=$$tmp/data XDG_STATE_HOME=$$tmp/state \
	XDG_CACHE_HOME=$$tmp/cache XDG_CONFIG_HOME=$$tmp/config \
	$(NVIM) --headless -u tests/minimal_init.lua -i NONE -n -c 'luafile tests/smoke.lua'; \
	rc=$$?; rm -rf $$tmp; exit $$rc
