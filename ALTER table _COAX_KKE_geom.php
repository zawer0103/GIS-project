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


if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";

  // ".$selectedCity.".".$selectedCity."_
  
    $alter =" ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_channel_coax_geom ADD COLUMN cable_description varchar(50); ";
    $result=pg_query($postgres, $alter); 
  $alter =" ALTER TABLE   ".$selectedCity.".".$selectedCity."_cable_channel_coax_geom ADD COLUMN cable_short_type_description varchar(50); ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_channel_coax_geom ADD COLUMN total_cable_length varchar(50);";
    $result=pg_query($postgres, $alter); 
      $alter ="  ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_channel_coax_geom ADD COLUMN total_cable_length varchar(50);";
    $result=pg_query($postgres, $alter); 



       $alter2 ="ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_channels_coax ALTER COLUMN cable_type SET DEFAULT 'coax';"; 
    $result=pg_query($postgres, $alter2); 

      /*    $alter2 ="ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_channels_coax ALTER COLUMN cable_type DROP DEFAULT;"; 
    $result=pg_query($postgres, $alter2); */

  
//ALTER TABLE fastiv.fastiv_cable_channel_coax_geom ADD COLUMN cable_description varchar(50); // работает

//ALTER TABLE fastiv.fastiv_cable_channels_coax ALTER COLUMN cable_type SET DEFAULT 'optic'::varchar; // работает
//ALTER TABLE kiev.kiev_cable_channel_coax_geom ADD COLUMN total_cable_length varchar(50);
    
    //  коментарий в самой БД к каждой колонке каждой таблицы  написаны в отдельном файле ADD COMENT.php

    
       }
}
?>

