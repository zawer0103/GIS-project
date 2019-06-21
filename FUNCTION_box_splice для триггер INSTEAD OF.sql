CREATE OR REPLACE FUNCTION public.box_splice() RETURNS trigger AS $box_splice$ 
--триггер INSTEAD OF UPDATE  OR INSERT OR DELETE ON установить на вьюшку  _box_splice_View_Intersects
--обновляем данные в таблицах _box_splice через вьюшку  
DECLARE 
  city name :=TG_TABLE_SCHEMA;
    view name :=TG_TABLE_NAME;
    tbl text := city||'.'||city||'_box_splice' ;
    SQl text;
  

BEGIN
  IF TG_OP = 'UPDATE' THEN
  
  SQL := 'UPDATE  '||tbl||'
  SET
  geom = $1.geom,
  year = $1.рік,  
  type = $1.тип,
  short_description = $1.модель,
  location =$1.локація,
  comment = $1.коментар 
  WHERE '||tbl||'.id = $1.id' ;

  EXECUTE SQL
   USING NEW;   --
   RETURN NEW;
  
 ELSIF TG_OP = 'INSERT' THEN 
 EXECUTE
  'INSERT INTO  '||tbl||'(geom,year,type,short_description,location,comment) 
  VALUES( 
  $1.geom,
  $1.рік,
  $1.тип,
  $1.модель,
  $1.локація,
  $1.коментар
    )   '  USING NEW;
  RETURN NEW; -- в черновцах и черкасах ок а житомир не работает инсерт
  
  ELSIF TG_OP = 'DELETE' THEN 
  EXECUTE
  'DELETE FROM  '||tbl||' 
  WHERE  '||tbl||'.id = $1.id '  USING OLD;
  RETURN OLD;
  END IF; 

END ;
$box_splice$   LANGUAGE plpgsql;