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
//    http://10.112.129.170/qgis-ck/php/test-zawer/CREATE VIEW+Triger _cable_air_ukr.php

$cities=array('bilatserkva','cherkassy','chernivtsi','chortkiv','dnipro','dobrotvir','fastiv','ivanofrankivsk','kharkiv', 'kherson', 'khmelnitsky','kiev','kramatorsk','kremenets','kropyvnytskyi','kryvyirih','lutsk','lviv','melitopol','novomoskovsk', 'obukhiv','poltava','putyvl','rivne','solonitsevka','stebnyk','sumy','terebovlya','ternopil','truskavets','ukrainka','vinnitsa','volochisk','zaporizhia','zhitomir');

/////$cities=array('fastiv');

if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";

  // ".$selectedCity.".".$selectedCity."_
 
      #$alter ="   COMMENT ON TABLE ".$selectedCity.".".$selectedCity."_  IS '[[[[]]]]]';    COMMENT ON COLUMN ".$selectedCity.".".$selectedCity."_ IS '[[[]]]]]';  ";   $result=pg_query($postgres, $alter);  # 


$box_view = "Drop view  if exists ".$selectedCity.".".$selectedCity."_optic_VKP_air_ukr_view ;
           
             ";
$result=pg_query($postgres, $box_view);

# заметил следующее: простым REPLACE поля местами не меняються
$view = "
 CREATE OR REPLACE VIEW ".$selectedCity.".".$selectedCity."_optic_VKP_air_ukr_view AS 
SELECT id, 
geom_cable as geom_cable, 
table_id as table_id, 
cable_short_type_description as кільк_волокон,
total_cable_length as довжина_км,
cable_description as марка_кабелю, 
progect_number  as номер_проекту, 
cable_progect_link  as  посилання_на_проект,
cable_mount_date  as рік_прокладання, 
cable_purpose  as призначення,
rezerve1 as примітки,
notes2  as примітки2, 

-- cable_type as тип_кабелю, 
(ST_length(geom_cable)/1000)::decimal(6,3) as Lmap_км,
CONCAT(cubic_start_street,', ',cubic_start_house_num ,' п.',cubic_start_house_entrance_num)  as початкова_адреса , 
CONCAT(cubic_end_street,', ',cubic_end_house_num ,' п.',cubic_end_house_entrance_num)  as кінцева_адреса , 
cubic_code_start as code_start, 
CASE WHEN cubic_coment_start IS NULL THEN  cubic_name_start ELSE  CONCAT(cubic_name_start,' (',cubic_coment_start,')') END as початковий_бокс, 
cubic_code_end as code_end, 
CASE WHEN cubic_coment_end IS NULL THEN  cubic_name_end ELSE  CONCAT(cubic_name_end,' (',cubic_coment_end,')') END   as кінцевий_бокс

  FROM ".$selectedCity.".".$selectedCity."_cable_air c
  WHERE geom_cable is NOT NULL  ;
  " ;
$result=pg_query($postgres, $view); 

//если заполняем table_id как NULL и  DEAFALT НЕ срабатывает!

$grant =" 
GRANT ALL ON ".$selectedCity.".".$selectedCity."_optic_VKP_air_ukr_view TO simpleuser; 
GRANT SELECT ON ".$selectedCity.".".$selectedCity."_optic_VKP_air_ukr_view  TO simplereader;
 ";
  $result=pg_query($postgres, $grant);

 #$query = "DROP TRIGGER IF EXISTS  optic_VKP_air_ukr ON ".$selectedCity.".".$selectedCity."_optic_VKP_air_ukr_view;" ;   echo $query.'<hr>';    $result=pg_query($postgres, $query);
// вот тут даже имя не  менять  только функцию переделать как в ККЕ Issues95
 $query = "
 CREATE TRIGGER optic_VKP_air_ukr INSTEAD OF INSERT OR UPDATE OR DELETE ON ".$selectedCity.".".$selectedCity."_optic_VKP_air_ukr_view  FOR EACH ROW EXECUTE PROCEDURE  public.optic_VKP_air_ukr_new();  " ;   
    echo $query.'<hr>'; 
    $result=pg_query($postgres, $query);# см файл FUNCTION optic_VKP_air_ukr_new  для триггер (INSTEAD OF).sql
 
 $fun =" CREATE OR REPLACE FUNCTION ".$selectedCity.".".$selectedCity."_MIN_table_id_VOK_VKP() RETURNS varchar(7) LANGUAGE SQL AS
  $$ 
  SELECT 't_'||left('00000',(5-length(tmp.id::varchar(5))))||tmp.id FROM (SELECT min(right(table_id, 5)::int) as id 
FROM  ".$selectedCity.".".$selectedCity."_cable_air   where geom_cable is NULL) tmp;  
 $$;

  Alter VIEW ".$selectedCity.".".$selectedCity."_optic_VKP_air_ukr_view
  Alter  COLUMN  table_id SET DEFAULT ".$selectedCity.".".$selectedCity."_MIN_table_id_VOK_VKP(); 
  " ;
$result=pg_query($postgres, $fun); // вот этот default  на вьюшку вроде как добавил нужно ещё потестить.

       }
}
?>

