
----- INIT / ENUMS
players = {}
roomowners = {}
admins = {}
banned = {}
staff = {}

roundvars = {}
maplist = {}
mapsets = {}
grounds = {}
roomsets = {debug=true}

groundTypes = {[0]='Wood','Ice','Trampoline','Lava','Chocolate','Earth','Grass','Sand','Cloud','Water','Stone','Snow','Rectangle','Circle','Invisible','Web'}

gui_btn = "<VI>"
gui_bg = 1 --background
gui_b = 0 --border
gui_o = .8

enum = {
	txarea = {
		help = 1,
		helptab = 2,
	}
}

----- INTERFACES / HANDLERS

settings = {
	commands = {
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
		rst =		function(pn, m, w1, w2)
						tfm.exec.newGame(roundvars.thismap, w2=='mirror' and true or false)
					end,
	},
	buttons = {
		close =		function(pn, id)
						local T = {[enum.txarea.help]='help'}
						if T[tonumber(id)] then
							players[pn].windows[T[tonumber(id)]] = nil
						end
						if id==1 then -- close the help text areas
							ui.removeTextArea(enum.txarea.helptab, pn)
						end
						ui.removeTextArea(id, pn)
					end,
		log =		function(pn, page)
						ShowLog(pn, tonumber(page))
					end,
		help =		function(pn, tab)
						if tab=='Close' then
							settings.buttons.close(pn, enum.txarea.help)
						else
							ShowHelp(pn, tab)
						end
					end,
		page =		function(pn, page)
						page = tonumber(page)
						local book = players[pn].book
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
							str = str..string.format("%s    <N>Page %s<a href='event:popup!page'>%s</a> <N>of %s    %s", page>1 and string.format("%s<a href='event:page!1'>&lt;&lt;</a>    <a href='event:page!%s'>&lt;</a>", c_gui_bt, page-1) or "<N>&lt;&lt;    &lt;", c_gui_bt, page, #book>0 and math.ceil(#book/8) or 1 , #book>(page*8) and string.format("%s<a href='event:page!%s'>&gt;</a>    <a href='event:page!%s'>&gt;&gt;</a>", c_gui_bt, page+1, math.ceil(#book/8)) or "<N>&gt;    &gt;&gt;")
						end
						str = str..c_gui_bt.."\n\n<a href='event:close!3'>Close</a>"
						local text = "<p align='center'><N><font size='15'>"..book.title.."</font>\n<p align='left'>"..str
						ui.addTextArea(3,text,pn,175,50,450,325,c_gui_bg,c_gui_b,o_gui,true)
					end,
	},
	keys = {
		[16] =	function(pn, enable)  -- shift
					players[pn].keys['shift'] = enable
				end,
		[71] =	function(pn, enable)  -- g
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
		[192] =	function( pn ) -- ` (display log)
					if players[pn].windows.log then
						ui.removeTextArea(100, pn)
						players[pn].windows.log = false
					else
						ShowLog(pn)
					end
				end
	}
}

----- BREAKCORD

function ReadXML()
	if roundvars.notvanilla then
		xml = tfm.get.room.xmlMapInfo.xml
		local b,frg,sT = {false}, 0, mapsets
		for attr, val in xml:match('<P .->'):gmatch('(%S+)="(%S*)"') do
			local a = string.upper(attr)
			if a == 'G' then
				sT.Gravity = string.split(val or "")
				sT.Wind, sT.Gravity = sT.Gravity[1], sT.Gravity[2]
			elseif a == 'L' then sT.Length = tonumber(val)
			end
		end
		sT.Mirrored = tfm.get.room.mirroredMap and true or false
		if xml:find('<O>(.-)</O>') then
			for attributes in xml:match('<O>(.-)</O>'):gmatch('<O (.-)/>') do
				local array = {}
				for attr, val in attributes:gmatch('(%S+)="(%S*)"') do
					array[string.upper(attr)] = val or ""
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
		if xml:find('<DS') then
			for ds in xml:gmatch('<DS(.-)/>') do
				local a={}
				for attr,val in ds:gmatch('(%S+)="(%S*)"') do
					a[string.upper(attr)] = tonumber(val) or ""
				end
				table.insert(sT.mousespawns, {a.X,a.Y})
			end
		elseif xml:find(' DS') then
			local ds = xml:match(' DS(.-)" ')	
			if ds:match('m') then
				local ms,mt,ml = ds:match(';(.+)'), {x={},y={}}
				ml = string.split(ms or "")
				mt.x,mt.y = TableSplit(ml)
				for i=1,#mt.x do table.insert(sT.mousespawns,{mt.x[i],mt.y[i]}) end
			end
		elseif xml:find('<T ') then
			for t in xml:gmatch('<T(.-)/>') do
				local a = {}
				for attr,val in t:gmatch('(%S+)="(%S*)"') do
					a[string.upper(attr)] = tonumber(val) or ""
				end
				table.insert(sT.mousespawns,{a.X,a.Y - 15})
			end
		end
		for name,attr in pairs(tfm.get.room.playerList) do 
			ShowMapInfo(name)
		end
		for i,ground in ipairs(grounds) do
			grounds.list[i] = {"\tZ: "..(i-1), string.format("\t%s<a href='event:groundinfo!%s'>info</a></font> ", gui_btn, i), string.format("\tType: %s", groundTypes[tonumber(ground.T or 0)] or 'Unknown'), string.format("\tX: %s", ground.X), string.format("\tY: %s", ground.Y)}
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
	ui.addTextArea(100, text, name,props[type][1],props[type][2],props[type][3],props[type][4],gui_bg,gui_b,gui_o, true)
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
	titles = {General="General Powers", Admins="Admin Powers", Maps="Loading Maps", Credits="Credits"}

	info = {General="<li>!admins/!banned - lists the admins or banned players</li><li>!help - help</li><li>!log - see the message history (hotkey: `)</li><li>!m - kills yourself</li><li>!mapinfo - lists information about the map</li><br><br><font size='15'>Hotkeys:</font><br><li>press h - help</li><li>press shift+g - see ground list</li><li>hold g - click a ground to see its properties</li>",
			Admins="<li>!time # - changes the time</li><br><br><font size='15'>Debug</font><li>!debug on/!debug off - toggles debug mode and its commands</li><li>!tp [player]/!tp all - teleports a player or all players where you click</li><li>hold shift - click to teleport</li><li>o - see settings (room)</li><br><font size='15'>Room Owners Only:</font><br><li>!admin [player]/!unadmin [player] - gives/takes admin power</li><li>!ban [player]/!unban [player] - bans/unbans the player (cannot ban room owners)</li>",
			Maps="<li>!map/!np [code] - loads the map code</li><li>!map/!np [code] mirror - loads the map code in a mirrored state</li><li>!skip - skips the current round during rotation</li><br><font size='15'>Other:</font><br><li>!map/!np history - list of maps played</li><li>!rst/!rst aie/!rst mirror - reloads the map</li>",
			Credits="<li>Buildtool by Emeryaurora#0000 for a large portion of the base code</li>"}
	
	info = "<p align='center'><font size='15'>"..titles[tab].."</font></p><br>"..info[tab]:gsub('>!(.-)([,:%-])','><font color="#BABD2F">!%1%2</font>')
	ui.addTextArea(enum.txarea.helptab, gui_btn.."<p align='center'>"..table.concat(buttonstr,'                      '), pn,75,35,650,20,gui_bg,gui_b,gui_o,true)
	ui.addTextArea(enum.txarea.help, info, pn,75,70,650,nil,gui_bg,gui_b,gui_o,true)
	players[pn].windows.help = true
end

function init()
	for _,v in ipairs({'AfkDeath','AutoNewGame','AutoScore','AutoShaman','AutoTimeLeft','PhysicalConsumables'}) do
		tfm.exec['disable'..v](true)
	end
	system.disableChatCommandDisplay(nil,true)
	for name in pairs(tfm.get.room.playerList) do eventNewPlayer(name) end
end

----- EVENTS

function eventChatCommand( pn , msg )
	local m,words = string.lower(msg), {}
	local mapped = {admin='adminban', ban='adminban', unadmin='adminban', unban='adminban', map='mapnp', np='mapnp', admins='ablist', banned='ablist', m='kill'}
	local showcommand,showcommandadmins = {tp=true,map=true,np=true,rst=true,time=true,kill=true},{admin=true,unadmin=true,ban=true,unban=true,admins=true}
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
	if settings.keys[k] then  -- prevent possible NPE
		settings.keys[k](pn,d,x,y)
	end
end

function eventMouse(pn, x, y)
	if not players[pn] then return end
	if roomsets.debug and players[pn].tptarget and admins[pn] then
		ExecuteForTargets(pn, players[pn].tptarget,
			function(name)
				tfm.exec.movePlayer(name, x, y)
			end
		)
		players[pn].tptarget = nil
	elseif players[pn].keys['shift'] then --shift+click to tp if admin
		if roomsets.debug and admins[pn] then
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
	grounds = {list={}}
	mapsets,roundvars = {Wind=0,Gravity=10,MGOC=100,Length=800,mousespawns={}}, {}
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
	maplist[#maplist+1] = {string.format("\t%s<a href='event:load!%s'>code: %s</a></font>", gui_btn, roundvars.thismap, roundvars.thismap), string.format("\t%s",tfm.get.room.xmlMapInfo and tfm.get.room.xmlMapInfo.author or 'unknown'), string.format("\tperm: %s", tfm.get.room.xmlMapInfo and tfm.get.room.xmlMapInfo.permCode or 'unknown')}
	ReadXML()
end

function eventNewPlayer( pn )
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
		loglist = {}
		}
	if staff[pn] or tfm.get.room.name:find(ZeroTag(pn)) or (ti > 0 and tfm.get.room.name:find(tn)) then 
		roomowners[pn] = true 
	end
	if roomowners[pn] then admins[pn] = true end
	--ShowHelp(pn,'General')
	--ShowLog(pn)
	MSG(pn.. " has entered the room.", nil, "J")
	if p.isDead then tfm.exec.respawnPlayer(pn) end
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
