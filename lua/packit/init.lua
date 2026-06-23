local M = {}

local _state = {}

---@class PackitOpts
---@field packpath? string
---@field pack_name? string
---@field base_url? string
---@field notify? boolean

---@type PackitOpts
local _config = {
	packpath = vim.fn.stdpath("data") .. "/site",
	pack_name = "packit",
	base_url = "https://github.com/",
	notify = true
}

---@class PackitPluginState
---@field spec table
---@field loaded boolean
---@field path string

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
	local ok, err = pcall(function() end)
end

---@param config PackitConfig
function M.setup(config)
	require("packit.package").load()
end

return M
