
----- INIT / ENUMS
players = {}
roomowners = {}
admins = {}
banned = {}
staff = {}

roundvars = {}
timers = {}
maplist = {}
mapsets = {}
grounds = {}
cnails = {}
cp_coords = {}

roomsets = {debug=false,cheats={true, "Cheats"},checkpoint={false, "Checkpoint"},rev_delay={true, "Revive delay"},rev_interval={1000, "Minimum revive inteval"}}

groundTypes = {[0]='Wood','Ice','Trampoline','Lava','Chocolate','Earth','Grass','Sand','Cloud','Water','Stone','Snow','Rectangle','Circle','Invisible','Web'}

gui_btn = "<VI>"
gui_bg = 1 --background
gui_b = 0 --border
gui_o = .8

enum = {
	txarea = {
		help = 1,
		helptab = 2,
		book = 3,
		leaderboard = 4,
		leaderboardtab = 5,
		ps = 6,
		rs = 7,
		cheats = 8,
		start_timeshow = 100,
		end_timeshow = 108,
		cp = 200,
		log = 1000,
	}
}

gamemodes = {
	normal = {
		event = {
			NewPlayer = function(pn)
				tfm.exec.respawnPlayer(pn)
			end,
			PlayerDied = function(pn)
				if not banned[pn] then
					if roomsets.rev_delay[1] then
						local pos = nil
						if roomsets.checkpoint[1] and cp_coords[pn] then
							pos = {cp_coords[pn][1], cp_coords[pn][2]}
						end
						table.insert(timers,{os.time(),roomsets.rev_interval[1],'rev',pn, pos})
					else
						tfm.exec.respawnPlayer(pn)
						if roomsets.checkpoint[1] and cp_coords[pn] then
							tfm.exec.movePlayer(pn, cp_coords[pn][1], cp_coords[pn][2])
						end
					end
				end
			end,
			PlayerWon = function(pn, elapsed, elapsedRespawn)
				local t = (elapsedRespawn or elapsed)/100
				table.insert(roundvars.completes, {pn, t})
				gameplay.event.PlayerDied(pn)
				MSG("You beat map "..roundvars.thismap.." in "..t.." seconds!",name,'ROSE')
				for name,attr in pairs(tfm.get.room.playerList) do
					if players[pn].playersets['time_show'] then
						local x, y, sT = 10, 30, mapsets
						if #sT.holes > 0 then
							local hole = sT.holes[1]  -- {x, y}
							x = (sT.Mirrored and sT.Length - hole[1] or hole[1]) - 40
							if hole[2] > 70 then
								y = hole[2] - 60
							else
								y = hole[2] + 10
							end
						end
						i = enum.txarea.start_timeshow
						for xoff=-1,1 do
							for yoff=-1,1 do
								if not (xoff==0 and yoff==0) then
									i=i+1
									ui.addTextArea(i,"<b><font size='24' color='#000000' face='Soopafresh,Segoe,Verdana'>"..t.."s</font></b>", nil, x+(xoff*(border or 1)), y+(yoff*(border or 1)), 0, 0, 0xffffff, 0x000000, 0, true)
								end
							end
						end
						ui.addTextArea(enum.txarea.start_timeshow,"<b><font size='24' face='Soopafresh,Segoe,Verdana' color='#ea00f9'>"..t.."s</font></b>", nil, x, y, 0, 0, 0xffffff, 0x000000, 0, true)
						table.insert(timers,{os.time(),5500,'timeshow',pn})
					end
				end
			end,
		},
		keys = {
			[69] =	function(pn) -- e (checkpoint)
						if roomsets.cheats[1] and roomsets.checkpoint[1] then
							if not players[pn].keys['shift'] then
								local p = tfm.get.room.playerList[pn]
								SetCpMark(pn, p.x, p.y)
							else
								RemoveCpMark(pn)
							end
						end
					end,
		}
	},
	parkour = {
		event = {
			Loop = function(time, remaining)
				for name,attr in pairs(tfm.get.room.playerList) do
					if not gameplay.completed[name] then
						local next_stage = (gameplay.stage[name] or 0) + 1
						if cnails[next_stage] and pythag(attr.x,attr.y,cnails[next_stage][1],cnails[next_stage][2],8) then
							gameplay.stage[name] = next_stage
							tfm.exec.setPlayerScore(name, 1, true)
							local pos = nil
							if cnails[next_stage+1] then
								pos = cnails[next_stage+1]
							elseif next_stage+1 > #cnails then
								pos = table.copy(gameplay.armchair)
								pos[2] = pos[2] - 40
							end
							if pos then
								SetCpMark(name, pos[1], pos[2])
							end
							MSG("You reached level "..next_stage+1, name)
						elseif next_stage > #cnails then
							pos = table.copy(gameplay.armchair)
							pos[2] = pos[2] - 40
							if pythag(attr.x,attr.y,pos[1],pos[2],8) then
								gameplay.stage[name] = next_stage
								tfm.exec.giveCheese(name)
								tfm.exec.playerVictory(name)
							end
						end
					end
				end
			end,
			NewGame = function()
				if not gameplay.IsValidParkour() then
					gameplay = gamemodes.normal
					return
				end
				gameplay.stage = {}
				gameplay.timestart = {}
				gameplay.completed = {}
				local ostime = os.time()
				for name,attr in pairs(tfm.get.room.playerList) do
					tfm.exec.setPlayerScore(name, 1)
					gameplay.timestart[name] = ostime
				end
				SetCpMark(nil, cnails[1][1], cnails[1][2])
				tfm.exec.setGameTime(900)
			end,
			NewPlayer = function(pn)
				tfm.exec.respawnPlayer(pn)
				tfm.exec.setPlayerScore(pn, 1)
				SetCpMark(pn, cnails[1][1], cnails[1][2])
			end,
			PlayerDied = function(pn)
				if banned[pn] then return end
				tfm.exec.respawnPlayer(pn)
				local stage,pos = gameplay.stage[pn] or 0
				if stage > 0 and cnails[stage] then
					pos = cnails[stage]
				elseif stage > #cnails then
					pos = table.copy(gameplay.armchair)
					pos[2] = pos[2] - 40
				end
				if pos then
					tfm.exec.movePlayer(pn, pos[1], pos[2])
				end
			end,
			PlayerWon = function(pn, elapsed)
				gameplay.completed[pn] = true
				RemoveCpMark(pn)
				tfm.exec.setPlayerScore(pn, 1, true)
				gameplay.event.PlayerDied(pn)
				local t = math.round((os.time() - gameplay.timestart[pn])/1000, 2)
				table.insert(roundvars.completes, {pn, t})
				MSG(pn.." completed the map in "..t.." seconds.")
			end,
		},
		keys = {},
		IsValidParkour = function()
			return gameplay.armchair ~= nil and #cnails > 0
		end,
		stage = {},
		timestart = {},
		completed = {},
		armchair = nil,
	}
}
gameplay = gamemodes.normal

