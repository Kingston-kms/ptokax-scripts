---------------------------------------------------------------------------------------------------------
-- Mlink.Library.v3.0a.LUA5.X-PtokaX         				[ by: St0ne db ] [Modded by: Kingston]
---------------------------------------------------------------------------------------------------------

local Path,Script = Core.GetPtokaXPath().."scripts/RelBaseMySQL/","Релизы"

if (_VERSION == "Lua 5.1") then
	package.path = Path.."?.lua;"..package.path
	require "config";
	require "wizard";
	require "functions";
	TableMaxSize = table.maxn; 
	CollectTrash = function() collectgarbage("collect"); end	
elseif (_VERSION == "Lua 5.0.3") or (_VERSION == "Lua 5.0.2") then
	require(tVar.sFolder.."/config.lua");
	require(tVar.sFolder.."/wizard.lua");
	require(tVar.sFolder.."/functions.lua");
	TableMaxSize = table.getn; 
	CollectTrash = function() collectgarbage("collect"); end	
else
	Core.SendToAll("<"..SetMan.GetString(21).."> *** This bot requires Lua 5.1 or Lua 5.0.X.... your version is ".._VERSION);
end

--os.setlocale("ru_RU.CP1251");
luasql = require "luasql.mysql"
--require "luasql.mysql";
env = assert(luasql.mysql());

