if vim.g.loaded_packit then return end

vim.g.loaded_packit = true

if vim.fn.has("nvim-0.12") == 0 then
	vim.notify("packit requires Neovim >= 0.12 (detected " .. tostring(vim.version) .. ")", vim.log.levels.ERROR)
	return
end
