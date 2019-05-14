--[[##############################################################################

	Скрипт релизов на MySQL
	Автор: Kingston
	Версия: 1.0
	API: API2
	PtokaX 0.4.x.x, Lua 5.1
	
	При поддержке: http://mydc.ru

##################################################################################
	Файл конфигурации
################################################################################]]

-- Global Library Settings, Set Library specific options.
--os.setlocale"ru_RU.CP1251"
--date = "%d %B %Y %X"			-- формат времени [ mm/dd/yy hh:mm:ss ]

-- Skin design

separate = "\t"..string.rep("=",80)
separate1 = string.rep("=",60)
separate2 = string.rep("-",60)

-- Bot Variables
tVar = {
	-- Bot Settings, Customize various options for the Library bots.
	----------------------------------
	sOpNick			= "Admin", 	-- ник оператора для сообщения об ошибках
	sBot			= SetMan.GetString(21),				-- Ник бота [Мастер] ("Nick" или SetMan.GetString(21))
	sBotD			= "",		-- Описание бота
	sBotE			= "",			-- Email адрес бота
	sIsOP			= 1,					-- Есть ключик (1=да,0=нет)
	nBot			= SetMan.GetString(21),				-- Ник бота [Оповещения] ("Nick" или SetMan.GetString(21))
	nBotD			= "",		-- Описание бота
	nBotE			= "",		-- Email адрес бота
	nIsOP			= 1,					-- Есть ключик (1=да,0=нет)
	----------------------------------
	sTrig			= "!",					-- Префикс команд главного чата
	----------------------------------
	--sLibFile		= "Library.mll",		-- Main Library file
	--sLibData		= "LibData.mll",		-- Temporary Library data file
	--sLibLast		= "LibLast.mll",		-- Latest releases data file
	--sFolder			= "MLinkLib",			-- Script data folder
	----------------------------------
	sRC				= "on",					-- Send Right-Click menu [on,off]
	--sRCMenu			= "",					-- Right-Click menu name - taken from hubname or use "Custom Name"
	sRCSubMenu		= "Релизы",					-- Right-Click SubMenu - taken from scriptname or use "Custom Name"
	----------------------------------
	sSkin       	= "text",		-- Default skin folder name, all users start with this skin
	----------------------------------
	sNotify			= "main",					-- Send info about newly added releases / requests [main,pm,off]
	sOnConnect		= "main",					-- Send latest releases on connect [main,pm,off]
	sLastRel		= 3,					-- Maximum number of items in the history of new added releases
	TimeRel			= 30*86400,			-- за какое время будут показаны последние релизы при входе, в сек.
	Latest			= 20,			-- кол-во релизов по умолчанию для поиска
	----------------------------------
	sRating			= "no",					-- Show the Rating on connect, if provided [yes,no]
	sMag            = "no",					-- Show the Mlink on connect, if provided [yes,no]
	sUrl			= "no",					-- Show the URL on connect, if provided [yes,no]
	sDate 			= "%d/%m/%y в %H:%M:%S", --"%d %B %Y %X ",
	sTopNum			= "10",
}

tTimesToUpdate = {	                 -- В какое время обновляемся (часы:минуты)
	["05:00"] = 1,
}

-- Poster Ranking, You can add more ranks and ranges at anytime.
tRank = {
	[1]		=	{["name"] = "Чайник", ["Start"] = 0, ["End"]=100},  
	[2]		=	{["name"] = "Зеленый", ["Start"] = 100, ["End"]=300}, 
	[3]		=	{["name"] = "Стажер", ["Start"] = 300, ["End"]=600}, 
	[4]		=	{["name"] = "Ученик", ["Start"] = 600, ["End"]=1000}, 
	[5]		=	{["name"] = "Активный", ["Start"] = 1000, ["End"]=1500},
	[6]		=	{["name"] = "Спец", ["Start"] = 1500, ["End"]=2100}, 
	[7]		=	{["name"] = "Профи", ["Start"] = 2100, ["End"]=2800},
	[8]		=	{["name"] = "Мастер", ["Start"] = 2800, ["End"]=3600},
	[9]		=	{["name"] = "Эксперт", ["Start"] = 3600, ["End"]=4500},
	[10]	=	{["name"] = "Топлоадер", ["Start"] = 4500, ["End"]=5500},
	[11]	=	{["name"] = "Ветеран", ["Start"] = 5500, ["End"]=6600},
}

-- Commands, Choose the triggers you want for the wizards and quick commands.
tCmd = {
	-- Wizards
	----------------------------------
	sAddRel			= "new",		-- Add a new release
	sAddCat			= "newcat",		-- Add a new category
	sDelRel			= "del",		-- Delete a release (users can only delete their own release)
	sDelCat			= "delcat",		-- Delete a category
--	sReq			= "newreq",		-- Request a release
	sShowRel		= "show",		-- Browse through the release list
	sShowRelFromCat	= "showfromcat",
	sEditRel		= "editrel",
	sMoveRel		= "moverel",
	sEditLink		= "editlink",
	
	-- Quick Commands
	----------------------------------
--	qAddRel			= "qnew",		-- Add a new release
--	qAddCat			= "qnewcat",	-- Add a new category
--	qDelRel			= "qdel",		-- Delete a release (users can only delete their own release)
--	qDelCat			= "qdelcat",	-- Delete a category
--	qReq			= "qnewreq",	-- Request a release
--	qShow       	= "qshow",		-- Show release details
--	qSkin       	= "chskin",		-- Change your prefered skin
--	qRank			= "myrank",		-- Show your rank and number of posts
--	qComment		= "mycom",		-- Show your posts that have comments
--	qMag			= "mags",		-- Show all the available magnet links
--	qWeb            = "urls",		-- Show all the available web links
--	qClean			= "clean",		-- Force the cleaner to run
--	qAddSkin		= "newskin",	-- Add a skin to the database
	sStats			= "relstat",	-- Статистика
	OnConnect		= "onconnect",	-- Переключатель показа релизов при входе
	sAddMod			= "addmod",
	qHelp			= "mllhelp",	-- MLinkLib help
	sSearchName		= "relsearch",
	sLatest			= "rellatest",
	sNickRels		= "nickrels",
	UpdBase 		= "updbase",
	UserStats		= "userstats",
	UpdStats		= "updstats",
	TopRels			= "toprels",
}

-- Profile Access, Allow or deny access by profile number.
	--
    -- Allow = 1
	--  Deny = 0
	--
	-- Admin Access
pAdmin = {
		[-1] = 0,	-- Un-Reg		--		/	     \
		[0]  = 1,	-- hubowner       --    /   PtokaX   \
		[1]  = 1,	-- master           --  /	 Built-in	 \
		[2]  = 0,	-- moderator          --  \	 Profiles 	 /
		[3]  = 0,	-- superop          --    \			   /
		[4]  = 0,	-- operator   	-- ** Robocop/Leviathan users must uncomment **
		[5]  = 0,	-- legend  	-- ** Robocop/Leviathan users must uncomment **
		[6]  = 0,	-- hero       	-- ** Leviathan users must uncomment         **
		[7]  = 0,	-- vip
		[8]  = 0,	-- poweruser
		[9]  = 0,	-- reg
}
	-- User Access.
pUser = {
	   	[-1] = 0,	-- Un-Reg		--		/	     \
		[0]  = 1,	-- hubowner       --    /   PtokaX   \
		[1]  = 1,	-- master           --  /	 Built-in	 \
		[2]  = 1,	-- moderator          --  \	 Profiles 	 /
		[3]  = 1,	-- superop          --    \			   /
		[4]  = 1,	-- operator   	-- ** Robocop/Leviathan users must uncomment **
		[5]  = 1,	-- legend  	-- ** Robocop/Leviathan users must uncomment **
		[6]  = 1,	-- hero       	-- ** Leviathan users must uncomment         **
		[7]  = 1,	-- vip
		[8]  = 1,	-- poweruser
		[9]  = 1,	-- reg
}

-- Command access, Assign access types for the commands and wizards.
wAccess = {
	-- Admin Access = pAdmin,
	-- User Access 	= pUser
	--
	-- Wizards
	----------------------------------
	["AddRel"] 		= pUser,        -- Add a new release
	["AddCat"] 		= pAdmin,       -- Add a new category
	["DelRel"] 		= pUser,        -- Delete a release (users can only delete their own release)
	["DelCat"] 		= pAdmin,       -- Delete a category
	--["AddReq"] 		= pUser,        -- Request a release
	["ShowRel"]		= pUser,        -- Browse through the release List
	["EditRel"]		= pUser,
	["MoveRel"]		= pUser,
	["EditLink"]	= pUser,
	["ShowRelFromCat"] = pUser,
}

tAccess = {
	-- Quick Commands
	----------------------------------
--	[tCmd.qAddRel] 	= pUser,        -- Add a new release
--	[tCmd.qAddCat] 	= pAdmin,      	-- Add a new category
--	[tCmd.qDelRel] 	= pUser,        -- Delete a release (users can only delete their own release)
--	[tCmd.qDelCat] 	= pAdmin,     	-- Delete a category
--	[tCmd.qReq] 	= pUser,        -- Request a release
--	[tCmd.qShow] 	= pUser,        -- Show release details
--	[tCmd.qSkin] 	= pUser,        -- Change your prefered skin
--	[tCmd.qRank]	= pUser,		-- Show your rank and number of posts
--	[tCmd.qComment]	= pUser,		-- Show your posts that have comments
--	[tCmd.qMag]		= pUser,		-- Show all the available magnet links
--	[tCmd.qWeb]     = pUser,		-- Show all the available web links
--	[tCmd.qClean]	= pAdmin,		-- Force the cleaner to run
--	[tCmd.qAddSkin] = pAdmin,		-- Add a skin to the database
	[tCmd.sNickRels] = pUser,
	[tCmd.sLatest]	= pUser,
	[tCmd.sStats]	= pUser,
	[tCmd.sSearchName] = pUser,
	[tCmd.sAddMod]  = pAdmin,		-- Добавить, изменить, удалить модера категории.
	[tCmd.OnConnect] = pUser,		-- Переключатель показа при входе
	[tCmd.qHelp]	= pUser,		-- Help
	[tCmd.UpdBase]	= pAdmin,		-- 
	[tCmd.UserStats]= pUser,
	[tCmd.UpdStats] = pAdmin,
	[tCmd.TopRels]	= pUser,
}

---------------------------------------------------------------------------------------------------------

--###################################################################################
-- MySQL конфигурация
tSql = {
	-- Данные для подключение к MySQL серверу
	Host		=	"localhost",	-- Адрес MySQL сервера, по умолчанию значение: localhost
	Port		=	"3306",			-- Порт подключения к серверу MySQL, по умолчанию: 3306
	DbName		=	"ptokax",  		-- Название базы данных MySQL
	UserName	=	"ptokax",			-- Имя пользователя базы данных MySQL
	UserPass	=	"password",			-- Пароль пользователя базы данных MySQL
	Prefix		=	"rb",			-- Префикс таблиц MySQL
	
	Charset		=	"cp1251",
	TimeCon 	=	1,
}
