# Paquete sec13f.es

## Introduccion

El objetivo del paquete es facilitar al usuario de R una herramienta para crear un dataset con los datos historicos y actuales de los formularios 13f que la SEC pone a disposicion del publico a traves de la plataforma EDGAR. 

## Como funciona el paquete

La secuencia es la siguiente:
La funcion `indice13f()` descarga un archivo indice master que se carga en mongoDB y que sirve de mapa para que `recorreFormularios()` pueda ir recorriendo y extrayendo los datos de todos los archivos de texto que contienen la información del formulario 13f en la plataforma EDGAR de la SEC.

## Requisitos previos

El paquete construye una base de datos en MongoDB por lo tanto es necesario tenerlo instalado. La [documentacion](https://docs.mongodb.com/) de MongoDB esta en ingles pero hay multiples tutoriales online en espanol.

Tambien es recomedable instalar una GUI para poder acceder a los datos desde fuera de R y chequear que todo esta funcionando correctamente. Puede ser la [propia de MongoDB](https://www.mongodb.com/products/compass) o cualquier otra.

## Por donde empezar

Lo primero que necesitas es instalar y cargar el paquete `devtools` desde CRAN:

```r
install.packages("devtools")
library(devtools)
```
Despues, instala el paquete `sec13f.es` desde GitHub:

```r
install_github("Popiula/sec13f.es")
```
## Un ejemplo sencillo

```r
library("sec13f.es")

periodo = 2019
nombreColeccion = "INDICE"
nombreBD = "EDGAR13F"
mongoURL = "mongodb://localhost:27017"

master <- indice13f( periodo, nombreColeccion, nombreBD, mongoURL)
print(head(master))

registro <- recorreFormularios( nombreColeccion, nombreBD, mongoURL)

  ## La ejecucion de esta funcion puede tardar bastante tiempo.
  ## Tarda alrededor de un segundo por formulario asi que recorrer 
  ## 5.000 formularios que es mas o menos lo que tiene un trimestre,
  ## puede suponer algo mas de una hora.

library(mongolite)
conexion <- mongo(collection = nombreColeccion, db = nombreBD, url = mongoURL)
print(head(conexion$find()))
```

### Output: la base de datos de mongoDB

La base de datos tiene las siguientes colecciones:

+ registro
+ indice
+ header
+ holdings: una por cada periodo 

#### registro

Incluye informacion de la ejecucion de recorreFormularios(): a que hora empieza, el accessionNumber de cada formulario cargado, a que hora se carga cada formulario, cuantos formularios se han cargado, cuantas filas tiene la tabla de inversiones de ese formulario y el tiempo medio de carga.

Si se interrumpe a medias la ejecucion de recorreFormularios() por voluntad del usuario (que puede hacerlo pulsando `escape`) o por algun error, se interrumpira la carga pero se mantendran en la base de datos los formularios que ya hayan sido cargados durante la ejecucion, antes de la interrupcion.

#### indice

#### header

#### holdings

## Copyright and License

Copyright 2019 Ana Guardia  
Licensed under the GPLv3
