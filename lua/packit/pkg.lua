local M = {}

function M.build_autocmd(pkg_name, callback)
	vim.api.nvim_create_autocmd("PackChanged", {
		callback = function(ev)
			local name, kind = ev.data.spec.name, ev.data.kind
			if name == name and kind == 'update' then
				if not ev.data.active then vim.cmd.packadd(pkg_name) end
				callback()
			end
		end
	})
end

return M
