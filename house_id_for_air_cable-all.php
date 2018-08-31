<?php


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
         
  $cities=array('bilatserkva','cherkassy','chernivtsi','chortkiv','dnipro','dobrotvir','fastiv','ivanofrankivsk','kharkiv', 'kherson', 'khmelnitsky',/*'kiev',*/'kramatorsk','kremenets','kropyvnytskyi','kryvyirih','lutsk','lviv','melitopol','novomoskovsk', 'obukhiv','poltava','putyvl','rivne','solonitsevka','stebnyk','sumy','terebovlya','ternopil','truskavets','ukrainka','vinnitsa','volochisk','zaporizhia','zhitomir');

  //".$selectedCity.".".$selectedCity."

  if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";
$cable_air_house_id = " create temp table TMP1 as 
		SELECT ".$selectedCity."_cable_air.cubic_start_house_id, ".$selectedCity."_cable_air.cubic_start_street, ".$selectedCity."_cable_air.cubic_start_house_num, ".$selectedCity."_cable_air.geom_start_point FROM ".$selectedCity.".".$selectedCity."_cable_air  where  ".$selectedCity."_cable_air.geom_start_point IS NOT NULL;
		 UPDATE TMP1 SET cubic_start_house_id = ".$selectedCity."_buildings.cubic_house_id, cubic_start_street=".$selectedCity."_buildings.cubic_street, cubic_start_house_num=".$selectedCity."_buildings.cubic_house  FROM ".$selectedCity.".".$selectedCity."_buildings  WHERE ".$selectedCity."_buildings.building_geom IS NOT NULL AND ".$selectedCity."_buildings.cubic_house_id IS NOT NULL AND  ST_DWithin(TMP1.geom_start_point,".$selectedCity."_buildings.building_geom,3) is true;
		 UPDATE ".$selectedCity.".".$selectedCity."_cable_air SET cubic_start_house_id = TMP1.cubic_start_house_id, cubic_start_street=TMP1.cubic_start_street, cubic_start_house_num=TMP1.cubic_start_house_num  FROM TMP1 WHERE ".$selectedCity."_cable_air.geom_start_point=TMP1.geom_start_point;
		 drop table TMP1 ; 

		create temp table TMP2 as 
		SELECT ".$selectedCity."_cable_air.cubic_end_house_id, ".$selectedCity."_cable_air.cubic_end_street, ".$selectedCity."_cable_air.cubic_end_house_num, ".$selectedCity."_cable_air.geom_end_point FROM ".$selectedCity.".".$selectedCity."_cable_air  where  ".$selectedCity."_cable_air.geom_end_point IS NOT NULL;
		 UPDATE TMP2 SET cubic_end_house_id = ".$selectedCity."_buildings.cubic_house_id, cubic_end_street=".$selectedCity."_buildings.cubic_street, cubic_end_house_num=".$selectedCity."_buildings.cubic_house  FROM ".$selectedCity.".".$selectedCity."_buildings  WHERE ".$selectedCity."_buildings.building_geom IS NOT NULL AND ".$selectedCity."_buildings.cubic_house_id IS NOT NULL AND ST_DWithin(TMP2.geom_end_point,".$selectedCity."_buildings.building_geom,3) is true;
		 UPDATE ".$selectedCity.".".$selectedCity."_cable_air SET cubic_end_house_id = TMP2.cubic_end_house_id, cubic_end_street=TMP2.cubic_end_street, cubic_end_house_num=TMP2.cubic_end_house_num  FROM TMP2 WHERE ".$selectedCity."_cable_air.geom_end_point=TMP2.geom_end_point;
		 drop table TMP2; 

		create temp table TMP1 as 
		SELECT  ".$selectedCity."_cable_air.cubic_start_house_entrance_num, ".$selectedCity."_cable_air.geom_start_point FROM ".$selectedCity.".".$selectedCity."_cable_air  where  ".$selectedCity."_cable_air.geom_start_point IS NOT NULL;
		 UPDATE TMP1 SET cubic_start_house_entrance_num=".$selectedCity."_entrances.cubic_entrance_number  FROM ".$selectedCity.".".$selectedCity."_entrances  WHERE ".$selectedCity."_entrances.geom IS NOT NULL AND ".$selectedCity."_entrances.cubic_house_id IS NOT NULL AND ST_DFullyWithin(TMP1.geom_start_point,".$selectedCity."_entrances.geom,5) is true;
		 UPDATE ".$selectedCity.".".$selectedCity."_cable_air SET  cubic_start_house_entrance_num=TMP1.cubic_start_house_entrance_num  FROM TMP1 WHERE ".$selectedCity."_cable_air.geom_start_point=TMP1.geom_start_point;
		 drop table TMP1;

		 create temp table TMP2 as 
		SELECT  ".$selectedCity."_cable_air.cubic_end_house_entrance_num, ".$selectedCity."_cable_air.geom_end_point FROM ".$selectedCity.".".$selectedCity."_cable_air  where  ".$selectedCity."_cable_air.geom_end_point IS NOT NULL;
		 UPDATE TMP2 SET cubic_end_house_entrance_num=".$selectedCity."_entrances.cubic_entrance_number  FROM ".$selectedCity.".".$selectedCity."_entrances  WHERE ".$selectedCity."_entrances.geom IS NOT NULL AND ".$selectedCity."_entrances.cubic_house_id IS NOT NULL AND ST_DFullyWithin(TMP2.geom_end_point,".$selectedCity."_entrances.geom,5) is true;
		 UPDATE ".$selectedCity.".".$selectedCity."_cable_air SET  cubic_end_house_entrance_num=TMP2.cubic_end_house_entrance_num  FROM TMP2 WHERE ".$selectedCity."_cable_air.geom_end_point=TMP2.geom_end_point;
		  drop table TMP2; 
		UPDATE ".$selectedCity.".".$selectedCity."_cable_air SET cable_type='optic' WHERE ".$selectedCity."_cable_air.geom_cable IS NOT NULL and ".$selectedCity."_cable_air.cable_type is NULL;  " ;
$result=pg_query($postgres, $cable_air_house_id);
	}
}

 ?>