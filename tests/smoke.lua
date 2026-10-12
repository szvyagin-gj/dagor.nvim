-- Run through `make test`: it points XDG_* at an empty directory, so the
-- parsers are downloaded and built from the pinned GitHub revisions.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local failures = 0

local function check(cond, msg)
	io.stdout:write((cond and "ok    " or "FAIL  ") .. msg .. "\n")
	if not cond then
		failures = failures + 1
	end
end

local function capture_names(buf, lang)
	local tree = vim.treesitter.get_parser(buf, lang):parse()[1]
	local query = vim.treesitter.query.get(lang, "highlights")
	local seen = {}
	for id in query:iter_captures(tree:root(), buf) do
		seen[query.captures[id]] = true
	end
	return seen, tree:root():has_error()
end

local function open(name)
	vim.cmd.edit(root .. "/tests/fixtures/" .. name)
	return vim.api.nvim_get_current_buf()
end

local function case(name, lang, ft, expected)
	check(not vim.treesitter.language.add(lang), lang .. ": parser is absent before first use")
	local buf = open(name)
	check(vim.bo[buf].filetype == ft, lang .. ": filetype is " .. ft)
	-- The first open starts the install; highlighting starts when it ends.
	local started = vim.wait(300000, function()
		return vim.treesitter.highlighter.active[buf] ~= nil
	end, 200)
	check(started, lang .. ": parser installs on first use and highlighting starts")
	if not started then
		return
	end
	local seen, has_error = capture_names(buf, lang)
	check(not has_error, lang .. ": fixture parses without errors")
	for _, c in ipairs(expected) do
		check(seen[c], lang .. ": capture @" .. c)
	end
	check(vim.bo[buf].syntax == "", lang .. ": regex syntax is off")
end

case("sample.nut", "quirrel", "quirrel", {
	"keyword.function",
	"keyword.return",
	"constant",
	"function.method",
	"function.call",
	"function.method.call",
})
case("sample.blk", "blk", "blk", {
	"comment",
	"keyword.import",
	"string.special.path",
	"module",
	"property",
	"type.builtin",
})
case("sample.das", "daslang", "daslang", {
	"keyword.import",
	"keyword.type",
	"keyword.function",
	"keyword.repeat",
	"keyword.return",
	"attribute",
	"function",
	"function.call",
	"type.builtin",
	"string.escape",
})

local dagor = require("dagor")
check(dagor.install():wait(60000) == true, "install() succeeds when the parsers are present")

vim.cmd("silent! %bwipeout!")
dagor.setup({ filetypes = { quirrel = { "squirrel" } } })
local buf = open("sample.nut")
check(vim.bo[buf].filetype == "squirrel", "filetypes option: .nut opens as squirrel")
check(vim.treesitter.highlighter.active[buf] ~= nil, "filetypes option: squirrel buffer is highlighted")

dagor.setup({ install_info = { quirrel = { path = "/nonexistent/tree-sitter-quirrel" } } })
vim.api.nvim_exec_autocmds("User", { pattern = "TSUpdate" })
local info = require("nvim-treesitter.parsers").quirrel.install_info
check(
	info.path == "/nonexistent/tree-sitter-quirrel" and info.url == nil and info.revision == nil,
	"install_info option: local path replaces url and revision"
)

io.stdout:write(failures == 0 and "all checks passed\n" or (failures .. " check(s) failed\n"))
if failures > 0 then
	vim.cmd.cquit()
end
vim.cmd("qa!")
