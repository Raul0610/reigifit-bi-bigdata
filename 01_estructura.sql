-- 01_estructura.sql | Data mart de ventas REIGI FIT
use master
go
if db_id('datamart_reigifit') is null create database datamart_reigifit
go
use datamart_reigifit
go

-- Limpieza para poder re-ejecutar el script (primero la tabla de hechos)
if object_id('fac_ventas')     is not null drop table fac_ventas
if object_id('dim_tiempo')     is not null drop table dim_tiempo
if object_id('dim_cliente')    is not null drop table dim_cliente
if object_id('dim_producto')   is not null drop table dim_producto
if object_id('dim_canal')      is not null drop table dim_canal
if object_id('dim_metodoPago') is not null drop table dim_metodoPago
go

--  DIMENSIONES
create table dim_tiempo                      -- Día -> Mes -> Trimestre -> Año
(fecha date primary key,
anio smallint,
mes smallint,
nombreMes varchar(15),
diaMes smallint,
diaSemana varchar(15),
trimestre smallint)
go

create table dim_cliente                     -- Distrito -> Provincia -> Departamento
(id_cliente int primary key identity,
pk_cliente int,
nombre varchar(200),
distrito varchar(80),
provincia varchar(80),
departamento varchar(80))
go

create table dim_producto                    -- Producto -> Subcategoría -> Categoría
(id_producto int primary key identity,
pk_producto int,
nombre varchar(200),
subcategoria varchar(60),
categoria varchar(60),
talla varchar(20),
color varchar(30),
precio money)
go

create table dim_canal                       -- Canal -> Grupo de canal
(id_canal int primary key identity,
pk_canal int,
nombreCanal varchar(50),
grupoCanal varchar(50))
go

create table dim_metodoPago                  -- Método de pago -> Tipo de pago
(id_metodoP int primary key identity,
pk_metodoP int,
nombreMetodo varchar(50),
tipoPago varchar(30))
go

--  TABLA DE HECHOS
create table fac_ventas
(id_venta int primary key identity,
idVentaOrigen int unique,                    -- evita cargar dos veces la misma venta
id_cliente int references dim_cliente,
id_producto int references dim_producto,
id_canal int references dim_canal,
id_metodoP int references dim_metodoPago,
fecha date references dim_tiempo,
cantidad int,
subTotal money,
descuento money,
total money)
go

--Carga única de dim_tiempo
set language Spanish
declare @f date = '2024-01-01'
while @f <= '2026-12-31'
begin
    insert into dim_tiempo
    values (@f, year(@f), month(@f), datename(month, @f), day(@f), datename(weekday, @f), datepart(quarter, @f))
    set @f = dateadd(day, 1, @f)
end
set language us_english
go
