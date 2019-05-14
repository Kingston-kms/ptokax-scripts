--[[

	Название скрипта: Регистрации с базой в MySQL
	Версия скрипта: 2.0
	Версия API: 2
	Автор: Kingston
	Дата: март 2013
	
	Функционал:
	При регистрации на хабе, данные пользователя заносятся в таблицу в базе MySql, если пользователь уже зарегистрирован,
	но его нет в базе, он добавляется автоматически. Если юзер меняет пароль, он меняется в базе, если пользователь удаляет учетку, из базы MySql учетка также удаляется.
	Ведется подсчет записей в базе. Ведется логирование ошибок скрипта с занесением в базу. При запуске скрипта создаются таблицы если их нет. Просмотр данных об учетных записях
          по различным параметрам: ник, IP адрес, ID номер строки в базе, если несколько записей, выводит все.
	
	Пользовательские команды:
	!regme <pass> - зарегистрироваться
	!passwd <new_pass> - изменить пароль (встроенная команда)
	!unreg - удалить регистрацию
	!mypass - просмотр своего пароля (STRELOK)
	!email - добавить/изменить свой E-mail
	
	Протестировано на PtokaX 0.4.1.1,0.4.1.2,0.5.0.0
	
	За основу взят скрипт RegBot.by.NRJv.1.2_api2.lua

]]--
--
----------------------------------------------------- Конфигурация -----------------------------------------------------
local ShowInfo = 1	-- Дополнительная информация о том, как можно избежать повторных вводов пароля при входе на хаб (0 - не показывать/ 1 - показывать)
local ShowToAll = 0	-- Сообщегние всем пользователям, что на хабе новый зарегистрированный участник (0 - не показывать/ 1 - показывать)
------------------------------------------------------------------------------------------------------------------------
local ShowDebug = 1 -- Cлужебные сообщения об автомаческих действиях с базой (0 - не показывать/ 1 - показывать)
local LogLevel = 3 -- Уровень уведомлений: 0 - ответы на запросы команд, 1 - сообщения таймеров, 2 - автоматические уведомления, 3 - все уведомления и ошибки. Работает при ShowDebug = 1
local TimeUpd = 5 	-- Время для автоматического обновления количества зарегистрированных (в минутах)
local TimeCon = 1 -- Время подключения к базе если произошел дисконнект по таймауту (в минутах)
--------------------------------------------------------------------------------------------
-- Параметры чистки регистраций
local CleanRegBase = true -- Производить очистку или нет, false - нет, true - да
local ProfToDel = { -- Время не посещения хаба, после которого удаляются учетки по профилям, дни / 0 - не удалять
    [0] = 0,	-- Админ
    [1] = 0,	-- ОП
    [2] = 60,	-- VIP
    [3] = 30,	-- Рег
}
local IntToDel = { -- Интервал проверки учеток для очистки, часы:минуты
	["04:00"] = 1,
}
-------------------------------------------------------------------------------------------------------------------------
-- MySQL
local sNameDB = "ptokax"			-- Имя базы данных
local sUserDB = "ptokax"					-- Имя пользователя БД
local sPasswordDB = "password"		-- Пароль пользователя БД
local sAdressDB = "localhost"			-- Адрес сервера MySQL
local sPortDB = "3306"					-- Порт сервера MySQL (3306 по умолчанию)
local sCharsetDB = "cp1251"
local sPrefixTable = "regs_"			-- Префикс таблиц для этого скрипта
--
luasql = require "luasql.mysql"
--require "luasql.mysql"					-- Подключение драйвера (библиотеки)
local env = luasql.mysql()      		-- Инициализация драйвера (библиотеки)
local con = env:connect(sNameDB, sUserDB, sPasswordDB, sAdressDB, sPortDB) -- Подключение к базе
--
local bot = SetMan.GetString(21)		-- Получение имени бота из настроек хаба
local SendMsg = "Admin"					-- Куда отправлять сообщения операторам: в главном чате - main; в OpChat - opchat; Admin - отправка в ЛС на определенный ник
--
local lHeader = string.rep("=",80) 		-- Верхняя строка сообщения
local lSeparate = string.rep("-",60)	-- Разделитель внутри сообщения
local lFooter = string.rep("=",80)		-- Нижняя строка
local newline = "\n"					-- Перенос строки (Windows - "\r\n"; *nix - "\n")
local tab = "\t"						-- Табуляция
local df = '%d %B %Y в %X';
-- Текстовые сообщения
local newreg = "Приветствуем нового зарегистрировавшегося участника" -- сообщение всем о новом юзере
-- дополнительная информация
local helpreg = tab.."Теперь для входа на хаб под вашим ником необходимо знать пароль."..newline..
				tab.."Вы можете вводить его каждый раз вручную, либо прописать пароль в настройках клиента."..newline..
				tab.."Для этого найдите в списке избранных хабов этот хаб,"..newline..
				tab.."Зайдите в его свойства и пропишите в строках Nick и Password ваши ник и пароль."..newline..
				tab.."Для добавления своего E-mail адреса в базу введите !email <e-mail> где 'e-mail' ваш E-mail адрес."..newline..
                tab.."Команда и E-mail адрес вводятся без кавычек, пробелов и символов $."..newline..
				tab.."E-mail понадобится на случай восстановления забытого пароля."..newline
-- Помощь по регистрации
local reghelp = tab.."Помощь по регистрации"..newline..
				tab..lSeparate..newline..
				tab.."!reghelp"..tab..tab.."-"..tab.."Этот файл помощи"..newline..
				tab.."!regme пароль"..tab.."-"..tab.."Зарегистрироваться (можно не указывать пасс)"..newline..
				tab.."!passwd новый_пароль"..tab.."-"..tab.."Сменить пароль (встроенная команда хаба)"..newline..
				tab.."!mypass"..tab..tab.."-"..tab.."Посмотреть свой пароль"..newline..
				tab.."!unreg"..tab..tab.."-"..tab.."Удалить аккаунт"..newline..
				tab..lSeparate..newline..
				tab.."1. Также все команды доступны в меню хаба."..newline..
				tab.."2. Нажмите правой кнопкой мыши на вкладку хаба"..newline..
				tab.."3. Выберите подменю Пользователи - Регистрация"..newline
