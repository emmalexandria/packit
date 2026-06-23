---@alias PackitConfigDir {autocmd: boolean, keybinds: boolean, opts: boolean}

---@class PackitConfig
---@field config_dir? PackitConfigDir

---@alias PackitFileReturn PackitSpec | PackitSpec[]

---@class PackitSpec
---@field [1] string
---@field name string?
---@field version string?
---@field dependencies? PackitSpec[]
---@field init? function
---@field opts? table
