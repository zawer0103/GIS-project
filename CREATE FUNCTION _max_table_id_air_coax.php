<?PHP 
header('Content-Type: text/plain; charset=utf-8');
ini_set('display_errors', 1);
//подобные скрипты заливаю сюда \\\Secure FTP Connections\chernivtsi_inner_server\var\www\QGIS-Web-Client-master\site\php\test-zawer\
// запускаю в браузере так: http://10.112.129.170/qgis-ck/php/test-zawer/view-topology-switches-and_ktv.php
$conn_string = "host=127.0.0.1 port=5432 dbname=postgres user=postgres password=Xjrjkzlrf30";
           $postgres = pg_connect($conn_string); // 
           if(!$postgres){
                    echo "Error : Unable to open database\n";
                    } 
            else {
                 echo "Opened database successfully\n";
                                }
         
  
$cities=array('bilatserkva','cherkassy','chernivtsi','chortkiv','dnipro','dobrotvir','fastiv','ivanofrankivsk','kharkiv', 'kherson', 'khmelnitsky','kiev','kramatorsk','kremenets','kropyvnytskyi','kryvyirih','lutsk','lviv','melitopol','novomoskovsk', 'obukhiv','poltava','putyvl','rivne','solonitsevka','stebnyk','sumy','terebovlya','ternopil','truskavets','ukrainka','vinnitsa','volochisk','zaporizhia','zhitomir');
  

////цикл для перебора городов из массива
if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";

//".$selectedCity.".".$selectedCity."
////table_id = NULL  
$fun =" CREATE OR REPLACE FUNCTION ".$selectedCity.".".$selectedCity."_max_table_id_air_coax() RETURNS varchar(7) LANGUAGE SQL AS
  $$ SELECT 't_'||left('00000',(5-length(tmp.id::varchar(5))))||tmp.id FROM (SELECT CASE when max(right(table_id, 5)::int) is NULL THEN 1 else max(right(table_id, 5)::int)+1 end as id from  ".$selectedCity.".".$selectedCity."_cable_air_coax_geom) tmp; $$;
  Alter table ".$selectedCity.".".$selectedCity."_cable_air_coax_geom
  Alter  COLUMN  table_id SET DEFAULT ".$selectedCity.".".$selectedCity."_max_table_id_air_coax(); " ;

$result=pg_query($postgres, $fun); 

  }
}
//

?>
