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
  
$cities=array('bilatserkva','cherkassy','chernivtsi','chortkiv','dnipro','dobrotvir','fastiv','ivanofrankivsk','kharkiv', 'kherson', 'khmelnitsky','kiev','kramatorsk','kremenets','kropyvnytskyi','kryvyirih','lutsk','lviv','melitopol','novomoskovsk', 'obukhiv','poltava','putyvl','rivne','solonitsevka','stebnyk','sumy','terebovlya','ternopil','truskavets','ukrainka','vinnitsa','volochisk','zaporizhia','zhitomir');


if (is_array($cities) || is_object($cities))
{
    foreach ($cities as $city)
    {
          $selectedCity = $city;
  echo $city."\n";

  // ".$selectedCity.".".$selectedCity."_
  
    $alter =" ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_air ADD CONSTRAINT unic_id_air  UNIQUE  (table_id);  ";
    $result=pg_query($postgres, $alter);  # table for optical cable

    $alter =" ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_air_coax ADD CONSTRAINT unic_id_air_coax  UNIQUE  (table_id);  ";
    $result=pg_query($postgres, $alter);  
    

   $alter =" ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_air_cable_geom ADD CONSTRAINT table_key_air  FOREIGN KEY (table_id) REFERENCES ".$selectedCity.".".$selectedCity."_cable_air (table_id);  ";
    $result=pg_query($postgres, $alter);  # table for optical cable

    $alter =" ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_air_coax_geom ADD CONSTRAINT table_key_air_coax  FOREIGN KEY (table_id) REFERENCES ".$selectedCity.".".$selectedCity."_cable_air_coax (table_id);  ";
    $result=pg_query($postgres, $alter); 
  
  # ОШИБКИ

/*
ALTER TABLE kiev.kiev_cable_air_coax_geom ADD CONSTRAINT table_key_air_coax  FOREIGN KEY (table_id) REFERENCES kiev.kiev_cable_air_coax (table_id);
ALTER TABLE kiev.kiev_cable_air_cable_geom ADD CONSTRAINT table_key_air  FOREIGN KEY (table_id) REFERENCES kiev.kiev_cable_air (table_id);  

    */                                                         
    
       }
}
?>