LibTask = {

	["Start"] = function()
		WizTemp = {};
	end,

	["UpdBase"] = function()
	-- Обновление базы: магнет, tth, размер и т.д.
	local iStart = os.clock()
	local cur = QuerySql(("SELECT `cat`, `num`, `magnet`, `lenght` FROM `rb_rels` WHERE `magnet` LIKE '%magnet:?%';"));
	local row = cur:fetch ({}, "a");
	while row do
		local TTH = "";
		local lenght = 0;
		QuerySql(("UPDATE `rb_rels` SET `tth`='%s',`lenght`='%s' WHERE `cat`='%s' AND `num`='%s';"):dbformat("0","0",row.cat,row.num));
		for Magnet in row.magnet:gmatch"(magnet:%S+)" do
			TTH = TTH..Magnet:match"urn:tree:tiger:(%w+)&xl="..", ";
			if Magnet:match"&xl=(%d+)&dn=" == nil then
				lenght = "0";
			else
			lenght = lenght+Magnet:match"&xl=(%d+)&dn=";
			end
		end
		local cur1 = QuerySql(("SELECT `link` FROM `rb_links` WHERE `rel_cat`='%s' AND `rel_id`='%s';"):dbformat(row.cat,row.num));
		local row1 = cur1:fetch ({}, "a");
		while row1 do
			for Magnet in row1.link:gmatch"(magnet:%S+)" do
			TTH = TTH..Magnet:match"urn:tree:tiger:(%w+)&xl="..", ";
				if Magnet:match"&xl=(%d+)&dn=" == nil then
					lenght = "0";
				else
					lenght = lenght+Magnet:match"&xl=(%d+)&dn=";
				end
			end
			row1 = cur1:fetch (row1,"a");
		end
		cur1:close();
		TTH = TTH:slice(0, -3);
		QuerySql(("UPDATE `rb_rels` SET `tth`='%s',`lenght`='%s' WHERE `cat`='%s' AND `num`='%s';"):dbformat(TTH,lenght,row.cat,row.num));
		row = cur:fetch (row, "a");
	end
    cur:close();
	--ToOpChat("Обновление базы завершено. Затрачено времени: "..(os.clock() - iStart).." сек.")
	end,
	
	["UpdStats"] = function()
		local iStart = os.clock()
		local cur = QuerySql(("SELECT * FROM `rb_users`;"));
		local row = cur:fetch ({}, "a");
		while row do
			local points = "0";
			local cur1 = QuerySql(("SELECT * FROM `rb_rels` WHERE `author`='%s';"):dbformat(row.nick));
			local points = cur1:numrows();
			local row1 = cur1:fetch ({},"a")
			while row1 do
				local rel_point = "0"
				for x in row1.magnet:gmatch"(magnet:%S+)" do
					rel_point = rel_point+2;
				end
				--[[for x in row.name:gmatch"(magnet:%S+)" do
					rel_point = rel_point-0.5;
				end]]--
				if row1.desc == "0" or row1.desc == "Не задано" then
					rel_point = rel_point-1;
				else
					rel_point = rel_point+3;
				end
				if row1.links ~= "0" then
					rel_point = rel_point+1;
					local cur2 = QuerySql(("SELECT * FROM `rb_links` WHERE `rel_cat`='%s' AND `rel_id`='%s'"):dbformat(row1.cat,row1.num));
					local row2 = cur2:fetch ({},"a");
					while row2 do
						for x in row2.link:gmatch"(magnet:%S+)" do
							rel_point = rel_point+2;
						end
						for x in row2.link:gmatch"(http://%S+)" do
							rel_point = rel_point+2;
						end
						row2 = cur2:fetch (row1,"a");
					end
					cur2:close();
				end
				QuerySql(("UPDATE `rb_rels` SET `points`='%s' WHERE `cat`='%s' AND `num`='%s' AND `author`='%s';"):dbformat(rel_point,row1.cat,row1.num,row.nick));
				points = points+rel_point;
				
				row1 = cur1:fetch (row1, "a");
			end
			cur1:close();
			QuerySql(("UPDATE `rb_users` SET `points`='%s' WHERE `nick`='%s';"):dbformat(points,row.nick));
			row = cur:fetch (row, "a");
		end
		cur:close();
		--ToOpChat("Обновление базы завершено. Затрачено времени: "..(os.clock() - iStart).." сек.")
	end,
	
	["RelDupeCheck"] = function(tth)
		local cur = QuerySql("SELECT * FROM `rb_rels` WHERE `name` LIKE '%"..tth.."%' OR `magnet` LIKE '%"..tth.."%' OR `tth` LIKE '%"..tth.."%'");
		local num = cur:numrows();
		if num > 0 then
			local row1 = cur:fetch ({}, "a");
			local dupe = {};
			while row1 do
				dupe = {['cat'] = row1.cat, ['rel']=row1.num};
				row1 = cur:fetch (row1, "a");
			end
			return dupe
		else
			return false
		end
		cur:close();
	end,
	
	["NewCat"] = function(user,temp)
		local cur = QuerySql("SELECT `id` FROM `rb_cat`");
		local num = cur:numrows()+1;
		QuerySql(("INSERT INTO `rb_cat` (`num`,`name`,`desc`,`expire`) VALUES ('%s','%s','%s','%s')"):dbformat(num,temp.cat.name,temp.cat.desc,temp.cat.exp));
		cur:close();
		local cur = QuerySql(("SELECT `num` FROM `rb_cat` WHERE `name`='%s'"):dbformat(temp.cat.name));
		local row = cur:fetch ({}, "a");
		while row do
			QuerySql(("INSERT INTO `rb_latest` (`cat`,`rel`) VALUES ('%s','0')"):dbformat(row.num));
			row = cur:fetch (row, "a");
		end
		cur:close();
	end,
		
	["DelCat"] = function(user,temp)
	    QuerySql(("DELETE FROM `rb_cat` WHERE `num` = '%s'"):dbformat(temp.cat.var));
		QuerySql(("DELETE FROM `rb_rels` WHERE `cat`='%s'"):dbformat(temp.cat.var));
		QuerySql(("DELETE FROM `rb_latest` WHERE `cat`='%s'"):dbformat(temp.cat.var));
	end,
	
	["DelRel"] = function(user,temp)
		QuerySql(("DELETE FROM `rb_rels` WHERE `cat`='%s' AND `num`='%s'"):dbformat(temp.rel.cat,temp.rel.var));
	end,
	
	["EditRel"] = function(user,temp)
		local relinfo = RelInfo(temp.rel.cat,temp.rel.var)
		if temp.new.name == "0" then
			temp.new.name = relinfo.name;
        end
		if temp.new.magnet == "0" then
			temp.new.magnet = relinfo.magnet;
        end
        if temp.new.desc == "0" then
			temp.new.desc = relinfo.desc;
		end
		QuerySql(("UPDATE `rb_rels` SET `name`='%s', `magnet`='%s', `desc`='%s' WHERE `cat`='%s' AND `num`='%s'"):dbformat(temp.new.name,temp.new.magnet,temp.new.desc,temp.rel.cat,temp.rel.var));
	end,

	["MoveRel"] = function(user,temp)
		local relinfo = RelInfo(temp.rel.cat,temp.rel.var);
		local oldcat = CatInfo(temp.rel.cat);
		local newcat = CatInfo(temp.new.cat);
		local oldlatest = QuerySql(("SELECT rel FROM `rb_latest` WHERE `cat` = '%s'"):dbformat(temp.rel.cat));
		local oldrow = oldlatest:fetch ({}, "a");
		oldlatest:close();
		local newlatest = QuerySql(("SELECT rel FROM `rb_latest` WHERE `cat` = '%s'"):dbformat(temp.new.cat));
		local newrow = newlatest:fetch ({}, "a");
		newlatest:close();
		if oldrow.rel == temp.rel.var then
			QuerySql(("UPDATE `rb_latest` SET `rel`='%s' WHERE `cat`='%s'"):dbformat(oldrow.rel-1,temp.rel.cat));
		end
		QuerySql(("UPDATE `rb_latest` SET `rel`='%s' WHERE `cat`='%s'"):dbformat(newrow.rel+1,temp.new.cat));
		QuerySql(("UPDATE `rb_cat` SET `rels`='%s' WHERE `num`='%s'"):dbformat(oldcat.rels-1,temp.rel.cat));
		QuerySql(("UPDATE `rb_cat` SET `rels`='%s' WHERE `num`='%s'"):dbformat(newcat.rels+1,temp.new.cat));
		QuerySql(("UPDATE `rb_rels` SET `cat`='%s', `num`='%s' WHERE `name`='%s' AND `magnet`='%s' AND `time`='%s' AND `author`='%s'"):dbformat(temp.new.cat,newcat.rels+1,relinfo.name,relinfo.magnet,relinfo.time,relinfo.author));
	end,
	
	["EditLink"] = function(user,temp)
		local relinfo = RelInfo(temp.rel.cat,temp.rel.var);
		if relinfo.links == "0" then
			QuerySql(("UPDATE `rb_rels` SET `links`='1' WHERE `cat`='%s' AND `num`='%s'"):dbformat(temp.rel.cat,temp.rel.var));
		end
		if temp.link.id ~= "" then
			QuerySql(("DELETE FROM `rb_links` WHERE `id`='%s' AND `rel_cat`='%s' AND `rel_id`='%s'"):dbformat(temp.link.id,temp.rel.cat,temp.rel.var));
		else
			QuerySql(("INSERT INTO `rb_links` (`rel_cat`,`rel_id`,`link`,`author`) VALUES ('%s','%s','%s','%s');"):dbformat(temp.rel.cat,temp.rel.var,temp.link.new,temp.var.sNick));
		end
		local cur = QuerySql(("SELECT * FROM `rb_links` WHERE `rel_cat`='%s' AND `rel_id`='%s'"):dbformat(temp.rel.cat,temp.rel.var));
		local numrows = cur:numrows();
		if numrows == 0 then
			QuerySql(("UPDATE `rb_rels` SET `links`='0' WHERE `cat`='%s' AND `num`='%s'"):dbformat(temp.rel.cat,temp.rel.var));
		end
		cur:close();
	end,

	["AddRel"] = function(user,temp)
		local cur0 = QuerySql(("SELECT `num` FROM `rb_rels` WHERE `cat`='%s' ORDER by `num` DESC LIMIT 1"):dbformat(temp.rel.cat));
		local row0 = cur0:fetch ({}, "a");
		if row0 == nil then
			QuerySql(("INSERT INTO `rb_rels` (`cat`,`num`,`name`,`desc`,`magnet`,`tth`,`lenght`,`time`,`author`) VALUES ('%s','%s','%s','%s','%s','%s','%s','%s','%s')"):dbformat(temp.rel.cat,1,temp.rel.name,temp.rel.desc,temp.rel.mlink,temp.rel.tth,temp.rel.lenght,os.time(),user.sNick));
			QuerySql(("UPDATE `rb_cat` SET `rels` = '%s' WHERE `num`= '%s'"):dbformat(1,temp.rel.cat));
		else
			while row0 do
				QuerySql(("INSERT INTO `rb_rels` (`cat`,`num`,`name`,`desc`,`magnet`,`tth`,`lenght`,`time`,`author`) VALUES ('%s','%s','%s','%s','%s','%s','%s','%s','%s')"):dbformat(temp.rel.cat,(row0.num+1),temp.rel.name,temp.rel.desc,temp.rel.mlink,temp.rel.tth,temp.rel.lenght,os.time(),user.sNick));
				QuerySql(("UPDATE `rb_cat` SET `rels` = '%s' WHERE `num`= '%s'"):dbformat((row0.num+1),temp.rel.cat));
				row0 = cur0:fetch (row0, "a");
			end
		end
		cur0:close();
		local cur = QuerySql(("SELECT num FROM `rb_rels` WHERE `cat`='%s' AND `name`='%s' AND `author`='%s' AND `magnet`='%s'"):dbformat(temp.rel.cat,temp.rel.name,user.sNick,temp.rel.mlink));
		local row = cur:fetch ({}, "a");
		QuerySql(("UPDATE `rb_latest` SET `rel`='%s' WHERE `cat`='%s'"):dbformat(row.num,temp.rel.cat));
		if tVar.sNofify ~= "off" then
			local info = QuerySql(("SELECT * FROM `rb_rels` WHERE `cat`='%s' AND `num`='%s'"):dbformat(temp.rel.cat,row.num));
			local rel = info:fetch ({}, "a");
			while rel do
				local cat = QuerySql(("SELECT `name` FROM `rb_cat` WHERE `num`='%s'"):dbformat(temp.rel.cat));
				local row = cat:fetch ({}, "a");
				local hub = Core.GetOnlineUsers();
                for u = 1, TableMaxSize(hub) do
                    local user = hub[u];
                    if pUser[user.iProfile] == 1 then
                        magnet = "";
                        if rel.magnet ~= "0" then
                            magnet = " ML: "..rel.magnet;
                        else
                            magnet = "";
                        end
                        ToUser(user,"Релиз: "..rel.name.." добавлен в категорию: "..row.name..", автор: "..rel.author..magnet);
                    end
                end
				cat:close();
				rel = info:fetch (rel, "a");
			end
			info:close();
		end
		cur:close();
	end,
};

