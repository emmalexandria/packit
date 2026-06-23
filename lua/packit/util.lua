local function is_array(tab)
	local i = 0
	for _ in pairs(tab) do
		i = i + 1
		if tab[i] == nil then return false end
	end
	return true
end
