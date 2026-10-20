 Descripción de Componentes

1. sql/

Contiene los scripts SQL desarrollados para SQL Server:

01_estructura.sql: Script para la creación de la base de datos, tablas de staging y modelo de datos.

02_etl.sql: Script automatizado para la carga masiva y transformación de datos.

2. data/

Archivos CSV fuente que alimentan el proceso ETL:

stg_cliente.csv: Datos de clientes.

stg_producto.csv: Catálogo de productos.

stg_operacion.csv: Registro de operaciones y transacciones.

3. powerbi/

dashboard_reigifit.pbix: Archivo de Power BI Desktop con el modelo dimensional y tableros interactivos.

4. docs/

evidencias/: Capturas de pantalla, logs de ejecución e historial de pruebas.

 Instrucciones de Ejecución

Sigue estos pasos en orden para poner en marcha el proyecto:

Crear la Estructura de Base de Datos:

Abre SQL Server Management Studio (SSMS).

Ejecuta el script sql/01_estructura.sql para crear la base de datos y sus respectivas tablas.

Preparar los Archivos de Datos:

Copia los 3 archivos CSV ubicados en la carpeta data/ (stg_cliente.csv, stg_producto.csv, stg_operacion.csv).

Colócalos en la ruta local C:\etl\ (o modifica la ruta directamente dentro del script 02_etl.sql según tu configuración).

Cargar y Transformar Datos (ETL):

En SSMS, ejecuta el script sql/02_etl.sql para realizar el proceso de ingesta y transformación de datos hacia las tablas finales.

Visualización en Power BI:

Abre el archivo powerbi/dashboard_reigifit.pbix en Power BI Desktop.

Actualiza los parámetros de conexión para vincular el reporte a tu instancia local de SQL Server.
