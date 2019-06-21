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

  $CREATE =" create table IF NOT EXISTS ".$selectedCity.".".$selectedCity."_box_splice (id serial, geom geometry, mid varchar(7), year varchar(50), type varchar(100), short_description varchar(100), location varchar(100) , comment varchar(256) );
    ALTER TABLE ".$selectedCity.".".$selectedCity."_box_splice ADD CONSTRAINT unic_box_id  UNIQUE  (mid); ";
   $result=pg_query($postgres, $CREATE);

   $ALT =" 
       ALTER TABLE ".$selectedCity.".".$selectedCity."_box_splice 
       ADD COLUMN micro_district varchar(100),ADD COLUMN  coverage_zone varchar(100),ADD COLUMN adress varchar(100),ADD COLUMN entrance varchar(100); ";
   $result=pg_query($postgres, $ALT);
  
  # план: ДОБАВИТЬ в таблицу _box_splice КОЛОНКИ +
  # micro_district
  # coverage_zone
  # adress
  # entrance

   # ДОБАВИТЬ ТРИГГЕР на INSERT вставку ящика: заполянть поля выше через ST_Intersects -- создан ниже # функция в отдельном файле
   # добавить в ночной апдейт обновление этих полей, т.к. с триггером UPDATE может ничего и не получиться 
   # переделываю вьшку без всяких ST_Intersects - только названия полей укр...

    $alter ="  
    COMMENT ON TABLE ".$selectedCity.".".$selectedCity."_box_splice  IS 'бокси/ящики/муфти намальовані вручну без привязки до БД КУБІК';
    COMMENT ON COLUMN ".$selectedCity.".".$selectedCity."_box_splice.mid IS 'унікальний код в БД'; 
    COMMENT ON COLUMN ".$selectedCity.".".$selectedCity."_box_splice.year IS 'вказуємо: дату або рік або проект'; 
    COMMENT ON COLUMN ".$selectedCity.".".$selectedCity."_box_splice.type IS 'вказуємо: ящик або муфта або крос або шафа'; 
    COMMENT ON COLUMN ".$selectedCity.".".$selectedCity."_box_splice.short_description IS 'вказуємо модель муфти кроса або ящика';
    COMMENT ON COLUMN ".$selectedCity.".".$selectedCity."_box_splice.location IS 'підвал або горище або ТК№ххх'; 
    COMMENT ON COLUMN ".$selectedCity.".".$selectedCity."_box_splice.comment IS 'коментар';  ";
    $result=pg_query($postgres, $alter);  # 

    $alter =" CREATE INDEX mid ON  ".$selectedCity.".".$selectedCity."_box_splice(mid);
    CREATE INDEX box_geom ON  ".$selectedCity.".".$selectedCity."_box_splice(geom);";  
    $result=pg_query($postgres, $alter); echo $alter."\n";  # создать индексы по тем полям по которым будет связка JOIN
    

    $fun =" CREATE OR REPLACE FUNCTION ".$selectedCity.".".$selectedCity."_max_mid() RETURNS varchar(7) LANGUAGE SQL AS
  $$ SELECT 'm_'||left('00000',(5-length(tmp.id::varchar(5))))||tmp.id FROM (SELECT CASE when max(right(mid, 5)::int) is NULL THEN 1 else max(right(mid, 5)::int)+1 end as id from  ".$selectedCity.".".$selectedCity."_box_splice) tmp; $$;
   Alter table ".$selectedCity.".".$selectedCity."_box_splice
  Alter  COLUMN  mid SET DEFAULT ".$selectedCity.".".$selectedCity."_max_mid(); " ;  
  $result=pg_query($postgres, $fun);  //функция для создания хитрого уникального номера муфты и добавляем эту функцию по дефолту для table_id
  //echo $fun."\n";
    
   // в QGIS вьюшку назвать Бокси/ящики/муфти

