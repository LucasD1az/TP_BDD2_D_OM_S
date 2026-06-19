# Trabajo Práctico Final - Bases de Datos 2 (TUIA)

Comisión 2 - Grupo 20

Integrantes:
* Lucas Díaz Celauro
* Lisandro Odisio Martinelli
* Aldana Desire Sánchez

## Proyecto Data Warehouse: The Drinking Company (TDC)

Este repositorio contiene el desarrollo del Trabajo Práctico Final para la materia Bases de Datos 2 de la Tecnicatura Universitaria en Inteligencia Artificial (TUIA). El objetivo del proyecto es diseñar e implementar un Data Warehouse completo para la compañía "The Drinking Company" (TDC) a partir de sus diversos sistemas operacionales, permitiendo la elaboración de dashboards para las gerencias en Power BI.

---

## Estructura del Repositorio

El proyecto está organizado en las siguientes carpetas principales, separando las fuentes crudas, los scripts de bases de datos, el proyecto de integración y los entregables finales:

```text
├── Trabajo Práctico Final - Enunciado.pdf  # Requerimientos y consignas del TP
├── Trabajo Práctico Final - Software.pdf   # Requisitos de instalación
├── .gitignore                              # Archivos ignorados por Git
│
├── data/                                   # Fuentes de datos crudas (Staging Area)
│   ├── Area_Comercializacion/              # Clientes (XML), regiones y ventas históricas/actuales
│   ├── Area_Produccion/                    # Catálogo de productos y variaciones de stock (TXT)
│   └── Area_Recursos_Humanos/              # Nómina de empleados y feriados (Excel)
│
├── Database_Creation_Queries/              # Scripts SQL para la arquitectura de datos
│   ├── SQL_Staging_DB_Creation.sql         # Creación de la base de datos de Staging
│   ├── SQL_Intermediate_DB_Creation.sql    # Creación de la base de datos Intermedia
│   ├── SQL_DW_DB_Creation.sql              # Creación del Data Warehouse final
│   └── Documentacion_Ingesta_SSIS.md       # Notas y documentación sobre el proceso ETL para la ingesta a staging
│
├── Modelo_dimensional/                     # Diseño Conceptual y Lógico
│   ├── Modelado_Dimensional.png            # Diagrama del esquema estrella
│   └── Modelado_dimensional.sql            # Script complementario del modelado
│
├── TDC_Project/                            # Proyecto de SSIS (Visual Studio)
│   ├── Master_Pkg.dtsx                     # Paquete Maestro que orquesta el flujo general
│   ├── SSIS_Pkg_*.dtsx                     # Paquetes individuales de extracción y transformación
│   └── TDC_Project.sln                     # Solución principal de Visual Studio
│
└── Entregables/                            # Archivos finales para la corrección del TP
    ├── DataBase_TDC_Staging_DB.zip         # Backup comprimido de la BD Staging
    ├── DataBase_TDC_Intermediate.zip       # Backup comprimido de la BD Intermedia
    ├── DataBase_TDC_DataWarehouse.zip      # Backup comprimido del DW final
    ├── SSIS_Project.zip                    # Proyecto ETL comprimido completo
    └── TDC_Reportes.pbix                   # Tablero interactivo (Dashboards) en Power BI
```
