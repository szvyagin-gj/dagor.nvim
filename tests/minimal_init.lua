-- Init for the smoke test: only this plugin and nvim-treesitter are on the runtimepath.
local root = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h")
local ts = vim.env.NVIM_TREESITTER
assert(ts and vim.uv.fs_stat(ts), "set NVIM_TREESITTER to a checkout of nvim-treesitter (main branch)")

vim.opt.rtp:prepend(ts)
vim.opt.rtp:prepend(root)
