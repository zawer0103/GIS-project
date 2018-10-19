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
  
    $alter =" ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_channels ADD CONSTRAINT unic_id  UNIQUE  (table_id);  ";
    $result=pg_query($postgres, $alter); 
    
   $alter =" ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_channel_cable_geom ADD CONSTRAINT table_key  FOREIGN KEY (table_id) REFERENCES ".$selectedCity.".".$selectedCity."_cable_channels (table_id);  ";
    $result=pg_query($postgres, $alter); 


    $alter =" ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_channels_coax ADD CONSTRAINT unic_id_coax  UNIQUE  (table_id);  ";
    $result=pg_query($postgres, $alter); 

   $alter =" ALTER TABLE ".$selectedCity.".".$selectedCity."_cable_channel_coax_geom ADD CONSTRAINT table_key_coax  FOREIGN KEY (table_id) REFERENCES ".$selectedCity.".".$selectedCity."_cable_channels_coax (table_id);  ";
    $result=pg_query($postgres, $alter); 

    #ERROR:  there is no unique constraint matching given keys for referenced table &quot;cherkassy_cable_channels_coax
    #ERROR:  there is no unique constraint matching given keys for referenced table "fastiv_cable_channels"
    #In postgresql all foreign keys must reference a unique key in the parent table
    # нужно добавить в таблицах _cable_channels   для поля table_id  добавить unique key 

     ///ALTER TABLE fastiv.fastiv_cable_channels ADD CONSTRAINT unic_id  UNIQUE  (table_id); // протестил ОК
    ///ALTER TABLE fastiv.fastiv_cable_channel_cable_geom ADD CONSTRAINT table_key  FOREIGN KEY (table_id) REFERENCES fastiv.fastiv_cable_channels (table_id); // протестил ОК

    #  у нас какие-то лишние таблицы везде: _cable_channels_cable_geom
    #  в QGIS  у нас подключены  _cable_channel_cable_geom    (без буквы s)


                                                             
    
       }
}
?>