-- инфа после регистрации
local inforeg = tab.."Вы зарегистрированы на хабе!"..newline..
				tab.."Ваш ник: %s"..newline..
				tab.."Пароль: %s"..newline..
                tab.."Добавьте хаб в Избранные командой /fav в главный чат."..newline..
				tab.."Сохраните пароль в свойствах хаба в Избранных и не забудьте перезайти на хаб!"..newline
-- приветствие в личку при запросе регистрации
local welreg =	tab.."Добро пожаловать на наш хаб "..SetMan.GetString(0).."."..newline..
				tab.."Вами была запущена система регистрации на хабе."..newline..
				tab.."Вам предстоит придумать пароль, желательно состоящий из латинских букв и цифр."..newline..
				tab.."Для начала регистрации введите команду \"!regme пароль\", где 'пароль' - ваш придуманный пароль."..newline..
                tab.."Команда и пароль вводятся без кавычек, пароль не должен содержать пробелы, знак $."..newline
-- сообщение при входе незареганого юзера
local needreg = tab.."Добро пожаловать на хаб "..SetMan.GetString(0).."."..newline..
                tab.."Вы не зарегистрированный пользователь хаба, имеете следующие ограничения:"..newline..
                tab.." - не участвуете в статистике хаба, "..newline..
                tab.." - нет доступа к системе релизов (новинок сети: фильмы, музыка, игры, программы), "..newline..
                tab.." - нет доступа к истории чата, "..newline..
                tab.." - нет доступа к сервисам хаба: просмотр онлайн температуры, запрос помощи, "..newline..
                tab.." - не можете отправлять Личные сообщения, ограничен поиск файлов и другое.."..newline..
                tab.."Пройти регистрацию можно через меню хаба Пользователю - Регистрация. (пр. кн. мыши по вкладке хаба или по нику)"..newline
         
tProfiles = {	--Кто может использовать админские команды (1 - да / 0 - нет):
		[-1] = 0,	-- Анрег
		[0] = 1,	-- Админ
		[1] = 0,	-- ОП
		[2] = 0,	-- VIP
		[3] = 0,	-- Рег
}
--
--[[*string.dbformat = function(self, ...)
  local t = {...}
  for k, v in ipairs(t) do
    t[k] = tostring(v):gsub("'", "\\'")
  end
  return self:format(unpack(t))
end]]--
_G.string.dbformat = function(self, ...)
  local t = {...}
  for k, v in ipairs(t) do
    t[k] = tostring(v):gsub("(['\\\"])", "\\%1")
  end
  return self:format(unpack(t))
end
--
_G.string.explode = function(self, Sep)
  local ret = {}
  for k in (self..Sep):gmatch(("(.-)%s+"):format(Sep)) do
    _G.table.insert(ret, k)
  end
  return ret
end
--
function string.sqlescape(str)
	return str:gsub("\\","\\\\"):gsub("'","\\'")
end
--
function OnStartup()
    os.setlocale('ru_RU.cp1251', time)
	local con = env:connect(sNameDB, sUserDB, sPasswordDB, sAdressDB, sPortDB) -- Подключение к базе
    CheckCon();
	if con then
        con:execute(("CREATE TABLE IF NOT EXISTS %susers ("..
        "`id` INT NOT NULL AUTO_INCREMENT ,"..
        "`nick` VARCHAR( 64 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,"..
        "`pass` VARCHAR( 64 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,"..
        "`ip` VARCHAR( 15 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,"..
        "`profile` INT( 1 ) NOT NULL ,"..
        "`email` VARCHAR( 32 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL ,"..
        "PRIMARY KEY ( `id` ) "..
        ") ENGINE = MYISAM CHARACTER SET utf8 COLLATE utf8_general_ci"):dbformat(sPrefixTable))
        
        con:execute(("CREATE TABLE IF NOT EXISTS %sconfig ("..
        "`config_name` VARCHAR( 64 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL ,"..
        "`config_value` VARCHAR( 64 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL "..
        ") ENGINE = MYISAM CHARACTER SET utf8 COLLATE utf8_general_ci;"):dbformat(sPrefixTable))
        
        con:execute(("CREATE TABLE IF NOT EXISTS %serrors ("..
        "`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY ,"..
        "`datetime` DATETIME NOT NULL ,"..
        "`error` TEXT CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL "..
        ") ENGINE = MYISAM CHARACTER SET utf8 COLLATE utf8_general_ci;"):dbformat(sPrefixTable))
        
        local cur = con:execute(("SHOW COLUMNS FROM %susers like 'email';"):dbformat(sPrefixTable))
        local row = cur:fetch({}, "a")
        if row == nil then
            con:execute(("ALTER TABLE `%susers` ADD `email` VARCHAR( 32 ) CHARACTER SET utf8 COLLATE utf8_general_ci NULL;"):dbformat(sPrefixTable))
        end
        
        if (GetNeedReg() == nil) then
            con:execute(("INSERT INTO `%sconfig` (`config_name`, `config_value`) VALUES ('needreg', '');"):dbformat(sPrefixTable))
        end
    
        if (GetRegCount() == nil) then
            con:execute(("INSERT INTO `%sconfig` (`config_name`, `config_value`) VALUES "..
            "('count', '0'), "..
            "('date', '"..os.time().."');"):dbformat(sPrefixTable))
        end
	else
		local Msg = "*** Подключение к базе не установлено, проверьте настройки."
        SendDbg(Msg,3)
	end
	TmrMan.AddTimer (TimeUpd*60*1000,'UpdInfo');
	CheckCon = TmrMan.AddTimer (TimeCon*60*1000);
--TmrMan.AddTimer (TimeCon*60*1000,'CheckCon')
    TmrMan.AddTimer (1000)
    --TmrMan.AddTimer (IntToDel*60*1000,'CleanReg')
end
--
function SendDbg(str,ll)
    if (ShowDebug == 1) then
        if ll <= LogLevel then
            if SendMsg == "main" then
                Core.SendToOps("<"..bot.."> "..str)
            elseif SendMsg == "opchat" then
                Core.SendToOpChat(str)
            else
                Core.SendPmToNick(SendMsg, bot, str)
            end
        end
    end
