--нормально работает осталось протестировать функцию
  CREATE OR REPLACE FUNCTION zhitomir.max_t_air_zhitomir() RETURNS varchar(7) LANGUAGE SQL AS
  $$ SELECT 't_'||left('00000',(5-length(tmp.id::varchar(5))))||tmp.id FROM (SELECT max(right(table_id, 5)::int)+1 as id from zhitomir.zhitomir_cable_air_cable_geom) tmp; $$;

Alter table zhitomir.zhitomir_cable_air_cable_geom
Alter  COLUMN  table_id SET DEFAULT zhitomir.max_t_air_zhitomir(); 