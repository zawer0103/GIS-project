CREATE OR REPLACE FUNCTION public.optic_kke_ukr_new() RETURNS trigger AS $optic_kke_ukr_new$ 
--триггер INSTEAD OF UPDATE  OR INSERT OR DELETE ON установить на вьюшку  _optic_kke_ukr_view_new
--теперь обновляем данные в таблицах _cable_channels через вьюшку  
DECLARE 
    city name :=TG_TABLE_SCHEMA;
    view name :=TG_TABLE_NAME;
    tbl_view text := city||'.'||view;
    tbl_UPD text := city||'.'||city||'_cable_channels' ;
 
    SQl text;
    SQl2 text;
    SQl3 text;
    SQl4 text;
    SQL_geom text;
    SQL_DEL_light text;
    SQL_DEL_full text;

BEGIN
  IF TG_OP = 'UPDATE' THEN
  
  SQL := 'UPDATE  '||tbl_UPD||'
  SET
    geom_cable =$1.geom_cable,
    table_id =$1.table_id,

    cable_short_type_description=$1.кільк_волокон,
    cable_description=$1.марка_кабелю_по_договору,
    cable_description_fact=$1.марка_кабелю_по_факту,
    cable_diameter=$1.діаметр_по_договору,
    contract_chanel_length=$1.довжина_по_договору_км,
    cable_length_house=$1.довжина_по_будинку_км,
    other_contract_channel_length=$1.довжина_інший_власник_км,
    total_cable_length=$1.загальна_довжина_факт_км,
    --(st_length(geom_cable) / 1000::double precision)::numeric(6,3)=$1.довжина_по_карті_км,

    tu_number=$1.номер_ТУ, 
    tu_date=$1.дата_ТУ,
    rental_contract_new_num=$1.номер_договору,
    rental_contract_new_date=$1.дата_договору,  
    rental_contract_new_add_num=$1.номер_ДУ_додатку, 
    rental_contract_new_add_date=$1.дата_ДУ_додатку, 
    acceptance_act_num=$1.номер_Акту_опосвідчення,
    acceptance_act_date=$1.дата_Акту_опосвідчення,
    cartogram_num=$1.номер_картограми_УТ,
    cartogram_date=$1.дата_картограми_УТ,
    approval_cartogram_num=$1.номер_погодження_УТ,
    approval_cartogram_date=$1.дата_погодження_УТ,
    cable_ukrtelefon_id=$1.ID_кабелю_в_УТ,
    
    progect_number=$1.номер_проекту,
    executive_doc_state=$1.виконавча_документація,
    cable_mount_date=$1.рік_прокладання,

    rental_contract_old_num=$1.номер_старого_договору,
    rental_contract_old_date=$1.дата_старого_договору,  
    rental_contract_old_add_num=$1.номер_старої_ДУ_додатку, 
    rental_contract_old_add_date=$1.дата_старої_ДУ_додатку, 

    contract_start_address=$1.Початкова_адреса_по_договору,
    contract_start_pit=$1.Початковий_ТК_по_договору,
    contract_end_address=$1.Кінцева_адреса_по_договору,
    contract_end_pit=$1.Кінцевий_ТК_по_договору,
    summ_route_description=$1.ділянка_по_контракту,
    notes1=$1.власник_кк,
    notes2=$1.статус,
    rezerve1=$1.примітки1,
    rezerve2=$1.примітки2,
    rezerve3=$1.ПГС


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
    cable_short_type_description =COALESCE( cable_short_type_description  , $1.кільк_волокон  ) ,
    cable_description     =COALESCE( cable_description , $1.марка_кабелю_по_договору ) ,
    cable_description_fact =COALESCE( cable_description_fact  , $1.марка_кабелю_по_факту  ) ,
    cable_diameter =COALESCE( cable_diameter  , $1.діаметр_по_договору  ) ,
    contract_chanel_length =COALESCE( contract_chanel_length  , $1.довжина_по_договору_км ) ,
    cable_length_house =COALESCE( cable_length_house  , $1.довжина_по_будинку_км  ) ,
    other_contract_channel_length     =COALESCE( other_contract_channel_length , $1.довжина_інший_власник_км ) ,
    total_cable_length =COALESCE( total_cable_length  , $1.загальна_довжина_факт_км ) ,
    tu_number     =COALESCE( tu_number , $1.номер_ТУ   ) ,
    tu_date     =COALESCE( tu_date , $1.дата_ТУ  ) ,
    rental_contract_new_num     =COALESCE( rental_contract_new_num , $1.номер_договору ) ,
    rental_contract_new_date =COALESCE( rental_contract_new_date  , $1.дата_договору    ) ,
    rental_contract_new_add_num     =COALESCE( rental_contract_new_add_num , $1.номер_ДУ_додатку   ) ,
    rental_contract_new_add_date =COALESCE( rental_contract_new_add_date  , $1.дата_ДУ_додатку  ) ,
    acceptance_act_num =COALESCE( acceptance_act_num  , $1.номер_Акту_опосвідчення  ) ,
    acceptance_act_date     =COALESCE( acceptance_act_date , $1.дата_Акту_опосвідчення ) ,
    cartogram_num     =COALESCE( cartogram_num , $1.номер_картограми_УТ  ) ,
    cartogram_date =COALESCE( cartogram_date  , $1.дата_картограми_УТ ) ,
    approval_cartogram_num =COALESCE( approval_cartogram_num  , $1.номер_погодження_УТ  ) ,
    approval_cartogram_date     =COALESCE( approval_cartogram_date , $1.дата_погодження_УТ ) ,
    cable_ukrtelefon_id     =COALESCE( cable_ukrtelefon_id , $1.ID_кабелю_в_УТ ) ,
    progect_number =COALESCE( progect_number  , $1.номер_проекту  ) ,
    executive_doc_state     =COALESCE( executive_doc_state , $1.виконавча_документація ) ,
    cable_mount_date =COALESCE( cable_mount_date  , $1.рік_прокладання  ) ,
    rental_contract_old_num     =COALESCE( rental_contract_old_num , $1.номер_старого_договору ) ,
    rental_contract_old_date =COALESCE( rental_contract_old_date  , $1.дата_старого_договору    ) ,
    rental_contract_old_add_num     =COALESCE( rental_contract_old_add_num , $1.номер_старої_ДУ_додатку  ) ,
    rental_contract_old_add_date =COALESCE( rental_contract_old_add_date  , $1.дата_старої_ДУ_додатку   ) ,
    contract_start_address =COALESCE( contract_start_address  , $1.Початкова_адреса_по_договору ) ,
    contract_start_pit =COALESCE( contract_start_pit  , $1.Початковий_ТК_по_договору  ) ,
    contract_end_address =COALESCE( contract_end_address  , $1.Кінцева_адреса_по_договору ) ,
    contract_end_pit =COALESCE( contract_end_pit  , $1.Кінцевий_ТК_по_договору  ) ,
    summ_route_description =COALESCE( summ_route_description  , $1.ділянка_по_контракту ) ,
    notes1 =COALESCE( notes1  , $1.власник_кк ) ,
    notes2 =COALESCE( notes2  , $1.статус ) ,
    rezerve1 =COALESCE( rezerve1  , $1.примітки1  ) ,
    rezerve2 =COALESCE( rezerve2  , $1.примітки2  ) ,
    rezerve3 =COALESCE(      rezerve3  , $1.ПГС  )

   WHERE '||tbl_UPD||'.table_id  = $1.table_id ' ;

  EXECUTE SQL2
   USING NEW;  
   
 --------Привязка к ручным боксам и ЛОУ/ОП  должно быть однинаково  с функцией для ВКП------------
 -------------------------------------------------------------------------------------------------
  
 --!!! мы определили уже конечную и начальную точку geom_end_point и geom_start_point в функции для таблиц _cable_channels
 -- и вот сюда НУЖНО добавить перерисовку линий кабеля который привязываеться к боксу/ЛОУ
  SQL_geom :=' UPDATE '||tbl_UPD||'
   SET  geom_cable=ST_SetPoint(geom_cable,0,geom_start_point)   WHERE  '||tbl_UPD||'.table_id = $1.table_id ;  
   UPDATE '||tbl_UPD||' 
     SET  geom_cable=ST_SetPoint(geom_cable,ST_NPoints(geom_cable)-1,geom_end_point)   WHERE   '||tbl_UPD||'.table_id = $1.table_id ; ' ;

  EXECUTE  SQL_geom  USING NEW; -- оказываеться срок действия этого SQL_geom только внутри IF!
   RETURN NEW;
  
  RETURN NEW; 
 /* -- чтобы не затереть поля, залитые из CSV  нужно пока ИСПОЛЬЗОВАТЬ COALESCE  поля.таблицы= COALESCE(поля.таблицы, Поля.вьюшки) например:
  -- tu_date =COALESCE(tu_date,$1.дата_ТУ) других идей нет 
  */

  ELSIF TG_OP = 'DELETE' THEN 
  -- оказываеться срок действия этого SQL только внутри IF
  SQL_DEL_light='UPDATE  '||tbl_UPD||'
   SET
     geom_cable =NULL,
     geom_end_point = NULL,
     geom_start_point = NULL,
     cubic_code_start = NULL,
     cubic_name_start = NULL,
     cubic_coment_start = ''ВОК видалено з карти'',
     cubic_code_end = NULL,
     cubic_name_end = NULL,
     cubic_coment_end = ''ВОК видалено з карти'',
     cubic_end_house_id = NULL,
     cubic_start_house_id = NULL,
     cubic_start_street = ''видалено з карти'',
     cubic_start_house_num = NULL,
     cubic_end_street = ''видалено з карти'',
     cubic_end_house_num = NULL 

     WHERE '||tbl_UPD||'.table_id  = $1.table_id ;';

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
     -------затираем всё---
         cable_short_type_description = NULL  ,
    cable_description = NULL  ,
    cable_description_fact  = NULL  ,
    cable_diameter  = NULL  ,
    contract_chanel_length  = NULL  ,
    cable_length_house  = NULL  ,
    other_contract_channel_length = NULL  ,
    total_cable_length  = NULL  ,
    tu_number = NULL  ,
    tu_date = NULL  ,
    rental_contract_new_num = NULL  ,
    rental_contract_new_date  = NULL  ,
    rental_contract_new_add_num = NULL  ,
    rental_contract_new_add_date  = NULL  ,
    acceptance_act_num  = NULL  ,
    acceptance_act_date = NULL  ,
    cartogram_num = NULL  ,
    cartogram_date  = NULL  ,
    approval_cartogram_num  = NULL  ,
    approval_cartogram_date = NULL  ,
    cable_ukrtelefon_id = NULL  ,
    progect_number  = NULL  ,
    executive_doc_state = NULL  ,
    cable_mount_date  = NULL  ,
    rental_contract_old_num = NULL  ,
    rental_contract_old_date  = NULL  ,
    rental_contract_old_add_num = NULL  ,
    rental_contract_old_add_date  = NULL  ,
    contract_start_address  = NULL  ,
    contract_start_pit  = NULL  ,
    contract_end_address  = NULL  ,
    contract_end_pit  = NULL  ,
    summ_route_description  = NULL  ,
    notes1  = NULL  ,
    notes2  = NULL  ,
    rezerve1  = NULL  ,
    rezerve2  = NULL  ,
    rezerve3  = NULL  
 
     WHERE '||tbl_UPD||'.table_id  = $1.table_id ;'; 

     -- при удалении проверку  добавляю дополнительную проверку: contract_chanel_length IS NOT NULL OR tu_number IS NOT NULL OR rental_contract_new_num IS NOT NULL; - если эти поля пустые, но можно ВСЁ затирать.
 
    IF  OLD.довжина_по_договору_км IS NOT NULL  OR OLD.номер_ТУ  IS NOT NULL OR OLD.номер_договору IS NOT NULL 
    THEN EXECUTE SQL_DEL_light USING  OLD; 
    ELSE EXECUTE  SQL_DEL_full  USING  OLD;
    END IF;   
    /* перестало писать "ВОК_удалён"  -- стало конфликтовать с триггером на таблицу: там при ЛЮБЫХ изменениях geom  всё затирает  поэтому добавил там ещё одну проверку   IF NEW.geom_cable IS NOT NULL THEN  
    -- работает но вызывает FATAl EROR в QGIS если в таблице атрибутов нажать "обновить"
     */
    RETURN OLD; 
   
  END IF; 

/* для информации cubic_coment_start = ''ВОК_удалён''
  вот это всё не работает (помогли только две одинарные кавычки ): 
  --одно и тоже  Ошибка PostGIS при удалении объектов: ERROR:  column "coment" does not exist
  -- cubic_code_start = quote_literal("coment"),
  -- cubic_code_start = quote_literal(coment), 
  --'|| quote_ident(cubic_code_start)|| ' = '|| quote_literal(newvalue)||'
  --cubic_code_start = '||quote_literal(coment)||',
  -- cubic_code_start = = $$'|| newvalue || '$$
*/
END ;
$optic_kke_ukr_new$   LANGUAGE plpgsql;