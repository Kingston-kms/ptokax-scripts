---------------------------------------------------------------------------------------------------------
-- Mlink.Library.v2.0.LUA5.X-PtokaX         											 [ by: St0ne db ]
-- Mlink.Library.v3.0.LUA5.X-PtokaX 							 [Converted to new API by lUk3f1l3w4lK3R]
---------------------------------------------------------------------------------------------------------

Wizard = {

	["Start"] = function(user,data,cmd)
		local tWiz = {
			[tCmd.sAddRel] 	= "AddRel",
			[tCmd.sAddCat] 	= "AddCat",
			[tCmd.sDelRel] 	= "DelRel",
			[tCmd.sDelCat] 	= "DelCat",
			--[tCmd.sReq] 	= "AddReq",
			[tCmd.sShowRel]	= "ShowRel",
			[tCmd.sShowRelFromCat]	= "ShowRelFromCat",
			[tCmd.sEditRel] = "EditRel",
			[tCmd.sMoveRel] = "MoveRel",
			[tCmd.sEditLink] = "EditLink",
		};
		if tWiz[cmd] then
			if wAccess[tWiz[cmd]][user.iProfile] == 1 then
				Wizard.InitTemp(user,tWiz[cmd]);
				Wizard[tWiz[cmd]]["Start"](user,data,WizTemp[user.sNick]);
			else
				PmToUser(user,"У Вас нет доступа к данной команде.")
			end
			return true;
		end
		return nil;
	end,
	
	["QAC"] = function(user,cmd)
		if tAccess[cmd][user.iProfile] == 1 then
		    return 1;
		else
		    PmToUser(user,Wizard.Denial(tVar.sSkin));
		end
	end,

    ["Movement"] = function(user,data,step,maxstep)
		if string.lower(data) == "quit" or string.lower(data) == "q" then
    		step = -99;
		elseif string.lower(data) == "back" or string.lower(data) == "b" then
			if step > 1 then
			    step = step - 1;
			else
			    step = 1;
			end
			data = -1;
		end
		return step,data;
	end,
	
	["InitTemp"] = function(user,wiz)
		WizTemp[user.sNick] = {
		    ["cat"] = {["name"] = "", ["desc"] = "", ["exp"] = 0, ["var"] = 0},
			
		    ["rel"] = {["name"] = "", ["desc"] = "", ["url"] = "", ["mlink"] = "", ["tth"] = "",["cat"] = 0, ["var"] = {},["lenght"] = 0},
			
			["new"] = {["name"] = "0", ["desc"] = "0", ["magnet"] = "0", ["cat"] = "0"},
			
			["link"] = {["new"] = "", ["id"] = ""},
			
			["vote"] = {["rating"] = 0, ["comment"] = ""},
			
		    ["step"] = 1,
			--["skin"] = LibData[user.sNick]["skin"],
			["var"] = user, ["wizard"] = wiz,
		};
		if wiz == "Clear" then WizTemp[user.sNick] = nil; CollectTrash(); end
	end,
	
	["Show"] = {
	
		["CatList"] = function()
			local cur = QuerySql("SELECT * FROM `rb_cat`");
			local row = cur:fetch ({}, "a")
			local s = ""
			while row do
				local cur2 = QuerySql(("SELECT id FROM `rb_rels` WHERE `cat`='%s'"):dbformat(row.num));
				local row2 = cur2:numrows();
				cur2:close();
			  s = s..("\t%s\t%s\t(релизов: %s )\tМодератор: %s\n\t\tОписание: %s\n\t%s\n"):format(row.num,row.name,row2,row.moder,row.desc,string.rep("-",85));
			  row = cur:fetch (row, "a")
			end
			cur:close();
			return s;
		end,
		
		["NewCat"] = function(temp)
		    local msg = ("\tПроверьте информацию для новой категории:".."\n\tНазвание: %s\n\tОписание: %s\n\tВремя хранения: %s"):format(temp.cat.name,temp.cat.desc,temp.cat.exp);
		    return msg;
		end,
		
		["CatDetails"] = function(temp)
			local s = ""
			local cur = QuerySql(("SELECT * FROM `rb_cat` WHERE `num`='%s'"):dbformat(temp.cat.var));
			local row = cur:fetch ({}, "a");
			while row do
				s = (("\tНазвание: %s\n\tОписание: %s\n\tКол-во: %s"):format(row.name,row.desc,row.rels));
				row = cur:fetch(row, "a");
			end
			cur:close();
			return s
		end,
		
		["OnEntry"] = function()
			local s = "\n\t"..string.rep("=",80).."{show latest releases}\t"..string.rep("=",80);
			return s;
		end,
		
		["LatestRel"] = function(temp)
			local s = "\n";
			for i=1,SizeDB() do
				local header = "";
				local cur = QuerySql(("SELECT * FROM `rb_rels` WHERE `cat`='%s' ".."AND `time` > '"..(os.time()-tVar.TimeRel).."' ORDER BY `num` DESC LIMIT %s"):dbformat(i,tVar.sLastRel));
				local row = cur:fetch ({}, "a");
				local rel = "";
				while row do
					local cur1 = QuerySql(("SELECT name,moder FROM `rb_cat` WHERE `num`='%s'"):dbformat(i));
					local row1 = cur1:fetch ({}, "a");
					while row1 do
						header = "\t•••••••••••••••• ["..i.."] "..row1.name.." (модератор: "..row1.moder..") •••••••••••••••• \n"
						row1 = cur1:fetch {row1, "a"};
					end
					cur1:close();
					local magnet = "";
					if row.magnet ~= "0" then
						local array = {};
						local i = 0;
						for MagnetI in row.magnet:gmatch"(magnet:%S+)" do
							array[i] = MagnetI;
							--magnet = array[i];
							i = i + 1;
							magnet = array[0].." (всего: "..i.." ) ";
						--magnet = row.magnet:match"(magnet:%S+)";							
						end
					else
						magnet = "";
					end
					rel = rel..("\t  %s.%s\t%s\n\t\t%s добавлено: %s, %s\n"):format(row.cat,row.num,row.name,magnet,row.author,os.date(tVar.sDate,row.time));
					row = cur:fetch ({}, "a");
				end
				cur:close();
				s = s..header..rel
			end
			return s;
		end,		
		
		["RelList"] = function(temp)
			local s = "\n";
            local cur = QuerySql(("SELECT Q.* FROM (SELECT * FROM `rb_rels` WHERE `cat`='%s' ORDER BY `num` DESC LIMIT 200) Q ORDER BY Q.`num` ASC;"):dbformat(temp.rel.cat));
			local row = cur:fetch ({}, "a");
			while row do
				s = s..("\t%s.%s\t%s , добавлено: %s, автор: %s\n"):format(row.cat,row.num,row.name,os.date(tVar.sDate,row.time),row.author);
				if row.magnet ~= "0" then
					s = s.."\t\tМагнет-ссылка: "..row.magnet.."\n";
				end
				if row.desc ~= "0" then
					s = s.."\t\tОписание: Есть\n";
				end
				if row.links == "1" then
					s = s.."\t\tДополнительные ссылки: Есть\n";
				end
				s = s.."\t"..string.rep("-",100).."\n";
				row = cur:fetch (row, "a");
			end
			cur:close();
			return s;
		end,
		
		["DelRelList"] = function(temp)
			local a = "";
			local catinfo = CatInfo(temp.rel.cat);
			if pAdmin[temp.var.iProfile] == 1 or (catinfo.moder == temp.var.sNick) then a = "\tАдминский доступ, вы можете удалять любой релиз.\n" else a = "\tПользовательский доступ, вы можете удалять только свои релизы.\n" end 
			local s = ""
            local cur = QuerySql(("SELECT Q.* FROM (SELECT * FROM `rb_rels` WHERE `cat`='%s' ORDER BY `num` DESC LIMIT 200) Q ORDER BY Q.`num` ASC;"):dbformat(temp.rel.cat));
			local row = cur:fetch ({}, "a");
			while row do
				s = s..("\t%s.%s\t%s , добавлено: %s, автор: %s\n"):format(row.cat,row.num,row.name,os.date(tVar.sDate,row.time),row.author);
				if row.magnet ~= "0" then
					s = s.."\t\tМагнет-ссылка: "..row.magnet.."\n";
				end
				if row.desc ~= "0" then
					s = s.."\t\tОписание: Есть\n";
				end
				s = s.."\t"..string.rep("-",100).."\n";
				row = cur:fetch (row, "a");
			end
			s = s..a
			cur:close();
			return s;
		end,				
		
		["EditRelList"] = function(temp)
			local a = "";
			local catinfo = CatInfo(temp.rel.cat);
			if pAdmin[temp.var.iProfile] == 1 or (catinfo.moder == temp.var.sNick) then a = "\tАдминский доступ, вы можете редактировать любой релиз.\n" else a = "\tПользовательский доступ, вы можете редактировать только свои релизы.\n" end 
			local s = ""
            local cur = QuerySql(("SELECT Q.* FROM (SELECT * FROM `rb_rels` WHERE `cat`='%s' ORDER BY `num` DESC LIMIT 200) Q ORDER BY Q.`num` ASC;"):dbformat(temp.rel.cat));
			local row = cur:fetch ({}, "a");
			while row do
				s = s..("\t%s.%s\t%s , добавлено: %s, автор: %s\n"):format(row.cat,row.num,row.name,os.date(tVar.sDate,row.time),row.author);
				if row.magnet ~= "0" then
					s = s.."\t\tМагнет-ссылка: "..row.magnet.."\n";
				end
				if row.desc ~= "0" then
					s = s.."\t\tОписание: Есть\n";
				end
				s = s.."\t"..string.rep("-",100).."\n";
				row = cur:fetch (row, "a");
			end
			s = s..a
			cur:close();
			return s;
		end,

		["MoveRelList"] = function(temp)
			local a = "";
			local catinfo = CatInfo(temp.rel.cat);
			if pAdmin[temp.var.iProfile] == 1 or (catinfo.moder == temp.var.sNick) then a = "\tАдминский доступ, вы можете перемещать любой релиз.\n" else a = "\tПользовательский доступ, вы можете перемещать только свои релизы.\n" end 
			local s = ""
            local cur = QuerySql(("SELECT Q.* FROM (SELECT * FROM `rb_rels` WHERE `cat`='%s' ORDER BY `num` DESC LIMIT 200) Q ORDER BY Q.`num` ASC;"):dbformat(temp.rel.cat));
			local row = cur:fetch ({}, "a");
			while row do
				s = s..("\t%s.%s\t%s , добавлено: %s, автор: %s\n"):format(row.cat,row.num,row.name,os.date(tVar.sDate,row.time),row.author);
				if row.magnet ~= "0" then
					s = s.."\t\tМагнет-ссылка: "..row.magnet.."\n";
				end
				if row.desc ~= "0" then
					s = s.."\t\tОписание: Есть\n";
				end
				s = s.."\t"..string.rep("-",100).."\n";
				row = cur:fetch (row, "a");
			end
			s = s..a
			cur:close();
			return s;
		end,
		
		["RelDetails"] = function(temp)
			local cur = QuerySql(("SELECT * FROM `rb_rels` WHERE `cat`='%s' AND `num`='%s'"):dbformat(temp.rel.cat,temp.rel.var));
			local row = cur:fetch ({}, "a");
			local msg = "";
			local links = ""
			while row do
				if row.desc == "0" then
					row.desc = "нет";
				end
				if row.magnet == "0" then
					row.magnet = "нет";
				end
				if row.links ~= "0" then
					local cur2 = QuerySql(("SELECT * FROM `rb_links` WHERE `rel_cat`='%s' AND `rel_id`='%s'"):dbformat(temp.rel.cat,temp.rel.var));
					local row2 = cur2:fetch ({}, "a")
					while row2 do
						links = links.."\n\t"..row2.link
						row2 = cur2:fetch (row2, "a");
					end
					cur2:close();
				else
					links = "Нет";
				end
				msg = msg..("\tРелиз №: %s.%s\n\t%s\n\tНазвание: %s\n\tМагнет-ссылка: %s\n\tАвтор: %s\n\tДата релиза: %s\n\t%s\n\tОписание: %s\n\t%s\n\tДополнительные ссылки: %s\n"):format(row.cat,row.num,string.rep("-",110),row.name,row.magnet,row.author,os.date(tVar.sDate,row.time),string.rep("-",110),row.desc,string.rep("-",110),links);
				row = cur:fetch (row, "a");
			end
			cur:close();
			return msg;
		end,

		["EditRelDetails"] = function(temp)
			local cur = QuerySql(("SELECT * FROM `rb_rels` WHERE `cat`='%s' AND `num`='%s'"):dbformat(temp.rel.cat,temp.rel.var));
			local row = cur:fetch ({}, "a");
			local msg = "";
			while row do
				if row.desc == "0" then
					row.desc = "нет";
				end
				if row.magnet == "0" then
					row.magnet = "нет";
				end
				msg = msg..("\tРелиз №: %s.%s\n\t%s\n\tНазвание: %s\n\tМагнет-ссылка: %s\n\tАвтор: %s\n\tДата релиза: %s\n\t%s\n\tОписание: %s\n"):format(row.cat,row.num,string.rep("-",110),row.name,row.magnet,row.author,os.date(tVar.sDate,row.time),string.rep("-",110),row.desc);
				row = cur:fetch (row, "a");
			end
			cur:close();
			if temp.new.name == "" then
				temp.new.name = "Не изменено"
			end
			if temp.new.magnet == "" then
				temp.new.magnet = "Не изменено"
			end
			if temp.new.desc == "" then
				temp.new.desc = "Не изменено"
			end
			local new_info = ("%s\n\tНовая информация о релизе:\n%s\n\tНовое название: %s\n\tНовая ML: %s \n\tНовое описание: %s\n"):format(separate,separate,temp.new.name,temp.new.magnet,temp.new.desc);
			msg = msg..new_info
			return msg;
		end,
	
		["LinkRelDetails"] = function(temp)
			local cur = QuerySql(("SELECT * FROM `rb_rels` WHERE `cat`='%s' AND `num`='%s'"):dbformat(temp.rel.cat,temp.rel.var));
			local row = cur:fetch ({}, "a");
			local msg = "";
			local links = "";
			while row do
				if row.desc == "0" then
					row.desc = "нет";
				end
				if row.magnet == "0" then
					row.magnet = "нет";
				end
				msg = msg..("\tРелиз №: %s.%s\n\t%s\n\tНазвание: %s\n\tМагнет-ссылка: %s\n\tАвтор: %s\n\tДата релиза: %s\n\t%s\n\tОписание: %s\n"):format(row.cat,row.num,string.rep("-",110),row.name,row.magnet,row.author,os.date(tVar.sDate,row.time),string.rep("-",110),row.desc);
				if row.links ~= "0" then
					local cur2 = QuerySql(("SELECT * FROM `rb_links` WHERE `rel_cat`='%s' AND `rel_id`='%s'"):dbformat(temp.rel.cat,temp.rel.var));
					local row2 = cur2:fetch ({}, "a");
					while row2 do
						links = links.."\n\t"..row2.id.."\t"..row2.link
						row2 = cur2:fetch (row2, "a");
					end
					cur2:close();
				else
					links = "нет";
				end
				row = cur:fetch (row, "a");
			end
			cur:close();
			msg = msg.."\tДополнительные ссылки: "..links.."\n"
			return msg;
		end,
	},
	
	["Tags"] = function(msg,temp)
		local Pre = function(s)
			s = string.gsub(s,"%%","%%%%")
			return s;
		end
		if string.find(msg,"({category list})") then
			msg = string.gsub(msg,"{category list}",Pre(Wizard.Show.CatList()));
		end
		if string.find(msg,"({verify category})") then
			msg = string.gsub(msg,"{verify category}",Pre(Wizard.Show.NewCat(temp)));
		end
		if string.find(msg,"({category details})") then
			msg = string.gsub(msg,"{category details}",Pre(Wizard.Show.CatDetails(temp)));
		end
		if string.find(msg,"({release list})") then
			msg = string.gsub(msg,"{release list}",Pre(Wizard.Show.RelList(temp)));
		end
		if string.find(msg,"({release details})") then
			msg = string.gsub(msg,"{release details}",Pre(Wizard.Show.RelDetails(temp)));
		end		
		if string.find(msg,"({delete release list})") then
			msg = string.gsub(msg,"{delete release list}",Pre(Wizard.Show.DelRelList(temp)));
		end
		if string.find(msg,"({edit release list})") then
			msg = string.gsub(msg,"{edit release list}",Pre(Wizard.Show.EditRelList(temp)));
		end
		if string.find(msg,"({move release list})") then
			msg = string.gsub(msg,"{move release list}",Pre(Wizard.Show.MoveRelList(temp)));
		end
		if string.find(msg,"({edit release details})") then
			msg = string.gsub(msg,"{edit release details}",Pre(Wizard.Show.EditRelDetails(temp)));
		end	
		if string.find(msg,"({link release details})") then
			msg = string.gsub(msg,"{link release details}",Pre(Wizard.Show.LinkRelDetails(temp)));
		end	
		if string.find(msg,"({show latest releases})") then
			msg = string.gsub(msg,"{show latest releases}",Pre(Wizard.Show.LatestRel(temp)));
		end
   		return msg;
	end,

	["AddCat"] = {
		["Start"] = function(user,data,temp)
			local step = temp.step;
			local msg = "";
			if data == -1 then
				PmToUser(user,Wizard.Tags(Wizard.AddCat[step](),temp));
				if step < 6 then temp.step = step + 1; end
				return 1;
			end			
   			if step == 1 then
   	       		msg = Wizard.Tags(Wizard.AddCat[1](),temp);
   			elseif step == 2 then
                temp.cat.name = data;
				msg = Wizard.AddCat[2]();
			elseif step == 3 then
	    		temp.cat.desc = data;
				msg = Wizard.AddCat[3]();
			elseif step == 4 then
				if tonumber(data) then
					if tonumber(string.format("%.0f",data)) >= 0 and tonumber(string.format("%.0f",data)) <= 99 then
						if tonumber(string.format("%.0f",data)) == 0 then data = -1; end
						temp.cat.exp = data;
      					msg = Wizard.Tags(Wizard.AddCat[4](),temp);
					else
            			msg = Wizard.AddCat[3]();
            			step = step - 1;
					end
				else
           			msg = Wizard.AddCat[4]();
        			return 1;
				end
			elseif (step == 5 or step == 6) and string.lower(data) == "1" then
                LibTask.NewCat(user,temp);
				msg = Wizard.AddCat[5]();
                Wizard.InitTemp(user,"Clear");
			elseif step == -99 then
				msg = Wizard.AddCat[5]();
                Wizard.InitTemp(user,"Clear");
			else
    			msg = Wizard.Tags(Wizard.AddCat[4](),temp);
			end
			
			if step < 6 then temp.step = step + 1; end
			PmToUser(user,msg);
		end,
		[1] = function()
			local s = "\n"..separate
		    .."\n{category list}"..separate.."\n"
			.."\tВведите название новой категории.\n"..separate
			return s;
		end,
		[2] = function()
			local s = "\n"..separate.."\n"
			.."\tВведите описание категории.\n"..separate
			return s;
		end,
		[3] = function()
			local s = "\n"..separate.."\n"
			.."\tВведите число из диапазона от 1 до 99, чтобы задать время хранения файлов (в сутках).\n"
			.."\tДля того чтобы отключить очистку категории, введите: 0\n"..separate
			return s;
		end,
		[4] = function()
			local s = "\n"..separate.."\n"
			.."{verify category}\n"..separate.."\n"
			.."\tДля продолжения введите: 1\n"..separate
			return s;
		end,
		[5] = function()
			local s = "Категория добавлена."
			return s;
		end,
	},
	
	["DelCat"] = {
		["Start"] = function(user,data,temp)
            local step = temp.step; 
			local msg = "";
			if data == -1 then
				ToUser(user,Wizard.Tags(Wizard.DelCat[step](),temp));
				if step < 5 then temp.step = step + 1; end
				return 1;
			end			
			if step == 1 then
                msg = Wizard.Tags(Wizard.DelCat[1](),temp);
			elseif step == 2 then
				if tonumber(data) and tonumber(data) > 0 and tonumber(data) <= tonumber(SizeDB()) then
     				data = string.format("%.0f",data)
                    temp.cat.var = data;
                    msg = Wizard.Tags(Wizard.DelCat[2](),temp);
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
                    step = step - 1;
				end								
			elseif step == 3 and string.lower(data) == "1" then
                LibTask.DelCat(user,temp);
				msg = Wizard.DelCat[3]();
                Wizard.InitTemp(user,"Clear");
			elseif step == -99 then
				msg = Wizard.DelCat[3]();
                Wizard.InitTemp(user,"Clear");
			else
    			msg = Wizard.Tags(Wizard.DelCat[2](),temp);
			end
			if step < 4 then temp.step = step + 1; end
			PmToUser(user,msg);
		end,
		[1] = function()
			local s = "\n"..separate
   			.."\n{category list}"..separate.."\n"
			.."\tВведите номер категории, которую хотите удалить.\n"..separate
			return s;
		end,
		[2] = function()
			local s = "\n"..separate
			.."\n{category details}\n"..separate.."\n"
			.."\tДля удаления категории, введите: 1\n"..separate
			return s;
		end,
		[3] = function()
			local s = "Категория удалена."
			return s;
		end,
	},
	
	["AddRel"] = {
		["Start"] = function(user,data,temp)
			if SizeDB() == 0 then
				PmToUser(user,Wizard.CatError());
				Wizard.InitTemp(user,"Clear");
				return 1;
			end
			local step = temp.step;
			local msg = "";			
			if data == -1 then
				PmToUser(user,Wizard.Tags(Wizard.AddRel[step](),temp));
				if step < 6 then temp.step = step + 1; end
				return 1;
			end			
			if step == 1 then
				msg = Wizard.Tags(Wizard.AddRel[1](),temp);
			elseif step == 2 then
				if tonumber(data) and tonumber(data) > 0 and tonumber(data) <= tonumber(SizeDB()) then
     				data = string.format("%.0f",data);
                    temp.rel.cat = data;
                    msg = Wizard.AddRel[2]();
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
                    step = 1;
				end
			elseif step == 3 then
				if data:match"(magnet:%S+)" then
					PmToUser(user,"Магнет ссылки запрещены в названии.")
					step = 2;
				else
					data = data:gsub("\r\n", " \ ");
					temp.rel.name = data;
					msg = Wizard.AddRel[3]();
				end
			elseif step == 4 then
			    data = data:gsub("\r\n", " \ ");
				if data:match"(magnet:%S+)" then
					for Magnet in data:gmatch"(magnet:%S+)" do
						local dupe = LibTask.RelDupeCheck(Magnet:match"urn:tree:tiger:(%w+)&xl=");
						if dupe then
							PmToUser(user,"Найден дубликат Magnet ссылки: "..Magnet.."\r\n\t\tРелиз №: "..dupe.cat.."."..dupe.rel.."\r\n\t\tДанная Magnet ссылка не будет добавлена.");
						else
							temp.rel.tth = temp.rel.tth..Magnet:match"urn:tree:tiger:(%w+)&xl="..", ";
							local size = Magnet:match"&xl=(%d+)&dn=";
							if size == nil then
								temp.rel.lenght = temp.rel.lenght;
							else
								temp.rel.lenght = temp.rel.lenght+size;
							end
							temp.rel.mlink = temp.rel.mlink..Magnet.." / ";
						end
					end
					if not temp.rel.mlink:match"(magnet:%S+)" then
						PmToUser(user,"Нет ни одной принятой ссылки, повторите ввод.");
						step = 3;
					else
						temp.rel.tth = temp.rel.tth:slice( 0, -3);
						temp.rel.mlink = temp.rel.mlink:slice( 0, -4);
						msg = Wizard.AddRel[4]();
					end
				else
					PmToUser(user,"Вы должны ввести Магнет ссылку, это необходимо.");
					step = 3;
				end
			elseif step == 5 then
			    if string.lower(data) == "0" then
		            temp.rel.desc = "0";
				else
					data = data:gsub("\r\n", "\r\n\t");
			    	temp.rel.desc = data;
				end             
				msg = Wizard.Tags(Wizard.AddRel[5](),temp);
				LibTask.AddRel(user,temp);
                Wizard.InitTemp(user,"Clear");
			end
			if step < 5 then temp.step = step + 1; end
			PmToUser(user,msg);					
		end,
		[1] = function()
   			local s = "\n"..separate
			.."\n\tВ релизы не разрешается добавление материалов уже имевшихся в локальной сети."
			.."\n\tЕсли Вы нашли в сети, что-то интересное и хотите привлечь к этому внимание других,"
			.."\n\tто ссылку и описание можно дать в общий чат хаба. В категорию музыка, не добавляются"
			.."\n\tотдельные треки в mp3. В категорию фильмы не добавляются трейлеры и не разрешается"
			.."\n\tдобавлять видео качества хуже, чем DVDrip. Ссылки на видео более низкого качества"
			.."\n\tможно давать в общий чат хаба.\n"..separate
			.."\n{category list}"..separate.."\n"
			.."\t\tВведите номер категории релиза.\n"..separate
			return s;
		end,
		[2] = function()
   			local s = "\n"..separate.."\n"
			.."\tВведите название релиза.\n"..separate
			return s;
		end,
		[3] = function()
   			local s = "\n"..separate.."\n"
			.."\tВведите Магнет ссылку на файл. Если Вы хотите добавить еще ссылки, воспользуйтесь специальным меню после добавления релиза.\n"..separate
			return s;
		end,
		[4] = function()
   			local s = "\n"..separate.."\n"
			.."\tПри желании, вы можете добавить описание релиза. Вы можете пропустить этот шаг, введите: 0\n"..separate
			return s;
		end,
		[5] = function()
			local s = "\n"..separate.."\n"
			.."\tСпасибо за уделенное время, ваш релиз будет оценен. С уважением, Администрация.\n"..separate
			return s;
		end,
	},
	
	["CatError"] = function()
    	local s = "\n"..separate.."\n"
		.."\tОшибка: Категорий нет.\n"..separate
		return s;
	end,
	
	["ShowRel"] = {
		["Start"] = function(user,data,temp)
            --local _,_,cat = string.find(data,"%b<>%s+%S+%s+(%d+)");
			local step = temp.step; 
			local msg = "";
			if data == -1 then
				PmToUser(user,Wizard.Tags(Wizard.ShowRel[step](),temp));
				if step < 4 then temp.step = step + 1; end
				return 1;
			end						
			if step == 1 then
			    msg = Wizard.Tags(Wizard.ShowRel[1](),temp);
			elseif step == 2 then
				if tonumber(data) and (tonumber(data) > 0) and (tonumber(data) <= tonumber(SizeDB())) then
     				data = string.format("%.0f",data)
                    temp.rel.cat = data;
					msg = Wizard.Tags(Wizard.ShowRel[2](),temp);
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
                    step = 1;
				end
			elseif step == 3 then
				if string.find(data,"(%d+)%.(%d+)") then
                	_,_,cat,rel = string.find(data,"(%d+)%.(%d+)");
					if tonumber(cat) and tonumber(rel) and tonumber(cat) > 0 and tonumber(cat) <= tonumber(SizeDB()) and tonumber(rel) > 0 and tonumber(rel) <= tonumber(SizeDB(cat)) then
						temp.rel.var = rel;
						msg = Wizard.Tags(Wizard.ShowRel[3](),temp);
					else
					   	PmToUser(user,"Неверная команда, повторите ввод.");
                		step = 2;
					end
				else
                    PmToUser(user,"Неверная команда, повторите ввод.");
                	step = 2;
				end
				if string.lower(data) == "категории" then
					msg = Wizard.Tags(Wizard.ShowRel[1](),temp);
					step = 1;
				elseif string.lower(data) == "релизы" then
					msg = Wizard.Tags(Wizard.ShowRel[2](),temp);
					step = 2;
				end
			elseif step == -99 then
				msg = Wizard.ShowRel[3]();
                Wizard.InitTemp(user,"Clear");
			else
    			msg = Wizard.ShowRel[2]();
			end
			if step < 3 then temp.step = step + 1; end
			Core.SendPmToUser(user,tVar.sBot,msg);

		end,
		[1] = function()
			local s = "\n"..separate
			.."\n{category list}"..separate.."\n"
			.."\tВведите номер категории для просмотра.\n"..separate
			return s;
		end,
		[2] = function()
			local s = "\n"..separate
			.."{release list}"..separate.."\n"
			.."\tВведите номер релиза, который хотите просмотреть.\n"
			.."\tДля возврата к выбору категории, введите: категории.\n"..separate
			return s;
		end,
		[3] = function()
			local s = "\n"..separate.."\n"
			.."{release details}"..separate.."\n"
			.."\tДля возврата к выбору категории, введите: категории.\n"
			.."\tДля возврата к списку релизов, введите: релизы.\n"
			.."\tДля перехода к определенному релизу, введите его ID, например: 1.1\n"..separate
			return s;
		end,
	},

	["ShowRelFromCat"] = {
		["Start"] = function(user,data,temp)
            local step = temp.step; 
			local msg = "";
			if data == -1 then
				PmToUser(user,Wizard.Tags(Wizard.ShowRelFromCat[step](),temp));
				if step < 4 then temp.step = step + 1; end
				return 1;
			end						
			if step == 1 then
			    _,_,cat = string.find(data,"%b<>%s+%S+%s+(%d+)");
				temp.rel.cat = cat;
				msg = Wizard.Tags(Wizard.ShowRelFromCat[1](),temp);
			elseif step == 2 then
				if string.find(data,"(%d+)%.(%d+)") then
                	local _,_,cat,rel = string.find(data,"(%d+)%.(%d+)");
					if tonumber(cat) and tonumber(rel) and tonumber(cat) > 0 and tonumber(cat) <= tonumber(SizeDB()) and tonumber(rel) > 0 and tonumber(rel) <= tonumber(SizeDB(cat)) then
						temp.rel.var = rel;
						msg = Wizard.Tags(Wizard.ShowRelFromCat[2](),temp);
					else
						PmToUser(user,"Неверная команда, повторите ввод.");
                		step = 1;
					end
				elseif string.find(data,"(%d+)") then
					local _,_,rel = string.find(data,"(%d+)");
					if tonumber(rel) and tonumber(rel) > 0 and tonumber(rel) <= tonumber(SizeDB(cat)) then
					   	temp.rel.var = rel;
						msg = Wizard.Tags(Wizard.ShowRelFromCat[2](),temp);
					else
						PmToUser(user,"Неверная команда, повторите ввод.");
						step = 1;
					end
				end
				if string.lower(data) == "релизы" then
					msg = Wizard.Tags(Wizard.ShowRelFromCat[1](),temp);
					step = 1;
				end
			elseif step == -99 then
				msg = Wizard.ShowRelFromCat[2]();
                Wizard.InitTemp(user,"Clear");
			else
    			msg = Wizard.ShowRelFromCat[2]();
			end
			if step < 2 then temp.step = step + 1; end
			Core.SendPmToUser(user,tVar.sBot,msg);

		end,
		[1] = function()
			local s = "\n"..separate
			.."{release list}"..separate.."\n"
			.."\tВведите номер релиза, который хотите просмотреть.\n"..separate
			return s;
		end,
		[2] = function()
			local s = "\n"..separate.."\n"
			.."{release details}"..separate.."\n"
			.."\tДля возврата к списку релизов, введите: релизы.\n"..separate
			return s;
		end,
	},
	
	["ShowAll"] = function()
		local s = "\n"..separate
		.."{show all releases}\n"
		.."\tДля просмотра релиза, введите его номер.\n"..separate
		return s;
	end,
	
	["ShowLatest"] = function()
		local s = "\n"..separate
		.."{show latest releases}\n"
		.."\tДля просмотра релиза, введите его номер.\n"..separate
		return s;
	end,

	["DelRel"] = {
		["Start"] = function(user,data,temp)
            local step = temp.step; 
			local msg = "";
			if data == -1 then
				PmToUser(user,Wizard.Tags(Wizard.DelRel[step](),temp));
				if step < 4 then temp.step = step + 1; end
				return 1;
			end
			if step == 1 then
		      	msg = Wizard.Tags(Wizard.DelRel[1](),temp);
			elseif step == 2 then
				if tonumber(data) and tonumber(data) > 0 and tonumber(data) <= tonumber(SizeDB()) then
                    temp.rel.cat = string.format("%.0f",data);
                    temp.rel.name = user;
					msg = Wizard.Tags(Wizard.DelRel[2](),temp);
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
                    step = 1;
				end
			elseif step == 3 then
				if string.find(data,"(%d+)%.(%d+)") then
					_,_,cat,rel = string.find(data,"(%d+)%.(%d+)");
					local relinfo = RelInfo(cat,rel);
					local catinfo = CatInfo(cat);
					if tonumber(cat) and tonumber(rel) and tonumber(cat) > 0 and tonumber(cat) <= tonumber(SizeDB()) and tonumber(rel) > 0 and tonumber(rel) <= tonumber(SizeDB(cat)) and (pAdmin[user.iProfile] == 1 or user.sNick == relinfo.author or user.sNick == catinfo.moder) then
						temp.rel.var = rel;                    
						msg = Wizard.Tags(Wizard.DelRel[3](),temp);
					else
						PmToUser(user,"Неверная команда, повторите ввод.");
						step = 2;
					end
				elseif string.lower(data) == "категории" then
					msg = Wizard.Tags(Wizard.DelRel[1](),temp);
					step = 1;
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
					step = 2;
				end
			elseif step == 4 then
				if string.lower(data) == "1" then
					LibTask.DelRel(user,temp);
					msg = Wizard.DelRel[4]();
					Wizard.InitTemp(user,"Clear");
					step = 4;
				elseif 	string.lower(data) == "релизы" then
					msg = Wizard.Tags(Wizard.DelRel[2](),temp);
					step = 2;
				end
			elseif step == -99 then
				msg = Wizard.DelRel[4]();
                Wizard.InitTemp(user,"Clear");
			else
    			msg = Wizard.Tags(Wizard.DelRel[4](),temp);
			end
			if step < 5 then temp.step = step + 1; end
			PmToUser(user,msg);			
		end,
		[1] = function()
			local s = "\n"..separate
			.."\n{category list}"..separate.."\n"
			.."\tВыберите категорию релиза для удаления, введите ее номер.\n"..separate
			return s;
		end,
		[2] = function()
	      	local s = "\n"..separate
			.."\n{delete release list}"..separate.."\n"
			.."\tДля удаления релиза, введите его ID номер.\n"
			.."\tДля возврата к списку категорий введите: категории\n"..separate
			return s;
		end,
		[3] = function()
	   	   	local s = "\n"..separate
			.."\n{release details}"..separate.."\n"
			.."\tДля удаления релиза введите: 1\n"
			.."\tДля возврата к списку релизов, введите: релизы\n"..separate
			return s;
		end,
		[4] = function()
			local s = "Релиз был удален."
			return s;
		end,
	},
	
	["EditRel"] = {
		["Start"] = function(user,data,temp)
            local step = temp.step; 
			local msg = "";
			if data == -1 then
				PmToUser(user,Wizard.Tags(Wizard.EditRel[step](),temp));
				if step < 4 then temp.step = step + 1; end
				return 1;
			end
			if step == 1 then
		      	msg = Wizard.Tags(Wizard.EditRel[1](),temp);
			elseif step == 2 then
				if tonumber(data) and tonumber(data) > 0 and tonumber(data) <= tonumber(SizeDB()) then
                    temp.rel.cat = string.format("%.0f",data);
                    temp.rel.name = user;
					msg = Wizard.Tags(Wizard.EditRel[2](),temp);
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
                    step = 1;
				end
			elseif step == 3 then
				if string.find(data,"^(%d+)%.(%d+)") then
					_,_,cat,rel = string.find(data,"^(%d+)%.(%d+)");
					local relinfo = RelInfo(cat,rel);
					local catinfo = CatInfo(temp.rel.cat);
					if tonumber(cat) and tonumber(rel) and tonumber(cat) > 0 and tonumber(cat) <= tonumber(SizeDB()) and tonumber(rel) > 0 and tonumber(rel) <= tonumber(SizeDB(cat)) and (pAdmin[user.iProfile] == 1 or user.sNick == relinfo.author or user.sNick == catinfo.moder) then
						temp.rel.var = rel;                    
						msg = Wizard.Tags(Wizard.EditRel[3](),temp);
					else
						PmToUser(user,"Нет доступа для редактирования релизов данной категории.");
						step = 2;
					end
				elseif string.lower(data) == "категории" then
					msg = Wizard.Tags(Wizard.EditRel[1](),temp);
					step = 1;
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
					step = 2;
				end
			elseif step == 4 then
				_,_,num,new = data:find("^(%d+)%s-(.*)");
				if num == "0" then
					LibTask.EditRel(user,temp);
					Wizard.InitTemp(user,"Clear");
					msg = Wizard.EditRel[4]();
					step = 4;
				elseif num == "1" and new then
						temp.new.name = new;
						msg = Wizard.Tags(Wizard.EditRel[3](),temp);
						step = 3;
				elseif num == "2" and new then
						temp.new.magnet = new;
						msg = Wizard.Tags(Wizard.EditRel[3](),temp);
						step = 3;
				elseif num == "3" and new then
						temp.new.desc = new;
						msg = Wizard.Tags(Wizard.EditRel[3](),temp);
						step = 3;
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
					step = 3;
				end
			elseif step == -99 then
				msg = Wizard.EditRel[4]();
                Wizard.InitTemp(user,"Clear");
			else
    			msg = Wizard.Tags(Wizard.EditRel[4](),temp);
			end
			if step < 5 then temp.step = step + 1; end
			PmToUser(user,msg);
		end,
		[1] = function()
			local s = "\n"..separate
			.."\n{category list}"..separate.."\n"
			.."\tВыберите категорию релиза, введите ее номер.\n"..separate
			return s;
		end,
		[2] = function()
	      	local s = "\n"..separate
			.."\n{edit release list}"..separate.."\n"
			.."\tДля редактирования релиза, введите его ID номер.\n"
			.."\tДля возврата к списку категорий введите: категории\n"..separate
			return s;
		end,
		[3] = function()
	   	   	local s = "\n"..separate
			.."\n{edit release details}"..separate.."\n"
			.."\tДля редактирования нужного поля релиза введите:\n"
			.."\t\t\"1 Новое название\"\t- изменить название\n"
			.."\t\t\"2 Магнет-ссылка\"\t- изменить Магнет-ссылку\n"
			.."\t\t\"3 описание\"\t- изменить описание\n"..separate.."\n"
			.."\tДля завершения редактирования, введите: 0\n"..separate
			return s;
		end,
		[4] = function()
			local s = "Релиз отредактирован."
			return s;
		end,
	},

	["MoveRel"] = {
		["Start"] = function(user,data,temp)
            local step = temp.step; 
			local msg = "";
			if data == -1 then
				PmToUser(user,Wizard.Tags(Wizard.MoveRel[step](),temp));
				if step < 4 then temp.step = step + 1; end
				return 1;
			end
			if step == 1 then
		      	msg = Wizard.Tags(Wizard.MoveRel[1](),temp);
			elseif step == 2 then
				if tonumber(data) and tonumber(data) > 0 and tonumber(data) <= tonumber(SizeDB()) then
                    temp.rel.cat = string.format("%.0f",data);
                    temp.rel.name = user;
					msg = Wizard.Tags(Wizard.MoveRel[2](),temp);
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
                    step = 1;
				end
			elseif step == 3 then
				if string.find(data,"^(%d+)%.(%d+)") then
					_,_,cat,rel = string.find(data,"^(%d+)%.(%d+)");
					local relinfo = RelInfo(cat,rel);
					local catinfo = CatInfo(temp.rel.cat);
					if tonumber(cat) and tonumber(rel) and tonumber(cat) > 0 and tonumber(cat) <= tonumber(SizeDB()) and tonumber(rel) > 0 and tonumber(rel) <= tonumber(SizeDB(cat)) and (pAdmin[user.iProfile] == 1 or user.sNick == relinfo.author or user.sNick == catinfo.moder) then
						temp.rel.var = rel;                    
						msg = Wizard.Tags(Wizard.MoveRel[3](),temp);
					else
						PmToUser(user,"Нет доступа для редактирования релизов данной категории.");
						step = 2;
					end
				elseif string.lower(data) == "категории" then
					msg = Wizard.Tags(Wizard.MoveRel[1](),temp);
					step = 1;
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
					step = 2;
				end
			elseif step == 4 then
				_,_,num = data:find("^(%d+)%s-");
				if tonumber(num) and tonumber(num) > 0 and tonumber(num) <= tonumber(SizeDB()) then
					temp.new.cat = num;
					LibTask.MoveRel(user,temp);
					Wizard.InitTemp(user,"Clear");
					msg = Wizard.MoveRel[4]();
					step = 4;
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
					step = 3;
				end
			elseif step == -99 then
				msg = Wizard.MoveRel[4]();
                Wizard.InitTemp(user,"Clear");
			else
    			msg = Wizard.Tags(Wizard.MoveRel[4](),temp);
			end
			if step < 5 then temp.step = step + 1; end
			PmToUser(user,msg);
		end,
		[1] = function()
			local s = "\n"..separate
			.."\n{category list}"..separate.."\n"
			.."\tВыберите категорию релиза, введите ее номер.\n"..separate
			return s;
		end,
		[2] = function()
	      	local s = "\n"..separate
			.."\n{move release list}"..separate.."\n"
			.."\tДля перемещения релиза, введите его ID номер.\n"
			.."\tДля возврата к списку категорий введите: категории\n"..separate
			return s;
		end,
		[3] = function()
	   	   	local s = "\n"..separate
			.."\n\tИнформация о релизе:\n"..separate.."\n"
			.."\n{release details}"..separate.."\n"
			.."\n\tСписок категорий:\n"..separate.."\n"
			.."\n{category list}"..separate.."\n"
			.."\tДля перемещения релиза в нужную категорию введите ее номер.\n"..separate
			return s;
		end,
		[4] = function()
			local s = "Релиз перемещен."
			return s;
		end,
	},
	
	["EditLink"] = {
		["Start"] = function(user,data,temp)
            local step = temp.step; 
			local msg = "";
			if data == -1 then
				PmToUser(user,Wizard.Tags(Wizard.EditLink[step](),temp));
				if step < 4 then temp.step = step + 1; end
				return 1;
			end
			if step == 1 then
		      	msg = Wizard.Tags(Wizard.EditLink[1](),temp);
			elseif step == 2 then
				if tonumber(data) and tonumber(data) > 0 and tonumber(data) <= tonumber(SizeDB()) then
                    temp.rel.cat = string.format("%.0f",data);
                    temp.rel.name = user;
					msg = Wizard.Tags(Wizard.EditLink[2](),temp);
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
                    step = 1;
				end
			elseif step == 3 then
				if string.find(data,"^(%d+)%.(%d+)") then
					_,_,cat,rel = string.find(data,"^(%d+)%.(%d+)");
					local relinfo = RelInfo(cat,rel);
					local catinfo = CatInfo(temp.rel.cat);
					if tonumber(cat) and tonumber(rel) and tonumber(cat) > 0 and tonumber(cat) <= tonumber(SizeDB()) and tonumber(rel) > 0 and tonumber(rel) <= tonumber(SizeDB(cat)) and (pAdmin[user.iProfile] == 1 or user.sNick == relinfo.author or user.sNick == catinfo.moder) then
						temp.rel.var = rel;                    
						msg = Wizard.Tags(Wizard.EditLink[3](),temp);
					else
						PmToUser(user,"Нет доступа для добавления ссылок в релизы данной категории.");
						step = 2;
					end
				elseif string.lower(data) == "категории" then
					msg = Wizard.Tags(Wizard.EditLink[1](),temp);
					step = 1;
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
					step = 2;
				end
			elseif step == 4 then
				--_,_,num,new = data:find("^(%d+)%s-(.*)");
				if string.lower(data) == "0" then
					Wizard.InitTemp(user,"Clear");
					msg = Wizard.EditLink[4]();
					step = 4;
				elseif data:find("^(%d+)") then
					local id_link = data:match("^(%d*)");
					temp.link.id = tonumber(id_link);
					LibTask.EditLink(user,temp);
					temp.link.id = ""
					msg = Wizard.Tags(Wizard.EditLink[3](),temp);
					step = 3;
				elseif data:find("http://%S+") then
						temp.link.new = data;
						LibTask.EditLink(user,temp);
						msg = Wizard.Tags(Wizard.EditLink[3](),temp);
						step = 3;
				elseif data:find("magnet:%S+") then
						temp.link.new = data;
						LibTask.EditLink(user,temp);
						msg = Wizard.Tags(Wizard.EditLink[3](),temp);
						step = 3;
				elseif data:find("ftp://%S+") then
						temp.link.new = data;
						LibTask.EditLink(user,temp);
						msg = Wizard.Tags(Wizard.EditLink[3](),temp);
						step = 3;
				else
					PmToUser(user,"Неверная команда, повторите ввод.");
					step = 3;
				end
			elseif step == -99 then
				msg = Wizard.EditLink[4]();
                Wizard.InitTemp(user,"Clear");
			else
    			msg = Wizard.Tags(Wizard.EditLink[4](),temp);
			end
			if step < 5 then temp.step = step + 1; end
			PmToUser(user,msg);
		end,
		[1] = function()
			local s = "\n"..separate
			.."\n{category list}"..separate.."\n"
			.."\tВыберите категорию релиза, введите ее номер.\n"..separate
			return s;
		end,
		[2] = function()
	      	local s = "\n"..separate
			.."\n{edit release list}"..separate.."\n"
			.."\tВыберите релиз, в который хотите добавить ссылку, введите его ID номер.\n"
			.."\tДля возврата к списку категорий введите: категории\n"..separate
			return s;
		end,
		[3] = function()
	   	   	local s = "\n"..separate
			.."\n{link release details}"..separate.."\n"
			.."\tДля добавления ссылки в релиз, есть несколько вариантов:\n"
			.."\t\t1. Раздача на рутрекере http://rutracker.org/forum/viewtopic.php?t=3543712\n"
			.."\t\t2. Субтитры magnet:?xt=urn:tree:tiger:BE6ULQ3JHMG2JZUJHLXEKW3ODPHK2WZ4E6NQJQA&xl=82945&dn=Castle.2009.S03E22.720p.HDTV.X264.RUS.srt\n"
			.."\t\t3. Взято с ftp://www.dtkms.ru\n"
			.."\tТакже можно и без каких-либо слов, фраз\n"
			.."\tДля удаления ссылки, введите ее номер\n"..separate.."\n"
			.."\tДля завершения добавления ссылок, введите: 0\n"..separate
			return s;
		end,
		[4] = function()
			local s = "Ссылки добавлены."
			return s;
		end,
	},
	
};
