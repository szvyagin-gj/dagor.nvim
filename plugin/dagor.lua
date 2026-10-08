if vim.g.loaded_dagor then
	return
end
vim.g.loaded_dagor = 1

require("dagor").setup()
