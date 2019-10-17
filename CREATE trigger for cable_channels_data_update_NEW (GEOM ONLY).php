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
 // запускаю в браузере так: http://10.112.129.170/qgis-ck/php/test-zawer/CREATE trigger for cable_channels_data_update_NEW (GEOM ONLY).php
         
 $cities=array('bilatserkva','cherkassy','chernivtsi','chortkiv','dnipro','dobrotvir','fastiv','ivanofrankivsk','kharkiv', 'kherson', 'khmelnitsky','kiev','kramatorsk','kremenets','kropyvnytskyi','kryvyirih','lutsk','lviv','melitopol','novomoskovsk', 'obukhiv','poltava','putyvl','rivne','solonitsevka','stebnyk','sumy','terebovlya','ternopil','truskavets','ukrainka','vinnitsa','volochisk','zaporizhia','zhitomir'); 

//$cities=array('fastiv');
////цикл для перебора гордов из массива
if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";

  // ".$selectedCity.".".$selectedCity."_

 $query = "
DROP TRIGGER IF EXISTS  ".$selectedCity."_cable_channels_data_update_new ON ".$selectedCity.".".$selectedCity."_cable_channels;
" ;  
   echo $query.'<hr>'; //  тут все названия тригеров новые 
    $result=pg_query($postgres, $query);

 $query = "
 CREATE TRIGGER cable_channels_data_update_new AFTER UPDATE of geom_cable ON ".$selectedCity.".".$selectedCity."_cable_channels  FOR EACH ROW EXECUTE PROCEDURE  cable_channels_data_update_new();
  " ;   
    echo $query.'<hr>'; // тут все названия триггеров новые
      $result=pg_query($postgres, $query);#! есть триггер на изменение конкретного поля
      //получить список тригеров с привязкой к таблицам можно так select * from information_schema.triggers

       }
}
?>

