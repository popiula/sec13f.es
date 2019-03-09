#' Es una funcion interna que descarga un archivo en el directorio de trabajo
#' Es llamada por la funcion \link[sec13f]{indice13f}
#'
#' @usage descargaMaster(link, filename, dmethod)
#'
#' @param link direccion donde se encuentra el archivo a descargar
#' @param filename nombre que se le da al archivo una vez descargado
#' @param dmethod metodo de descarga
#'
#' @return descarga el archivo master y devuelve verdadero o falso en funcion de si ha podido descargarlo o no
#'
#' @examples
#' \dontrun{
#'
#' descargaMaster(link, filename, dmethod)
#'
#'}
#'
#'@import R.utils
#'
#'@export
descargaMaster <- function(link, nombreArchivo, metodoD) {
    tryCatch({
        utils::download.file(link, nombreArchivo, method = metodoD, quiet = TRUE)
        return(TRUE)
    }, error = function(e) {
                    return(FALSE)
                })
}