end
--
function CheckCon()
	if not con or not con:execute("USE "..sNameDB) then
		con = assert(env:connect(sNameDB,sUserDB,sPasswordDB,sAdressDB,sPortDB))
		if con then
		local charset,e = con:execute("SET NAMES "..sCharsetDB);
			return true
		end
	else
		return true
	end
end
--

function RegFromSQL()
	--if GetAllRegs() then

        --local Msg = "";
        local upd,e = con:execute(("UPDATE `%sconfig` SET config_value='%s' WHERE `config_name`='count'"):dbformat(sPrefixTable,GetAllRegs()))
        local upd2,e2 = con:execute(("UPDATE `%sconfig` SET config_value='%s' WHERE `config_name`='date'"):dbformat(sPrefixTable,os.time()))
        if upd and upd2 then
            Msg = "*** Параметры конфигурации обновлены."
        else
            Msg = "*** Произошла какая то ошибка"
            if e then OnError(e); end;
            if e2 then OnError(e2); end;
        end
        SendDbg(Msg,1)
		local charset,e = con:execute("SET NAMES "..sCharsetDB);
		local usr,e = con:execute(("SELECT * FROM `%susers`"):dbformat(sPrefixTable))
		local usr1 = usr:fetch({}, "a")
		if usr1 then
				--if (GetNeedReg() ~= '' ) then
				while usr1 do
						local cur,e = con:execute(("SELECT * FROM `%susers` WHERE `id`='%s';"):dbformat(sPrefixTable,usr1.id))			
						local row = cur:fetch({}, "a")
						if row then
							nick = ("%s"):format(row.nick)
							pass = ("%s"):format(row.pass)
							profile = ("%s"):format(row.profile)
							RegMan.AddReg(nick, pass, tonumber(profile))
							local Msg = "*** В базу хаба был занесен новый пользователь: "..nick..""
							SendDbg(Msg,1)
							--local RegUser = Core.GetUser(nick)
							--if RegUser then
							--	Core.SendPmToNick(nick, bot, (newline..tab..lHeader..newline..inforeg..tab..lFooter):format(nick, pass))
							--	if (ShowInfo == 1) then
							--		Core.SendPmToNick(nick, bot, newline..tab..lHeader..newline..helpreg..tab..lFooter)
							--	end
							--end
						end
						cur:close();
					--end
					con:execute(("UPDATE `%sconfig` SET config_value = '' WHERE `config_name` = 'needreg';"):dbformat(sPrefixTable))
				--else
					--local Msg = "*** Пользователей, ожидающих регистрацию на хабе, нет."
					--SendDbg(Msg,1)
					usr1 = usr:fetch(usr1, "a")
				end
		end
		usr:close()
		end

	--end
--end

function UpdInfo()
	if GetAllRegs() then

        local Msg = "";
        local upd,e = con:execute(("UPDATE `%sconfig` SET `config_value`='%s' WHERE `config_name`='count'"):dbformat(sPrefixTable,GetAllRegs()))
        local upd2,e2 = con:execute(("UPDATE `%sconfig` SET `config_value`='%s' WHERE `config_name`='date'"):dbformat(sPrefixTable,os.time()))
        if upd and upd2 then
            Msg = "*** Параметры конфигурации обновлены."
        else
            Msg = "*** Произошла какая то ошибка"
            if e then OnError(e); end;
            if e2 then OnError(e2); end;
        end
        SendDbg(Msg,1)

		if (GetNeedReg() ~= '' ) then
			local NeedRegs = string.explode(GetNeedReg(),', ');
			for _,v in pairs(NeedRegs) do
				local cur,e = con:execute(("SELECT * FROM `%susers` WHERE `id`='%s';"):dbformat(sPrefixTable,v))			
				local row = cur:fetch({}, "a")
				if row then
					nick = ("%s"):format(row.nick)
					pass = ("%s"):format(row.pass)
					RegMan.AddReg(nick, pass, 3)
					local Msg = "*** В базу хаба был занесен новый пользователь: "..nick..""
                    SendDbg(Msg,1)
					local RegUser = Core.GetUser(nick)
					if RegUser then
						Core.SendPmToNick(nick, bot, (newline..tab..lHeader..newline..inforeg..tab..lFooter):format(nick, pass))
						if (ShowInfo == 1) then
							Core.SendPmToNick(nick, bot, newline..tab..lHeader..newline..helpreg..tab..lFooter)
						end
					end
				end
                cur:close();
			end
			con:execute(("UPDATE `%sconfig` SET `config_value` = '' WHERE `config_name` = 'needreg';"):dbformat(sPrefixTable))
		else
			local Msg = "*** Пользователей, ожидающих регистрацию на хабе, нет."
            SendDbg(Msg,1)
		end
	end
end
--
function ClearReg()
    if CleanRegBase then
        --Core.SendToAll('Начинаем очистку.')
        local HubRegs = RegMan.GetRegs()
        local md,mn,pd,pn,a = 0,0,0,0,0;
        for i,v in ipairs(HubRegs) do
local charset,e = con:execute("SET NAMES "..sCharsetDB);
            local sel,e = con:execute(("SELECT * FROM `%susers` WHERE `nick`='%s'" ):dbformat(sPrefixTable,v.sNick));
            if e then OnError(e); end;
            local row = sel:fetch({}, "a")
            if row then
                --Core.SendToAll('Есть запись.')
                while row do
                        if ProfToDel[tonumber(row.profile)] > 0 then
                        --Core.SendToAll('Очищаем профиль')
                            if (os.time() - tonumber(row.logout)) > (ProfToDel[tonumber(row.profile)]*24*60*60) then
                                local del,e = con:execute(("DELETE FROM `%susers` WHERE `nick`='%s'"):dbformat(sPrefixTable,row.nick));
                                --local Msg = ""
                                if del == 1 then
                                    md = md+1;
                                    --Msg = "Пользователь "..row.nick.." удален из базы MySQL."
                                else
                                    mn=mn+1;
                                    --Msg = "Ошибка удаления пользователя "..row.nick.." из базы MySQL."
                                    if e then OnError(e); end;
                                end
                                --SendDbg(Msg)
                                --local msg2 = "";
                                if (RegMan.GetReg(v.sNick) == nil) then
                                    pn=pn+1;
                                    --msg2 = "Пользователь "..v.sNick.." не найден в базе хаба."
                                else
                                    pd=pd+1;
                                    --msg2 = "Пользователь "..v.sNick.." удален из базы хаба."
                                    RegMan.DelReg(v.sNick);
                                    RegMan.Save();
                                end
                                --SendDbg(msg2)
                            end
                        end
                row = sel:fetch(row, "a")
                end
            else
                local ins,e = con:execute(("INSERT INTO `%susers` (nick, ip, profile) VALUES ('%s', '%s', '%s');"):dbformat(sPrefixTable,v.sNick,'0.0.0.0',v.iProfile));
                --local Msg3 = ""
                if ins == 1 then
                    a=a+1;
                    --Msg3 = "Пользователь "..v.sNick.." добавлен в базу MySQL"
                else
                    --Msg3 = "Ошибка добавления пользователя "..v.sNick.." в базу MySQL"
                    if e then OnError(e); end;
                end
                --SendDbg(Msg)
            end
        end
        --OnError("ALL "..a..", MD "..md..", MN "..mn..", PD "..pd..", PN "..pn..".")
        --Core.SendToAll('Завершаем очистку.')
    end
