bind = {}

local Bindings = {}

function bind.GetTable() return Bindings end

function bind.Add( btn, name, func )

	if not isfunction( func ) then return end
	if not isnumber( btn ) then return end

	if Bindings[ btn ] == nil then
		Bindings[ btn ] = {}
	end

	Bindings[ btn ][ name ] = func

end

function bind.Remove( btn, name )

	if not isnumber( btn ) then return end
	if not Bindings[ btn ] then return end

	Bindings[ btn ][ name ] = nil

end

local FirstPressed = {}

hook.Add( "Think", "CallBindings", function()
	for btn, tbl in pairs( Bindings ) do
		local cache = input.IsButtonDown( btn )
		if cache and FirstPressed[ btn ] then
			for _, func in pairs( tbl ) do func() end
		end
		FirstPressed[ btn ] = not cache
	end
end )
