<?php
header('Content-Type: text/plain; charset=utf-8');
ini_set('display_errors', 1);
/*
	class dbConnSetClass{
	  private $outerIp = '10.112.129.170';
	  private $shareAddress = '//10.112.129.165/share/';
	  private $dbConnSet = array(
	    "host"=>"host=127.0.0.1",
	    "port"=>"port=5432",
	    "dbname"=>"dbname=postgres",
	    "user"=>"user=simpleuser",
	    "password"=>"password=proleEmploymentPassword"
	    );
	}

    public function sshFileReplaceToShare($address, $port, $login, $password, $locationPath, $destinationPath){
    $connection = ssh2_connect($address, $port);
    ssh2_auth_password($connection, $login, $password);
    ssh2_scp_send($connection, $locationPath, $destinationPath, 0644); //копирование файла с клиента на сервер, используя протокол SCP.
    // Add this to flush buffers/close session 
    ssh2_exec($connection, 'exit'); //Запуск команды на удаленном сервере и выделение для нее канала.
	}

    else if(strtolower($fileType) == 'qfts' ){//and strtolower($restriction) =='admin'
          if (move_uploaded_file($_FILES[$button_id]['tmp_name'], $target_file)) {
              echo "The file ". basename( $_FILES[$button_id]['name']). " has been uploaded.";
              chmod($target_file, 0666);
              $locationPath = self::dirCreate($selectedCity, $target_file, $file_name, $fileType);
              $destinationPath = '/mnt/samba/share/'.$file_name;
              $query = "INSERT INTO public.file_upload(user_name, file_name, file_type ,time_upload) VALUES ('".$login_user."','".$file_name."','".$fileType."',now());";
              $file_logger -> dbConnect($query, false, true);
              self::sshFileReplaceToShare('10.112.129.165', 5432, 'yshpylovyi', 'yshpylovyi2017', $locationPath, $destinationPath);
             header("location: main_page.php?restriction=".$restriction."&e_mail=".$login_user); // Redirecting To Other Page

/////////////////////////////
          
$locationPath = '/mnt/samba/share/tmp';
$destinationPath = '/mnt/samba/share/';
sshFileReplaceToShare('10.112.129.165', 5432, 'yshpylovyi', 'yshpylovyi2017', $locationPath, $destinationPath);
*/



$connection = ssh2_connect('10.112.129.165', 5432);
    $sss=ssh2_auth_password($connection, 'yshpylovyi', 'yshpylovyi2017');
if($sss = false){echo "Error : Unable to open database\n";
                 } 
else {echo "Opened database successfully\n";
}

$cities=array('bilatserkva','cherkassy','chernivtsi','chortkiv','dnipro','dobrotvir','fastiv','ivanofrankivsk','kharkiv', 'kherson', 'khmelnitsky','kiev','kramatorsk','kremenets','kropyvnytskyi','kryvyirih','lutsk','lviv','melitopol','novomoskovsk', 'obukhiv','poltava','putyvl','rivne','solonitsevka','stebnyk','sumy','terebovlya','ternopil','truskavets','ukrainka','vinnitsa','volochisk','zaporizhia','zhitomir');

if (is_array($cities) || is_object($cities)){
    foreach ($cities as $city)    {
          $selectedCity = $city;
    echo $city."\n";
   $file_name='quickfinder_'.$selectedCity.'.qfts';    

$locationPath = '/var/www/QGIS-Web-Client-master/searchfiles/'.$file_name; 
$destinationPath = '/mnt/samba/share/tmp/'.$file_name; //тут добавить цикл для множества файлов
 ssh2_scp_send($connection, $locationPath, $destinationPath, 0644); //копирование файла с клиента на сервер, используя протокол SCP. -- всё чтобыло скопировало успешно!
	}
}
ssh2_exec($connection, 'exit');
?>