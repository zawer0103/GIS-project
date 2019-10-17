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

//  http://10.112.129.170/qgis-ck/php/test-zawer/Revoke for CITY_cable_channel_cable_geom.php

if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";

  // ".$selectedCity.".".$selectedCity."_

 $revoke =" 
REVOKE ALL ON ".$selectedCity.".".$selectedCity."_cable_channel_cable_geom FROM simpleuser;
REVOKE ALL ON ".$selectedCity.".".$selectedCity."_cable_channel_cable_geom FROM simplereader;
 " ;  $result=pg_query($postgres, $revoke); 


#ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_channel_cable_geom DISABLE TRIGGER cable_channels_data_update

$alter ="ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_channel_cable_geom DISABLE TRIGGER cable_channels_data_update;";
    $result=pg_query($postgres, $alter); 

$alter ="

 COMMENT ON TABLE  ".$selectedCity.".".$selectedCity."_cable_channel_cable_geom  IS 'не используем: перешли на вьюшку'";
    $result=pg_query($postgres, $alter); 

       }
}
?>

