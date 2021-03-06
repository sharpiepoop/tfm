-- string split
string.split = function(s,t)
	local r = {}
	for p in string.gmatch(s,"[^"..t.."]+") do
		table.insert(r,p)
	end
	return r
end

-- string s starts with prefix p ?
string.startswith = function(s,p)
   return string.sub(s,1,string.len(p))==p
end

-- combine some arrays (not tables!)
table.combine = function(...)
	local r = {}
	for _,a in pairs(arg) do
		if a and type(a)=='table' then
			for _,e in pairs(a) do
				table.insert(r,e)
			end
		end
	end
	return r
end

Map = {}
MapFilter = {}

-- private:

-- This turns an array into a chainable filter thing
Map.__a = function(a,p)
	a = a or {}
	for n,_ in pairs(MapFilter) do
		if string.startswith(n,'with') then
			a[n] = MapFilter[n]
		end
		for _,e in ipairs(a) do
			if p and string.startswith(n,p..'_') then
				e[string.sub(n,3)] = MapFilter[n]
			end
		end
	end
	return a
end

-- The main filtering function (input array,   attribute/key,  operator,  value, inverse/not)
Map.__f = function(a,k,op,V)
	local r = {}
	local m = true
	if inv then m=false end
	for i,e in ipairs(a) do
		if type(e)=='table' then
			local b = false
			local has = false
			local v = e[k]
			if v then has = true end
			if     op == 'has' then b = has
			elseif op == '=='  then b = has and v==V
			elseif op == '!='  then b = has and v~=V
			elseif op == '~='  then b = has and v~=V
			elseif op == '<='  then b = has and v<=V
			elseif op == '>='  then b = has and v>=V
			elseif op == '<'   then b = has and v< V
			elseif op == '>'   then b = has and v> V
			end
			if b==m then
				table.insert(r,e)
			end
		end
	end
	return r
end

-- Simple attribute test
Map.__t = function(e,k)
	if e[k] then return true end
	return false
end


-- public:

-- constants
Map.enum = {}
Map.enum.collsion = { all =1, mice=3, grounds=2, none=4}
Map.enum.ground   = { wood=0, ice =1, tramp  =2, lava=3, choc=4, earth=5, grass=6, sand=7, cloud=8, water=9, stone=10, snow=11, rect=12, circle=13 }


-- get map properties
Map.length = function(C)
	return C.P.L or 800
end
Map.gravity = function(C)
	if C.P.G then
		print("Map.gravity " .. C.P.G[1])
		return C.P.G[2]
	end
	return 10
end
Map.wind = function(C)
	if C.P.G then
		print("Map.wind " .. C.P.G[2])
		return C.P.G[1]
	end
	return 0
end
Map.background = function(C)
	return C.P.F
end
Map.isNightmode = function(C)
	return Map.__t(C.P,'N')
end
Map.isSoulmate = function(C)
	return Map.__t(C.P,'A')
end
Map.isCollision = function(C)
	return Map.__t(C.P,'C')
end

-- get map sections
Map.grounds = function(C)
	return Map.__a(C.Z.S,'S')
end
Map.miceStuff = function(C)
	return Map.__a(C.Z.D,'D')
end
Map.shamanObjects = function(C)
	return Map.__a(C.Z.O,'O')
end
Map.joints = function(C)
	local r = nil
	if C.Z.L then
		r = table.combine(C.Z.L.JD, C.Z.L.JP, C.Z.L.JPL, C.Z.L.JR)
	end
	return Map.__a(r)
end
Map.cheese = function(C)
	if C and C.Z and C.Z.D then
		return Map.__a(C.Z.D.F)
	end
	return nil
end
Map.holes = function(C)
	return Map.__a(C.Z.D.T)
end
Map.miceSpawns = function(C)
	return Map.__a(C.Z.D.DS)
end
Map.shamanSpawns = function(C)
	return Map.__a(C.Z.D.DC)
end

-- get ground element properties
MapFilter.S_type = function(e)
	return e.T
end
MapFilter.S_x = function(e)
	return e.X
end
MapFilter.S_y = function(e)
	return e.Y
end
MapFilter.S_length = function(e)
	return e.L
end
MapFilter.S_height = function(e)
	return e.H
end
MapFilter.S_collision = function(e)
	if e.c then
		return Map.enum.collision[e.c]
	end
	return Map.enum.collsion.all
end
MapFilter.S_isForeground = function(e)
	return Map.__t(e,'N')
end
MapFilter.S_isDynamic = function(e)
	if e.P[1]==1 then
		return true
	end
	return false
end

-- shaman object 
MapFilter.O_x = function(e)
	return e.X
end
MapFilter.O_y = function(e)
	return e.Y
end


-- filtering functions

MapFilter.with = function(a,attr,op,value,inv)
	op = op or 'has'
	return Map.__a(Map.__f(a,attr,op,value,inv))
end

-- For grounds / decorations
MapFilter.withType = function(a,value)
	return a:with('T','==',value)
end

-- For grounds
MapFilter.withForeground = function(a,value)
	if value==true then	return a:with('N') end
	return a:with('N','has',nil,true)
end

-- For objects
MapFilter.withId = function(a,value)
	return a:with('C','==',value)
end