tQCmd = {

	[tCmd.OnConnect] = function(user,data)
		if Wizard.QAC(user,tCmd.OnConnect) then
			local _,_,key = string.find(data,"%b<>%s+%S+%s+(%S+)");
			local cur = QuerySql(("SELECT * FROM `rb_users` WHERE `nick`='%s'"):dbformat(user.sNick))
			local row = cur:fetch ({}, "a");
			while row do
				if row.on_connect == "0" then
					if key == "1" then
						ToUser(user,"ВКЛючен показ релизов при входе на хаб.");
						QuerySql(("UPDATE `rb_users` SET `on_connect` = '%s' WHERE `nick` ='%s'"):dbformat(key,user.sNick))
					elseif key == "0" then
						ToUser(user,"Показ релизов при входе на хаб не был включен.");
					end
				end
				if row.on_connect == "1" then
					if key == "0" then
						ToUser(user,"ВЫКЛючен показ релизов при входе на хаб.");
						QuerySql(("UPDATE `rb_users` SET `on_connect` = '%s' WHERE `nick` ='%s'"):dbformat(key,user.sNick))
					elseif key == "1" then
						ToUser(user,"Показ релизов при входе на хаб не был выключен.");
					end
				end
				row = cur:fetch (row, "a");
			end
			cur:close();
		end
	end,

	[tCmd.sAddMod] = function(user,data)
		if Wizard.QAC(user,tCmd.sAddMod) then
			local _,_,cat,moder = string.find(data,"%b<>%s+%S+%s+(%d+)%s+(.*)");
			QuerySql(("UPDATE `rb_cat` SET `moder`='%s' WHERE `num`='%s'"):dbformat(moder,cat));
			ToUser(user,"Модератор категории №: "..cat.." изменен на "..moder);
		end
	end,

	[tCmd.TopRels] = function(user,data)
		if Wizard.QAC(user,tCmd.TopRels) then
			local top_header = ("\r\n\t%s\r\n\tТоп %s лучших релизеров:\r\n\t%s\r\n\tПозиция\tНик\t\t\tРанг\t\tБаллы\r\n\t%s"):format(separate1,tVar.sTopNum,separate1,separate2);
			local user_line = "";
			local i = 1;
			local cur = QuerySql(("SELECT * FROM `rb_users` ORDER BY `points` DESC LIMIT %s;"):dbformat(tVar.sTopNum))
			local row = cur:fetch ({}, "a")
			while row do
				local rang = "";
				for i,v in pairs(tRank) do
					if tonumber(row.points) > tRank[i]["Start"] and tonumber(row.points) <= tRank[i]["End"] then
						rang = tRank[i]["name"];
					end
				end
				if row.nick:len() < 8 then
					row.nick = row.nick.."  \t\t\t";
				elseif row.nick:len() >= 8 and row.nick:len() < 16 then
					row.nick = row.nick.." \t\t";
				elseif row.nick:len() >= 16 and row.nick:len() < 24 then
					row.nick = row.nick.." \t"
				end
				user_line = user_line..("\r\n\t%s\t%s%s\t\t%s"):format(i,row.nick,rang,row.points)
				i = i+1;
				row = cur:fetch (row,"a")
			end
			cur:close();
			local msg = top_header..user_line.."\r\n\t"..separate1
			PmToUser(user,msg)
		end
	end,

	[tCmd.sStats] = function(user,data)
		if Wizard.QAC(user,tCmd.sStats) then
			local cur = QuerySql("SELECT id FROM `rb_cat`;");
			local num_cat = cur:numrows();
			cur:close();
			local cur = QuerySql("SELECT id FROM `rb_rels`;");
			local num_rel = cur:numrows();
			cur:close();
			local cur = QuerySql("SELECT * FROM `rb_cat`;")
			local row = cur:fetch ({}, "a");
			local cat_list = "";
			local db_lenght = 0;
			while row do
				local cur1 = QuerySql(("SELECT `id` FROM `rb_rels` WHERE `cat`='%s'"):dbformat(row.num));
				local row1 = cur1:numrows();
				cur1:close();
				local cat_lenght = 0;
				local cur2 = QuerySql(("SELECT `lenght` FROM `rb_rels` WHERE `cat`='%s'"):dbformat(row.num));
				local row2 = cur2:fetch ({}, "a");
				while row2 do
					cat_lenght = cat_lenght+row2.lenght;
					row2 = cur2:fetch (row2,"a");
				end
				cur2:close();
				db_lenght = db_lenght+cat_lenght;
				cat_lenght = GetNormalShare(cat_lenght,3)
				if row.name:len() <= 8 then
					row.name = row.name.."\t\t\t";
				elseif row.name:len() > 8 and row.name:len() <= 16 then
					row.name = row.name.."\t\t";
				elseif row.name:len() > 16 and row.name:len() <= 24 then
					row.name = row.name.."\t"
				end
				cat_list = cat_list..("\t%s\t%s(релизов: %s )\tРазмер данных: %s\n"):format(row.num,row.name,row1,cat_lenght);
				row = cur:fetch (row, "a")
			end
			cur:close();
			local all_magnet = "";
			local cur = QuerySql("SELECT `id` FROM `rb_rels` WHERE `magnet` LIKE '%magnet:?%' OR `name` LIKE '%magnet:?%';");
			local magnet_rel = cur:numrows();
			cur:close();
			local cur = QuerySql("SELECT `id` FROM `rb_links` WHERE `link` LIKE '%magnet:?%';");
			local magnet_link = cur:numrows();
			cur:close();
			all_magnet = magnet_rel+magnet_link;
			db_lenght = GetNormalShare(db_lenght,3)
			PmToUser(user,("\r\n%s\r\n\tСтатистика базы:\r\n\tВсего категорий: %s\r\n\tВсего релизов: %s\r\n\tВсего MAGNET: %s\r\n\tВсего данных: %s\r\n%s\r\n\tСтатистика по категориям:\r\n%s%s"):format(separate,num_cat, num_rel,all_magnet,db_lenght,separate,cat_list,separate));
		end
	end,
	
	[tCmd.UserStats] = function(user,data)
		if Wizard.QAC(user,tCmd.UserStats) then
			local points = "0";
			local cur = QuerySql(("SELECT * FROM `rb_rels` WHERE `author`='%s';"):dbformat(user.sNick));
			local rels = cur:numrows();
			if rels > 1 then
                local points = rels;
                local row = cur:fetch ({},"a")
                while row do
                    local rel_point = "0"
                    for x in row.magnet:gmatch"(magnet:%S+)" do
                        rel_point = rel_point+2;
                    end
                    if row.desc == "0" or row.desc == "Не задано" then
                        rel_point = rel_point-1;
                    else
                        rel_point = rel_point+3;
                    end
                    if row.links ~= "0" then
                        rel_point = rel_point+1;
                        local cur1 = QuerySql(("SELECT * FROM `rb_links` WHERE `rel_cat`='%s' AND `rel_id`='%s'"):dbformat(row.cat,row.num));
                        local row1 = cur1:fetch ({},"a");
                        while row1 do
                            for x in row1.link:gmatch"(magnet:%S+)" do
                                rel_point = rel_point+2;
                            end
                            for x in row1.link:gmatch"(http://%S+)" do
                                rel_point = rel_point+2;
                            end
                            row1 = cur1:fetch (row1,"a");
                        end
                        cur1:close();
                    end
                    QuerySql(("UPDATE `rb_rels` SET `points`='%s' WHERE `cat`='%s' AND `num`='%s' AND `author`='%s';"):dbformat(rel_point,row.cat,row.num,user.sNick));
                    points = points+rel_point;
                    
                    row = cur:fetch (row, "a");
                end

                local rang = "";
                for i,v in pairs(tRank) do
                    if points > tRank[i]["Start"] and points <= tRank[i]["End"] then
                        rang = tRank[i]["name"];
                    end
                end
                QuerySql(("UPDATE `rb_users` SET `points`='%s' WHERE `nick`='%s';"):dbformat(points,user.sNick));
                
                local max_rel,max_cat;
                local cur = QuerySql(("SELECT `cat`, COUNT(*) FROM `rb_rels` WHERE `author` = '%s' GROUP BY `cat` ORDER BY COUNT( * ) DESC LIMIT 1;"):dbformat(user.sNick))
                local row = cur:fetch ({}, "n")
                while row do
                    for i,v in ipairs(row) do
                        if i == 1 then max_cat = v end;
                        if i == 2 then max_rel = v end;
                    end
                    row = cur:fetch (row, "n")
                end
                cur:close();
                local cat_name;
                local cur = QuerySql(("SELECT `name` FROM `rb_cat` WHERE `num`='%s';"):dbformat(max_cat));
                local row = cur:fetch ({}, "a")
                while row do
                    cat_name = row.name;
                    row = cur:fetch (row, "a")
                end
                cur:close();
                local msg = ("\r\n\t%s\r\n\tВаша статистика:\r\n\t%s\r\n\tБаллы: %s\r\n\tРанг: %s\r\n\tКол-во релизов: %s\r\n\tНаиболее активен в категории: %s\r\n\t%s\r\n\tИнформация:\r\n\t%s\r\n\t+1 балл за релиз в целом\r\n\t+2 балл за каждую MAGNET ссылку\r\n\t+3 балла за описание релиза\r\n\t+1 балл за присутствие Дополнительных ссылок\r\n\t+2 балл за каждую MAGNET ссылку в Дополнительных ссылках\r\n\t+2 балл за каждую WEB ссылку в Дополнительных ссылках\r\n\t%s\r\n\tОбновление статистики при просмотре\r\n\t%s"):format(string.rep("=",60),string.rep("-",60),points,rang,rels,cat_name,string.rep("=",60),string.rep("-",60),string.rep("-",60),string.rep("=",60))
                
                PmToUser(user,msg)
            else
				ToUser(user,"Вы не добавили ни одного релиза в базу, статистика пуста.")
			end
            cur:close();
		end
	end,
	
	[tCmd.sSearchName] = function(user,data)
		if Wizard.QAC(user,tCmd.sSearchName) then
			local _,_,search = string.find(data,"%b<>%s+%S+%s+(.*)");
			if search == nil then
				ToUser(user,"Введите фразу для поиска, желательно одно конкретное слово.");
			else
				--search = search:gsub()
				local like = search:gsub(" ", "%%' AND `name` LIKE '%%")
				local cur = QuerySql("SELECT * FROM `rb_rels` WHERE `name` LIKE '%"..like.."%'");
				local num_search = cur:numrows();
				local row = cur:fetch ({}, "a");
				local rel_list = "";
				while row do
					rel_list = rel_list..("\r\n\t%s.%s\tНазвание: %s ^ Magnet: %s"):format(row.cat,row.num,row.name,row.magnet);
					row = cur:fetch (row, "a")
				end
				cur:close();
				s = ("\r\n\t%s\r\n\tРезультаты поиска фразы %s:\r\n\t%s\r\n\tКол-во релизов: %s\r\n\t%s%s\r\n\t%s"):format(string.rep("=",60),search,string.rep("-",60),num_search,string.rep("-",60),rel_list,string.rep("=",60));
				PmToUser(user,s)
			end
		end
	end,
	
	[tCmd.sLatest] = function(user,data)
		if Wizard.QAC(user,tCmd.sLatest) then
			local _,_,num = string.find(data,"%b<>%s+%S+%s+(%d+)");
			if num == nil then
				num_rel = tVar.Latest;
			else
                if tonumber(num) > 100 then
                    ToUser(user,"Максимальное кол-во отображаемых релизов: 100");
                    num_rel = 100;
                else
                    num_rel = tonumber(num);
                end
			end
			local cur = QuerySql(("SELECT Q.* FROM (SELECT * FROM `rb_rels` ORDER BY `time` DESC LIMIT %s) Q ORDER BY Q.`time` ASC;"):dbformat(num_rel));
			local row = cur:fetch ({}, "a");
			local s = "\r\n\t"..string.rep("=",60).."\r\n\tПоследние релизы:\r\n\t";
			while row do
				s = s..string.rep("-",60).."\r\n\t"..row.cat.."."..row.num.."\tНазвание: "..row.name.." ^ Magnet: "..row.magnet.."\r\n\t"
				row = cur:fetch (row, "a")
			end
			s = s..string.rep("=",60)
			cur:close();
			PmToUser(user,s)
		end
	end,
	
	[tCmd.sNickRels] = function(user,data)
		if Wizard.QAC(user,tCmd.sNickRels) then
		local _,_,nick = string.find(data,"%b<>%s+%S+%s+(%S+)");
		if nick == nil then
			nick = user.sNick
		end
		local cur = QuerySql(("SELECT * FROM `rb_rels` WHERE `author`='%s' ORDER by `time` DESC LIMIT 150;"):dbformat(nick));
		local nums = cur:numrows();
		local row = cur:fetch ({}, "a");
		local s = "\r\n\t"..string.rep("=",60).."\r\n\tРелизы пользователя "..nick.." (всего "..nums.." )\r\n\t";
		while row do
			s = s..string.rep("-",60).."\r\n\t"..row.cat.."."..row.num.."\tНазвание: "..row.name.." ^ Magnet: "..row.magnet.."\r\n\t"
			row = cur:fetch (row, "a")		
		end
		s = s..string.rep("=",60)
		cur:close();
		PmToUser(user,s)
		end
	end,
	
	[tCmd.qHelp] = function(user,data)
		if Wizard.QAC(user,tCmd.qHelp) then
	       ToUser(user,"\n\t"..string.rep("=",15).."\tПомощь: Релизы\t"..string.rep("=",15)..
												  "\n\t!show\t\t-\tПросмотр релизов"..
												  "\n\t!new\t\t-\tДобавить релиз"..
												  "\n\t!del\t\t-\tУдалить релиз"..
												  "\n\t!editrel\t\t-\tИзменить релиз"..
												  "\n\t!mllhelp\t\t-\tПросмотр данной справки"..
												  "\n\t"..string.rep("=",15).."\tПомощь: Релизы\t"..string.rep("=",15)
												  )
	       return 1
	    end
	end,
	
	
	[tCmd.UpdBase] = function(user,data)
		if Wizard.QAC(user,tCmd.UpdBase) then
		ToUser(user,"Запущено обновление базы");
		LibTask.UpdBase();
		ToUser(user,"Обновление завершено");
		CollectTrash();
	    end
	end,

	[tCmd.UpdStats] = function(user,data)
		if Wizard.QAC(user,tCmd.UpdStats) then
		ToUser(user,"Запущено обновление базы");
		LibTask.UpdStats();
		ToUser(user,"Обновление завершено");
		CollectTrash();
	    end
	end,
};

