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
  


////цикл для перебора гордов из массива
if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";

//".$selectedCity.".".$selectedCity."
/*
$del_view ="  DROP  VIEW 
".$selectedCity.".".$selectedCity."_ctv_opt_topology_VIEW,      
".$selectedCity.".".$selectedCity."_ctv_coax_topology_VIEW,
".$selectedCity.".".$selectedCity."_switches_topology_vlanNULL_VIEW,
".$selectedCity.".".$selectedCity."_switches_topology_VIEW,
".$selectedCity.".".$selectedCity."_build_NO_RGU_VIEW;  ";  // 
$result=pg_query($postgres, $del_view); 
*/


$ctv_view = "CREATE OR REPLACE VIEW ".$selectedCity.".".$selectedCity."_ctv_opt_topology_VIEW AS 
SELECT t1.id, t1.topology_line_geom, t1.cubic_street||', '||t1.cubic_house  as address, t1.cubic_code as code, t1.cubic_name as name, t1.cubic_coment as coment, t2.cubic_street||', '||t2.cubic_house as mother_address, t2.cubic_code as mother_code, t2.cubic_name as mother_name, t2.cubic_coment as mother_coment     FROM  ".$selectedCity.".".$selectedCity."_ctv_topology t1 
  INNER JOIN  ".$selectedCity.".".$selectedCity."_ctv_topology t2 on t1.cubic_ou_code=t2.cubic_code
  WHERE t2.cubic_name IN ('Передатчик оптический','Усилитель оптический','Магистральный распределительный узел','Магістральний оптичний вузол', 'Кросс-муфта') AND  t1.topology_line_geom IS NOT NULL;

  CREATE OR REPLACE VIEW ".$selectedCity.".".$selectedCity."_ctv_coax_topology_VIEW  AS 
 SELECT t1.id, t1.topology_line_geom, t1.cubic_street||', '||t1.cubic_house  as address, t1.cubic_code as code, t1.cubic_name as name, t1.cubic_coment as coment, t2.cubic_street||', '||t2.cubic_house as mother_address, t2.cubic_code as mother_code, t2.cubic_name as mother_name, t2.cubic_coment as mother_coment     FROM  ".$selectedCity.".".$selectedCity."_ctv_topology t1 
  INNER JOIN  ".$selectedCity.".".$selectedCity."_ctv_topology t2 on t1.cubic_ou_code=t2.cubic_code
  WHERE t2.cubic_name IN ( 'Блок питания','Домовой узел','Оптический узел',  'Ответвитель домовой',  'Ответвитель магистральный',  'Распределительный стояк', 'Оптичний приймач', 'Магистральный узел',  'Порт ОК' ) AND  t1.topology_line_geom IS NOT NULL;

CREATE OR REPLACE VIEW ".$selectedCity.".".$selectedCity."_build25_VIEW AS SELECT id, building_geom, openstreet_building_levels FROM ".$selectedCity.".".$selectedCity."_buildings WHERE building_geom IS NOT NULL AND openstreet_building_levels::decimal>2 ;

CREATE OR REPLACE VIEW ".$selectedCity.".".$selectedCity."_switches_topology_vlanNULL_VIEW AS
   SELECT DISTINCT on(t1.cubic_mac_address) t1.id, t1.topology_line_geom , t1.cubic_vlan, t1.cubic_street||', '||t1.cubic_house_num  as adress, t1.cubic_mac_address as mac,  t1.cubic_switch_model as switch_model, t1.cubic_switch_role as switch_role, t2.cubic_street||', '||t2.cubic_house_num  as parent_adress, t2.cubic_mac_address as parent_mac,  t2.cubic_switch_model as parent_switch_model, t2.cubic_switch_role as parent_switch_role  FROM ".$selectedCity.".".$selectedCity."_switches t1  
   INNER JOIN (SELECT DISTINCT on(cubic_mac_address) id, cubic_street, cubic_house_num, cubic_mac_address,cubic_switch_model,cubic_switch_role   FROM ".$selectedCity.".".$selectedCity."_switches) t2 ON t1.cubic_parent_mac_address=t2.cubic_mac_address
   WHERE t1.cubic_vlan IS NULL AND t1.topology_line_geom IS NOT NULL; 

