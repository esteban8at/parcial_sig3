---PARCIAL 1
---ESTEBAN OCHOA TORRES
---COD:1628759
---INGENIERÍA TOPOGRÁFICA---

drop table act_economicas
drop table barrios;
drop table equipamentos;
drop table espacio_publico;
drop table estaciones_mio;
drop table vias;
---PREGUNTA 1--------
select*from barrios
select distinct  barrio from barrios b,estaciones_mio a
where  (st_intersects(b.geom,a.geom)= 't')


--PREGUNTA 2---

select*from act_economicas
select*from barrios  ---objectid

---EN LA CAPA ACTIVIDADES ECONOMICAS

alter table act_economicas add column barrio varchar;
alter table act_economicas add column comuna varchar;
alter table act_economicas add column identificador varchar ;
alter table act_economicas add column distancia_estacion double precision;7
alter table act_economicas drop column identificador2

---SE DEBE ACTUALIZAR TENIENDO EN CUENTA, SI EL BARRIO PRESENTA UNA ACTIVIDAD ECONOMICA
update act_economicas x set barrio=y.barrio,comuna=y.comuna from   barrios y where (st_intersects(x.geom,y.geom)= 't')

---SE CREA UNA VISTA, CON EL GID DE LA ACTIVIDAD ECONOMÍCA, RELACIONADA CON LA DISTANCIA ENTRE LA ESTACIÓN Y LA ACTIVIDAD
create or replace view act_est as
select distinct on (a.gid) a.gid as gid_actividad, b.id_estacio as gid_estacion, min(st_distance(a.geom,b.geom)) a from act_economicas a, estaciones_mio b 
group by a.gid,b.gid
order by a.gid, min(st_distance(a.geom,b.geom))

update act_economicas b set distancia_estacion=a.a,identificador=a.gid_estacion from act_est a where a.gid_actividad=b.gid
select*from act_economicas


--PREGUNTA 3

select*from equipamentos
select*from barrios

---SE SELECCIONAN LAS ÁREAS DE LA CAPA EQUIPAMENTOS Y BARRIOS, TENIENDO EN CUENTA QUE SE INTERSECTA EL EQUIPAMENTO Y LOS BARRIOS
create or replace view equipamentos_2 as
select a.nombre_eqp,a.gid,a.shape_area as area_equipamento ,b.shape_area as area_total_barrio ,b.barrio from equipamentos a, barrios b 
where st_intersects(a.geom,b.geom)='t'

select*from equipamentos_2

----SE CREA UNA VISTA TENIENDO EN CUENTA, LOS ÁREAS TOTALES Y SE TIENE EN CUENTA LA SUMA DEL ÁREA DE EQUIPAMENTO POR BARRIO PARA HALLAR EL PORCENTAJE TOTAL
create or replace view area_total as
select a.barrio, sum(a.area_equipamento)as suma,a.area_total_barrio , ((sum(a.area_equipamento)*100)/a.area_total_barrio) as areqbarr from equipamentos_2 a
group by a.barrio,a.area_total_barrio order by areqbarr desc

select*from area_total

----PUNTO 4
---SE TIENE EN CUENTA LAS DOS CONDICIONALES OBLICATORIAS
update espacio_publico set fuente = 'UNIVERSIDAD DEL VALLE - PARCIAL SIG3'
where categoria = 'ZONA VERDE' and (area_ha > 1)

select*from espacio_publico where categoria='ZONA VERDE' and (area_ha>1)

----PUNTO 5----
select*from act_economicas2
select*from vias

---SE CREA UNA COLUMNA LLAMADA BUFFER, EN DONDE SE ALMACENARA EL TIPO DE VÍA EN UN RANGO A 300 METROS Y 
---SE INTERSECTAN LAS ACTIVIDADES ECONÓMICAS Y LA ZONA DE AFECCION DE LA VÍA
alter table act_economicas2 add column buffer varchar