OnStartup = function()
    --GenMenu();
	--os.setlocale("ru_RU.CP1251");
	OpChat = SetMan.GetOpChat();
	--Core.RegBot(tVar.sBot,tVar.sBotD,tVar.sBotE,true);
	--if tVar.sNotify ~= "off" or tVar.sOnConnect ~= "off" then
	--	Core.RegBot(tVar.nBot,tVar.nBotD,tVar.nBotE,true);
	--end
    if tVar.sRCSubMenu == "" then tVar.sRCSubMenu = Script end
	LibTask.Start();
	CheckSQL();
	TmrMan.AddTimer(1000);
    ConTmr = TmrMan.AddTimer (5*60*1000);
end

function OnTimer(ConTmr)
	CheckSQL();
end

function CheckSQL()
        if not conn or not conn:execute("USE "..tSql.DbName) then
                conn = assert(env:connect(tSql.DbName,tSql.UserName,tSql.UserPass,tSql.Host,tSql.Port))
                if conn then
                        conn:execute("SET NAMES "..tSql.Charset)
                        CreateTable()
                        return true
                end
        else
                return true
        end
end

OnExit = function()
	conn:close();
	env:close();
end

OnError = function(msg)
	local user = Core.GetUser(tVar.sOpNick)
	if user then
		ToUser(user,msg)
	end
