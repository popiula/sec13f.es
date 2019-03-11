# Paquete sec13f.es  
  
---  
  
## Introduccion
  
---  
  

El objetivo del paquete es facilitar al usuario de R una herramienta para crear un dataset con los datos historicos y actuales de los formularios 13f que la SEC pone a disposicion del publico a traves de la plataforma EDGAR. 
  
  
## Como funciona el paquete
  
---  
  
La secuencia es la siguiente:
La funcion `indice13f()` descarga un archivo indice master que se carga en mongoDB y que sirve de mapa para que `recorreFormularios()` pueda ir recorriendo y extrayendo los datos de todos los archivos de texto que contienen la información del formulario 13f en la plataforma EDGAR de la SEC.
  
  
## Requisitos previos
  
---  
  
El paquete construye una base de datos en MongoDB por lo tanto es necesario tenerlo instalado. La [documentacion](https://docs.mongodb.com/) de MongoDB esta en ingles pero hay multiples tutoriales online en espanol. 

[Guia oficial de installacion de MongoDB](https://docs.mongodb.com/guides/server/install/)

Tambien es recomedable instalar una GUI para poder acceder a los datos desde fuera de R y chequear que todo esta funcionando correctamente. Puede ser la [propia de MongoDB](https://www.mongodb.com/products/compass) o cualquier otra. También se puede acceder a los datos desde la Shell de Mongo, es una cuestion de preferencias el hacerlo de una manera o de otra. Para no iniciados creo que es mas sencillo hacerlo a traves de una GUI.
  
  
## Por donde empezar
    
---  
   
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
  
---  
  
```r
library("sec13f.es")

periodo = 2019
nombreBD = "EDGAR13F"
mongoURL = "mongodb://localhost:27017"

master <- indice13f(periodo, nombreBD, mongoURL)
print(head(master))

registro <- recorreFormularios(nombreBD, mongoURL)

  ## La ejecucion de esta funcion puede tardar bastante tiempo.
  ## Tarda alrededor de un segundo por formulario asi que recorrer 
  ## 5.000 formularios que es mas o menos lo que tiene un trimestre,
  ## puede suponer algo mas de una hora.

library(mongolite)
conexion <- mongo(collection = "indice", db = nombreBD, url = mongoURL)
print(head(conexion$find()))
```

  
### Output: base de datos de mongoDB
  
---  
  
La base de datos tiene las siguientes colecciones:

* indice
* registro
* header
* holdings: una por cada periodo 

  
#### indice
  
---  
  
El dataframe contiene las siguientes variables:

+ accessionNumber = id del formulario   
+ cik = id del inversor
+ companyName = nombre del inversor
+ formType = tipo de formulario
+ dateFiled = fecha de envio
+ edgarLink = link para localizar el archivo en EDGAR  
  
```r  
> head(master)
       accessionNumber     cik                        companyName formType  dateFiled
1 0000919574-18-001804 1000097 KINGDON CAPITAL MANAGEMENT  L L C    13F-HR 2018-02-14
2 0001140361-18-008010 1000275               ROYAL BANK OF CANADA   13F-HR 2018-02-14
3 0001000490-18-000001 1000490               GIRARD PARTNERS LTD    13F-HR 2018-02-07
4 0001140361-18-008253 1000742         SANDLER CAPITAL MANAGEMENT   13F-HR 2018-02-14
5 0000950123-18-002599 1001085   BROOKFIELD ASSET MANAGEMENT INC  13F-HR/A 2018-02-15
6 0000950123-18-002829 1001085   BROOKFIELD ASSET MANAGEMENT INC  13F-HR/A 2018-03-05
                                    edgarLink
1 edgar/data/1000097/0000919574-18-001804.txt
2 edgar/data/1000275/0001140361-18-008010.txt
3 edgar/data/1000490/0001000490-18-000001.txt
4 edgar/data/1000742/0001140361-18-008253.txt
5 edgar/data/1001085/0000950123-18-002599.txt
6 edgar/data/1001085/0000950123-18-002829.txt
```
  
      
#### registro
  
---  
  
Incluye informacion de la ejecucion de recorreFormularios(): a que hora empieza, el accessionNumber de cada formulario cargado, a que hora se carga cada formulario, cuantos formularios se han cargado, cuantas filas tiene la tabla de inversiones de ese formulario y el tiempo medio de carga.

Si se interrumpe a medias la ejecucion de recorreFormularios() por voluntad del usuario (que puede hacerlo pulsando `escape`) o por algun error, se interrumpira la carga pero se mantendran en la base de datos los formularios que ya hayan sido cargados durante la ejecucion, antes de la interrupcion.

+ nform = puesto que ocupa el formulario en el orden de la carga 
+ totalForms = numero total de formularios en la carga    
+ accessionNumber = numero de identificacion de un formulario asignado por la SEC  
+ horaInicio = hora de inicio de la carga de un conjunto de formularios
+ horaCarga = hora de fin de la carga de un conjunto de formularios 
+ tiempoMedio = tiempo medio dedicado a extraer y cargar los datos de cada formulario en esta carga (la carga se define por el numero de formularios a cargar y la hora de inicio)
+ excedeTiempo = 1 si excede el limite de tiempo definido y salta al siguiente formulario sin cargarlo y 0 si se carga dentro del tiempo establecido.
+ nfilas = numero de filas que se cargan de la tabla de inversiones

```r
> tail(registro)

      nform totalForms      accessionNumber horaInicio horaCarga tiempoMedio excedeTiempo nfilas
20217  3366       3371 0001144204-18-000071   07:32:12  08:39:20         1.2            0     89
20218  3367       3371 0001601622-18-000001   07:32:12  08:39:20         1.2            0     17
20219  3368       3371 0001624809-18-000001   07:32:12  08:39:21         1.2            0     34
20220  3369       3371 0001637246-18-000001   07:32:12  08:39:21         1.2            0    205
20221  3370       3371 0001680091-18-000001   07:32:12  08:39:23         1.2            0    674
20222  3371       3371 0001144204-18-000220   07:32:12  08:39:24         1.2            0    598
```
  
  
#### header
  
---  
  
      
#### holdings
  
---  
    
      
## Copyright and License

Copyright 2019 Ana Guardia  
Licensed under the GPLv3
