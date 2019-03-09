#' Descarga y devuelve el contenido de los formularios de un archivo indice o solo los descarga, a eleccion del usuario
#'
#' \link[sec13f.es]{limpiaMaster} Elimina del indice los formularios ya cargados en la base de datos de mongo
#' Es llamada por la funcion \link[sec13f.es]{recorreFormularios} para evitar duplicar el trabajo y duplicar los registros de formularios.
#'
#' @usage limpiaMaster(coleccion = paste0(format(Sys.Date(),'%Y%m%d'), 'indice'),
#'                     nombreBD = paste0(format(Sys.Date(),'%Y%m%d'), 'sec13f'),
#'                     mongoURL = 'mongodb://localhost:27017')
#'
#' @param coleccion nombre de la coleccion de mongo que contiene el indice de los formularios a recorrer
#' @param nombreBD nombre de la base de datos de mongo que contiene el indice de los formularios a recorrer
#' @param mongoURL parametro de la url necesaria para concectar con mongo
#'
#' @return dataframe con los resultados
#'
#' @examples
#' \dontrun{
#'
#' limpiaMaster(coleccion = paste0(format(Sys.Date(),'%Y%m%d'), 'indice'),
#'              nombreBD = paste0(format(Sys.Date(),'%Y%m%d'), 'sec13f'),
#'              mongoURL = 'mongodb://localhost:27017')
#'
#'}
#'
#'@import mongolite
#'@import stringr
#'@import dplyr
#'
limpiaMaster <- function(coleccion = paste0(format(Sys.Date(), "%Y%m%d"), "indice"),
                         nombreBD = paste0(format(Sys.Date(), "%Y%m%d"), "sec13f"),
                         mongoURL = "mongodb://localhost:27017") {
# options(warn = -1) # remove warnings library(mongolite)
conexion <- mongo(collection = coleccion, db = bd, url = url)
master <- conexion$find()
conexion <- mongo(collection = "des13f", db = bd, url = url)
mongoMaster <- conexion$find(query = "{}", fields = "{\"accessionNumber\" : true, \"_id\": false}"  #query = '{}', fields = '{'accessionNumber' : true, '_id': true}'
)

    # necesito quedarme con las id que son los accession numbers library('dplyr') library('stringr')
    masterLimpio <- master[!(stringr::str_sub(master$EDGAR_LINK, -24, -5) %in% mongoMaster$accessionNumber), ]
    return(masterLimpio)
}