end

ChatArrival = function(user,data)
	local data = string.sub(data,1,-2)
	local _,_,sTrig,sCmd = string.find(data,"%b<>%s*(%S)(%S+)")
	if sTrig and sCmd and sTrig == tVar.sTrig then
    	if not Wizard.Start(user,data,sCmd) then
    	    if tQCmd[sCmd] then
    	        tQCmd[sCmd](user,data);
    	        return true;
    	    end
		else
		    return true;
		end
	end
end

ToArrival = function(user,data)
	if string.sub(data,6,5+(string.len(tVar.sBot))) == tVar.sBot then
		data = string.sub(data,(18+string.len(tVar.sBot)+2*string.len(user.sNick)),(string.len(data)-1));
		local _,_,sTrig,sCmd = string.find(data,"(%S)(%S+)");
		if sTrig and sCmd and sTrig == tVar.sTrig then
    		if not Wizard.Start(user,data,sCmd) then
    		    if tQCmd[sCmd] then
    		        tQCmd[sCmd](user,"<"..user.sNick.."> "..data);
    		        return true;
    		    end
    		end
        elseif WizTemp[user.sNick] then
			local wiz = WizTemp[user.sNick]["wizard"];
			Wizard[wiz]["Start"](user,data,WizTemp[user.sNick]);
			return true;
		end
	end
