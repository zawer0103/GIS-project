<?PHP 
header('Content-Type: text/plain; charset=utf-8');
ini_set('display_errors', 1);

$conn_string = "host=127.0.0.1 port=5432 dbname=postgres user=postgres password=Xjrjkzlrf30";
           $postgres = pg_connect($conn_string); // 
           if(!$postgres){
                    echo "Error : Unable to open database\n";
                    } 
            else {
                 echo "Opened database successfully\n";
                                }
  
$cities=array('bilatserkva','cherkassy','chernivtsi','chortkiv','dnipro','dobrotvir','fastiv','ivanofrankivsk','kharkiv', 'kherson', 'khmelnitsky','kiev','kramatorsk','kremenets','kropyvnytskyi','kryvyirih','lutsk','lviv','melitopol','novomoskovsk', 'obukhiv','poltava','putyvl','rivne','solonitsevka','stebnyk','sumy','terebovlya','ternopil','truskavets','ukrainka','vinnitsa','volochisk','zaporizhia','zhitomir');

 // запускаю в браузере так: http://10.112.129.170/qgis-ck/php/test-zawer/CSV_Backup_.php


  $tables=array('cable_channels', 'cable_air', 'cable_channels_coax', 'cable_air_coax'  );


  $dirlink = "/var/www/QGIS-Web-Client-master/site/tmp/backupCSV/" ;
  mkdir($dirlink,0777);

if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";
  // ".$selectedCity.".".$selectedCity."_
 
  foreach ($tables as $table)
    {
          $selectedtable = $table;
  echo $table."\n";

  chmod($dirlink,0777); // без этого нихрена не записывает
  $linkStorage = $dirlink.$selectedCity."_".$selectedtable.".csv"; // 

 $backup =" COPY ( SELECT * FROM ".$selectedCity.".".$selectedCity."_".$selectedtable.") TO  '".$linkStorage."'  WITH CSV HEADER DELIMITER ';' encoding 'win1251';" ;

  $result=pg_query($postgres, $backup); 
      }
       }
}
?>

