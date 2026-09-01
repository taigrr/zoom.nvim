BUSTED ?= $(shell command -v busted 2>/dev/null || printf '%s' "$$HOME/.luarocks/bin/busted")
LUACHECK ?= $(shell command -v luacheck 2>/dev/null || printf '%s' "$$HOME/.luarocks/bin/luacheck")

.PHONY: test lint

test:
	$(BUSTED) tests/

lint:
	$(LUACHECK) lua/ plugin/