end
--
function OnTimer()
    if IntToDel[os.date("%H:%M")] and tonumber(os.date("%S")) == 0 then
        SendDbg("Время чистить регистрации. Процесс может повесить хаб на несколько секунд.",1)
        ClearReg()
    end
    collectgarbage("collect")
end
--
function OnExit()
	con:close()
	env:close()
end
--
function GetAllDataNick(nick)
	local charset,e = con:execute("SET NAMES "..sCharsetDB);
	local cur,e = con:execute(("SELECT * FROM `%susers` WHERE `nick`='"..nick.."' ;"):dbformat(sPrefixTable))
	if cur:numrows() > 0 then
        local row = cur:fetch({}, "a")
        if row then
            nickdb = ""
            while row do
                nickdb = nickdb..(newline..tab..lHeader..
                        newline..tab.."Данные полученные из базы по нику - "..nick..":"..
                        newline..tab..lSeparate..
                        newline..tab.."ID Номер:"..tab..tab.."%s"..
                        newline..tab.."Ник:"..tab..tab..tab.."%s"..
                        newline..tab.."Пароль:"..tab..tab..tab.."%s"..
                        newline..tab.."IP адрес:"..tab..tab.."%s"..
                        newline..tab.."Номер профиля:"..tab.."%s"..
                        newline..tab.."E-mail адрес:"..tab..tab.."%s"..
                        newline..tab.."Последний вход:"..tab..tab.."%s"..
                        newline..tab.."Последний выход:"..tab.."%s"..
                        newline..tab..lFooter):format(row.id, row.nick, row.pass, row.ip, row.profile, row.email, os.date(df,row.login), os.date(df,row.logout))
                row = cur:fetch(row, "a")
            end
            return nickdb
        else
            return ("*** Пользователь с ником - "..nick.." не найден в базе.")	
        end
    end
	cur:close()
end
--
function GetAllDataID(id)
local charset,e = con:execute("SET NAMES "..sCharsetDB);
    local cur,e = con:execute(("SELECT * FROM `%susers` WHERE `id`='%s';"):dbformat(sPrefixTable,id))
	if cur == nil then
        if e then OnError(e); end;
	else
		local row = cur:fetch({}, "a")
		if row then
			nickdb = ""
			while row do
				nickdb = nickdb..(newline..tab..lHeader..
					  newline..tab.."Данные полученные из базы по ID - "..id..":"..
					  newline..tab..lSeparate..
					  newline..tab.."ID номер:"..tab..tab.."%s"..
					  newline..tab.."Ник:"..tab..tab..tab.."%s"..
					  newline..tab.."Пароль:"..tab..tab..tab.."%s"..
					  newline..tab.."IP адрес:"..tab..tab.."%s"..
					  newline..tab.."Номер профиля:"..tab.."%s"..
					  newline..tab.."E-mail адрес:"..tab..tab.."%s"..
					  newline..tab.."Последний вход:"..tab..tab.."%s"..
					  newline..tab.."Последний выход:"..tab.."%s"..
					  newline..tab..lFooter):format(row.id, row.nick, row.pass, row.ip, row.profile, row.email, os.date(df,row.login), os.date(df,row.logout))
				row = cur:fetch(row, "a")
			end
			return nickdb
		else
			return ("*** Пользователь с ID - "..id.." не найден в базе.")	
		end
	end
	cur:close()
end
--
function GetAllDataIp(ip)
local charset,e = con:execute("SET NAMES "..sCharsetDB);
	local cur,e = con:execute(("SELECT * FROM `%susers` WHERE `ip`='%s';"):dbformat(sPrefixTable, ip))
	if cur == nil then
        if e then OnError(e); end;
	else
		local row = cur:fetch({}, "a")
		if row then
			ipdb = ""
			while row do
				ipdb = ipdb..(newline..tab..lHeader..
					newline..tab.."Данные полученные из базы по IP - "..ip..":"..
					newline..tab..lSeparate..
					newline..tab.."ID записи:"..tab..tab.."%s"..
					newline..tab.."Ник:"..tab..tab..tab.."%s"..
					newline..tab.."Пароль:"..tab..tab..tab.."%s"..
					newline..tab.."IP адрес:"..tab..tab.."%s"..
					newline..tab.."Номер профиля:"..tab.."%s"..
					newline..tab.."E-mail адрес:"..tab..tab.."%s"..
					newline..tab.."Последний вход:"..tab..tab.."%s"..
					newline..tab.."Последний выход:"..tab.."%s"..
					newline..tab..lFooter):format(row.id, row.nick, row.pass, row.ip, row.profile, row.email, os.date(df,row.login), os.date(df,row.logout))
				row = cur:fetch(row, "a")
			end
			return ipdb
		else
			return ("*** Пользователь с IP адресом - "..ip.." не найден в базе.")
		end
	end
	cur:close()
end
--
function GetNeedReg()
local charset,e = con:execute("SET NAMES "..sCharsetDB);
	local cur = con:execute(("SELECT config_value FROM `%sconfig` WHERE `config_name` = 'needreg';"):dbformat(sPrefixTable))
	local row = cur:fetch({}, "a")
	if row then
		--needreg = ("%s"):format(row.config_value)
		return row.config_value
	end
	cur:close()
