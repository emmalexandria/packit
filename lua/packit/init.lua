local M = {}

local Util = require("packit.util")
local Pkg = require("packit.pkg")

local _state = {}

---@class PackitOpts
---@field packpath? string
---@field pack_name? string
---@field base_url? string
---@field notify? boolean

---@type PackitOpts
local _config = {
	base_url = "https://github.com/",
	notify = true
}

---@class PackitPluginState
---@field spec PackitResolvedSpec
---@field loaded boolean
---@field path string

---@class PackitUserSpec
---@field [1] string?
---@field url string?
---@field name string?
---@field main string?
---@field opts table?
---@field build function?
---@field dependencies? PackitUserSpec[]

---@class PackitResolvedSpec
---@field src string
---@field name string
---@field c_name string?
---@field main string?
---@field opts table
---@field build function?
---@field dependency boolean

---@param raw string
---@return string
local function resolve_url(raw)
	if raw:match("^https://") or raw:match("^git@") then
		return raw
	end
	return _config.base_url .. raw
end

---@param url string
---@return string
local function plugin_name(url)
	local name = url:match("([^/]+)$") or url or ""
	-- First remove .git if that is in the URL
	name = name:gsub("%.git$", "")
	-- Then assume no plugin is ending its name in .nvim
	return name:gsub("%.nvim$", "")
end

---@param spec PackitResolvedSpec
local function run_config(spec)
	local ok, err = pcall(function()
		require(spec.main or spec.c_name or spec.name).setup(spec.opts or {})
	end)
	if not ok and _config.notify then
		vim.notify("packit config error for " .. spec.src .. ": " .. tostring(err), vim.log.levels.WARN)
	end
end

local function normalise_single(raw, dep)
	local source = resolve_url(raw[1]) or raw.url or ""
	---@type PackitResolvedSpec
	local normalised = {
		src = source,
		name = plugin_name(source),
		c_name = raw.name,
		main = raw.main,
		opts = raw.opts,
		dependency = dep
	}

	local build_t = type(raw.build)

	if build_t == "function" or build_t == "nil" then
		normalised.build = raw.build
	end

	local dependencies = raw.dependencies and vim.tbl_map(function(d) normalise_single(d, true) end, raw.dependencies) or
			{}

	local plugins = {}
	for _, d in pairs(dependencies) do
		table.insert(d)
	end

	table.insert(plugins, normalised)

	return plugins
end


---@param raw table
---@param dep boolean
---@return PackitResolvedSpec[]
local function normalise_file(raw, dep)
	local plugins = {}

	local function normalise_add(raw, dep)
		for _, p in pairs(normalise_single(raw, dep)) do
			table.insert(plugins, p)
		end
	end

	if Util.is_array(raw) then
		for _, p in ipairs(raw) do
			normalise_add(p, false)
		end
		return plugins
	else
		normalise_add(raw, false)
	end

	return plugins
end

---@param specs PackitResolvedSpec[]
local function dedup_specs(specs)
	local dedup = {}
	for _, s in pairs(specs) do
		local existing = Util.find_key_pred(function(f) return f.src == s.src end, dedup)

		if existing ~= nil then
			local val = dedup[existing]
			if val.dependency == true and s.dependency == false then
				dedup[existing] = s
			end
		else
			table.insert(dedup, s)
		end
	end

	return dedup
end

---@param spec PackitResolvedSpec
local function add_spec(spec)
	local pack_format = {
		src = spec.src,
		name = spec.c_name
	}



	vim.pack.add({ pack_format })

	if spec.build then
		Pkg.build_autocmd(spec.main or spec.c_name or spec.name, spec.build)
	end

	run_config(spec)
end

local function read_plugins()
	local config = vim.fn.stdpath("config")

	local plugin_dir = config .. "/lua/plugins"

	local ret_plugins = {}

	for name, type in vim.fs.dir(plugin_dir) do
		if type == "file" and name:sub(-4) == ".lua" then
			local mod = name:gsub("%.lua$", "")
			local raw = require("plugins." .. mod)
			local plugins = normalise_file(raw, false)

			for _, p in pairs(plugins) do
				table.insert(ret_plugins, p)
			end
		end
	end

	return ret_plugins
end

function M.setup(config)
	_state.plugins = read_plugins()
	_state.plugins = dedup_specs(_state.plugins)

	for _, i in pairs(_state.plugins) do
		add_spec(i)
	end
end

return M
