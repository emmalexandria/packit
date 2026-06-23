local function is_array(tab)
	local i = 0
	for _ in pairs(tab) do
		i = i + 1
		if tab[i] == nil then return false end
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
	M.top_level = {}
	M.load_order = {}

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

	M.decide_order()
	for _, pkg in pairs(M.load_order) do
		vim.api.nvim_create_autocmd("BufEnter", { callback = vim.notify(pkg[1]) })
		M.install_spec(pkg)
	end
end

---@param name string
---@return boolean
function M.has(name)
	local names = vim.tbl_map(function(spec) return spec[1] end, M.load_order)

	return vim.tbl_contains(names, name)
end

function M.decide_order()
	-- Start by coping all the top-level plugins straight into the load order, they will all be loaded first
	for _, pkg in pairs(M.top_level) do
		pkg.dependencies = pkg.dependencies or {}
		for _, dep in pairs(pkg.dependencies) do
			if (M.has(dep[1]) == false) then
				vim.tbl_deep_extend("force", M.load_order, dep)
			end
		end

		vim.tbl_deep_extend("force", M.load_order, pkg)
	end
end

---@param spec PackitSpec
function M.install_spec(spec)
	local src_type = categorise_src(spec[1])

	local url = spec[1]
	local name = spec.name or url:match("([^/]+)$")

	if src_type == "github" then
		url = "https://github.com/" .. url
	end


	vim.pack.add({ src = url, name = spec.name, version = spec.version })

	require(name).setup(spec.opts or {})
end

return M