end
--
function GetAllRegs()
local charset,e = con:execute("SET NAMES "..sCharsetDB);
	local cur,e = con:execute(("SELECT * FROM `%susers`"):dbformat(sPrefixTable))
	if cur == nil then
        if e then OnError(e); end;
	else
		local row = cur:fetch({}, "n")
		if row then
			--count = cur:numrows()
			return tonumber(cur:numrows())
		end
	end
	cur:close()
end
--
function GetRegCount()
local charset,e = con:execute("SET NAMES "..sCharsetDB);
	local cur,e = con:execute(("SELECT config_value FROM `%sconfig` WHERE `config_name` = 'count';"):dbformat(sPrefixTable))
	if cur == nil then
        if e then OnError(e); end;
	else
		local row = cur:fetch({}, "a")
		if row then
			--regcount = ("%s"):format(row.config_value)
			return tonumber(row.config_value)
		end
	end
	cur:close()
end
--
function GetRegFromDB(sNick)
	local charset,e = con:execute("SET NAMES "..sCharsetDB);
	local cur = con:execute("SELECT `id` FROM `"..sPrefixTable.."users` WHERE `nick`= '"..sNick:sqlescape().."';")
	if cur:numrows() > 0 then
		local row = cur:fetch({}, "a")
		if row then
			--sNick = ("%s"):format(row.nick)
			return row.id --("%s"):format(sNick)
		else
			return nil
		end
	end
	cur:close()
end
--
function UserConnected(tUser)
    UserMenu(tUser)
    if RegMan.GetReg(tUser.sNick) ~= nil then
		sPass = RegMan.GetReg(tUser.sNick).sPassword;
        UserID = GetRegFromDB(tUser.sNick);
        msg2 = ""
        if UserID == nil then
			local charset,e = con:execute("SET NAMES "..sCharsetDB);
            local ins,e = con:execute(("INSERT INTO `%susers` (nick, ip, profile) VALUES (`%s`, `%s`, `%s`);"):dbformat(sPrefixTable,tUser.sNick,tUser.sIP,tUser.iProfile));
            if ins == 1 then
                msg2 = " внесенеы."
            end
			if ins == nil then	
                msg2 = " не внесены."
                --if e then OnError(e); end;
            end
        else
			local charset,e = con:execute("SET NAMES "..sCharsetDB);
            --local upd,e = con:execute(("UPDATE `%susers` SET `pass`='%s', `ip`='%s', `profile`='%s', `login`='%s' WHERE `id`='%s';"):dbformat(sPrefixTable,sPass,tUser.sIP,tUser.iProfile,os.time(),UserID));
			local upd,e = con:execute(("UPDATE `%susers` SET `login`='%s', `profile`='%s', `ip`='%s' WHERE `id`='%s';"):dbformat(sPrefixTable,os.time(),tUser.iProfile,tUser.sIP,UserID));
            if upd == 1 then
                msg2 = " обновлены."
            else
                msg2 = " не обновлены."
                --if e then OnError(e); end;
            end
        end
 		local Msg = "*** Пришел зарегистрированный пользователь: "..tUser.sNick..". Данные"..msg2;       
        SendDbg(Msg,2)
	end
end
--
function UserDisconnected(tUser)
    if RegMan.GetReg(tUser.sNick) ~= nil then
        if GetRegFromDB(tUser.sNick) ~= "" then
			local charset,e = con:execute("SET NAMES "..sCharsetDB);
            local upd,e = con:execute(("UPDATE `%susers` SET `logout`='%s' WHERE `nick`='%s'"):dbformat(sPrefixTable,os.time(),tUser.sNick))
            local msg2
            if upd == 1 then
                msg2 = " обновлены."
            else
                msg2 = " не обновлены."
                if e then OnError(e); end;
            end
			local Msg = "*** Ушел зарегистрированный пользователь: "..tUser.sNick..". Данные"..msg2;
            SendDbg(Msg,2)
		end
    end
end
--
function ChatArrival(tUser, sData)
    Core.GetUserAllData(tUser)
	local sData = sData:sub(1,-2)
	local _,_,cmd = sData:find("%b<>%s+(%S+)")
	-- Команда получения пароля от STRELOK
	if cmd == "!mypass" then
		if (tUser.iProfile > -1) then
		local sPass = RegMan.GetReg(tUser.sNick).sPassword
			if not (sPass == nil) then Core.SendPmToUser(tUser, bot, "Ваш пароль: "..sPass)
			else Core.SendToUser(tUser, "<"..bot.."> Просмотр пароля невозможен!") end
		else 
			Core.SendToUser(tUser, "<"..bot.."> Команда доступна только для зарегистрированных пользователей!")
		end	
	return true
	end
	-- Конец
	if cmd == "!email" then
		if (tUser.iProfile > -1) then
			local s,e,email = string.find(sData, "%b<>%s+%S+%s+(%S+)")
			if email == nil then
				Core.SendPmToUser(tUser, bot, "Вы забыли ввести E-mail!")
			return true
			end				
			if email:find"^[%w%.%-_]+%@[%w%.%-_]+%.[a-z]+$" then
                --local charset = con:execute("SET NAMES cp1251")
				local upd,e = con:execute(("UPDATE `%susers` SET `email` = '%s' WHERE `nick` ='%s';"):dbformat(sPrefixTable,email,tUser.sNick))
                if upd == 1 then
                    Core.SendPmToUser(tUser, bot, "Вы ввели E-mail "..email.." При восстановлении утерянного пароля Вам нужно будет указывать этот E-mail адрес.")
                else
                    Core.SendPmToUser(tUser, bot, "Неизвестная ошибка, повторите команду.")
                    if e then OnError(e); end;
                end
			else
				Core.SendPmToUser(tUser, bot, "Вы ввели неправильный E-mail.")
			end
		else
			Core.SendPmToUser(tUser, bot, "Команда доступна только для зарегистрированных пользователей!")
		end
	return true	
	end
