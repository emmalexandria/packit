<h3 align="center">packit</h3>

#### Reasoning

As of Neovim v0.12, we have a built-in manager for plugins (not packages, although it is confusingly called `pack`). I generally like to keep my configurations as stock and minimal as possible so this was hugely appealing to me, but I found it difficult to move away from the structured configuration approach offered by [lazy.nvim](https://github.com/folke/lazy.nvim). I wrote `packit` as a way to enable these kinds of configurations, including: 

- Keybinds in plugin spec
- Multiple plugin specs per file
- Naive dependency system 
- (Manual) lazy load conditions with autocommands/ft plugins
- Auto-installation of plugins in `lua/plugins`
- (Optional) auto-loading of `lua/config/[autocmd,opts,keybinds].lua`
- Automatic prefixing of your preferred Git provider
- Familiar plugin spec for `lazy.nvim` users

`packit` is **not** a package manager, it is simply a wrapper plugin around `vim.pack` with some niceties. It's designed to be simple enough that you can understand it in it's entirety with ease, something I value in a Neovim plugin. Folke and echasnovski do amazing work, but they also operate on a different plane of existence to me. 

#### Downsides 
- Extremely naive assumptions about the name of the main module
- Lack of spec merging when a plugin is specified >1 times
- Probably slow, my Lua-fu is terrible
- Limited, only supports one config file structure

#### Getting started 
Setting up `packit` is incredibly simple, simply put the following in your `init.lua` 

```lua
vim.pack.add({"https://github.com/emmalexandria/packit"})

require("packit").setup()
```
