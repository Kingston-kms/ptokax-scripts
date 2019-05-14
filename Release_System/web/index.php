<?php
// объявление корня сайта
//define(ROOT,dirname(__FILE__).'/');

// подключение необходимых файлов
require_once('inc/config.php');
require_once('inc/functions.php');
require_once('inc/magnet.class.php');
require_once('lang/ru/language.php');
require_once('libs/Smarty.class.php');

// Подключение к базе
$sql = mysql_connect( $db['host'],$db['user'],$db['password']) or die('Can\'t connect to MySQL Server');
mysql_select_db($db['database'],$sql);

// инициализация шаблонизатора смарти
$template = new Smarty();
$template->template_dir = TPL."tpl/";
$template->cache_dir = TPL."cache/";
$template->compile_dir= TPL."compile/";
$template->debugging = SMT_DBG;
$smarty->caching = SMT_CACHE;

// выборка категорий
mysql_query("SET NAMES ".$db['charset'].";");
$query = mysql_query("SELECT * FROM rb_cat;");
$cat_num = mysql_num_rows($query);
$category = mysql_fetch_array($query);
if (short_url == true) {
	$cat_url = "cat/";} else {
	$cat_url = "index.php?cat="; }
for ($c=0; $c < $cat_num; $c++ ){
	$share =0;
	$catlist = $catlist."<li><a href=\"".$cat_url.$category['num']."\" title=\"".$category['desc']."\" >".$category['name']."</a></li>";

	$rel_query = mysql_query("SELECT `lenght` FROM `rb_rels` WHERE `cat`=".$category['num']);
	$get_lenght = mysql_fetch_array($rel_query);
	do 
		$share = $share+$get_lenght['lenght'];
	while ($get_lenght = mysql_fetch_array($rel_query)); 
	$share_cat[$c]['rels'] = $category['rels'];
	$share_cat[$c]['name'] = $category['name'];
	$share_cat[$c]['lenght'] = $share;
	$all_share = $all_share+$share;
	$category = mysql_fetch_array($query);
}

//while ($category = mysql_fetch_array($query));

// формирование хедера
$header = $lang['title'];
$main_url= "./";
$main_page = $lang['main'];

$navigate = "<a href=\"".$main_url."\" >".$main_page."</a>";

// обработка запросов категорий
$cat_id = $_GET['cat'];
$rel_id = $_GET['rel'];
if (isset($cat_id)) {
	if ($cat_id > 0 && $cat_id <= $cat_num ){

	$query = mysql_query("SELECT * FROM rb_cat WHERE `num`=$cat_id;");
	$cat = mysql_fetch_array($query);
	$cat_name = $cat['name'];
	if (short_url == true) {
		$cat_url = "cat/".$cat_id;} else {
		$cat_url = "index.php?cat=".$cat_id; }
		$navigate = $navigate." &gt; <a href=\"".$cat_url."\" >".$cat_name."</a>";
		$main_text = $cat['desc'];
		$title = $lang['title']." - ".$cat_name;
	
		$page = $_GET['page'];

		$query = mysql_query("SELECT COUNT(*) FROM rb_rels WHERE `cat`=$cat_id;");
		$rels = mysql_result($query, 0);
		$total = intval(($rels - 1) / $rop) + 1;
		$page= intval($page);
		if (empty($page) or $page < 0) $page =1;
		if ($page > $total) $page = $total;
		$start = $page*$rop - $rop;
		$rels = mysql_query("SELECT * FROM rb_rels WHERE `cat`=$cat_id ORDER BY num DESC LIMIT $start, $rop;");
		$relsrow[] = mysql_fetch_array($rels);
		
		$rel_list = "<div  class=\"rel_list\" ><table>";
		if (short_url == true) {
			$rel_url = "rel/";} else {
			$rel_url = "index.php?rel="; }
		for ($i=0; $i < $rop; $i++)
			{
				$rel_id = $relsrow[$i]['id'];
				if (!$rel_id == "") {
				$rel_list = $rel_list."<tr><td><img src=\"template/img/rel.gif\" alt=\"Релиз\" /></td><td><a href=\"".$rel_url.$rel_id."\" >".$relsrow[$i]['name']."</a></td></tr>";
				}
				$relsrow[] = mysql_fetch_array($rels);
			}
		$rel_list = $rel_list."</table></div>";
		$main_data = $rel_list;

		if (short_url == true) {
			$page_url = $cat_url."/";} else {
			$page_url = $cat_url."&amp;page="; }
		// Проверяем нужны ли стрелки назад
		if ($page != 1) $pervpage = "<a href=\"".$page_url."1\" title=\"".$lang['first_page']."\" ><<</a> <a href=\"".$page_url.($page-1)."\" title=\"".$lang['1back']."\" ><</a> ";
		// Проверяем нужны ли стрелки вперед  
		if ($page != $total) $nextpage = " <a href=\"".$page_url.($page+1)."\" title=\"".$lang['1forward']."\" >></a> <a href=\"".$page_url.$total."\" title=\"".$lang['last_page']."\" >>></a>";
		
		// Находим две ближайшие станицы с обоих краев, если они есть  
		if($page - 2 > 0) $page2left = " <a href=\"".$page_url.($page-2)."\" title=\"".($page-2)."\" >".($page-2)."</a> | ";  
		if($page - 1 > 0) $page1left = "<a href=\"".$page_url.($page-1)."\" title=\"".($page-1)."\" >".($page-1)."</a> | ";  
		if($page + 2 <= $total) $page2right = " | <a href=\"".$page_url.($page+2)."\" title=\"".($page+2)."\" >".($page+2)."</a>";
		if($page + 1 <= $total) $page1right = " | <a href=\"".$page_url.($page+1)."\" title=\"".($page+1)."\" >".($page+1)."</a>";
		
		// Вывод меню  
		$page_bar = $lang['pages'].": ".$pervpage.$page2left.$page1left."<b>".$page."</b>".$page1right.$page2right.$nextpage; 
		
		
	} else { // если категория не существует
	$navigate = $navigate." &#8250; ".$lang['error'];
	$main_text = $data['error_text'];
	$title = $lang['title']." - ".$lang['error'];
	$main_data = $data['error_cat_info'];
	}
}

