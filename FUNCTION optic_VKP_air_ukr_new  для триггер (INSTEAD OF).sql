CREATE OR REPLACE FUNCTION public.optic_VKP_air_ukr_new() RETURNS trigger AS $optic_VKP_air_ukr_new$ 
--триггер INSTEAD OF UPDATE  OR INSERT OR DELETE ON установить на вьюшку  _optic_VKP_air_ukr_view
--теперь обновляем данные в таблицах _cable_air через вьюшку  
DECLARE 
    city name :=TG_TABLE_SCHEMA;
    view name :=TG_TABLE_NAME;
    tbl_view text := city||'.'||view;
    tbl_UPD text := city||'.'||city||'_cable_air' ;
 
    SQl text;
    SQl2 text;
    SQl3 text;
    SQl4 text;
    SQL_geom text;
    SQL_DEL_light text;
    SQL_DEL_full text;

BEGIN
  IF TG_OP = 'UPDATE' THEN
  -- см ексель поля вьюшки
  -- возможно оно запускает в том числе  geom ?
  SQL := 'UPDATE  '||tbl_UPD||'
  SET
    geom_cable =$1.geom_cable, 
    table_id =$1.table_id, 
    cable_description =$1.марка_кабелю, 
    cable_short_type_description =$1.кільк_волокон,
    total_cable_length =$1.довжина_км,
    progect_number  =$1.номер_проекту, 
    cable_progect_link  =$1. посилання_на_проект,
    cable_mount_date  =$1.рік_прокладання, 
    cable_purpose  =$1.призначення,
    rezerve1 =$1.примітки,
    notes2  =$1.примітки2
    
  WHERE '||tbl_UPD||'.table_id  = $1.table_id; 
   ' ;

  EXECUTE SQL
  USING NEW;   --
 --------Привязка к ручным боксам и ЛОУ/ОП  должно быть однинаково  с функцией для ВКП------------
 -------------------------------------------------------------------------------------------------
  
 --!!!  мы определили уже конечную и начальную точку geom_end_point и geom_start_point в другой функции для таблиц _cable_channels
 -- и вот сюда добавил перерисовку линий кабеля который привязываеться к боксу/ЛОУ

SQL_geom :=' UPDATE '||tbl_UPD||'
   SET  geom_cable=ST_SetPoint(geom_cable,0,geom_start_point)   WHERE  '||tbl_UPD||'.table_id = $1.table_id ;  
   UPDATE '||tbl_UPD||' 
     SET  geom_cable=ST_SetPoint(geom_cable,ST_NPoints(geom_cable)-1,geom_end_point)   WHERE   '||tbl_UPD||'.table_id = $1.table_id ; ' ;
 
EXECUTE  SQL_geom  USING NEW;
   RETURN NEW;
---------------------------------------------------------

 ELSIF TG_OP = 'INSERT' THEN 

  SQL2 := 'UPDATE  '||tbl_UPD||'
    SET
    geom_cable =$1.geom_cable, 
    table_id =$1.table_id, 
    cable_description =$1.марка_кабелю, 
    cable_short_type_description =$1.кільк_волокон,
    total_cable_length =$1.довжина_км,
    progect_number  =$1.номер_проекту, 
    cable_progect_link  =$1. посилання_на_проект,
    cable_mount_date  =$1.рік_прокладання, 
    cable_purpose  =$1.призначення,
    rezerve1 =$1.примітки,
    notes2  =$1.примітки2

   WHERE '||tbl_UPD||'.table_id  = $1.table_id ' ;

  EXECUTE SQL2
   USING NEW;  
   
 --------Привязка к ручным боксам и ЛОУ/ОП  ------------
 -------------------------------------------------------------------------------------------------
  
 --!!! мы определили уже конечную и начальную точку geom_end_point и geom_start_point в функции для таблиц _cable_channels
 -- и вот сюда НУЖНО добавить перерисовку линий кабеля который привязываеться к боксу/ЛОУ
  SQL_geom :=' UPDATE '||tbl_UPD||'
   SET  geom_cable=ST_SetPoint(geom_cable,0,geom_start_point)   WHERE  '||tbl_UPD||'.table_id = $1.table_id ;  
   UPDATE '||tbl_UPD||' 
     SET  geom_cable=ST_SetPoint(geom_cable,ST_NPoints(geom_cable)-1,geom_end_point)   WHERE   '||tbl_UPD||'.table_id = $1.table_id ; ' ;

  EXECUTE  SQL_geom  USING NEW; -- оказываеться срок действия этого SQL_geom только внутри IF!
  RETURN NEW;
  
  ELSIF TG_OP = 'DELETE' THEN 
  -- оказываеться срок действия этого SQL только внутри IF
  -- пока затираем всё... 
     SQL_DEL_full ='UPDATE  '||tbl_UPD||'
   SET
     geom_cable =NULL,
     geom_end_point = NULL,
     geom_start_point = NULL,
     cubic_code_start = NULL,
     cubic_name_start = NULL,
     cubic_coment_start = NULL,
     cubic_code_end = NULL,
     cubic_name_end = NULL,
     cubic_coment_end = NULL,
     cubic_end_house_id = NULL,
     cubic_start_house_id = NULL,
     cubic_start_street = NULL,
     cubic_start_house_num = NULL,
     cubic_end_street = NULL,
     cubic_end_house_num = NULL ,
     
    cable_description  = NULL , 
    cable_short_type_description  = NULL ,
    total_cable_length  = NULL ,
    progect_number   = NULL ,
    cable_progect_link  = NULL ,
    cable_mount_date   = NULL ,
    cable_purpose   = NULL ,
    rezerve1  = NULL ,
    notes2   = NULL 
 
     WHERE '||tbl_UPD||'.table_id  = $1.table_id ;'; 

     
    EXECUTE  SQL_DEL_full  USING  OLD;
    RETURN OLD; 
  END IF; 

END ;
$optic_VKP_air_ukr_new$   LANGUAGE plpgsql;