--
	if cmd == "!regme" then
        if not(tUser.bRegistered) and RegMan.GetReg(tUser.sNick) == nil then
			local s,e,cmd2 = string.find(sData, "%b<>%s+%S+%s+(%S+)")
            local Msg = "";
			if (cmd2 == nil) then
				Core.SendPmToUser(tUser, bot, newline..tab..lHeader..newline..welreg..tab..lFooter)
				return true
			end
            --local charset = con:execute("SET NAMES cp1251")
			local ins,e = con:execute(("INSERT INTO `%susers` (nick, pass, ip, profile, email, login, logout) VALUES ('%s', '%s', '%s', '3', '','%s', '%s');"):dbformat(sPrefixTable,tUser.sNick,cmd2,tUser.sIP,os.time(),os.time()))
			if ins == 1 then
                Msg = "*** В базу был добавлен новый пользователь: "..tUser.sNick..""
            else
                Msg = "Ошибка добавления в базу нового пользователя."
                if e then OnError(e); end;
            end
            SendDbg(Msg,2)
			if RegMan.AddReg(tUser.sNick, cmd2, 3) then
                RegMan.Save();
                Core.SendPmToUser(tUser, bot, (newline..tab..lHeader..newline..inforeg..tab..lFooter):format(tUser.sNick, cmd2))
                if (ShowInfo == 1) then
                    Core.SendPmToUser(tUser, bot, newline..tab..lHeader..newline..helpreg..tab..lFooter)
                end
                if (ShowToAll == 1) then
                    Core.SendToAll("<"..bot.."> "..newreg..": "..tUser.sNick.." !!!")
                end
            end
		else
			Core.SendToUser(tUser, "<"..bot.."> Вы уже зарегистрированы!")
		end
	return true
	end
--
	if cmd == "!unreg" then
		if (tUser.iProfile > -1) then
            --local charset = con:execute("SET NAMES cp1251")
			local del,e = con:execute(("DELETE FROM %susers WHERE nick='%s';"):dbformat(sPrefixTable,tUser.sNick))
            local upd,e = con:execute(("UPDATE %sconfig SET `config_value`='%s' WHERE `config_name`='count'"):dbformat(sPrefixTable,(GetRegCount()-1)))
			local Msg = "*** Пользователь "..tUser.sNick.." удалил свою регистрацию."
            SendDbg(Msg,2)
			if RegMan.DelReg(tUser.sNick) then
                RegMan.Save()
                Core.SendToUser(tUser, "<"..bot.."> Вы удалили свою учетную запись.")
            end
		else
			Core.SendToUser(tUser, "<"..bot.."> Команда доступна только для зарегистрированных пользователей!")
		end
		return true
	end
--
	if cmd == "!deleteuser" then
		if tProfiles[tUser.iProfile] == 1 then
            local s,e,nick = string.find(sData, "%b<>%s+%S+%s+(%S+)")
            if (nick == nil) then
                Core.SendToUser(tUser, "<"..bot.."> Не указали ник!")
            end
            --local charset = con:execute("SET NAMES cp1251")
			local del,e = con:execute(("DELETE FROM %susers WHERE nick='%s';"):dbformat(sPrefixTable,nick))
            local Msg = "";
            if del == 1 then
                local upd = con:execute(("UPDATE %sconfig SET `config_value`='%s' WHERE `config_name`='count'"):dbformat(sPrefixTable,(GetRegCount()-1)))
				Msg = "*** Из базы MySQL был удален пользователь: "..nick.."."
            elseif del == 0 then Msg = "*** Пользователь: "..nick.." в MySQL базе не найден."
            else
                Msg = "*** Ошибка удаления из базы MySQL пользователя: "..nick
                if e then OnError(e); end;
            end
            SendDbg(Msg,0)
            local Msg2 = "";
            if (RegMan.DelReg(nick) == nil) then
                Msg2 = "*** Ошибка удаления из базы хаба пользователя: "..nick..".";
            else 
                Msg2 = "*** Из базы хаба был удален пользователь: "..nick..".";
                RegMan.Save()
            end
            SendDbg(Msg2,0)
        else
            Core.SendToUser(tUser, "<"..bot.."> Команда недоступна для вашего профиля!")
        end
		return true
	end
--
	if cmd == "!reghelp" then
		Core.SendPmToUser(tUser, bot, newline..tab..lHeader..newline..reghelp..tab..lFooter)
		return true
	end
--
	if cmd == "!passwd" then
	if tUser.iProfile ~= -1 then
		local s,e,pass = string.find(sData, "%b<>%s+%S+%s+(%S+)")
		if (pass == nil) then
			Core.SendToUser(tUser, "<"..bot.."> Вы забыли ввести пароль!")
		end
        --local charset = con:execute("SET NAMES cp1251")
		local upd,e = con:execute(("UPDATE `%susers` SET pass='%s' WHERE nick='%s';"):dbformat(sPrefixTable,pass,tUser.sNick))
        local msg2 = "";
        if upd == 1 then
            msg2 = "Вы успешно изменили свой пароль. Не забудьте прописать его в свойствах хаба."
        else
            msg2 = "Произошла ошибка."
            if e then OnError(e); end;
        end
        Core.SendToUser(tUser, "<"..bot.."> "..msg2.."|")
		local Msg = "*** В базе изменена запись о пароле пользователя: "..tUser.sNick.."."
        
        if RegMan.ChangeReg(tUser.sNick, pass, tUser.iProfile) then
            RegMan.Save();
        end
        SendDbg(Msg,2)
	else
		Core.SendToUser(tUser, "<"..bot.."> Команда доступна только для зарегистрированных пользователей!")
	end	
		return true
	end
--
	if cmd == "!addcfg" then -- меню команды отключено, возможно будет выпелено вообще
		if tProfiles[tUser.iProfile] == 1 then
            local Msg = "";
			if GetAllRegs() then
				local ins,e = con:execute("INSERT INTO `"..sPrefixTable.."config` (`config_name`, `config_value`) VALUES ('count', '"..GetAllRegs().."'), ('date', '"..os.time().."')")
                if ins == 1 then
                	Msg = "*** Параметры конфигурации сохранены."
				else
                    Msg = "*** Произошла ошибка."
                    if e then OnError(e); end;
                end
			else
				Msg =  "*** В базе нет записей."
			end
            SendDbg(Msg)
		else
			Core.SendToUser(tUser, "<"..bot.."> Данная команда недоступна для вашего профиля!")
		end
	return true
	end
