local M = {}

local function exe(name, hint)
	if vim.fn.executable(name) == 1 then
		vim.health.ok(name .. " found")
	else
		vim.health.warn(name .. " not found", hint)
	end
end

function M.check()
	vim.health.start("dagor.nvim")

	if vim.fn.has("nvim-0.12") == 1 then
		vim.health.ok("Neovim 0.12 or newer")
	else
		vim.health.error("Neovim 0.12 or newer is required")
	end

	local ok, ts = pcall(require, "nvim-treesitter")
	if ok and type(ts.install) == "function" then
		vim.health.ok("nvim-treesitter (main branch) found")
	else
		vim.health.error(
			"nvim-treesitter main branch not found",
			"Install nvim-treesitter/nvim-treesitter (not the master branch)"
		)
	end

	vim.health.start("dagor.nvim: build tools")
	exe("tree-sitter", "Install the tree-sitter CLI; it builds the parsers")
	exe("curl", "Needed to download the grammar tarballs")
	exe("tar", "Needed to unpack the grammar tarballs")
	local cc = vim.iter({ "cc", "gcc", "clang" }):find(function(c)
		return vim.fn.executable(c) == 1
	end)
	if cc then
		vim.health.ok("C compiler found: " .. cc)
	else
		vim.health.warn("no C compiler found", "Install cc, gcc or clang")
	end

	vim.health.start("dagor.nvim: parsers")
	for lang in vim.spairs(require("dagor.parsers")) do
		local added, err = vim.treesitter.language.add(lang)
		local qok, query = pcall(vim.treesitter.query.get, lang, "highlights")
		if not added then
			vim.health.warn(
				("%s parser is not installed (%s)"):format(lang, err),
				"It installs on first use, or run require('dagor').install()"
			)
		elseif not qok or not query then
			vim.health.error(
				lang .. " parser is installed but the highlights query does not load",
				not qok and tostring(query) or nil
			)
		else
			vim.health.ok(lang .. " parser and highlights query load")
		end
	end
end

return M
