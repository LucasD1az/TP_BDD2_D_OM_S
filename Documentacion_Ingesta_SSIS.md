# Guía de Desarrollo SSIS: Ingesta a Capa de Staging

Esta documentación detalla los pasos estandarizados para replicar la ingesta de datos desde los múltiples sistemas operacionales de "The Drinking Company" hacia nuestra base de datos intermedia. Siguiendo la arquitectura del proyecto, en esta etapa se realiza una "Carga sin transformación" (Raw Data).

## 1. Requisitos Previos

Antes de comenzar a desarrollar en Visual Studio, asegúrate de cumplir con lo siguiente:
* Tener instalado Visual Studio junto con SQL Server Data Tools (SSDT) y la extensión de proyectos de Integration Services (SSIS).
* Tener instalados los drivers ODBC de MySQL (necesarios para conectarse a la base de datos de ventas actuales).
* Disponer de acceso a todas las fuentes de datos requeridas: Bases de datos (SQL Server, MySQL) y archivos planos (XML, XLS, TXT).

## 2. Creación del Proyecto en Visual Studio

1.  Abre Visual Studio y selecciona **Crear un proyecto nuevo**.
2.  En el buscador, escribe "Integration Services" y selecciona la plantilla **Proyecto de Integration Services**.
3.  Asigna un nombre representativo (ej. `TDC_Project`) y haz clic en **Crear**.

## 3. Configuración del driver ODBC

* Ejecutar (en Windows) `Win`+`R` y escribir `odbcad32` en el buscador. Esto abrirá la configuración de ODBC.
* Ir a `System DSN`, y agregar un nuevo system data source.
* Seleccionar `MySQL ODBC 9.7 Unicode Driver` entre las opciones, y seleccionar `Finish`.
* Poner un nombre para la fuente de datos (e.g. `MySQL_sales_source`) y configurar la conexión: 
    * La IP va en TCP/IP, seguido del puerto.
    * Luego se completa el usuario y la contraseña.
    * Si fue ingresado correctamente, en la opción para la base de datos debería poder seleccionarse `sales`.
    * Finalmente, usar `Test` para verificar la conexión. Si es correcta, debería poner `Connection Successful`.

## 4. Configuración de Administradores de Conexión

En la parte inferior del entorno de Visual Studio, en la pestaña **Administradores de conexión**, se deben crear los enlaces hacia nuestros orígenes y nuestro destino.

* **Conexión al Destino (Staging DB):** Crea una **Nueva conexión OLE DB** apuntando a tu servidor local y selecciona la base de datos `SQL_Staging_DB`.
* **Conexiones a los Orígenes:**
    * **MySQL:** Crea una conexión **ODBC** utilizando los drivers previamente instalados.
    * **SQL Server (History Sales):** Crea una conexión **OLE DB**.
    * **Archivos (Excel, TXT, CSV):** Crea una **Nueva conexión de Excel** o **Nueva conexión de archivos planos** según corresponda al formato.
* Respecto a la conexión de Excel, existe un error en los paquetes SSIS que requiere que se descargue un driver o que se guarde la planilla en una versión moderna (64 bit). Estos nuevos archivos están en la carpeta de Recursos Humanos del proyecto.

## 5. Diseño de los Paquetes SSIS (Nodos de Carga)

Se debe crear un paquete SSIS (`.dtsx`) individual por cada fuente de datos. Dentro de cada paquete, el flujo se divide en dos grandes tareas:

### A. Flujo de Control (Control Flow)
1.  Arrastra una **Tarea Ejecutar SQL**. Configúrala con la conexión OLE DB hacia Staging y escribe el comando `TRUNCATE TABLE [Nombre_de_la_Tabla]`. Esto es vital para vaciar la tabla destino antes de cada carga, evitando datos duplicados si el paquete se ejecuta varias veces[cite: 63].
2.  Arrastra una **Tarea Flujo de Datos** desde el cuadro de herramientas.
3.  Conecta la flecha verde desde la Tarea Ejecutar SQL hacia la Tarea Flujo de Datos para definir el orden de ejecución.

### B. Flujo de Datos (Data Flow)
1.  Haz doble clic en la **Tarea Flujo de Datos** para ingresar a su pestaña.
2.  Arrastra el **Origen** correspondiente (Origen de ODBC, Origen de archivo plano, etc.) y configúralo para leer la tabla o archivo operacional.
3.  Arrastra un **Destino de OLE DB**.
4.  Conecta la flecha azul del Origen hacia el Destino OLE DB.
5.  Haz doble clic en el Destino OLE DB, selecciona la tabla "espejo" correspondiente en Staging.
6.  Ve a la sección **Asignaciones (Mappings)** y valida que las columnas de origen crucen correctamente con las de destino.

## 6. Ejecución y Validación

* Para probar la ingesta, presiona el botón **Iniciar (Start)** en la barra superior de Visual Studio. 
* Si los nodos se pintan de verde, la ejecución fue exitosa.
* **Validación final:** Abre SQL Server Management Studio (SSMS) y ejecuta una consulta `SELECT *` sobre la tabla recién cargada para confirmar que los datos aterrizaron correctamente en el Staging Area.