--
	if cmd == "!cleanregb" then
        SendDbg("Запрошена команда чистки регистраций. Процесс может повесить хаб на несколько секунд.",0)
        ClearReg()
        collectgarbage("collect")
	return true
	end

	if cmd == "!regfromsql" then
        SendDbg("Запрошена команда импорта регистраций. Процесс может повесить хаб на несколько секунд.",0);
        RegFromSQL();
        collectgarbage("collect")
	return true
	end

	if cmd == "!updcfg" then
		if tProfiles[tUser.iProfile] == 1 then
			if (GetAllRegs() > GetRegCount()) then
                local Msg2 = "";
				local upd,e = con:execute(("UPDATE `%sconfig` SET config_value='%s' WHERE config_name='count'"):dbformat(sPrefixTable,GetAllRegs()))
				local upd2,e2 = con:execute(("UPDATE `%sconfig` SET config_value='%s' WHERE config_name='date'"):dbformat(sPrefixTable,os.time()))
                if upd and upd2 then
                    Msg = "*** Параметры конфигурации обновлены."
                else
                    Msg = "*** Произошла какая то ошибка."
                    if e then OnError(e); end;
                    if e2 then OnError(e2); end;
                end
                SendDbg(Msg,0)
			else
				local Msg = "*** База не требует обновления."
                SendDbg(Msg,0)
			end
            if (GetNeedReg() ~= '' ) then
                local NeedRegs = string.explode(GetNeedReg(),', ');
                for _,v in pairs(NeedRegs) do
                    local cur = con:execute(("SELECT * FROM `%susers` WHERE id='%s';"):dbformat(sPrefixTable,v))			
                    local row = cur:fetch({}, "a")
                    if row then
                        nick = ("%s"):format(row.nick)
                        pass = ("%s"):format(row.pass)
                        RegMan.AddReg(nick, pass, 3)
                        
                        local Msg = "*** В базу хаба был занесен новый пользователь: "..nick..""
                        SendDbg(Msg,0)
                        local RegUser = Core.GetUser(nick)
                        if RegUser then
                            Core.SendPmToNick(nick, bot, (newline..tab..lHeader..newline..inforeg..tab..lFooter):format(nick, pass))
                            if (ShowInfo == 1) then
                                Core.SendPmToNick(nick, bot, newline..tab..lHeader..newline..helpreg..tab..lFooter)
                            end
                        end
					end
                end
                assert(con:execute(("UPDATE `%sconfig` SET config_value = '' WHERE config_name = 'needreg';"):dbformat(sPrefixTable)))
			else
				local Msg = "*** Пользователей, ожидающих регистрацию на хабе, нет."
                SendDbg(Msg,0)
			end
		else
			Core.SendToUser(tUser, "<"..bot.."> Данная команда недоступна для вашего профиля!")
		end
	return true
	end
--
	if cmd == "!truncate" then
		if tProfiles[tUser.iProfile] == 1 then
			local s,e,tbl = string.find(sData, "%b<>%s+%S+%s+(%S+)")
			if (tbl == nil) then
			local Msg = newline..tab..lHeader..newline..tab.."Внимание. Вы собираетесь очистить одну из таблиц, при этом все данные будут удалены. Вы действительно хотите это сделать?"..newline..tab.."Для очистки таблицы конфигурации скрипта, введите команду <!truncate config>"..newline..tab.."Для очистки таблицы пользователей введите команду <!truncate users>"..newline..tab.."Для очистки таблицы ошибок скрипта введите команду <!truncate errors>"..newline..tab..lFooter
            SendDbg(Msg,0)
			elseif (tbl == "config") or (tbl == "users") or (tbl == "errors") then
                local Msg = "";
				local trun,e = con:execute(("TRUNCATE `%s%s`"):dbformat(sPrefixTable,tbl))
                if trun then
                    Msg = "*** Таблица "..tbl.." была очищена."
                else
                    Msg = "*** Неизвестная ошибка."
                    if e then OnError(e); end;
                end
                SendDbg(Msg,0)
			end
		else
			Core.SendToUser(tUser, "<"..bot.."> Данная команда недоступна для вашего профиля!")
		end
	return true
	end
--
	if cmd == "!getregip" then
		if tProfiles[tUser.iProfile] == 1 then
			local _,_,ip = string.find(sData, "%b<>%s+%S+%s+(%d*%.%d*%.%d*%.%d*)")
			if (ip == nil) then
				Core.SendToUser(tUser, "<"..bot.."> Вы ввели не правильные данные. Формат записи - xxx.xxx.xxx.xxx")
			else
				local Msg = GetAllDataIp(ip)
                SendDbg(Msg,0)
			end
		else
			Core.SendToUser(tUser, "<"..bot.."> Данная команда недоступна для вашего профиля!")
		end
	return true
	end
--
	if cmd == "!getregnick" then
		if tProfiles[tUser.iProfile] == 1 then
			local _,_,nick = string.find(sData, "%b<>%s+%S+%s+(%S+)")
				if (nick == nil) then
					Core.SendToUser(tUser, "<"..bot.."> Вы не ввели ник.")
				else
					local Msg = GetAllDataNick(nick)
                    SendDbg(Msg,0)
				end
		else
			Core.SendToUser(tUser, "<"..bot.."> Данная команда недоступна для вашего профиля!")
		end
	return true
	end
--
	if cmd == "!getregid" then
		if tProfiles[tUser.iProfile] == 1 then
			local _,_,id = string.find(sData, "%b<>%s+%S+%s+(%d+)")
				if (id == nil) then
					Core.SendToUser(tUser, "<"..bot.."> Введен неверный ID.")
				else
					local Msg = GetAllDataID(id)
                    SendDbg(Msg,0)
				end
		else
			Core.SendToUser(tUser, "<"..bot.."> Данная команда недоступна для вашего профиля!")
		end
	return true
	end