end

function GenMenu()
	local cur = QuerySql(("SELECT num,name FROM `rb_cat`;"))
	local row = cur:fetch ({}, "a");
	local s = ""
	while row do
		s = s.."$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Просмотр\\Из категории\\"..row.name.."$<%[mynick]> "..tVar.sTrig..tCmd.sShowRelFromCat.." "..row.num.."&#124;|";
		row = cur:fetch (row, "a")
	end
	cur:close();
	return s
end

local sOpContextMenu = "$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Управление\\Добавить категорию$<%[mynick]> "..tVar.sTrig..tCmd.sAddCat.."&#124;|"..
					"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Управление\\Удалить категорию$<%[mynick]> "..tVar.sTrig..tCmd.sDelCat.."&#124;|"..
					"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Управление\\Модер категории$<%[mynick]> "..tVar.sTrig..tCmd.sAddMod.." %[line:Введите номер категории] %[line:Введите ник модератора, 0 - убрать модера]&#124;|"


local sUserContextMenu = "$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Информация\\Статистика$<%[mynick]> "..tVar.sTrig..tCmd.sStats.."&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Информация\\Топ "..tVar.sTopNum.."$<%[mynick]> "..tVar.sTrig..tCmd.TopRels.."&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Информация\\Моя статистика$<%[mynick]> "..tVar.sTrig..tCmd.UserStats.."&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Информация\\Мои релизы$<%[mynick]> "..tVar.sTrig..tCmd.sNickRels.."&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Информация\\Помощь$<%[mynick]> "..tVar.sTrig..tCmd.qHelp.." &#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Просмотр\\Все релизы$<%[mynick]> "..tVar.sTrig..tCmd.sShowRel.."&#124;|"..
				GenMenu()..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Просмотр\\Последние N релизов$<%[mynick]> "..tVar.sTrig..tCmd.sLatest.." %[line:Введите кол-во для показа. Max: 100. Def: 20]&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Просмотр\\Поиск по названию$<%[mynick]> "..tVar.sTrig..tCmd.sSearchName.." %[line:Введите фразу для поиска.]&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Просмотр\\Поиск по автору$<%[mynick]> "..tVar.sTrig..tCmd.sNickRels.." %[line:Введите ник автора.]&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Добавить\\Новый релиз$<%[mynick]> "..tVar.sTrig..tCmd.sAddRel.."&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Добавить\\Новую ссылку$<%[mynick]> "..tVar.sTrig..tCmd.sEditLink.."&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Изменить\\Редактировать$<%[mynick]> "..tVar.sTrig..tCmd.sEditRel.."&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Изменить\\Переместить$<%[mynick]> "..tVar.sTrig..tCmd.sMoveRel.."&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Удалить\\Релиз$<%[mynick]> "..tVar.sTrig..tCmd.sDelRel.."&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Удалить\\Ссылку$<%[mynick]> "..tVar.sTrig..tCmd.sEditLink.."&#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Показ при входе\\ВКЛючить$<%[mynick]> "..tVar.sTrig..tCmd.OnConnect.." 1 &#124;|"..
				"$UserCommand 1 3 "..tVar.sRCSubMenu.."\\Показ при входе\\ВЫКЛючить$<%[mynick]> "..tVar.sTrig..tCmd.OnConnect.." 0 &#124;|"
				
