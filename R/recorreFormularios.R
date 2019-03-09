#' Descarga y devuelve el contenido de los formularios de un archivo indice o solo los descarga, a eleccion del usuario
#'
#' \link[sec13f.es]{recorreFormularios} Recorre los formularios de la SEC contenidos en la coleccion que se pasa como input
#' y almacena la informacion en dos colecciones de documentos de mongo. Una para la tabla de inversiones y otra para el
#' resto de informacion del formulario 13f. Utiliza \link[sec13f.es]{extraeDatos} para extraer la informacion de cada
#' formulario.
#'
#' @usage recorreFormularios(coleccion = paste0(format(Sys.Date(),'%Y%m%d'), 'indice'),
#'                           db = paste0(format(Sys.Date(),'%Y%m%d'), 'sec13f'),
#'                           mongoURL = 'mongodb://localhost:27017')
#'
#' @param coleccion nombre de la coleccion de mongo que contiene el indice de los formularios a recorrer
#' @param bd nombre de la base de datos de mongo que contiene el indice de los formularios a recorrer
#' @param mongoURL parametro de la url necesaria para concectar con mongo
#'
#' @return devuelve el dataframe con el listado de los formularios registrados en ese o esos periodos.
#'   lo descarga de \url{https://www.sec.gov/Archives/edgar/full-index/}
#'   Tambien devuelve el estado de la descarga y el numero de formularios e inversores recibidos en ese/esos
#'   periodos.
#'
#' @examples
#' \dontrun{
#' recorreFormularios(coleccion = paste0(format(Sys.Date(),'%Y%m%d'), 'indice'),
#'                    bd = paste0(format(Sys.Date(),'%Y%m%d'), 'sec13f'),
#'                    mongoURL = 'mongodb://localhost:27017')
#'}
#'
#'@import mongolite
#'@import dplyr
#'@import stringr
#'
#'@export
recorreFormularios <- function( coleccion = paste0( format(Sys.Date(), "%Y%m%d"), "indice"),
                                bd = paste0( format(Sys.Date(), "%Y%m%d"), "sec13f"),
                                mongoURL = "mongodb://localhost:27017") {
    inicio <- Sys.time()  # se usa para calcular el tiempo medio
    # options(warn = -1) # remove warnings
    master <- limpiaMaster(coleccion = coleccion, bd = bd, mongoURL = mongoURL)
    master <- arrange(master, desc(DATE_FILED))
    if (nrow(master) > 0) {
        total.forms <- nrow(master)
        print(paste0("Formularios a cargar: ", total.forms))
        if (!file.exists(dirName))
            {
                dir.create(dirName)
            }  # crea la carpeta si no existe ya
        for (i in 1:total.forms) {
            link <- paste0("https://www.sec.gov/Archives/", master$EDGAR_LINK[i])
            # print(paste0('Dentro extraeDatos() a las : ', format(Sys.time(), '%H:%M:%S')))
            superaTiempo <- 0
            datos <- NULL
            tryCatch({
                datos <- withTimeout({
                  extraeDatos(link)
                }, timeout = 60 * 5)
            }, TimeoutException = function(ex) {
                message(paste0(str_sub(master$EDGAR_LINK[i], -24, -5), " Timeout. Salta el formulario."))
            })

            if (is.null(datos)) {
                superaTiempo <- 1
            }
            tmedio <- as.character(round(difftime(Sys.time(), inicio, units = "secs")/i, digits = 2))  # tiempo medio de computacion en segundos - descarga y carga en json
            tempStatus <- data.frame(nform = i, totalForms = total.forms, accessionNumber = str_sub(master$EDGAR_LINK[i], -24,
                -5), hora = format(Sys.time(), "%H:%M:%S"), tiempoMedio = tmedio, excedeTiempo = superaTiempo, nfilas = datos[[3]])
            print(tempStatus)
            conexion <- mongo(collection = "registro", db = "sec13f", url = "mongodb://localhost:27017")
            conexion$insert(tempStatus)
            ## vamos con mongoDB ################################################################################################ inicio
            ## una conexion en mongoDB ###########################################################################################3
            if (superaTiempo == 0) {
                conexion <- mongo(collection = "des13f", db = "sec13f", url = "mongodb://localhost:27017")
                conexion$insert(datos[[1]])
                if (!is.na(datos[[2]])) {
                  conexion <- mongo(collection = "holdings13f", db = "sec13f", url = "mongodb://localhost:27017")
                  conexion$insert(datos[[2]])
                } else {
                  conexion <- mongo(collection = "incidenciasHoldings", db = "sec13f", url = "mongodb://localhost:27017")
                  conexion$insert(datos[[1]]$accessionNumber)
                }
            } else if (superaTiempo == 1) {
                print("Error en el formulario, salto al siguiente")
                conexion <- mongo(collection = "incidencias", db = "sec13f", url = "mongodb://localhost:27017")
                conexion$insert(str_sub(master$EDGAR_LINK[i], -24, -5))
            }
        }  # loop
        conexion <- mongo(collection = "registro", db = "sec13f", url = "mongodb://localhost:27017")
        registro <- conexion$find()
        return(registro)
    }
}
