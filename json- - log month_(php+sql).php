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

//$jsonString = file_get_contents('/var/www/QGIS-Web-Client-master/site/csv/cubic/_hybrids_measurement/hybriddata.json');  //тут я сохраняю локальный пример json если URL (от Яценко Юры) не работает
/*
$url = 'http://ssc.volia.net/api/gis/data.json';   //запускаем каждые 15мин когда стабильно будет работать URL 
$jsonString  = file_get_contents($url);           //запускаем каждые 15мин когда стабильно будет работать URL


$jsonDecoded = json_decode($jsonString, true);
$linkStorage = "/var/www/QGIS-Web-Client-master/site/tmp/hybrids_measurement.csv"; // у PHP  НЕТ доступа на запись сюда /var/www/QGIS-Web-Client-master/site/csv/cubic/_hybrids_measurement/ 
 
$fp = fopen($linkStorage, 'w');
foreach($jsonDecoded as $row){
        fputcsv($fp, $row);
}
fclose($fp);
echo 'csv from json DONE '. "\n".$linkStorage. "\n"; // полученные данные из json  сохраняю как csv
  */             
  
$cities=array('bilatserkva','cherkassy','chernivtsi','chortkiv','dnipro','dobrotvir','fastiv','ivanofrankivsk','kharkiv', 'kherson', 
  'khmelnitsky','kiev','kramatorsk','kremenets','kropyvnytskyi','kryvyirih','lutsk','lviv','melitopol','novomoskovsk', 'obukhiv','poltava','putyvl','rivne','solonitsevka','stebnyk','sumy','terebovlya','ternopil','truskavets','ukrainka','vinnitsa','volochisk','zaporizhia','zhitomir');
  
//список городов нуно брать отсюда: public.links атрибут city_eng ///////// создать нормльный массив из этого линка я не смог ПРОБЛЕМУ лучше решить


$createTMP ="create temp table TMP (mac varchar(20),freq varchar(10), level varchar(10), snr varchar(10), ber varchar(10), ts double precision); COPY TMP FROM '/var/www/QGIS-Web-Client-master/site/tmp/hybrids_measurement.csv' WITH (FORMAT csv);  ";
$resultTMP=pg_query($postgres, $createTMP); //


////цикл для перебора гордов из массива
if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";

/*$drop_hybrids_online ="drop table IF EXISTS ".$selectedCity.".".$selectedCity."_hybrids_online;";
$result=pg_query($postgres, $drop_hybrids_online); //удаляем таблицы для теста*/


$create_hybrids_log_month ="create table IF NOT EXISTS ".$selectedCity.".".$selectedCity."_hybrids_log_month (city varchar(20), house_id  varchar(20), street varchar(100), house varchar(20), sector varchar(20), flat varchar(20), mac varchar(20), serial varchar(20), technology_name varchar(20), link varchar(100), equipment_geom geometry,   equipment_level varchar(20), equipment_snr varchar(20), equipment_frequency varchar(20), equipment_modulation varchar(20),  equipment_update_time timestamp with time zone);";
$result=pg_query($postgres, $create_hybrids_log_month); //ВНИМАНИЕ !!!  в json поле называеться mac а в БД КУБИК - это поле называеться serial (см таблицу [city]_hybrids) )

$insert_hybrids_log_month ="INSERT INTO ".$selectedCity.".".$selectedCity."_hybrids_log_month (serial, equipment_level, equipment_snr, equipment_frequency,  equipment_update_time) SELECT TMP.mac, TMP.level, TMP.snr, TMP.freq, to_timestamp(TMP.ts)::timestamp with time zone FROM TMP WHERE TMP.mac IN (SELECT ".$selectedCity.".".$selectedCity."_hybrids.serial FROM ".$selectedCity.".".$selectedCity."_hybrids); ";  ///  потом(когда Яценко добавит в json) нужно добавить поле modulation  //ВНИМАНИЕ !!!  в json поле называеться mac а в БД КУБИК - это поле называеться serial (см таблицу [city]_hybrids) )
$result=pg_query($postgres, $insert_hybrids_log_month); //вставляем данные мониторинга  в таблицу [city]_hybrids-online (каждые 15мин) 

$clear_hybrids_log_month ="DELETE FROM ".$selectedCity.".".$selectedCity."_hybrids_log_month WHERE (now()::timestamp - equipment_update_time::timestamp) >'1 month'::interval;"; //вроде нормально, но нужно проверить 
$result=pg_query($postgres, $clear_hybrids_log_month); //очистка таблиц log   (каждые 15мин?)

$update_hybrids_log_month ="UPDATE ".$selectedCity.".".$selectedCity."_hybrids_log_month set city=".$selectedCity.".".$selectedCity."_hybrids.city, house_id=".$selectedCity.".".$selectedCity."_hybrids.house_id, street=".$selectedCity.".".$selectedCity."_hybrids.street, house=".$selectedCity.".".$selectedCity."_hybrids.house, sector=".$selectedCity.".".$selectedCity."_hybrids.sector, flat=".$selectedCity.".".$selectedCity."_hybrids.flat,mac=".$selectedCity.".".$selectedCity."_hybrids.mac, technology_name=".$selectedCity.".".$selectedCity."_hybrids.technology_name, equipment_geom=".$selectedCity.".".$selectedCity."_hybrids.equipment_geom, link=".$selectedCity.".".$selectedCity."_hybrids.link                 FROM ".$selectedCity.".".$selectedCity."_hybrids WHERE ".$selectedCity.".".$selectedCity."_hybrids_log_month.serial=".$selectedCity.".".$selectedCity."_hybrids.serial;"; 
$result=pg_query($postgres, $update_hybrids_log_month);//вставляем другие необходимые поля  в таблицу [city]_hybrids-online (каждые 15мин) из таблиц  [city]_hybrids

    }
}

?>