UserConnected = function(user)
	if pUser[user.iProfile] == 1 then
		Core.GetUserAllData(user)
	 	if string.lower(tVar.sRC) == "on" then
		--	if Core.GetUserValue(user,12) then
				if pAdmin[user.iProfile] == 1 then
					Core.SendToUser(user, sOpContextMenu)
				end
				Core.SendToUser(user,sUserContextMenu)
			--end--
	 	end
		
		--local temp = { ["skin"] = tVar.sSkin};
		local cur = QuerySql(("SELECT * FROM `rb_users` WHERE `nick`='%s'"):dbformat(user.sNick))
		local row = cur:fetch ({}, "a")
			if row == nil then
				ToUser(user, "Ваш ник занесен в базу, теперь вы можете добавлять релизы.")
				QuerySql(("INSERT INTO `rb_users` (`nick`, `ip`) VALUES ('%s', '%s');"):dbformat(user.sNick,user.sIP))
			else
				if tonumber(SizeDB()) > 0 and tonumber(SizeDB("1")) > 0 then
					if row.on_connect == "1" then
						--os.setlocale"ru_RU.1251"
						ToUser(user,Wizard.Tags(Wizard.Show.OnEntry(),temp));
						ToUser(user,"Чтобы отключить вывод релизов при соединении, воспользуйтесь меню.");
					elseif row.on_connect == "0" then
						ToUser(user,"Вывод релизов при соединении отключен, воспользуйтесь меню.");
					end
				else
					ToUser(user,"На данный момент релизов в базе нет.");
				end
			end
			--row = cur:fetch (row, "a");
		cur:close();
	end
end

OpConnected = UserConnected
RegConnected = UserConnected
