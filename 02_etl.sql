-- 02_etl.sql | ETL de ventas REIGI FIT (CSV -> staging -> data mart)
use datamart_reigifit
go

-- 1. EXTRACCIÓN
if object_id('stg_operacion') is not null drop table stg_operacion
if object_id('stg_cliente')   is not null drop table stg_cliente
if object_id('stg_producto')  is not null drop table stg_producto
go
create table stg_cliente   (pk_cliente int, nombre varchar(200), distrito varchar(80))
create table stg_producto  (pk_producto int, nombre varchar(200), subcategoria varchar(60),
                            categoria varchar(60), talla varchar(20), color varchar(30), precio decimal(10,2))
create table stg_operacion (idVenta int, fecha varchar(10), pk_cliente int, pk_producto int,
                            canal int, metodoPago int, cantidad int, descuento decimal(10,2))
go

bulk insert stg_cliente   from 'C:\etl\stg_cliente.csv'   with (format='CSV', firstrow=2, codepage='65001')
bulk insert stg_producto  from 'C:\etl\stg_producto.csv'  with (format='CSV', firstrow=2, codepage='65001')
bulk insert stg_operacion from 'C:\etl\stg_operacion.csv' with (format='CSV', firstrow=2, codepage='65001')
go
select 'stg_cliente' tabla, count(*) filas from stg_cliente
union all select 'stg_producto', count(*) from stg_producto
union all select 'stg_operacion', count(*) from stg_operacion
go

-- 2. TRANSFORMACIÓN + 3. CARGA DE DIMENSIONES 
insert into dim_cliente (pk_cliente, nombre, distrito, provincia, departamento)
select c.pk_cliente, ltrim(rtrim(c.nombre)), ltrim(rtrim(c.distrito)),
       case c.distrito when 'Callao' then 'Callao' when 'Arequipa' then 'Arequipa'
                       when 'Trujillo' then 'Trujillo' when 'Huacho' then 'Huaura'
                       when 'Cusco' then 'Cusco' else 'Lima' end,
       case c.distrito when 'Callao' then 'Callao' when 'Arequipa' then 'Arequipa'
                       when 'Trujillo' then 'La Libertad' when 'Cusco' then 'Cusco' else 'Lima' end
from stg_cliente c
where not exists (select 1 from dim_cliente d where d.pk_cliente = c.pk_cliente)
go

insert into dim_producto (pk_producto, nombre, subcategoria, categoria, talla, color, precio)
select p.pk_producto, ltrim(rtrim(p.nombre)), p.subcategoria, p.categoria, p.talla, p.color, p.precio
from stg_producto p
where not exists (select 1 from dim_producto d where d.pk_producto = p.pk_producto)
go

insert into dim_canal (pk_canal, nombreCanal, grupoCanal)
select v.pk, v.nombre, v.grupo
from (values (1,'WhatsApp','Mensajería directa'),
             (2,'Instagram','Mensajería directa'),
             (3,'Tienda en línea','Tienda en línea')) v(pk, nombre, grupo)
where not exists (select 1 from dim_canal d where d.pk_canal = v.pk)
go

insert into dim_metodoPago (pk_metodoP, nombreMetodo, tipoPago)
select v.pk, v.nombre, v.tipo
from (values (1,'Yape','Billetera digital'),
             (2,'Plin','Billetera digital'),
             (3,'Transferencia bancaria','Transferencia'),
             (4,'Efectivo','Efectivo'),
             (5,'Tarjeta','Tarjeta')) v(pk, nombre, tipo)
where not exists (select 1 from dim_metodoPago d where d.pk_metodoP = v.pk)
go

;with op as (
    select o.*, row_number() over (partition by o.idVenta order by o.fecha) rn
    from stg_operacion o
)
insert into fac_ventas (idVentaOrigen, id_cliente, id_producto, id_canal, id_metodoP,
                        fecha, cantidad, subTotal, descuento, total)
select o.idVenta, dc.id_cliente, dp.id_producto, ca.id_canal, mp.id_metodoP,
       convert(date, o.fecha, 23), o.cantidad,
       o.cantidad * dp.precio,
       o.descuento,
       o.cantidad * dp.precio - o.descuento
from op o
join dim_cliente    dc on dc.pk_cliente  = o.pk_cliente
join dim_producto   dp on dp.pk_producto = o.pk_producto
join dim_canal      ca on ca.pk_canal    = o.canal
join dim_metodoPago mp on mp.pk_metodoP  = o.metodoPago
where o.rn = 1
  and not exists (select 1 from fac_ventas f where f.idVentaOrigen = o.idVenta)
go

-- 5. VALIDACIÓN DE LA CARGA
select (select count(*) from stg_operacion)                       as filas_origen,
       (select count(distinct idVenta) from stg_operacion)        as ventas_unicas,
       (select count(*) from fac_ventas)                          as filas_fac_ventas,
       (select count(*) from stg_operacion) - (select count(*) from fac_ventas) as duplicados_descartados
go
select count(*) as ventas_sin_cliente from fac_ventas where id_cliente is null
go

-- 6. CONSULTAS DE LOS KPI
-- Ventas totales, unidades, ticket promedio y % de descuento
select sum(total) ventasTotales, sum(cantidad) unidades,
       sum(total) / count(distinct idVentaOrigen) ticketPromedio,
       100.0 * sum(descuento) / sum(subTotal) pctDescuento
from fac_ventas
go
select c.nombreCanal, sum(f.total) ventas,
       cast(100.0 * sum(f.total) / sum(sum(f.total)) over () as decimal(5,2)) pctParticipacion
from fac_ventas f join dim_canal c on c.id_canal = f.id_canal
group by c.nombreCanal order by ventas desc
go
select p.categoria, sum(f.cantidad) unidades, sum(f.total) ventas
from fac_ventas f join dim_producto p on p.id_producto = f.id_producto
group by p.categoria order by ventas desc
go
select t.anio, t.mes, t.nombreMes, sum(f.total) ventas
from fac_ventas f join dim_tiempo t on t.fecha = f.fecha
group by t.anio, t.mes, t.nombreMes order by t.anio, t.mes
go
select count(*) clientesConCompra,
       sum(case when n >= 2 then 1 else 0 end) recurrentes,
       cast(100.0 * sum(case when n >= 2 then 1 else 0 end) / count(*) as decimal(5,2)) pctRecurrentes
from (select id_cliente, count(distinct idVentaOrigen) n from fac_ventas group by id_cliente) t
go
