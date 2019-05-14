<?php

function FormatShare($number){
	$postfixs = array('����', '��', '��', '��','��');
	$postfix = 0;
	while($number > 1024) {
			$number /= 1024;
			++$postfix;
	}
	$number = round($number, 3);
	return $number.' '.$postfixs[$postfix];
}


?>