CREATE OR REPLACE VIEW ".$selectedCity.".".$selectedCity."_switches_topology_VIEW AS 
 SELECT DISTINCT on(t1.cubic_mac_address) t1.id, t1.topology_line_geom , t1.cubic_vlan, t1.cubic_street||', '||t1.cubic_house_num  as adress, t1.cubic_mac_address as mac,  t1.cubic_switch_model as switch_model, t1.cubic_switch_role as switch_role, t2.cubic_street||', '||t2.cubic_house_num  as parent_adress, t2.cubic_mac_address as parent_mac,  t2.cubic_switch_model as parent_switch_model, t2.cubic_switch_role as parent_switch_role  FROM ".$selectedCity.".".$selectedCity."_switches t1  
   INNER JOIN (SELECT DISTINCT on(cubic_mac_address) id, cubic_street, cubic_house_num, cubic_mac_address,cubic_switch_model,cubic_switch_role   FROM ".$selectedCity.".".$selectedCity."_switches) t2 ON t1.cubic_parent_mac_address=t2.cubic_mac_address
   WHERE t1.cubic_vlan IS NOT NULL AND t1.topology_line_geom IS NOT NULL; 

CREATE OR REPLACE VIEW ".$selectedCity.".".$selectedCity."_build_NO_RGU_VIEW AS SELECT id, building_geom, cubic_city, cubic_street,cubic_house, cubic_hpname, cubic_network_type , cubic_house_type, cubic_cnt, cubic_cnt_eth, cubic_cnt_docsis, cubic_cnt_ktv,cubic_cnt_atv, cubic_cnt_active_contr,cubic_parnet, (round(cubic_cnt_active_contr::decimal/(cubic_cnt::decimal+0.1),2))::varchar(6)   as percent   FROM ".$selectedCity.".".$selectedCity."_buildings WHERE round(cubic_cnt_active_contr::decimal/(cubic_cnt::decimal+0.1),2)<0.05 AND cubic_network_type!='Off_net SMART HD'  AND  building_geom IS NOT NULL order by percent;
  ";
  // таким образом можно будет создать любые сводные таблицы-вьюшки (напр для ком-ров) 
  //  id 2697  not UNIC    SELECT * FROM chernivtsi.chernivtsi_switches where  cubic_mac_address='7072cf55376b'
  // наши таблицы _switches  - это полнный капец. если есть кольца то одни свич встречаеться в этой таблице 60 раз и вьюшка в лоб не делатеся - получаеться одинаковый id  нужно делать distinc  cubic_mac_address 
  ///---- без вот этого сравнения t3.id=t1.id нихрена не работает!!!
  #############// если есть distinct то нужно !!!  REFRESH MATERIALIZED VIEW [ CONCURRENTLY ] name   #####################################
  #############  //CREATE MATERIALIZED VIEW   
  ######### REFRESH MATERIALIZED VIEW chernivtsi.chernivtsi_switches_topology_view  ### ошибка  is not a table or materialized view

  $result=pg_query($postgres, $ctv_view); 


$del_grant="
REVOKE ALL ON ".$selectedCity.".".$selectedCity."_ctv_opt_topology_VIEW FROM simpleuser;
REVOKE ALL ON ".$selectedCity.".".$selectedCity."_ctv_coax_topology_VIEW  FROM simpleuser;
REVOKE ALL ON ".$selectedCity.".".$selectedCity."_build25_VIEW  FROM simpleuser;
REVOKE ALL ON ".$selectedCity.".".$selectedCity."_switches_topology_vlanNULL_VIEW  FROM simpleuser;
REVOKE ALL ON ".$selectedCity.".".$selectedCity."_switches_topology_VIEW  FROM simpleuser;
REVOKE ALL ON ".$selectedCity.".".$selectedCity."_build_NO_RGU_VIEW FROM simpleuser; " ;
$result=pg_query($postgres, $del_grant);//отобрать права 


$create_grant =" 
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_ctv_opt_topology_VIEW TO simpleuser;
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_ctv_coax_topology_VIEW  TO simpleuser;
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_build25_VIEW  TO simpleuser;
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_switches_topology_vlanNULL_VIEW  TO simpleuser;
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_switches_topology_VIEW  TO simpleuser;
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_build_NO_RGU_VIEW TO simpleuser;

GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_ctv_opt_topology_VIEW TO simplereader;
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_ctv_coax_topology_VIEW  TO simplereader;
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_build25_VIEW  TO simplereader;
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_switches_topology_vlanNULL_VIEW  TO simplereader;
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_switches_topology_VIEW  TO simplereader;
GRANT SELECT  ON ".$selectedCity.".".$selectedCity."_build_NO_RGU_VIEW TO simplereader;
";



$result=pg_query($postgres, $create_grant);//предоставить права 

//  ALTER TABLE chernivtsi.chernivtsi_switches ADD PRIMARY KEY (id);
//  ALTER TABLE chernivtsi.chernivtsi_ctv_topology ADD PRIMARY KEY (id);
//  ALTER TABLE chernivtsi.chernivtsi_buildings ADD PRIMARY KEY (id);
// ALTER VIEW chernivtsi.chernivtsi_build25_VIEW ADD PRIMARY KEY (id); -- не работает  с вьюшками  нет у вьюшек primary key!


  }
}

?>
