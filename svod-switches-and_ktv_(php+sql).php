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
  
/*
$drop_tables ="drop table IF EXISTS svod.switches_model_and_status_cities, svod.switches_status_cities, svod.switches_status_company, svod.switches_model_working_cities, svod.switches_type_working_cities, svod.switches_working_company;";
$result=pg_query($postgres, $drop_tables); //удаляем таблицы для теста
*/

//обновляем  таблицы ниже раз в сутки
/*
switches_model_and_status_cities - все зарегистрированые, группировка по моделям и статусу(украден/на складе/на сети)  внутри города
switches_status_cities    - все зарегистрированые, группировка по статусу (украден/на складе/на сети) внутри города
switches_status_company   - все зарегистрированые, группировка статус (украден/на складе/на сети)  компания в целом

switches_model_working_cities - только рабочие, группировка рабочих комутаторов по моделям внутри города
switches_type_working_cities  - только рабочие, группировка   по типу (агрегация/доступ) внутри города
switches_working_company      - только рабочие, все рабочие по городам
*/

$create_tables ="
    create table IF NOT EXISTS svod.switches_model_and_status_cities (id serial PRIMARY KEY, city varchar(100), switch_model varchar(100),  status varchar(100),  Suma integer);
    create table IF NOT EXISTS svod.switches_status_cities (id serial PRIMARY KEY, city varchar(100),  status varchar(100),  Suma integer);
    create table IF NOT EXISTS svod.switches_status_company (id serial PRIMARY KEY,  status varchar(100),  Suma integer);

    create table IF NOT EXISTS svod.switches_model_working_cities (id serial PRIMARY KEY, city varchar(100), switch_model varchar(100),   Suma integer);
    create table IF NOT EXISTS svod.switches_type_working_cities (id serial PRIMARY KEY, city varchar(100), dev_type varchar(100),    Suma integer);
    create table IF NOT EXISTS svod.switches_working_company (id serial PRIMARY KEY,  city varchar(100),  Suma integer);

    create table IF NOT EXISTS svod.ktv_type_cities (id serial PRIMARY KEY, city varchar(100), ktv_type varchar(100),   Suma integer);
    create table IF NOT EXISTS svod.ktv_type_company (id serial PRIMARY KEY,  ktv_type varchar(100),   Suma integer);
 ";
$result=pg_query($postgres, $create_tables); //



$create_grant ="
GRANT ALL ON svod.switches_model_and_status_cities TO simpleuser;
GRANT ALL ON svod.switches_status_cities TO simpleuser; 
GRANT ALL ON svod.switches_status_company TO simpleuser; 
GRANT ALL ON svod.switches_model_working_cities TO simpleuser; 
GRANT ALL ON svod.switches_type_working_cities TO simpleuser; 
GRANT ALL ON svod.switches_working_company TO simpleuser;
GRANT ALL ON svod.ktv_type_cities  TO simpleuser;
GRANT ALL ON svod.ktv_type_company  TO simpleuser;";
$result=pg_query($postgres, $create_grant);//предоставить права

$clear_tables ="DELETE FROM svod.switches_model_and_status_cities; DELETE FROM svod.switches_status_cities; DELETE FROM svod.switches_status_company; DELETE FROM svod.switches_model_working_cities; DELETE FROM svod.switches_type_working_cities; DELETE FROM svod.switches_working_company ; DELETE FROM svod.ktv_type_cities; DELETE FROM svod.ktv_type_company;";
$result=pg_query($postgres, $clear_tables); //очистка таблиц онлайн  



////цикл для перебора гордов из массива
if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";

$insert_sw ="
  INSERT INTO svod.switches_model_and_status_cities (city, switch_model, status, Suma)  SELECT city, switch_model,  status, COUNT(switch_model) as Suma  FROM ".$selectedCity.".".$selectedCity."_switches_all group by city, status, switch_model order by  status, switch_model;

  INSERT INTO svod.switches_status_cities (city,  status, Suma)  SELECT city,  status, COUNT(status) as Suma  FROM ".$selectedCity.".".$selectedCity."_switches_all group by city, status  order by  status; 

  INSERT INTO svod.switches_model_working_cities (city, switch_model,  Suma)  SELECT city, switch_model,   COUNT(switch_model) as Suma  FROM ".$selectedCity.".".$selectedCity."_switches_working group by city,  switch_model order by   switch_model;

  INSERT INTO svod.switches_type_working_cities (city, dev_type,  Suma)  SELECT city, dev_type,   COUNT(dev_type) as Suma  FROM ".$selectedCity.".".$selectedCity."_switches_working group by city,  dev_type order by   dev_type;

  INSERT INTO svod.ktv_type_cities (city, ktv_type,  Suma)  SELECT cubic_city, cubic_name,   COUNT(cubic_name) as Suma  FROM ".$selectedCity.".".$selectedCity."_ctv_topology group by cubic_city,  cubic_name order by  cubic_name;
      ";  // 
$result=pg_query($postgres, $insert_sw); 
    }
}
// выполняем без цикла на основе готовых таблиц
$insert_company = "
INSERT INTO svod.switches_status_company (status, Suma)  SELECT  status, sum(Suma) as Suma_company  FROM svod.switches_status_cities  group by  status order by  status;
  INSERT INTO svod.switches_working_company (city, Suma)  SELECT  city, sum(Suma) as Suma_company  FROM svod.switches_model_working_cities  group by  city order by  city;
  INSERT INTO svod.ktv_type_company (ktv_type, Suma)  SELECT  ktv_type, sum(Suma) as Suma_company  FROM svod.ktv_type_cities  group by  ktv_type order by  ktv_type;";
$result=pg_query($postgres, $insert_company); 

?>
