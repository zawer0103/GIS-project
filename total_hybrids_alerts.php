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
  
//список городов нуно брать отсюда: public.links атрибут city_eng ///////// 
// у PHP  НЕТ доступа на запись сюда /var/www/QGIS-Web-Client-master/site/csv/cubic/_hybrids_measurement/ 

chmod("/var/www/QGIS-Web-Client-master/site/tmp/hybrids_alerts/",0777);

if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";
      $linkStorage_month = "/var/www/QGIS-Web-Client-master/site/tmp/hybrids_alerts/".$selectedCity."_hybrids_alerts_month.csv"; //сводные данные по алярмам за месяц // тут кавычки двойные       
      $total_hybrids_alerts_month ="COPY (select ttt.city, ttt.house_id, ttt.street, ttt.house, ttt.sector, ttt.flat, ttt.serial as mac_S, ttt.technology_name, ttt.QAM, MAX(count7) + MAX(count9) as alarm_per_month from 
(select  city, house_id, street, house, sector, flat, serial , technology_name, 2^(equipment_modulation::decimal-1) as QAM, count(*) as count7, 0 as count9
   from ".$selectedCity.".".$selectedCity."_hybrids_log_month where equipment_snr::decimal<28 and equipment_modulation='7'  group by city, house_id, street, house, sector, flat, serial , technology_name, QAM
UNION ALL
 select  city, house_id, street, house, sector, flat, serial , technology_name,  2^(equipment_modulation::decimal-1) as QAM, 0, count(*)   from ".$selectedCity.".".$selectedCity."_hybrids_log_month where equipment_snr::decimal<30 and equipment_modulation='9'
group by city, house_id, street, house, sector, flat, serial , technology_name, QAM ) as ttt

group by city, house_id, street, house, sector, flat, serial , technology_name, QAM
order by alarm_per_month DESC) TO  '".$linkStorage_month."'  WITH CSV HEADER DELIMITER ';' encoding 'win1251' ; "; // DELIMITER ';'  encoding 'win1251'- Хорошо дружит с екселем "   тут кавычки двойные - это внедрение перменной, одинарыне - это путь
$result=pg_query($postgres, $total_hybrids_alerts_month); //  сводный отчёт за месяц _hybrids_log_month
 


 /// может нужно переделать этот COPY на PHP иначе вылазит writing: Permission denied
    /// пример тут https://stackoverflow.com/questions/20156148/write-postgres-output-to-a-file-using-php


      $linkStorage_day = "/var/www/QGIS-Web-Client-master/site/tmp/hybrids_alerts/".$selectedCity."_hybrids_alerts_day.csv"; //сводные данные по алярмам  // тут кавычки двойные
            
      $total_hybrids_alerts_day ="COPY (select ttt.city, ttt.house_id, ttt.street, ttt.house, ttt.sector, ttt.flat, ttt.serial as mac_S, ttt.technology_name, ttt.QAM, MAX(count7) + MAX(count9) as alarm_per_day from 
(select  city, house_id, street, house, sector, flat, serial , technology_name, 2^(equipment_modulation::decimal-1) as QAM, count(*) as count7, 0 as count9   from ".$selectedCity.".".$selectedCity."_hybrids_log_day where equipment_snr::decimal<28 and equipment_modulation='7'  group by city, house_id, street, house, sector, flat, serial , technology_name, QAM
UNION ALL
 select  city, house_id, street, house, sector, flat, serial , technology_name,  2^(equipment_modulation::decimal-1) as QAM, 0, count(*)   from ".$selectedCity.".".$selectedCity."_hybrids_log_day where equipment_snr::decimal<30 and equipment_modulation='9'
group by city, house_id, street, house, sector, flat, serial , technology_name, QAM ) as ttt

group by city, house_id, street, house, sector, flat, serial , technology_name, QAM
order by alarm_per_day DESC) TO   '".$linkStorage_day."'  WITH CSV HEADER DELIMITER ';' encoding 'win1251' ; "; // DELIMITER ';'  encoding 'win1251'- Хорошо дружит с екселем "   тут кавычки двойные - это внедрение перменной, одинарыне - это путь
$result2=pg_query($postgres, $total_hybrids_alerts_day); //  сводный отчёт за день _hybrids_log_day
/**/

