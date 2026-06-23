local M = {}

function M.is_array(tab)
	if type(tab) ~= "table" then
		return false
	end

	local i = 0
	for _ in pairs(tab) do
		i = i + 1
		if tab[i] == nil then return false end
	end
	return true
end

return M
