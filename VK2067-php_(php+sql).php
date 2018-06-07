<?PHP 
header('Content-Type: text/plain; charset=utf-8');
ini_set('display_errors', 1);

$conn_string = "host=127.0.0.1 port=5432 dbname=postgres user=postgres password=password";
           $postgres = pg_connect($conn_string); // 
           if(!$postgres){
                    echo "Error : Unable to open database\n";
                    } 
            else {
                 echo "Opened database successfully\n";
                                }
$cities=array('bilatserkva','cherkassy','chernivtsi','chortkiv','dnipro','dobrotvir','fastiv','ivanofrankivsk','kharkiv', 'kherson', 
  'khmelnitsky','kiev','kramatorsk','kremenets','kropyvnytskyi','kryvyirih','lutsk','lviv','melitopol','novomoskovsk', 'obukhiv','poltava','putyvl','rivne','solonitsevka','stebnyk','sumy','terebovlya','ternopil','truskavets','ukrainka','vinnitsa','volochisk','zaporizhia','zhitomir');

////цикл для перебора гордов из массива
if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";

/*$drop_vk2067 ="drop table IF EXISTS ".$selectedCity.".".$selectedCity."_vk2067;";
$result=pg_query($postgres, $drop_vk2067); //удаляем таблицы _vk2067 для теста*/


$create_vk2067 ="create table IF NOT EXISTS ".$selectedCity.".".$selectedCity."_vk2067 (id SERIAL, cubic_street varchar(100), cubic_house varchar(50), cubic_code varchar(50),   cubic_name varchar(100), cubic_coment varchar(200), equipment_geom  geometry,  mother_cubic_street varchar(100), mother_cubic_house varchar(50), mother_cubic_code varchar(50), mother_cubic_name varchar(50), mother_cubic_coment varchar(50), mother_equipment_geom  geometry,  line_geom  geometry);";
$result=pg_query($postgres, $create_vk2067); //
$delete_vk2067 ="DELETE FROM ".$selectedCity.".".$selectedCity."_vk2067;";
$result=pg_query($postgres, $delete_vk2067); //очистка таблиц онлайн   (одни раз в сутки)


$insert_vk2067="INSERT INTO ".$selectedCity.".".$selectedCity."_vk2067 (cubic_street, cubic_house, cubic_code, cubic_name, cubic_coment, equipment_geom) SELECT cubic_street, cubic_house, cubic_code, cubic_name, cubic_coment, equipment_geom from ".$selectedCity.".".$selectedCity."_ctv_topology where cubic_name LIKE  'Блок питания'; ";  
$result=pg_query($postgres, $insert_vk2067); //заполнили таблицу _vk2067 исходными данными

$para_vk2067=" create temp table ".$selectedCity."TMP as SELECT cubic_street, cubic_house, cubic_code, cubic_name, cubic_coment, regexp_replace(split_part(cubic_coment,'_2_',2),'\)', '') as position2, equipment_geom FROM ".$selectedCity.".".$selectedCity."_vk2067 where strpos(cubic_coment,'_2_')>0 ;
UPDATE  ".$selectedCity.".".$selectedCity."_vk2067 Set mother_cubic_code=".$selectedCity."TMP.position2 FROM ".$selectedCity."TMP where ".$selectedCity.".".$selectedCity."_vk2067.cubic_code=".$selectedCity."TMP.cubic_code;
UPDATE  ".$selectedCity.".".$selectedCity."_vk2067 Set mother_cubic_street=".$selectedCity."TMP.cubic_street, mother_cubic_house=".$selectedCity."TMP.cubic_house,  mother_cubic_name=".$selectedCity."TMP.cubic_name, mother_cubic_coment=".$selectedCity."TMP.cubic_coment, mother_equipment_geom=".$selectedCity."TMP.equipment_geom FROM ".$selectedCity."TMP where ".$selectedCity.".".$selectedCity."_vk2067.mother_cubic_code=".$selectedCity."TMP.cubic_code;
drop  table ".$selectedCity."TMP;

create temp table ".$selectedCity."TMP2 as SELECT cubic_street, cubic_house, cubic_code,cubic_name, cubic_coment, regexp_replace(split_part(cubic_coment,'пара_',2),'\)', '') as position2, equipment_geom FROM ".$selectedCity.".".$selectedCity."_vk2067 
where strpos(cubic_coment,'пара_')>0 ;
UPDATE  ".$selectedCity.".".$selectedCity."_vk2067
Set mother_cubic_code=".$selectedCity."TMP2.position2
FROM ".$selectedCity."TMP2 where ".$selectedCity.".".$selectedCity."_vk2067.cubic_code=".$selectedCity."TMP2.cubic_code; 
UPDATE  ".$selectedCity.".".$selectedCity."_vk2067
Set mother_cubic_street=".$selectedCity."TMP2.cubic_street,mother_cubic_house=".$selectedCity."TMP2.cubic_house,  mother_cubic_name=".$selectedCity."TMP2.cubic_name, mother_cubic_coment=".$selectedCity."TMP2.cubic_coment, mother_equipment_geom=".$selectedCity."TMP2.equipment_geom
FROM ".$selectedCity."TMP2 where ".$selectedCity.".".$selectedCity."_vk2067.mother_cubic_code=".$selectedCity."TMP2.cubic_code;
drop  table ".$selectedCity."TMP2;

create temp table ".$selectedCity."TMP3 as SELECT equipment_geom as p1, mother_equipment_geom as p2,  st_makeline(equipment_geom, mother_equipment_geom) as line_geom from ".$selectedCity.".".$selectedCity."_vk2067;
UPDATE  ".$selectedCity.".".$selectedCity."_vk2067 
Set  line_geom=".$selectedCity."TMP3.line_geom FROM ".$selectedCity."TMP3 
where equipment_geom=".$selectedCity."TMP3.p1;  
select * from ".$selectedCity.".".$selectedCity."_vk2067
where line_geom IS NOT NULL ;";  
$result=pg_query($postgres, $para_vk2067); // поиск пары по разделителям _пара_ и _2_

		}
}
?>