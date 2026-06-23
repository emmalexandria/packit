local M = {}

local util = require("packit.util")

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
	return name:gsub("%.git$", "")
end

local function run_config(spec)
	local ok, err = pcall(function()
		require(spec.main or spec.name).setup(spec.opts or {})
	end)
	if not ok and _config.notify then
		vim.notify("packit config error for " .. spec.name .. ": " .. tostring(err), vim.log.levels.WARN)
	end
end


---@param raw table
---@param dep boolean
---@return PackitResolvedSpec[]
local function normalise(raw, dep)
	if util.is_array(raw) then
		local plugins = {}
		for _, p in pairs(raw) do
			table.insert(plugins, normalise(p, false))
		end
		return plugins
	end


	local dependencies = raw.dependencies and vim.tbl_map(normalise, raw.dependencies) or {}

	local source = raw.url or raw[1] or ""
	---@type PackitResolvedSpec
	local normalised = {
		src = source,
		name = raw.name or plugin_name(source),
		main = raw.main,
		opts = raw.opts,
		dependency = dep
	}

	local build_t = type(raw.build)

	if build_t == "function" or build_t == "nil" then
		normalised.build = raw.build
	end

	local ret = {}
	vim.tbl_deep_extend("keep", ret, dependencies)
	table.insert(ret, normalised)

	return ret
end

---@param all_specs PackitResolvedSpec[]
local function merge_specs(all_specs)
	local unique_specs = {}

	for _, s in pairs(all_specs) do
		if unique_specs[s.src] == nil then
			unique_specs[s.src] = { s }
		else
			table.insert(unique_specs[s.src], s)
		end
	end

	local merged_specs = {}

	for _, u in pairs(unique_specs) do
		local merged_spec = {}
		local tl = {}
		for _, spec in pairs(u) do
			if spec.dep then
				--- Merge in dependencies first
				merged_spec = vim.tbl_deep_extend("force", merged_spec, spec)
			else
				--- Top level declarations get merged in last
				table.insert(tl, spec)
			end
		end

		for _, spec in pairs(tl) do
			merged_spec = vim.tbl_deep_extend("force", merged_spec, spec)
		end

		table.insert(merged_specs, merged_spec)
	end

	return merged_specs
end


---@param spec PackitResolvedSpec
local function add_spec(spec)
	local pack_format = {
		src = spec.src,
	}

	vim.pack.add({ pack_format })
	run_config(spec)
end

local function read_plugins()
	local config = vim.fn.stdpath("config")

	local plugin_dir = config .. "/lua/plugins"

	_state.plugins = {}

	for name, type in vim.fs.dir(plugin_dir) do
		if type == "file" and name:sub(-4) == ".lua" then
			local mod = name:gsub("%.lua$", "")
			local raw = require("plugins." .. mod)
			local plugins = normalise(raw, false)

			_state.plugins = vim.tbl_deep_extend("keep", _state.plugins, plugins)
		end
	end
end

function M.setup(config)
	read_plugins()
	_state.plugins = merge_specs(_state.plugins)

	for _, i in pairs(_state.plugins) do
		add_spec(i)
	end
end

return M
