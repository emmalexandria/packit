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

---@param func function
---@param tab table
function M.find_key_pred(func, tab)
	for k, f in pairs(tab) do
		if func(f) then
			return k
		end
	end
end

function M.dump(o)
	if type(o) == 'table' then
		local s = '{ '
		for k, v in pairs(o) do
			if type(k) ~= 'number' then k = '"' .. k .. '"' end
			s = s .. '[' .. k .. '] = ' .. M.dump(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

function M.flatten(arr)

end

return M
