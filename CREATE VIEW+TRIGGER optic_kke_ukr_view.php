<?PHP 
header('Content-Type: text/plain; charset=utf-8');
ini_set('display_errors', 1);
//подобные скрипты заливаю сюда \\\Secure FTP Connections\chernivtsi_inner_server\var\www\QGIS-Web-Client-master\site\php\test-zawer\
// запускаю в браузере так: http://10.112.129.170/qgis-ck/php/test-zawer/CREATE VIEW+TRIGGER optic_kke_ukr_view.php
$conn_string = "host=127.0.0.1 port=5432 dbname=postgres user=postgres password=Xjrjkzlrf30";
           $postgres = pg_connect($conn_string); // 
           if(!$postgres){
                    echo "Error : Unable to open database\n";
                    } 
            else {
                 echo "Opened database successfully\n";
                                }
         
  $cities=array('bilatserkva','cherkassy','chernivtsi','chortkiv','dnipro','dobrotvir','fastiv','ivanofrankivsk','kharkiv', 'kherson', 'khmelnitsky','kiev','kramatorsk','kremenets','kropyvnytskyi','kryvyirih','lutsk','lviv','melitopol','novomoskovsk', 'obukhiv','poltava','putyvl','rivne','solonitsevka','stebnyk','sumy','terebovlya','ternopil','truskavets','ukrainka','vinnitsa','volochisk','zaporizhia','zhitomir');
  
//////$cities=array('fastiv');

////цикл для перебора гордов из массива
if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";

//".$selectedCity.".".$selectedCity."

$del_view ="  DROP  VIEW 
".$selectedCity.".".$selectedCity."_optic_kke_ukr_view_new  ;
";  // 
$result=pg_query($postgres, $del_view); 

$ctv_view = "CREATE OR REPLACE VIEW ".$selectedCity.".".$selectedCity."_optic_kke_ukr_view_new AS 
  SELECT 
    id,
    geom_cable AS geom_cable,
    table_id AS table_id,

    cable_short_type_description AS кільк_волокон,
    cable_description AS марка_кабелю_по_договору,
    cable_description_fact AS марка_кабелю_по_факту,
    cable_diameter AS діаметр_по_договору,
    contract_chanel_length AS довжина_по_договору_км,
    cable_length_house AS довжина_по_будинку_км,
    other_contract_channel_length AS довжина_інший_власник_км,
    total_cable_length AS загальна_довжина_факт_км,
    (st_length(geom_cable) / 1000::double precision)::numeric(6,3) AS довжина_по_карті_км,

    tu_number AS номер_ТУ, 
    tu_date AS дата_ТУ,
    rental_contract_new_num AS номер_договору,
    rental_contract_new_date AS дата_договору,  
    rental_contract_new_add_num AS номер_ДУ_додатку, 
    rental_contract_new_add_date AS дата_ДУ_додатку, 
    acceptance_act_num AS номер_Акту_опосвідчення,
    acceptance_act_date AS дата_Акту_опосвідчення,
    cartogram_num AS номер_картограми_УТ,
    cartogram_date AS дата_картограми_УТ,
    approval_cartogram_num AS номер_погодження_УТ,
    approval_cartogram_date AS дата_погодження_УТ,
    cable_ukrtelefon_id As ID_кабелю_в_УТ,
    
    progect_number AS номер_проекту,
    executive_doc_state AS виконавча_документація,
    cable_mount_date AS рік_прокладання,

    rental_contract_old_num AS номер_старого_договору,
    rental_contract_old_date AS дата_старого_договору,  
    rental_contract_old_add_num AS номер_старої_ДУ_додатку, 
    rental_contract_old_add_date AS дата_старої_ДУ_додатку, 

    contract_start_address AS Початкова_адреса_по_договору,
    contract_start_pit AS Початковий_ТК_по_договору,
    contract_end_address AS Кінцева_адреса_по_договору,
    contract_end_pit AS Кінцевий_ТК_по_договору,
    summ_route_description as ділянка_по_контракту,
    notes1 AS власник_кк,
    notes2 AS статус,
    rezerve1 AS примітки1,
    rezerve2 AS примітки2,
    rezerve3 AS ПГС,
    summ_archive_link AS посилання_на_документи,

    CASE
            WHEN cubic_start_street IS NULL THEN NULL
            ELSE concat(cubic_start_street, ', ', cubic_start_house_num) 
            END AS початкова_адреса_по_карті,
    CASE
            WHEN cubic_end_street IS NULL THEN NULL
            ELSE concat(cubic_end_street, ', ', cubic_end_house_num) 
    END AS кінцева_адреса_по_карті,

    cubic_code_start AS code_start,
        CASE
            WHEN cubic_coment_start IS NULL THEN cubic_name_start::text
            ELSE concat(cubic_name_start, ' (', cubic_coment_start, ')')
        END AS початковий_бокс,
    cubic_code_end AS code_end,
        CASE
            WHEN cubic_coment_end IS NULL THEN cubic_name_end::text
            ELSE concat(cubic_name_end, ' (', cubic_coment_end, ')')
        END AS кінцевий_бокс
   FROM ".$selectedCity.".".$selectedCity."_cable_channels c
  WHERE geom_cable IS NOT NULL OR contract_chanel_length IS NOT NULL OR tu_number IS NOT NULL OR rental_contract_new_num IS NOT NULL;
  COMMENT ON VIEW ".$selectedCity.".".$selectedCity."_optic_kke_ukr_view_new IS 'нова робоча вьюшка(демка)'
   ";
  
  $result=pg_query($postgres, $ctv_view);  //продумать все поля

/*
$del_grant="
REVOKE ALL ON ".$selectedCity.".".$selectedCity."_optic_kke_ukr_view_new FROM simpleuser;
$result=pg_query($postgres, $del_grant);//отобрать права 
*/

$create_grant =" 
GRANT ALL  ON ".$selectedCity.".".$selectedCity."_optic_kke_ukr_view_new TO simpleuser;
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_optic_kke_ukr_view_new TO simplereader;
";

$result=pg_query($postgres, $create_grant);//предоставить права 

 $query = "
 CREATE TRIGGER optic_kke_ukr_new INSTEAD OF INSERT OR UPDATE OR DELETE ON ".$selectedCity.".".$selectedCity."_optic_kke_ukr_view_new  FOR EACH ROW EXECUTE PROCEDURE  public.optic_kke_ukr_new();  " ;   
    echo $query.'<hr>'; 
    $result=pg_query($postgres, $query);# см файл FUNCTION optic_kke_ukr_new для триггер INSTEAD OF 

// добавим значение table_id по умолчанию на вьюшку
$fun =" CREATE OR REPLACE FUNCTION ".$selectedCity.".".$selectedCity."_MIN_table_id_VOK_KKE() RETURNS varchar(7) LANGUAGE SQL AS
  $$ 
  SELECT 't_'||left('00000',(5-length(tmp.id::varchar(5))))||tmp.id FROM (SELECT min(right(table_id, 5)::int) as id 
FROM  ".$selectedCity.".".$selectedCity."_cable_channels   where geom_cable is NULL AND tu_number is NULL  AND contract_chanel_length is NULL) tmp;  
 $$;

  Alter VIEW ".$selectedCity.".".$selectedCity."_optic_kke_ukr_view_new
  Alter  COLUMN  table_id SET DEFAULT ".$selectedCity.".".$selectedCity."_MIN_table_id_VOK_KKE(); 
  " ;
$result=pg_query($postgres, $fun); // вот этот default  на вьюшку вроде как добавил нужно ещё потестить.
  }
}

?>