----- INTERFACES / HANDLERS

settings = {
	commands = {
		adminban =	function(pn, m, w1, w2) --admin/unadmin and ban/unban
						if not roomowners[pn] then MSG('authority', pn, 'R')
						else
							local target,bT,T = pFind(w2,pn), {admin=true,ban=true}, w1:find('ban') and banned or admins
							if target then
								if T[target]~=bT[w1] and not roomowners[target] then
									T[target] = bT[w1] and true or nil
									if w1=='ban' then tfm.exec.killPlayer(target) tfm.exec.setPlayerScore(target,-10)
									elseif w1=='unban' then tfm.exec.respawnPlayer(target) tfm.exec.setPlayerScore(target,0)
									end
									MSG(string.format("%s is %s!",target,w1=='admin' and 'an admin now' or w1=='unadmin' and 'not an admin now' or w1=='ban' and 'banned now' or 'not banned now'))
								else MSG('target', pn, 'R')
								end
							end
						end
					end,
		help =		function(pn)
						ShowHelp(pn , 'General')
					end,
		m =			function(pn)
						tfm.exec.killPlayer(pn)
					end,
		mapnp =		function(pn, m, w1, w2, w3)
						if w2=='history' then
							players[pn].book = maplist
							players[pn].book.title = "Map History"
							settings.buttons.page(pn,1)
						else
							local T = {p4='#4',p8='#8'}
							if w2 then
								roundvars.maptype = 'normal'
								tfm.exec.newGame(T[w2] or w2, w3=='mirror' and true or false)
							--else tfm.exec.newGame(settings.maps.leisure[math.random(1,#settings.maps.leisure)]) roundvars.maptype = 'leisure'
							end
							return true
						end
					end,
		parkour =	function(pn, m, w1, w2)
						if w2 then
							roundvars.maptype = 'parkour'
							tfm.exec.newGame(w2, w3=='mirror')
						--else tfm.exec.newGame(settings.maps.leisure[math.random(1,#settings.maps.leisure)]) roundvars.maptype = 'leisure'
						end
					end,
		rst =		function(pn, m, w1, w2)
						tfm.exec.newGame(roundvars.thismap, w2=='mirror')
					end,
		time =		function(pn, m, w1, w2)
						tfm.exec.setGameTime(tonumber(w2))
					end,
		getxml =	function( pn )  -- TODO: remove for production
						if not admins[pn] then MSG('authority', pn, 'R')
						elseif tfm.get.room.xmlMapInfo == nil then
						  print('<R>Could not obtain map xml</R>')
						else
							local xml = tfm.get.room.xmlMapInfo.xml
							local m = math.ceil(xml:len()/2000)
							print('<b><font color="#FF0000">'..tfm.get.room.currentMap..':</font></b>')
							for i = 0, math.ceil((xml:len()/2000))-1 do
							  print('<b><font color="#870087" >'..xml:sub(xml:len()*(i/m)+1,xml:len()*((i+1)/m)):gsub('<','&lt;')..'</font></b>')
							end
						end
					end,
		pos =	function( pn )  -- TODO: remove for production
					mouse_pos[pn] = not mouse_pos[pn]
				end,
	},
	buttons = {
		close =		function(pn, window)
						players[pn].windows[window] = nil
						if window=='help' then
							ui.removeTextArea(enum.txarea.helptab, pn)
						elseif window=='leaderboard' then
							ui.removeTextArea(enum.txarea.leaderboardtab, pn)
						end
						ui.removeTextArea(enum.txarea[window], pn)
					end,
		groundinfo =function(pn, id)
						ShowGroundInfo(pn, id)
					end,
		leaderboard=function(pn, tabid)
						tabid = tonumber(tabid)
						if tabid==3 then
							settings.buttons.close(pn, 'leaderboard')
						else
							ShowLeaderboard(pn, tabid)
						end
					end,
		load =		function(pn, code, type)
						if admins[pn] then
							roundvars.maptype = type or 'normal'
							tfm.exec.newGame(code)
						else
							MSG("[•] @"..code, pn)
						end
					end,
		log =		function(pn, page)
						ShowLog(pn, tonumber(page))
					end,
		help =		function(pn, tab)
						if tab=='Close' then
							settings.buttons.close(pn,'help')
						else
							ShowHelp(pn, tab)
						end
					end,
		page =		function(pn, page)
						page = tonumber(page)
						local book = players[pn].book
						local bookheaders = {['Map History']={"\tMapcode","\tAuthor","\tPerm"}}
						local str = book.title=="Ground List" and "<textformat tabstops='[15,70,120,275,360]'>" or "<textformat tabstops='[10,150,350,400]'>"
						str = str..#book.." entries\n\n"
						if bookheaders[book.title] then
							str = str..table.concat(bookheaders[book.title],"").."\n\n"
						end
						local w = 0
						for i,entry in ipairs(book) do
							if i > (page-1)*8 and i<=(page*8) then
								str = str..table.concat(entry, "").."\n\n"
								w = w+1
							end
						end
						w = 8 - w
						if w > 0 then
							str = str..string.rep("\n\n", w)
						end
						str = str .. "<p align='center'>"
						if #book > 8 then
							str = str..string.format("%s    <N>Page %s<a href='event:popup!page'>%s</a> <N>of %s    %s", page>1 and string.format("%s<a href='event:page!1'>&lt;&lt;</a>    <a href='event:page!%s'>&lt;</a>", gui_btn, page-1) or "<N>&lt;&lt;    &lt;", gui_btn, page, #book>0 and math.ceil(#book/8) or 1 , #book>(page*8) and string.format("%s<a href='event:page!%s'>&gt;</a>    <a href='event:page!%s'>&gt;&gt;</a>", gui_btn, page+1, math.ceil(#book/8)) or "<N>&gt;    &gt;&gt;")
						end
						str = str..gui_btn.."\n\n<a href='event:close!book'>Close</a>"
						local text = "<p align='center'><N><font size='15'>"..book.title.."</font>\n<p align='left'>"..str
						ui.addTextArea(enum.txarea.book,text,pn,175,50,450,325,gui_bg,gui_b,gui_o,true)
					end,
		playersets =function(pn, action, set)						
						players[pn].playersets[set] = not players[pn].playersets[set]
						if set=='cp_particles' then SetCpMark(pn) end
						ShowPlayerSets(pn)
					end,
		popup =		function(pn, group, target)
						players[pn].popuptopic = group.."!"..(target or '')
						ui.addPopup(1,2,"<p align='center'>Enter a value!</p>",pn,300,40,200,true)
					end,
		roomsets =	function(pn, action, target)
						if admins[pn] then
							if action=='Toggle' then
								roomsets[target][1] = not roomsets[target][1]
								if target=='cheats' then
									if roomsets['cheats'][1] then
										ShowCheats(nil)
									else
										RemoveCpMark(nil)
									end
								elseif target=='checkpoint' then
									if not roomsets['checkpoint'][1] then
										RemoveCpMark(nil)
									end
								end
								MSG(string.format("%s has %s %s", pn, roomsets[target][1] and 'enabled' or 'disabled', roomsets[target][2]))
							elseif action=='Reset' then
								for _,v in ipairs({"rev_delay"}) do
									roomsets[v][1] = true
								end
								for _,v in ipairs({"checkpoint"}) do
									roomsets[v][1] = false
								end
								roomsets['rev_interval'][1] = 1000
								MSG(pn.." has reset the room settings")
							end
							UpdateRoomSets(pn)
						end
					end,	
	},
	keys = {
		[16] =	function(pn, enable)  -- shift
					players[pn].keys['shift'] = enable
				end,
		[46] =	function(pn)  -- delete
					tfm.exec.killPlayer(pn)
				end,
		[69] =	function(pn) -- e	
				end,
		[71] =	function(pn, enable)  -- g
					if enable and players[pn].keys['shift'] and roundvars.notvanilla then
						players[pn].book = grounds.list
						players[pn].book.title = "Ground List"
						settings.buttons.page(pn,1)
					end
					players[pn].keys['g'] = enable
				end,
		[72] =	function(pn) -- h (display help)
					if players[pn].windows.help then
						ui.removeTextArea(enum.txarea.help, pn)
						ui.removeTextArea(enum.txarea.helptab, pn)
						players[pn].windows.help = false
					else
						ShowHelp(pn,'General')
					end
				end,
		[76] =	function(pn) -- L (display leaderboard)
					if players[pn].windows.leaderboard then
						ui.removeTextArea(enum.txarea.leaderboard, pn)
						ui.removeTextArea(enum.txarea.leaderboardtab, pn)
						players[pn].windows.leaderboard = false
					else
						if players[pn].keys['shift'] then
							ShowLeaderboard(pn, 2)
						else
							ShowLeaderboard(pn, 1)
						end
					end
				end,
		[79] =	function(pn) -- o (display room options)
					if players[pn].windows.rs then
						ui.removeTextArea(enum.txarea.rs, pn)
						players[pn].windows.rs = false
					else
						ui.addTextArea(enum.txarea.rs,GetRoomSets(pn),pn,270,55,250,310,gui_bg,gui_b,gui_o,true)
						players[pn].windows.rs = true
					end
				end,
		[80] =	function(pn) -- p (display player options)
					if players[pn].windows.ps then
						ui.removeTextArea(enum.txarea.ps, pn)
						players[pn].windows.ps = false
					else
						ShowPlayerSets(pn)
					end
				end,
		[192] =	function( pn ) -- ` (display log)
					if players[pn].windows.log then
						ui.removeTextArea(enum.txarea.log, pn)
						players[pn].windows.log = false
					else
						ShowLog(pn)
					end
				end
	}
}

----- BREAKCORD

function SetCpMark(pn, x, y)
	if pn == nil then
		for name,attr in pairs(tfm.get.room.playerList) do
			SetCpMark(name, x, y)
		end
	else
		if x == nil or y == nil then
			if cp_coords[pn] then  -- allow re-setting cp with nil coords in case playersets changed
				x = cp_coords[pn][1]
				y = cp_coords[pn][2]
			else
				return
			end
		else
			cp_coords[pn] = {x, y}
		end
		if players[pn].playersets['cp_particles'] then
			ui.removeTextArea(enum.txarea.cp, pn)
		else
			ui.addTextArea(enum.txarea.cp,"", pn, x-1, y-2, 4, 4, 0xfc572d, 0xffffff, .5, false)
		end
	end
end

function RemoveCpMark(pn)
	if pn == nil then
		ui.removeTextArea(enum.txarea.cp, nil)
		cp_coords = {}
	else
		ui.removeTextArea(enum.txarea.cp, pn)
		cp_coords[pn] = nil
	end
end

function ReadXML()
	if roundvars.notvanilla then
		xml = tfm.get.room.xmlMapInfo.xml
		local frg,sT = 0, mapsets
		local first = true
		for p in xml:gmatch('<P .->') do
			if first then
				for attr, val in p:gmatch('(%S+)="(%S*)"') do
					local a = string.upper(attr)
					if a == 'G' then
						sT.Gravity = string.split(val or "")
						sT.Wind, sT.Gravity = sT.Gravity[1], sT.Gravity[2]
					elseif a == 'L' then sT.Length = tonumber(val)
					end
				end
				first = false
			else
				local array = {}
				for attr, val in p:gmatch('(%S+)="(%S*)"') do
					array[string.upper(attr)] = val or ""
				end
				if tonumber(array.T)==19 and array.C=='329cd2' then  -- armchair to denote final parkour cp
					gamemodes.parkour.armchair = {array.X,array.Y}
					break -- nothing else to check for at the moment
				end
			end
		end
		sT.Mirrored = tfm.get.room.mirroredMap and true or false
		if xml:find('<O>(.-)</O>') then
			for attributes in xml:match('<O>(.-)</O>'):gmatch('<O (.-)/>') do
				local array = {}
				for attr, val in attributes:gmatch('(%S+)="(%S*)"') do
					array[string.upper(attr)] = val or ""
				end
				if tonumber(array.C)==22 then
					cnails[#cnails + 1] = {array.X,array.Y}
				end
			end
		end
		if xml:find('<S>(.-)</S>') then
			for attributes in xml:match('<S>(.-)</S>'):gmatch('<S (.-)/>') do
				local array = {N=false,X=0,Y=0}
				for attr, val in attributes:gmatch('(%S+)="(%S*)"') do
					array[string.upper(attr)] = tonumber(val) or val or ""
					if attr == 'N' then array.N = true end
				end
				if sT.Mirrored then 
					array.X = sT.Length - tonumber(array.X) 
					if array.P[5] then
						array.P[5] = tonumber(array.P[5])>180 and array.P[5]-180 or array.P[5]+180
					end
				end
				if array.P then
					array.P = string.split(array.P or "")
				else
					array.P = {0,0,0.2,0.3,0,0,0,0}
				end
				grounds[#grounds+1] = array
			end
		end
		if xml:find('<T ') then
			for t in xml:gmatch('<T(.-)/>') do
				local a = {}
				for attr,val in t:gmatch('(%S+)="(%S*)"') do
					a[string.upper(attr)] = tonumber(val) or ""
				end
				table.insert(sT.holes,{a.X,a.Y})
			end
		end
		for name,attr in pairs(tfm.get.room.playerList) do 
			ShowMapInfo(name)
		end
		for i,ground in ipairs(grounds) do
			grounds.list[i] = {"\tZ: "..(i-1), string.format("\t%s<a href='event:groundinfo!%s'>info</a><N> ", gui_btn, i), string.format("\tType: %s", groundTypes[tonumber(ground.T or 0)] or 'Unknown'), string.format("\tX: %s", ground.X), string.format("\tY: %s", ground.Y)}
		end
	end
end

function MSG(msg, pn, color, sender)
	--print(str)
	--tfm.exec.chatMessage(str, pn)
	if not pn then
		for name,attr in pairs(tfm.get.room.playerList) do
			MSG(msg, name, color, sender)
		end
	elseif pFind(pn) and players[pn] then
		if color=='R' then
			msg = "error: "..msg
		end
		local maxlogs,ll,str = 25, players[pn].loglist
		str = string.format("<%s>Ξ %s%s</font>",color or 'J',sender and '['..sender..'] ' or '',msg)
		if ll[#ll] and ll[#ll][1]==str then
			ll[#ll][2] = (ll[#ll][2] or 1) + 1
		else
			table.insert(ll, {str})
			if #ll > maxlogs then
				table.remove(ll, 1)
			end
		end
		if players[pn].windows.log then
			ShowLog(pn)
		end
	end
end

function ShowLog(name, page)
	page = page or 0
	local props = {
		-- {x, y, xW, yW}
		offscreen={-180,300,175,0},
		onscreen={35,30,500,160}
	}
	local type = 'offscreen'
	local l,offs,text = {}, page*3, "<font size='12' face='Soopafresh,Segoe,Verdana'>"
	for _,log in ipairs(players[name].loglist) do
		if log[2] then
			table.insert(l, log[1].." ("..log[2]..")")
		else
			table.insert(l, log[1])
		end
	end
	if #l-offs-4 > 0 then
		text = text.."<VI><p align='center'><a href='event:log!"..tostring(page+1).."'>&#x25B2;</a></p>"
	end
	text = text..table.concat(table.slice(l, #l-offs-3, #l-offs), "<br>")
	if #l-offs+1 <= #l then
		text = text.."<br><VI><p align='center'><a href='event:log!"..tostring(page-1).."'>&#x25BC;</a></p>"
	end
	text = text.."</font>"
	ui.addTextArea(enum.txarea.log, text, name,props[type][1],props[type][2],props[type][3],props[type][4],gui_bg,gui_b,gui_o, true)
	players[name].windows.log = true
end

function ShowMapInfo( pn )
	if roundvars.notvanilla then
		local sT,strT = mapsets
		strT = {string.format("<ROSE>[Map Info]<J> %s <N>by %s%s%s<N>",roundvars.thismap, tfm.get.room.xmlMapInfo.author, sT.Mirrored and ' (mirrored)' or '', (roundvars.maptype=='divinity' or roundvars.maptype=='spiritual') and ' | <J>Difficulty: <VP>'..tostring(roundvars.divspilvl) or ''),
			string.format("Wind: %s | Gravity: %s",sT.Wind or '0',sT.Gravity or '10')}
		MSG(table.concat(strT, "\n"),pn,"N")
	end
end

function ShowGroundInfo(pn, id)
	if roundvars.notvanilla then
		local gT = grounds[tonumber(id)]
		local info = string.format("<N>Ground Properties</font><br><br>Z: %i <G>|<N> Type: %s <G>|<N> X: %i <G>|<N> Y: %i <G>|<N> Length: %i <G>|<N> Height: %i <G>|<N> Friction: %s <G>|<N> Restitution: %s <G>|<N> Angle: %s<br><N> Disappear: %s <G>|<N>Color: %s <G>|<N> Collision: %s <G>|%s Foreground <G>|%s Dynamic <G>|<N> Mass: %s <G>|%s Fixed Rotation",id-1, groundTypes[tonumber(gT.T or 0)] or 'Unknown', gT.X or 0, gT.Y or 0, gT.L or 0, gT.H or 0, gT.P[3] or '-', gT.P[4] or '-', gT.P[5] or '-', gT.V or 'null', gT.T~=12 and gT.T~=13 and 'null' or gT.O or '-', gT.C==1 and 'all' or gT.C==2 and 'cloud' or gT.C==3 and 'anticloud' or gT.C==4 and 'none' or gT.T==8 and 'cloud' or 'all', gT.N and '<VP>' or '<R>', tonumber(gT.P[1])==1 and '<VP>' or '<R>', gT.P[2] or '-', tonumber(gT.P[6])==1 and '<VP>' or '<R>')
		MSG(info,pn)
	else MSG('map type',pn, 'R')
	end
end

function ShowHelp(pn, tab)
	local buttonstr,titles,info = {}
	for i,v in pairs({'General', 'Admins', 'Maps', 'Credits', 'Close'}) do
		buttonstr[#buttonstr+1] = "<a href = 'event:help!"..v.."'>"..v.."</a>"
	end
	titles = {General="Welcome to Breakcord", Admins="Admin Powers", Maps="Loading Maps", Credits="Credits"}

	info = {General="This is a Work-In-Progress module intended as a #records alternative. It is obviously nowhere near completion so just use !parkour for now I guess?<br><br><li>!admins/!banned - lists the admins or banned players</li><li>!help - help</li><li>!log - see the message history (hotkey: `)</li><li>!m - kills yourself</li><li>!mapinfo - lists information about the map</li><br><br><font size='15'>Hotkeys:</font><br><li>press h - help</li><li>press shift+g - see ground list</li><li>hold g - click a ground to see its properties</li><li>press l - see leaderboards and best timings</li><li>press p - see player settings</li><li>press delete - kills youself</li><li>press e - set checkpoint</li><li>press shift+e - remove checkpoint</li>",
			Admins="<li>!time # - changes the time</li><li>o - see settings (room)</li><br><br><font size='15'>Cheats</font><li>!tp [player]/!tp all - teleports a player or all players where you click</li><li>hold shift - click to teleport</li><br><font size='15'>Room Owners Only:</font><br><li>!admin [player]/!unadmin [player] - gives/takes admin power</li><li>!ban [player]/!unban [player] - bans/unbans the player (cannot ban room owners)</li>",
			Maps="<li>!map/!np [code] - loads the map code</li><li>!map/!np [code] mirror - loads the map code in a mirrored state</li><li>!parkour [code] - loads a map in parkour mode</li><li>!skip - skips the current round during rotation</li><br><font size='15'>Other:</font><br><li>!map/!np history - list of maps played</li><li>!rst/!rst aie/!rst mirror - reloads the map</li>",
			Credits="<li>Buildtool by Emeryaurora#0000 for a large portion of the base code</li>"}
	
	info = "<p align='center'><font size='15'>"..titles[tab].."</font></p><br>"..info[tab]:gsub('>!(.-)([,:%-])','><font color="#BABD2F">!%1%2</font>')
	ui.addTextArea(enum.txarea.helptab, gui_btn.."<p align='center'>"..table.concat(buttonstr,'                      '), pn,75,35,650,20,gui_bg,gui_b,gui_o,true)
	ui.addTextArea(enum.txarea.help, info, pn,75,70,650,nil,gui_bg,gui_b,gui_o,true)
	players[pn].windows.help = true
end

function ShowCheats(pn)
	roundvars.cheats = true
	ui.addTextArea(enum.txarea.cheats,"<R>Cheats enabled", pn, 5, 25, 0, 0, gui_bg, gui_b, .7, true)
end

function ShowLeaderboard(pn, tab)
	local tabs = {"Room Best", "Global Best", "&#9421; Close"}
	local tabstr,str = "<p align='center'><V>"..string.rep("&#x2500;", 8).."<br>","<textformat tabstops='[30,80,230]'><p align='center'><font size='15'>"..tabs[tab].."</font><br>"
	
	for i,t in ipairs(tabs) do
		local col = (tab==i) and "<T>" or gui_btn
		tabstr = tabstr..string.format("%s<a href='event:leaderboard!%d'>%s</a><br><V>%s<br>",col,i,t,string.rep("&#x2500;", 8))
	end

	str = str.."<ROSE>@"..roundvars.thismap..(mapsets.Mirrored and " (Mirrored)" or "").."<br><V>"..string.rep("&#x2500;", 15).."</p><p align='left'><br>"

	if tab == 1 then
		if roundvars.cheats and not roomsets.debug then
			str = str.."<p align='center'>Room records are void with cheats. Restart the round without cheats to enable room records.</p>"
		else
			local sort = table.copy(roundvars.completes)
			table.sort(sort, function(a,b) return (a[2] < b[2]) end)
			for i, t in ipairs(sort) do
				local col = i == 1 and "<T>" or i > 3 and "<N>" or "<VP>"
				str = str..string.format("%s\t%02d\t%s\t%ss<br>", col, i, t[1], t[2])
			end
		end
	elseif tab == 2 then
		str = str.."Work-In-Progress"
	end
	ui.addTextArea(enum.txarea.leaderboardtab, tabstr, pn,170,60,70,nil,gui_bg,gui_b,gui_o,true)
	ui.addTextArea(enum.txarea.leaderboard, str, pn,250,50,300,300,gui_bg,gui_b,gui_o,true)
	players[pn].windows.leaderboard = true
	players[pn].windows.leaderboardtab = tab
end

function ShowPlayerSets(pn)
	local sets_t = {
		time_show = "Display the most recent timing on screen",
		cp_particles = "Display fancy particles as checkpoint"
	}
	local str = "<p align='center'><font size='15'>Player Settings</font><br><V>"..string.rep("&#x2500;", 15).."</p><br><p align='left'>"
	for key, desc in pairs(sets_t) do
		local blt,col = "&#9744;", "<VI>"
		if players[pn].playersets[key] then
			blt = "&#9745;"
			col = "<VP>"
		end
		str = str..string.format("%s%s<a href='event:playersets!Toggle&%s'>   %s</a><br>", col, blt, key, desc)
	end
	ui.addTextArea(enum.txarea.ps,str..string.format("</p><br><p align='center'>%s<a href='event:close!ps'>Close</a></font></p>", gui_btn),pn, 270,55,250,310,gui_bg,gui_b,gui_o,true)
	players[pn].windows.ps = true
end

function GetRoomSets(pn)
	local str = "<p align='center'><font size='15'>Room Settings</font><br><V>"..string.rep("&#x2500;", 15).."</p><br><p align='left'>"
	for _,v in ipairs({'cheats','checkpoint','rev_delay'}) do
		local blt,col = "&#9744;", "<VI>"
		if roomsets[v][1] then
			blt = "&#9745;"
			col = "<VP>"
		end
		str = str..string.format("%s<a href='event:roomsets!Toggle&%s'>%s   %s</a><br>", col, v, blt, roomsets[v][2])
	end
	str = str..'<br>'
	for _,v in ipairs({"rev_interval"}) do
		str = str..string.format("<N>%s: %s<a href='event:popup!RS&%s'>%s</a><br>", roomsets[v][2], gui_btn, v, roomsets[v][1])
	end
	return str..string.format("</p><br><p align='center'>%s<a href='event:roomsets!Reset'>Reset</a>     %s<a href='event:close!rs'>Close</a></p><N>", gui_btn, gui_btn)

end

function UpdateRoomSets()
	for name in pairs(tfm.get.room.playerList) do ui.updateTextArea(enum.txarea.rs, GetRoomSets(name),name) end
end

function init()
	for _,v in ipairs({'AfkDeath','AutoNewGame','AutoScore','AutoShaman','AutoTimeLeft','PhysicalConsumables'}) do
		tfm.exec['disable'..v](true)
	end
	system.disableChatCommandDisplay(nil,true)
	for name in pairs(tfm.get.room.playerList) do eventNewPlayer(name) end
	tfm.exec.newGame('#17')
end

----- EVENTS

function eventChatCommand(pn, msg)
	local m,words = string.lower(msg), {}
	local mapped = {admin='adminban', ban='adminban', unadmin='adminban', unban='adminban', map='mapnp', np='mapnp', admins='ablist', banned='ablist'}
	local showcommand,showcommandadmins = {tp=true,map=true,np=true,rst=true,time=true,parkour=true},{admin=true,unadmin=true,ban=true,unban=true,admins=true}
	local general = {help=true,banned=true,admins=true,afk=true,m=true,mapinfo=true,search=true}
	for word in m:gmatch("[^ ]+") do
		words[#words + 1] = word
	end
	if showcommandadmins[words[1]] then
		for name in pairs(admins) do
			MSG("!"..msg, name, 'G', pn)
		end
	elseif showcommand[words[1]] then
		MSG("!"..msg, nil, 'G', pn)
	end
	if not (general[words[1]] or admins[pn]) then
		MSG('authority', pn, 'R')
	else
		if mapped[words[1]] then
			settings.commands[mapped[words[1]]](pn, m, words[1], words[2], words[3])
		elseif settings.commands[words[1]] then
			settings.commands[words[1]](pn, m, table.unpack(words))
		else MSG('command', pn, 'R')
		end
	end
end

function eventKeyboard(pn, k, d, x, y)
	if gameplay.keys[k] then
		gameplay.keys[k](pn,d,x,y)
	elseif settings.keys[k] then  -- prevent possible NPE
		settings.keys[k](pn,d,x,y)
	end
end

function eventLoop(time, remaining)
	for i,v in ipairs(timers) do 
		if os.time()>(v[1]+v[2]) then
			if v[3]=='rev' then 
				tfm.exec.respawnPlayer(v[4])
				if v[5] then
					tfm.exec.movePlayer(v[4], v[5][1], v[5][2])
				end
			elseif v[3]=='timeshow' then
				for id=enum.txarea.start_timeshow,enum.txarea.end_timeshow do
					ui.removeTextArea(id, pn)
				end
			end
			table.remove(timers,i) break 
		end
	end
	for name,attr in pairs(tfm.get.room.playerList) do
		if players[name].playersets['cp_particles'] and cp_coords[name] then
			local x, y = cp_coords[name][1], cp_coords[name][2]
			tfm.exec.displayParticle(tfm.enum.particle.redConfetti, x, y-3, 0, 0, 0, 0, name)
			tfm.exec.displayParticle(tfm.enum.particle.blueConfetti, x, y+3, 0, 0, 0, 0, name)
		end
	end
	if gameplay.event['Loop'] then
		gameplay.event.Loop(pn)
	end
end

mouse_pos = {} -- TODO: remove for production
function eventMouse(pn, x, y)
	if not players[pn] then return end
	if mouse_pos[pn] then MSG("X: "..x.."  Y: "..y, pn) end  -- TODO: remove for production
	if roomsets.cheats[1] and players[pn].tptarget and admins[pn] then
		ExecuteForTargets(pn, players[pn].tptarget,
			function(name)
				tfm.exec.movePlayer(name, x, y)
			end
		)
		players[pn].tptarget = nil
	elseif players[pn].keys['shift'] then --shift+click to tp if admin
		if roomsets.cheats[1] and admins[pn] then
			tfm.exec.movePlayer(pn, x, y)
		end
	elseif players[pn].keys['g'] then --g+click static ground to see properties
		local gID = 0
		for i,v in ipairs(grounds) do
			if v.P[1] and PointGroundOverlap(v.T, v.P[5], v.L, v.H, v.X, v.Y, x, y) then
				gID = i
			end
		end
		if gID~=0 then ShowGroundInfo(pn, gID) end
	end
end

function eventNewGame()
	for id=enum.txarea.start_timeshow,enum.txarea.end_timeshow do
		ui.removeTextArea(id, pn)
	end
	grounds,cnails = {list={}}, {}
	mapsets,roundvars = {Wind=0,Gravity=10,MGOC=100,Length=800,holes={}}, {maptype=roundvars.maptype,completes={}}
	roundvars.thismap = tonumber(tfm.get.room.currentMap:match('%d+'))
	if roundvars.thismap>800 then roundvars.notvanilla = true	end
	if not roundvars.notvanilla then tfm.get.room.xmlMapInfo = nil end
	for name,attr in pairs(tfm.get.room.playerList) do
		players[name].tptarget = 'none'
		if banned[name] then
			tfm.exec.killPlayer(name)
			tfm.exec.setPlayerScore(name, -10)
		end
	end
	if not roomsets.cheats[1] then  -- start a fresh round that doesn't have cheats
		ui.removeTextArea(enum.txarea.cheats, nil)
	else
		roundvars.cheats = true
	end
	RemoveCpMark(nil)
	maplist[#maplist+1] = {string.format("\t%s<a href='event:load!%s'>code: %s</a><N>", gui_btn, roundvars.thismap, roundvars.thismap), string.format("\t%s",tfm.get.room.xmlMapInfo and tfm.get.room.xmlMapInfo.author or 'unknown'), string.format("\tperm: %s", tfm.get.room.xmlMapInfo and tfm.get.room.xmlMapInfo.permCode or 'unknown')}
	ReadXML()
	gameplay = gamemodes[roundvars.maptype] or gamemodes.normal
	if gameplay.event['NewGame'] then
		gameplay.event.NewGame()
	end
end

function eventNewPlayer(pn)
	local p = tfm.get.room.playerList[pn]
	local ti,tn = p.tribeId or 0, p.tribeName
	system.bindMouse(pn, true)
	for key in pairs(settings.keys) do
		system.bindKeyboard(pn, key, true)
	end
	-- hold down keys
	for _,v in ipairs({16,71}) do
		system.bindKeyboard(pn,v,true)
		system.bindKeyboard(pn,v,false)
	end
	players[pn] =
		{lang = p.community or 'en',
		tptarget = 'none',
		windows = {},
		keys = {},
		book = {title=''},
		playersets = {time_show=true},
		popuptopic = '',
		loglist = {}
		}
	if staff[pn] or tfm.get.room.name:find(ZeroTag(pn)) or (ti > 0 and tfm.get.room.name:find(tn)) then 
		roomowners[pn] = true 
	end
	if roomowners[pn] then admins[pn] = true end
	--ShowHelp(pn,'General')
	--ShowLog(pn)
	if roomsets.cheats[1] then
		ShowCheats(pn)
	end
	MSG(pn.. " has entered the room.", nil, "J")
	if gameplay.event['NewPlayer'] then
		gameplay.event.NewPlayer(pn)
	end
end

function eventPlayerDied(pn)
	if gameplay.event['PlayerDied'] then
		gameplay.event.PlayerDied(pn)
	end
end

function eventPlayerLeft(pn)
	MSG(pn.. " has left the room.", nil, "J")
end

function eventPlayerWon(pn, elapsed, elapsedRespawn)
	if gameplay.event['PlayerWon'] then
		gameplay.event.PlayerWon(pn, elapsed, elapsedRespawn)
	end
	for name,attr in pairs(tfm.get.room.playerList) do
		if players[name].windows.leaderboard and players[name].windows.leaderboardtab==1 then
			ShowLeaderboard(name, 1)
		end
	end
end

function eventPopupAnswer(id, pn, answer)
	local topic = players[pn].popuptopic
	local target = topic:match('!(.*)')
	if topic:find('page') then
		if tonumber(answer) and tonumber(answer)>0 and tonumber(answer)<=(math.ceil(#players[pn].book/8)) then
			settings.buttons.page(pn,tonumber(answer))
		else MSG("page",pn,'R')
		end
	elseif topic:find('RS!') and admins[pn] then
		if tonumber(answer) and tonumber(answer)>=0 then
			roomsets[target][1] = tonumber(answer)
			MSG(string.format("%s has set %s to %s", pn, roomsets[target][2]:lower(), answer))
			UpdateRoomSets()
		else MSG("number",pn,'R')
		end
	end
end

function eventTextAreaCallback(id, pn, callback)
	local params, button = {}
	if callback:find('!') then 
		button = callback:match('(%w+)!')
		params = string.split(callback:match('!(.*)'), '&')
	end
	settings.buttons[button or callback](pn, table.unpack(params))
end

----- UTILITIES

function ExecuteForTargets(pn, targets, f)
	if targets=='all' or targets=='*' then
		for name in pairs(tfm.get.room.playerList) do f(name) end
	elseif targets=='me' and pn then
		f(pn)
	elseif targets then
		f(targets)
	end
end

function math.round(num, numDecimalPlaces)
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
end

function pFind(target, pn)
	local ign = string.lower(target or ' ')
	for name in pairs(tfm.get.room.playerList) do
		if string.lower(name):find(ign) then return name end
	end
	if pn then MSG('target', pn, 'R') end
end

function PointGroundOverlap(GT, Gangle, GL, GH, GX, GY, xPos, yPos)
	local theta,c,s,cx,cy = math.rad(Gangle or 0)
	c,s = math.cos(-theta), math.sin(-theta)
	cx,cy = GX+c*(xPos-GX)-s*(yPos-GY), GY+s*(xPos-GX)+c*(yPos-GY)
	if (GT==13 and pythag(xPos,yPos,GX,GY,GL/2)) or (math.abs(cx-GX)<(GL/2) and math.abs(cy-GY)<(GH/2)) then
		return true
	end
end

function pythag(x1, y1, x2, y2, r)
	local x,y,r = x2-x1, y2-y1, r+r
	return x*x+y*y<r*r
end

function string.split(str, delimiter)
	local delimiter,a = delimiter or ',', {}
	for part in str:gmatch('[^'..delimiter..']+') do
		a[#a+1] = part
	end
	return a
end

function string.trim(str)
	return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

function table.copy(t)
	local t2 = {}
	for k,v in pairs(t) do
		if type(v) == 'table' then
			t2[k] = table.copy(v)
		else
			t2[k] = v
		end
	end
	return t2
end

function table.slice(tbl, first, last, step)
	local sliced = {}
	for i = first or 1, last or #tbl, step or 1 do
		sliced[#sliced+1] = tbl[i]
	end
	return sliced
end

function ZeroTag(pn, add) --#0000 removed for tag matches
	if add then
		if not pn:find('#') then
			return pn.."#0000"
		else return pn
		end
	else
		p = pn:find('#0000') and pn:sub(1,-6) or pn
		return p
	end
end

----- 
init()