$box_view = " DROP VIEW ".$selectedCity.".".$selectedCity."_box_splice_View_Intersects"; $result=pg_query($postgres, $box_view); 
# заметил следующее: простым REPLACE поля местами не меняються
$box_view = "
 CREATE OR REPLACE VIEW ".$selectedCity.".".$selectedCity."_box_splice_View_Intersects AS 
SELECT  c.id, c.geom,
c.mid as номер_в_БД,
c.type as тип,
c.short_description as модель,
c.location as локація,
c.comment as коментар,
c.year as рік,
c.micro_district as мікрорайон,
c.coverage_zone as номер_ПГС,
c.adress as адреса,
c.entrance as номер_підїзду
  FROM ".$selectedCity.".".$selectedCity."_box_splice c  ;
  " ;
$result=pg_query($postgres, $box_view);  # переносим Intersects в триггер будет только при вставке бокса

//ST_Intersects для подъездов не получается нужно ST_Distance  - стало чуть тормозить  !!!  добавил 4000 ящиков в Хмельницкий - лежит намертво. нужно убрать к чёрту этот ST_Distance и DISTINCT
//ST_Intersects проблему по сути не решает нужно уходить от єтой херни на жёсткую таблицу  с жёской привязкой к подъезду ночным апдейтом.
//C:\xampp\htdocs\zawer\php-arhive\my_fix\Issues # (муфто-ящики ручные)\

$grant =" 
GRANT ALL ON ".$selectedCity.".".$selectedCity."_box_splice TO simpleuser; 
GRANT SELECT ON ".$selectedCity.".".$selectedCity."_box_splice  TO simplereader;
GRANT ALL ON ".$selectedCity.".".$selectedCity."_box_splice_View_Intersects TO simpleuser; 
GRANT SELECT ON ".$selectedCity.".".$selectedCity."_box_splice_View_Intersects  TO simplereader;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA ".$selectedCity." TO simpleuser; ";
  $result=pg_query($postgres, $grant);
// нужно уточнить  нужен ли доступ сюда _box_splice
// без вот этого "GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA"  будет ошибка permission denied for sequence zhitomir_box_splice_id_seq

 #$query = "DROP TRIGGER IF EXISTS  box_splice ON ".$selectedCity.".".$selectedCity."_box_splice_View_Intersects;" ;   echo $query.'<hr>';    $result=pg_query($postgres, $query);

 $query = "
 CREATE TRIGGER box_splice INSTEAD OF INSERT OR UPDATE OR DELETE ON ".$selectedCity.".".$selectedCity."_box_splice_View_Intersects  FOR EACH ROW EXECUTE PROCEDURE  public.box_splice();  " ;   
    echo $query.'<hr>'; 
    $result=pg_query($postgres, $query);# см файл FUNCTION_box_splice.sql

 $query = "
 CREATE TRIGGER box_splice_move_cable_geom AFTER UPDATE or DELETE ON  ".$selectedCity.".".$selectedCity."_box_splice  FOR EACH ROW EXECUTE PROCEDURE  public.box_move_cable_geom();  " ;   
    echo $query.'<hr>'; 
    $result=pg_query($postgres, $query);# см файл box_move_cable_geom.sql --триггер для подвигания концов кабелей ВКП и ККЕ
    //C:\xampp\htdocs\zawer\php-arhive\my_fix\Issues # (муфто-ящики ручные)\

$query = "
 CREATE TRIGGER box_splice_Intersects AFTER INSERT OR UPDATE or DELETE ON  ".$selectedCity.".".$selectedCity."_box_splice  FOR EACH ROW EXECUTE PROCEDURE  public.box_splice_Intersects();  " ;   
    echo $query.'<hr>'; 
    $result=pg_query($postgres, $query); # см файл box_splice_Intersects.sql  -- при вставке бокса - заполним поля район, адрес, подъезд функцией ST_Intersects



       }
}
?>

