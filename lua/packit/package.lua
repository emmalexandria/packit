local function is_array(tab)
	local i = 0
	for _ in pairs(tab) do
		i = i + 1
		if t[i] == nil then return false end
	end
	return true
end

---@param ret table
---@return table[]
local function unify_packages(ret)
	local packages = {}
	if is_array(ret) then
		for i, t in ipairs(ret) do
			packages[i] = t
		end
	else
		packages[1] = ret
	end
	return packages
end

---@param src string
local function categorise_src(src)
	if src:sub(1, 8) == "https://" then
		return "url"
	else
		return "github"
	end
end



---@class PackitMan
---@field top_level PackitSpec[]
---@field load_order PackitSpec[]
local M = {}

function M.load()
	local config = vim.fn.stdpath("config")

	vim.notify(config)

	local plugins = config .. "/lua/plugins"

	for name, type in vim.fs.dir(plugins) do
		if type == "file" and name:sub(-4) == ".lua" then
			local mod = name:gsub("%.lua$", "")
			local tab = require("plugins." .. mod)
			local packages = unify_packages(tab)

			M.top_level = vim.tbl_deep_extend('force', M.top_level, packages)
		end
	end
end

function M.decide_order()
end

---@param spec PackitSpec
function M.install_spec(spec)
	local src_type = categorise_src(spec[1])

	if src_type == "github" then

	else if src_type == "url" then
		
	end
end

return M