-- xml is either a string, or blank/nil to use tfm.get.room.xmlMapInfo
Map.parse = function(xml)
	local C = {}
	if xml==nil then
		local mi = tfm.get.room.xmlMapInfo
		if string.startswith(tfm.get.room.currentMap,'@')==false then
			-- vanilla
			return nil
		end
		C.__cat = mi.permCode
		xml = mi.xml
	end

	local E = string.split(xml,'><')
	local p = C
	p.__tag = 'C'
	for _,e in ipairs(E) do
		e = string.gsub(e,'%"','')
		local A = string.split(e,' ')
		if table.getn(A) == 1 then
			-- In tfm XML, a tag without attributes is only used for sections (I think)...  I'm relying on that :-)
			if string.find(A[1],'/') then
				-- ascend from a section
				if p.__parent then
					p = p.__parent
				end
			elseif A[1]~='C' then
				-- descend into a section. We'll make a new table for it
				p[A[1]] = {}
				p[A[1]].__parent = p
				p = p[A[1]]
				p.__tag = A[1]
			end
		else
			-- Tag has attributes, we'll parse it out and stick it in our current table (p)
			local t = {}
			for _,a in ipairs(A) do
				if string.find(a,'=') then
					local v = string.split(a,'=')
					if table.getn(v)==1 then
						-- value was blank, we'll force something in there
						table.insert(v,'')
					end
					local L = string.split(v[2],',')
					if table.getn(L)>1 then
						-- list of comma-seperated values  (eg multispawn, or ground P attribute)
						local lt = {}
						for _,l in ipairs(L) do
							table.insert(lt,tonumber(l) or l)
						end
						t[v[1]] = lt
					else
						-- simple attr=value
						t[v[1]] = tonumber(v[2]) or v[2]
					end
				end
			end
			if p.__tag == A[1] then
				-- tag has same name as the current section, so it can be added there  (S/D/O)
				table.insert(p,t)
			else
				-- make a new array for this tag if needed, and add
				if not p[A[1]] then
					p[A[1]] = {}
				end
				table.insert(p[A[1]],t)
			end
		end
	end
	C.P = C.P[1]
	
	for n,_ in pairs(Map) do
		C[n] = Map[n]
	end
	
	return C
end


-----------------------------------------------------------------------------------------------------------------------

map  = nil
ui   = nil
next = nil

function eventNewGame()

	if tfm.get.room.currentMap == '@0' then
		-- Our flipped map
		tfm.exec.setUIMapName(ui)

	else
		-- Real map
		map = Map.parse()
		print("map:" .. tfm.get.room.currentMap)
		if map then
			print("parse ok")

            ui = string.format('<J> %s <BL>- @%s',tfm.get.room.xmlMapInfo.author,tfm.get.room.xmlMapInfo.mapCode)
			
			local xml = string.format('<C><P L="%d" G="%d,%d" />', map:length(), map:wind() * -1, map:gravity())
			xml = xml .. '<Z><S>'
			
			for ii,p in ipairs(map.P) do
				print('p:' .. ii .. ':' .. tostring(p))
			end

			if map:grounds() then
				for i,g in ipairs(map:grounds()) do
					-- if i==1 then
						-- for ii,p in ipairs(g.P) do
							-- print('p:' .. ii .. ':' .. tostring(p))
						-- end
					-- end
					local angle_number = tonumber(g.P[5])
					local angle_string = ''
					if angle_number then
						angle_number = angle_number * -1
						angle_string = tostring(angle_number)
					end
					
					xml = xml .. string.format('<S T="%d" X="%d" Y="%d" L="%d" H="%d" P="%s,%s,%s,%s,%s,%s,%s,%s" />', g.T, map:length() - g.X, g.Y, g.L, g.H, tostring(g.P[1]), tostring(g.P[2]), tostring(g.P[3]), tostring(g.P[4]), angle_string, tostring(g.P[6]), tostring(g.P[7]), tostring(g.P[8]))
				end
			end

			xml = xml .. '</S><D>'
			
			if map:cheese() then
				for i,cheese in ipairs(map:cheese()) do
					xml = xml .. string.format('<F X="%d" Y="%d" />', map:length() - cheese.X, cheese.Y)
				end
			end
			
			if map:holes() then
				for i,hole in ipairs(map:holes()) do
					xml = xml .. string.format('<T X="%d" Y="%d" />', map:length() - hole.X, hole.Y)
				end
			end
			
			if map:miceSpawns() then
				for i,spawn in ipairs(map:miceSpawns()) do
					xml = xml .. string.format('<DS X="%d" Y="%d" />', map:length() - spawn.X, spawn.Y)
				end
			end

			xml = xml .. '</D><O /></Z></C>'
			
			tfm.exec.newGame(xml)


		else
			print("parse failed")
		end
	end
end

function eventLoop(t,r)
	if np then
		if np[2] == 0 then
			tfm.exec.newGame(np[1])
			np = nil
		else
			np[2] = np[2] - 1
		end
	end
end

function eventChatCommand(p,s)
        -- print('player:' .. p .. ': ' .. s)
        local a = string.split(s,' ')
        local cmd = 'command_' .. string.lower(a[1])
        if _G[cmd] then
                _G[cmd](p,a)
        end
end

function command_mort(p,a)
	tfm.exec.killPlayer(p)
end

function command_admin(p,a)
        if p:lower() == "sharpiepoops" or p:lower() == "sharpieboob" then
                cmd = a[2]:lower()
                if cmd == 'np' then
                        np = { a[3], 10 }
                end
        end
end


tfm.exec.disableAutoShaman(true)
tfm.exec.newGame()