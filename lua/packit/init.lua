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
---@field spec PackitPluginSpec
---@field loaded boolean
---@field path string

---@class PackitPluginSpec
---@field [1] string?
---@field url string?
---@field name string?
---@field opts table?
---@field build function?

---@class PackitResolvedSpec
---@field src string
---@field name string
---@field opts table
---@field build function?

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
	local name = url:match("([^/]+)$") or url
	return name:gsub("%.git$", "")
end

local function run_config(spec)
	local ok, err = pcall(function()
		if (type(spec.config) == "function") then
			spec.config(spec, spec.opts)
		elseif spec.config == true then
			require(spec.name).setup(spec.opts or {})
		end
	end)
	if not ok and _config.notify then
		vim.notify("packit config error for " .. spec.name .. ": " .. tostring(err), vim.log.levels.WARN)
	end
end

---@param raw table
---@return PackitPluginSpec[]
local function normalise(raw)
	if util.is_array(raw) then
		local plugins = {}
		for _, p in pairs(raw) do
			plugins:insert(normalise(p))
		end
		return plugins
	end

	---@type PackitPluginSpec
	local normalised = {}
	local source = raw.url or raw[1] or ""
	normalised.url = source
	normalised.name = raw.name or plugin_name(raw.url)

	local build_t = type(raw.build)

	if build_t == "function" or build_t == "nil" then
		normalised.build = raw.build
	end



	return normalised
end


local function register_with_pack(spec)
	local pack_format = {
		src = spec.url,
		name = spec.name
	}

	vim.pack.add(pack_format)
end

local function read_plugins()
	local config = vim.fn.stdpath("config")

	local plugin_dir = config .. "/lua/plugins"

	for name, type in vim.fs.dir(plugins) do
		if type == "file" and name:sub(-4) == ".lua" then
			local mod = name:gsub("%.lua$", "")
			local raw = require("plugins" .. mod)
			local plugins = normalise(raw)
		end
	end
end

---@param config PackitConfig
function M.setup(config)
	require("packit.package").load()
end

return M