--
	if cmd == "!getcfg" then
		if tProfiles[tUser.iProfile] == 1 then
			if GetRegCount() and GetAllRegs() and GetNeedReg() then
				local Msg = newline..tab..lHeader..newline..tab.."Статистика базы пользователей"..
                            newline..tab..lSeparate..newline..tab.."Количество учеток в базе: "..GetRegCount()..
                            newline..tab.."Количество записей: "..GetAllRegs()..
                            newline..tab.."ID пользователей ожидающих регистрацию на хабе: "..GetNeedReg()..
                            newline..tab..lFooter
                SendDbg(Msg,0)
			else
				Core.SendToUser(tUser, "<"..bot.."> Прежде чем просматривать конфигурацию скрипта, необходимо сохранить данные в базу.")
			end
		else
			Core.SendToUser(tUser, "<"..bot.."> Данная команда недоступна для вашего профиля!")
		end
	return true
	end
--
	if cmd == "!errorsregs" then
		if tProfiles[tUser.iProfile] == 1 then
			local cur = con:execute(("SELECT * FROM `%serrors`"):dbformat(sPrefixTable))
				if not cur then
                    con:execute(("INSERT INTO `%serrors` (`datetime`, `error`) VALUES ('%s','%s');"):dbformat(sPrefixTable, os.time(), cmd))
                    Core.SendToUser(tUser,"<"..bot.."> Произошла ошибка в тексте запроса! Команда не будети выполнена! Сообщите администратору!")
				return true
			end				
			local row = cur:fetch({}, "a")
			if row then
				local sLine = lHeader
				local sLog = (tab..newline..tab.."%s"..newline..tab.."№"..tab.."Дата и время"..tab..tab.."Ошибка"..newline..tab.."%s"..newline):format(sLine, sLine)
				while row do
					sLog = ("%s"..tab.."%s."..tab.."%s"..tab.."%s"..newline):format(sLog, row.id, os.date(df,row.datetime), row.error)
					row = cur:fetch(row, "a")
				end
				local Msg = ("Ошибки скрипта RegBot.MySQL.2.0_API2.lua: %s"..tab.."%s"):format(sLog, sLine)
                SendDbg(Msg,0)
			else
				Core.SendToUser(tUser, "<"..bot.."> В базе нет ошибок!")	
			end	
		else
			Core.SendToUser(tUser, "<"..bot.."> Данная команда недоступна для вашего профиля!")
		end
	return true
	end
--
end
--
function UserMenu(tUser)
	if (tUser.iProfile == -1) then
        Core.SendToUser(tUser, "<"..bot.."> "..newline..tab..lHeader..newline..needreg..tab..lFooter)
		Core.SendToUser(tUser, "$UserCommand 0 3")
		Core.SendToUser(tUser, "$UserCommand 1 3 Пользователю\\Регистрация\\Зарегистрироваться$<%[mynick]> !regme&#124;")
        Core.SendToUser(tUser, "$UserCommand 1 3 Пользователю\\Регистрация\\Быстрая регистрация$<%[mynick]> !regme %[line:Введите пароль]&#124;")
		Core.SendToUser(tUser, "$UserCommand 1 3 Пользователю\\Регистрация\\Помощь при регистрации$<%[mynick]> !reghelp&#124;")
	else
		Core.SendToUser(tUser, "$UserCommand 0 3")
		Core.SendToUser(tUser, "$UserCommand 1 3 Пользователю\\Регистрация\\Сменить пароль$<%[mynick]> !passwd %[line:Введите новый пароль]&#124;")
		Core.SendToUser(tUser, "$UserCommand 1 3 Пользователю\\Регистрация\\Добавить (сменить) E-mail$<%[mynick]> !email %[line:Введите E-mail]&#124;")
		Core.SendToUser(tUser, "$UserCommand 1 3 Пользователю\\Регистрация\\Удалить регистрацию$<%[mynick]> !unreg&#124;")
		Core.SendToUser(tUser, "$UserCommand 1 3 Пользователю\\Регистрация\\Помощь при регистрации$<%[mynick]> !reghelp&#124;")
		Core.SendToUser(tUser, "$UserCommand 1 3 Пользователю\\Регистрация\\Узнать свой пароль$<%[mynick]> !mypass&#124;")
	end
	if tProfiles[tUser.iProfile] == 1 then
		Core.SendToUser(tUser, "$UserCommand 0 3")
		--Core.SendToUser(tUser, "$UserCommand 1 3 Управление\\Регистрация\\База\\Сохранить данные$<%[mynick]> !addcfg&#124;")
		Core.SendToUser(tUser, "$UserCommand 1 3 Управление\\Регистрация\\База\\Обновить данные$<%[mynick]> !updcfg&#124;")
		Core.SendToUser(tUser, "$UserCommand 1 3 Управление\\Регистрация\\База\\Очистка таблиц$<%[mynick]> !truncate&#124;")
        Core.SendToUser(tUser, "$UserCommand 1 3 Управление\\Регистрация\\База\\Чистка регистраций$<%[mynick]> !cleanregb&#124;") --
		Core.SendToUser(tUser, "$UserCommand 1 3 Управление\\Регистрация\\Поиск\\По IP$<%[mynick]> !getregip %[line:Введите IP]&#124;")
		Core.SendToUser(tUser, "$UserCommand 1 3 Управление\\Регистрация\\Поиск\\По нику$<%[mynick]> !getregnick %[line:Введите ник]&#124;")
		Core.SendToUser(tUser, "$UserCommand 1 3 Управление\\Регистрация\\Поиск\\По ID$<%[mynick]> !getregid %[line:Введите ID]&#124;")
		Core.SendToUser(tUser, "$UserCommand 1 3 Управление\\Регистрация\\Просмотреть конфигурацию$<%[mynick]> !getcfg&#124;")
		Core.SendToUser(tUser, "$UserCommand 1 3 Управление\\Регистрация\\Посмотреть ошибки скрипта$<%[mynick]> !errorsregs&#124;")
        Core.SendToUser(tUser, "$UserCommand 1 3 Управление\\Регистрация\\Удалить юзера$<%[mynick]> !deleteuser %[line:Введите ник]&#124;")
	end
end
--
ToArrival = ChatArrival
RegConnected,OpConnected = UserConnected,UserConnected
RegDisconnected,OpDisconnected = UserDisconnected,UserDisconnected
--
function OnError(sMsg)
	sMsg = sMsg:match"lua(:.*)"
	con:execute(("INSERT INTO `%serrors` (`datetime`, `error`) VALUES ('%s','%s');"):dbformat(sPrefixTable, os.time(), sMsg))
end
--