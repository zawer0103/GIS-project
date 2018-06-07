<?php
$i=0;
for ($i=1; $i<=9; $i++)
{	$dir ="t_0000$i"; 
	mkdir("C:/xampp/htdocs/zawer/ttt/$dir", 0777);
	echo "$dir" ;
	echo "\n" ;
}
for ($i=10; $i<=99; $i++)
{	$dir ="t_000$i"; 
	mkdir("C:/xampp/htdocs/zawer/ttt/$dir", 0777);
	echo "$dir" ;
	echo "\n" ;
}
for ($i=100; $i<=999; $i++)
{	$dir ="t_00$i"; 
	mkdir("C:/xampp/htdocs/zawer/ttt/$dir", 0777);
	echo "$dir" ;
	echo "\n" ;
} 
?>