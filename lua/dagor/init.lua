local M = {}

---@class dagor.Config
---@field detect boolean map *.nut, *.blk and *.das to the first filetype of their language
---@field install boolean build a missing parser the first time its filetype opens
---@field highlight boolean start tree-sitter highlighting in matching buffers
---@field filetypes table<string, string[]> filetypes that use each language
---@field install_info table<string, table> per-language override of the parser source
M.defaults = {
	detect = true,
	install = true,
	highlight = true,
	filetypes = { quirrel = { "quirrel" }, blk = { "blk" }, daslang = { "daslang" } },
	install_info = {},
}

local EXTENSIONS = { nut = "quirrel", blk = "blk", das = "daslang" }

local augroup = vim.api.nvim_create_augroup("dagor", { clear = true })
local config = vim.deepcopy(M.defaults)
local ft_lang = {} ---@type table<string, string>
local installing = {} ---@type table<string, boolean>
local failed = {} ---@type table<string, boolean>

local function loadable(lang)
	return vim.treesitter.language.add(lang) == true
end

-- Neovim caches runtime file lookups; a changed 'runtimepath' drops the cache,
-- so a parser that appeared after the first failed lookup becomes visible.
local function refresh_runtimepath()
	local rtp = vim.o.rtp
	vim.o.rtp = rtp .. ","
	vim.o.rtp = rtp
end

local function start(buf, lang)
	if vim.api.nvim_buf_is_loaded(buf) and not vim.treesitter.highlighter.active[buf] then
		vim.treesitter.start(buf, lang)
	end
end

local function start_all(lang)
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if ft_lang[vim.bo[buf].filetype] == lang then
			start(buf, lang)
		end
	end
end

local function enable(buf, lang)
	if loadable(lang) then
		if config.highlight then
			start(buf, lang)
		end
		return
	end
	-- Buffers opened during the install are picked up when it finishes.
	if not config.install or installing[lang] or failed[lang] then
		return
	end
	local ok, ts = pcall(require, "nvim-treesitter")
	if not ok or type(ts.install) ~= "function" then
		failed[lang] = true
		vim.notify("dagor.nvim: nvim-treesitter (main branch) is required to install parsers", vim.log.levels.WARN)
		return
	end
	installing[lang] = true
	ts.install(lang):await(function(err)
		vim.schedule(function()
			installing[lang] = nil
			refresh_runtimepath()
			if err or not loadable(lang) then
				failed[lang] = true
				vim.notify(
					("dagor.nvim: could not install the %s parser, see :checkhealth dagor"):format(lang),
					vim.log.levels.WARN
				)
			elseif config.highlight then
				start_all(lang)
			end
		end)
	end)
end

-- nvim-treesitter reloads its parser table on every install and update, so
-- the entries are added from the TSUpdate event and not once at startup.
local function register_parsers()
	vim.api.nvim_create_autocmd("User", {
		group = augroup,
		pattern = "TSUpdate",
		callback = function()
			local parsers = require("nvim-treesitter.parsers")
			for lang, spec in pairs(require("dagor.parsers")) do
				local info = vim.tbl_deep_extend("force", spec.install_info, config.install_info[lang] or {})
				if info.path then
					info.url, info.revision = nil, nil
				end
				parsers[lang] = { install_info = info }
			end
		end,
	})
end

---@param opts? dagor.Config
function M.setup(opts)
	config = vim.tbl_deep_extend("force", M.defaults, vim.g.dagor or {}, opts or {})
	vim.api.nvim_clear_autocmds({ group = augroup })
	register_parsers()

	ft_lang = {}
	for lang in pairs(require("dagor.parsers")) do
		local fts = config.filetypes[lang] or {}
		for _, ft in ipairs(fts) do
			ft_lang[ft] = lang
		end
		vim.treesitter.language.register(lang, fts)
	end

	if config.detect then
		for ext, lang in pairs(EXTENSIONS) do
			local ft = (config.filetypes[lang] or {})[1]
			if ft then
				vim.filetype.add({ extension = { [ext] = ft } })
			end
		end
	end

	if next(ft_lang) == nil then
		return
	end
	vim.api.nvim_create_autocmd("FileType", {
		group = augroup,
		pattern = vim.tbl_keys(ft_lang),
		callback = function(ev)
			enable(ev.buf, ft_lang[ev.match])
		end,
	})
	-- The plugin can load after a buffer set its filetype (lazy loading).
	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		local lang = ft_lang[vim.bo[buf].filetype]
		if lang and vim.api.nvim_buf_is_loaded(buf) then
			enable(buf, lang)
		end
	end
end

--- Install all parsers; returns the nvim-treesitter task.
---@param opts? { force?: boolean }
function M.install(opts)
	local langs = vim.tbl_keys(require("dagor.parsers"))
	table.sort(langs)
	return require("nvim-treesitter").install(langs, opts)
end

return M