else if (isset($rel_id)) {
			$query = mysql_query("SELECT * FROM rb_rels WHERE `id`=$rel_id;");
			if (mysql_num_rows($query) > 0 ) {
				$rel = mysql_fetch_array($query);
				$cat_query = mysql_query("SELECT * FROM rb_cat WHERE `num`=".$rel['cat'].";");
				$cat_data = mysql_fetch_array($cat_query);
				$title = $lang['title']." - ".$cat_data['name'];
				if (short_url == true) {
					$cat_url = "cat/";
					$rel_url = "rel/";
				} else {
					$cat_url = "index.php?cat=";
					$rel_url = "index.php?rel=";
				}
				$navigate = $navigate." &gt; <a href=\"".$cat_url.$rel['cat']."\" >".$cat_data['name']."</a> &gt; <a href=\"".$rel_url.$rel_id."\" >".$rel['name']."</a>";
				$main_text = $cat_data['desc'];
				
				$rel_info = "<table class=\"rel_info\">";
				$rel_info = $rel_info."<tr><th>".$lang['rel_name']."</th></tr><tr><td>".$rel['name']."</td></tr>";
				if ($rel['desc'] == "0") {
					$rel_desc = $lang['rel_no_desc']; }
					else { $rel_desc = $rel['desc']; }
				$rel_info = $rel_info."<tr><th>".$lang['rel_desc']."</th></tr><tr><td>".$rel_desc."</td></tr>";
				$arr_tth = split(", ", $rel['tth']);
				$tth_count = count($arr_tth);
				for ($r=0; $r < $tth_count; $r++) $tth = $tth.$arr_tth[$r].", ";
				$rel_info = $rel_info."<tr><th>".$lang['rel_tth']."</th></tr><tr><td>".$tth."</td></tr>";
				$arr_magnet = split(" / ", $rel['magnet']);
				$magnet_count = count($arr_magnet);
				for ($m=0; $m < $magnet_count; $m++) $magnets = $magnets."<a href=\"".str_replace("&","&amp;",$arr_magnet[$m])."\" >".$lang['magnet_n'].($m+1)."</a> ";
				$rel_info = $rel_info."<tr><th>".$lang['rel_magnet']."</th></tr><tr><td><img src=\"template/img/m.png\" alt=\"Magnet\" width=\"13\" height=\"13\" align=\"left\" /> ".$magnets."</td></tr>";
				if ($rel['links'] == "1") {
					$rel_info = $rel_info."<tr><th>".$lang['rel_links']."</th></tr>"; //<tr><td>".$magnets."</td></tr>";
					$query = mysql_query("SELECT * FROM rb_links WHERE `rel_cat`=".$rel['cat']." and `rel_id`=".$rel['num'].";");
					$links = mysql_fetch_array($query);
					do {
						$rel_info = $rel_info."<tr><td>".$links['link']."</td></tr>";
					}
					while ($links = mysql_fetch_array($query));
				}
				$rel_info = $rel_info."<tr><th>".$lang['rel_lenght']."</th></tr><tr><td>".FormatShare($rel['lenght'])."</td></tr>";
				$rel_info = $rel_info."<tr><th>".$lang['rel_time']."</th></tr><tr><td>".date("d.m.y в H:i",$rel['time'])."</td></tr>";
				$rel_info = $rel_info."<tr><th>".$lang['rel_author']."</th></tr><tr><td>".$rel['author']."</td></tr>";
				$rel_info = $rel_info."</table>";
				$main_data = $rel_info;
				$page_bar = "";
			} else {
				$navigate = $navigate." &#8250; ".$lang['error'];
				$main_text = $data['error_rel'];
				$title = $lang['title']." - ".$lang['error'];
				$main_data = $data['error_rel_info'];
				$page_bar = "";		
			}
		}
else 

{
	$title = $lang['title']." - ".$lang['main'];
	$main_text = $data['main_text'];
	$main_data = "<table>";
	$main_data = $main_data."<tr><th colspan=\"3\">".$lang['stat_t']."</th></tr>";
	$main_data = $main_data."<tr><td colspan=\"3\">".$lang['lenght_t']." ".FormatShare($all_share)."</td></tr>";
	$main_data = $main_data."<tr><th  colspan=\"3\" >".$lang['stat_cat']."</th></tr>";
	for ($sc=0; $sc < $cat_num; $sc++)
		{
			$main_data = $main_data."<tr><td>".($sc+1)."</td><td>".$share_cat[$sc]['name']."</td><td>".FormatShare($share_cat[$sc]['lenght'])."</td><td>".$lang['stat_rels']." ".$share_cat[$sc]['rels']."</td></tr>";
		}
	$main_data = $main_data."</table>";
	
}

// обработка переменных шаблона	
$var = array (
	'title' => $title,
	'header' => $header,
	'navigate' => $navigate,
	'main_text' => $main_text,
	'on_main' => $lang['on_main'],
	'rels_table' => $main_data,
	'page_bar' => $page_bar,
	'catlist' => $catlist,

);

$template->assign($var);
// вывод
$template->display('index.tpl');

?>