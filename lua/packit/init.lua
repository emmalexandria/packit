local M = {}

---@param config PackitConfig
function M.setup(config)
	require("packit.package").load()
end

return M
