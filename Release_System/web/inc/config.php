<?php
// переменные шаблонизатора смарти
define(SMARTY_DIR,'libs/');	// путь до смарти либс
define(TPL,'template/');		// путь до папки с шаблонами
define(SMT_DBG, false);				// debug smarty
define(STM_CACHE, false);			// caching

// url
define(short_url, false); // использовать короткие ссылки, необходима поддержка .htaccess сервером

// параметры оформления
$rop = 20;

// Параметры подключения к базе данных
$db = array (
	'host' => 'localhost',		// Адрес
	'port' => '3309',			// Порт
	'user' => 'ptokax',			// Имя пользователя
	'password' => 'password',	// Пароль
	'database' => 'ptokax',		// Имя базы
	'charset' => 'cp1251',		// Кодировка базы
);

?>