-----SE CARGA EL TIPO DE VÍA SEGÚN UN BUFFER DE 300 METROS (QUE SE LE REALIZA A LA VÍA)
-----ESTO DA COMO RESULTADO EN LOS PUNTOS QUE SE INTERSECTEN COLOCA EL TIPO DE VÍA EN LA CASILLA BUFFER MEDIANTE LA FUNCIÓN UPDATE
update act_economicas2 a set buffer=b.tipo_via from  vias b where st_intersects(a.geom,(st_buffer(st_transform(b.geom,3115),300)))

-----SE CREA EL BORRADO CON CONDICIONAL 
DELETE from act_economicas2   where tipo='Microempresa'  and ((empleados='3')or (empleados='2') or (empleados='1'))and buffer='Via Arteria Principal' 

select*from act_economicas2 where tipo='Microempresa'  and ((empleados='5')or (empleados='4') or (empleados='10'))and buffer='Via Arteria Principal'
---PUNTO 6------

--CÁLCULO DEL ÁREA EN HECTAREAS DEL POLIGONO ENVOLVENTE DE LOS CENTROIDES QUE TIENEN LA CARACERÍSTICA EN EL SERVICIO DE EQUIPACIÓN, MEDIANTE ST_CONVEXHULL()

select st_area(st_convexHull(st_collect(st_centroid(geom))))/10000 as APolEnv__ha , 
st_convexHull(st_collect(st_centroid(geom))) as poligonoEnv from equipamentos where servicio_e= 'RECREACION'


----PUNTO 7----
select*from barrios

---SE CALCULA EL PROMEDIO MEDIANTE EL USO DEL CÁLCULO DEL AREA QUE ESTABA EN EL SHAPE, TAMBIÉN SE PUEDE USAR MEDIANTE LA GEOMETRÍA DE BARRIOS, SELECCIONANDO OPERACIÓN(ST_AREA(barios.geom)/1000)
----SE ORDENAN POR EL ESTRATO,Y SE ORGANIZAN DE MANERA DESCENDENTE 
select distinct estra_moda, sum(shape_area/10000) as area_total,
		AVG(shape_area/1000) as area_promedio,
		max(shape_area/1000) as area_maxima,
		min(shape_area/1000) as area_minima	
		from barrios   group by barrios.estra_moda order by estra_moda desc

----PUNTO 9----
select*from NUEVA_TABLA
create table NUEVA_TABLA as 
select distinct b.* from act_economicas2 b, estaciones_mio estaciones 
where st_intersects(b.geom,st_Buffer(estaciones.geom,300));

---PUNTO 10----
----------CONSULTA----
select a.tipo as Tipo, a.count from act_economicas a
	where st_intersects(st_transform((st_setsrid(st_makepoint(-76.50372,3.436284),4326)),3115),st_Buffer(st_transform(a.geom,4326),1000))
	group by a.tipo order by a.count


----FUNCION---
create or replace function punto1023(double precision,double precision, integer) 
returns table (TIPO varchar, COUNT bigint) as $$
declare
lon alias for $1;
lat alias for $2;
radio alias for $3;
begin
return query
select a.tipo as tipo, a.count as cantidad from act_economicas a 
	where st_intersects(st_transform((st_setsrid(st_makepoint(lon,lat),4326)),3115),st_Buffer(a.geom,radio))
	group by a.tipo order by a.count;
end;
$$
language 'plpgsql';

select*from punto1023(-76.4542,3.4724,5000)







create or replace function  __16nuevaConsultaPunto10(double precision,double precision,integer)
returns SETOF Respuesta as  
$$
declare
dw record;
lon alias for $1;
lat alias for $2;
radio alias for $3;
begin  
	for dw in 
		execute 'create or replace view  Respuesta as
		select ac.tipo as Tipo, ac.count from act_economicas ac 
		where st_intersects(st_transform((st_setsrid(st_makepoint('||lon||','||lat||'),4326)),3115),st_Buffer(ac.geom,'||radio||'))
		group by ac.tipo order by ac.count'
	loop 
		return next Respuesta;
	end loop;
	return;

	
end;
$$
language plpgsql

select*from __16nuevaConsultaPunto10(-76.4542,3.4724,5000)

select*from Respuesta