// -------------------------------------------- FULL -------------------------------------------------------------//
$linkStorage_month_full = "/var/www/QGIS-Web-Client-master/site/tmp/hybrids_alerts/".$selectedCity."_hybrids_alerts_month_full.csv"; //развёрнутый отчёт о мониторинге (сюда запишем все измерения с алярмами)
$setnull="update ".$selectedCity.".".$selectedCity."_hybrids_log_month set equipment_modulation ='0' where equipment_modulation=''";
$resultnull=pg_query($postgres, $setnull); //////////// были пустые данные не NULL

      $total_hybrids_alerts_month_full = "COPY (select city, house_id, street, house, sector, flat, mac, serial as mac_S, technology_name, equipment_level as level, equipment_snr as SNR, equipment_frequency as freq, 2^(equipment_modulation::decimal -1) as QAM, equipment_update_time as update_time 
from ".$selectedCity.".".$selectedCity."_hybrids_log_month where equipment_snr::decimal<28  and equipment_modulation='7'
UNION
select city, house_id, street, house, sector, flat, mac, serial as mac_S, technology_name, equipment_level as level, equipment_snr as SNR, equipment_frequency as freq, 2^(equipment_modulation::decimal -1) as QAM, equipment_update_time as update_time 
from ".$selectedCity.".".$selectedCity."_hybrids_log_month where equipment_snr::decimal<30  and equipment_modulation='9'
UNION
select city, house_id, street, house, sector, flat, mac, serial as mac_S, technology_name, equipment_level as level, equipment_snr as SNR, equipment_frequency as freq, 2^(equipment_modulation::decimal -1) as QAM, equipment_update_time as update_time 
from ".$selectedCity.".".$selectedCity."_hybrids_log_month where equipment_level::decimal<47 and mac NOT IN (select mac 
from ".$selectedCity.".".$selectedCity."_hybrids_log_month where equipment_snr::decimal<30  and equipment_modulation='9')

group by city, house_id, street, house, sector, flat, mac, serial, technology_name, equipment_level, equipment_snr, equipment_frequency, equipment_modulation, equipment_update_time
order by  mac_S,  update_time) TO '".$linkStorage_month_full."'  WITH CSV HEADER DELIMITER ';' encoding 'win1251' ;" ;
$result3=pg_query($postgres, $total_hybrids_alerts_month_full); //развёрнутый отчёт о мониторинге за месяц 


$linkStorage_day_full = "/var/www/QGIS-Web-Client-master/site/tmp/hybrids_alerts/".$selectedCity."_hybrids_alerts_day_full.csv"; //развёрнутый отчёт о мониторинге за сутки (сюда запишем все измерения с алярмами)
      $total_hybrids_alerts_day_full = "COPY (select city, house_id, street, house, sector, flat, mac, serial as mac_S, technology_name, equipment_level as level, equipment_snr as SNR, equipment_frequency as freq, 2^(equipment_modulation::decimal -1) as QAM, equipment_update_time as update_time 
from ".$selectedCity.".".$selectedCity."_hybrids_log_day where equipment_snr::decimal<28  and equipment_modulation='7'
UNION
select city, house_id, street, house, sector, flat, mac, serial as mac_S, technology_name, equipment_level as level, equipment_snr as SNR, equipment_frequency as freq, 2^(equipment_modulation::decimal -1) as QAM, equipment_update_time as update_time 
from ".$selectedCity.".".$selectedCity."_hybrids_log_day where equipment_snr::decimal<30  and equipment_modulation='9'
UNION
select city, house_id, street, house, sector, flat, mac, serial as mac_S, technology_name, equipment_level as level, equipment_snr as SNR, equipment_frequency as freq, 2^(equipment_modulation::decimal -1) as QAM, equipment_update_time as update_time 
from ".$selectedCity.".".$selectedCity."_hybrids_log_day where equipment_level::decimal<47 and mac NOT IN (select mac 
from ".$selectedCity.".".$selectedCity."_hybrids_log_day where equipment_snr::decimal<30  and equipment_modulation='9')

group by city, house_id, street, house, sector, flat, mac, serial, technology_name, equipment_level, equipment_snr, equipment_frequency, equipment_modulation, equipment_update_time
order by  mac_S,  update_time) TO '".$linkStorage_day_full."'  WITH CSV HEADER DELIMITER ';' encoding 'win1251' ; " ;
$result4=pg_query($postgres, $total_hybrids_alerts_day_full);//развёрнутый отчёт о мониторинге за сутки 

/**/
    
// установлено єкспериментальным путём что при SNR<30 и/или Уровне сигнала (equipment_level) <47дБмкВ на QAM256 сыпится картинка
      }
}

?>
