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

$cities_for_test=array('cherkassy','chernivtsi','dnipro','ivanofrankivsk','kharkiv', 'kherson', 'khmelnitsky', 'kramatorsk','kropyvnytskyi','kryvyirih','lutsk','lviv','melitopol','novomoskovsk', 'obukhiv','poltava','putyvl','rivne','stebnyk','sumy','ternopil','truskavets','ukrainka','volochisk','zaporizhia','zhitomir');
  
//список городов нуно брать отсюда: public.links атрибут city_eng ///////// 
// у PHP  НЕТ доступа на запись сюда /var/www/QGIS-Web-Client-master/site/csv/cubic/_hybrids_measurement/ 

mkdir("/var/www/QGIS-Web-Client-master/site/tmp/switch-ports-optimization",0777) ;
chmod("/var/www/QGIS-Web-Client-master/site/tmp/switch-ports-optimization/",0777); // без этой команды нихрена не записывает в папку
//нихрена не понимаю: если файлы были созданы ранее, то перезаписывать их не хочет

if (is_array($cities_for_test) || is_object($cities_for_test))
{
    foreach ($cities_for_test as $city)
    {
          $selectedCity = $city;
  echo $city."\n";
      
      $linkStorage_no_free = "/var/www/QGIS-Web-Client-master/site/tmp/switch-ports-optimization/".$selectedCity."_sw_NO_free_ports.csv"; //
      $sw_NO_free_ports ="COPY (SELECT ".$selectedCity.".".$selectedCity."_switches_working.city, ".$selectedCity.".".$selectedCity."_switches_working.address, ".$selectedCity.".".$selectedCity."_switches_working.doorway, ".$selectedCity.".".$selectedCity."_switches_working.floor, ".$selectedCity.".".$selectedCity."_switches_working.dev_name, ".$selectedCity.".".$selectedCity."_switches_working.mac_address, ".$selectedCity.".".$selectedCity."_switches_working.switch_model, ".$selectedCity.".".$selectedCity."_switches_working.cubic_switch_contract_active_cnt,   _city_hlam.switch_katalog.ports_ALL,  _city_hlam.switch_katalog.ports_ACC, (_city_hlam.switch_katalog.ports_ACC-".$selectedCity.".".$selectedCity."_switches_working.cubic_switch_contract_active_cnt::int) as ports_free FROM ".$selectedCity.".".$selectedCity."_switches_working   LEFT JOIN  _city_hlam.switch_katalog ON ".$selectedCity.".".$selectedCity."_switches_working.switch_model=CONCAT( _city_hlam.switch_katalog.vendor,' ',_city_hlam.switch_katalog.model) WHERE  _city_hlam.switch_katalog.type='acc' and (_city_hlam.switch_katalog.ports_ACC-".$selectedCity.".".$selectedCity."_switches_working.cubic_switch_contract_active_cnt::int)<2  ORDER BY ".$selectedCity.".".$selectedCity."_switches_working.address ) TO  '".$linkStorage_no_free."'  WITH CSV HEADER DELIMITER ';' encoding 'win1251' ; "; //// тут кавычки двойные - это внедрение перменной, одинарные - это путь к файлу
      $result=pg_query($postgres, $sw_NO_free_ports); 
      
      /////////////////////////////////////////////////
     
       /*
        $sw_MANY_free_ports ="COPY (SELECT ".$selectedCity.".".$selectedCity."_switches_working.city, ".$selectedCity.".".$selectedCity."_switches_working.address, ".$selectedCity.".".$selectedCity."_switches_working.doorway, ".$selectedCity.".".$selectedCity."_switches_working.floor, ".$selectedCity.".".$selectedCity."_switches_working.dev_name, ".$selectedCity.".".$selectedCity."_switches_working.mac_address, ".$selectedCity.".".$selectedCity."_switches_working.switch_model, ".$selectedCity.".".$selectedCity."_switches_working.cubic_switch_contract_active_cnt,   _city_hlam.switch_katalog.ports_ALL,  _city_hlam.switch_katalog.ports_ACC, (_city_hlam.switch_katalog.ports_ACC-".$selectedCity.".".$selectedCity."_switches_working.cubic_switch_contract_active_cnt::int) as ports_free FROM ".$selectedCity.".".$selectedCity."_switches_working  
          LEFT JOIN  _city_hlam.switch_katalog ON ".$selectedCity.".".$selectedCity."_switches_working.switch_model=CONCAT( _city_hlam.switch_katalog.vendor,' ',_city_hlam.switch_katalog.model) WHERE  _city_hlam.switch_katalog.type='acc' and (_city_hlam.switch_katalog.ports_ACC-".$selectedCity.".".$selectedCity."_switches_working.cubic_switch_contract_active_cnt::int)>22  ORDER BY ".$selectedCity.".".$selectedCity."_switches_working.address) TO  '".$linkStorage_many_free."'  WITH CSV HEADER DELIMITER ';' encoding 'win1251' ; ";  // этот запрос выводит все ком-ры без абонов. не учитывая занятость SFP-downlinks поэтому ниже более подробная выборка mac адрес отсутвует в parent-mac 
          */
       
        $linkStorage_many_free_new = "/var/www/QGIS-Web-Client-master/site/tmp/switch-ports-optimization/".$selectedCity."_sw_MANY_free_ports_new.csv"; //

        $sw_MANY_free_ports_new = " COPY (SELECT  DISTINCT  ".$selectedCity."_switches_working.address, ".$selectedCity."_switches.cubic_hostname, ".$selectedCity."_switches.cubic_mac_address, ".$selectedCity."_switches.cubic_switch_model, ".$selectedCity."_switches.cubic_switch_role, ".$selectedCity."_switches.cubic_switch_contract_active_cnt, ".$selectedCity."_switches.cubic_rgu, _city_hlam.switch_katalog.ports_ACC FROM ".$selectedCity.".".$selectedCity."_switches 
          LEFT JOIN  _city_hlam.switch_katalog ON ".$selectedCity."_switches.cubic_switch_model= _city_hlam.switch_katalog.model 
          LEFT JOIN  ".$selectedCity.".".$selectedCity."_switches_working ON ".$selectedCity."_switches.cubic_mac_address= ".$selectedCity."_switches_working.mac_address 
           WHERE ".$selectedCity."_switches.cubic_mac_address NOT IN (SELECT  DISTINCT ".$selectedCity."_switches.cubic_parent_mac_address FROM ".$selectedCity.".".$selectedCity."_switches)  AND ".$selectedCity."_switches.cubic_switch_contract_active_cnt::int<2 AND ".$selectedCity."_switches.cubic_rgu::int<2 AND ".$selectedCity."_switches.cubic_inventary_state ='Работает и установлен на обьекте' AND ".$selectedCity."_switches.cubic_switch_role='acc' AND _city_hlam.switch_katalog.ports_ACC::int>23 order by ".$selectedCity."_switches.cubic_switch_model) TO  '".$linkStorage_many_free_new."'  WITH CSV HEADER DELIMITER ';' encoding 'win1251' ; " ;//   получилась два lEFT JOIN 
           
              
      $result=pg_query($postgres, $sw_MANY_free_ports_new);       
      }
}
?>
    