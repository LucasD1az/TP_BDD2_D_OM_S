# Trabajo Práctico Final - Bases de Datos 2 (TUIA)

Comisión 2 - Grupo 20

Integrantes:
* Aldana Desire Sánchez
* Lisandro Odisio Martinelli
* Lucas Diaz Celauro

## Proyecto Data Warehouse: The Drinking Company (TDC)

Este repositorio contiene el desarrollo del Trabajo Práctico Final para la materia Bases de Datos 2 de la Tecnicatura Universitaria en Inteligencia Artificial (TUIA). El objetivo del proyecto es diseñar e implementar un Data Warehouse completo para la compañía "The Drinking Company" (TDC) a partir de sus diversos sistemas operacionales, permitiendo la elaboración de dashboards para las gerencias en Power BI.

---

## Estructura del Repositorio

Actualmente, el proyecto cuenta con el enunciado oficial y las fuentes de datos operacionales distribuidas por áreas de negocio:

```text
├── Trabajo Práctico Final - Enunciado.pdf  # Requerimientos y consignas del TP
├── .gitignore                              # Archivos ignorados por Git
└── data/                                   # Fuentes de datos crudas
    ├── Area_Comercializacion/
    │   ├── customer_R.xml                  # Clientes minoristas (Retail)
    │   ├── customer_W.xml                  # Clientes mayoristas (Wholesale)
    |   ├── Regions.txt                     # Ciudades con sus regiones
    |   ├── TDChistorySales_2019.bak        # Ventas históricas (hasta 2008 inclusive)
    |   └── sales.sql                       # Ventas actuales
    ├── Area_Produccion/
    │   ├── Products.txt                    # Catálogo de productos
    │   └── Stock.txt                       # Variaciones de inventario 
    └── Area_Recursos_Humanos/
        ├── Employee.xls                    # Nómina de empleados y sus datos
        └── Holidays.xls                    # Calendario de feriados de la empresa
