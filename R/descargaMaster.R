#' Es una funcion interna que descarga un archivo en el directorio de trabajo
#' Es llamada por la funcion \link[sec13f.es]{indice13f}
#'
#' @usage descargaMaster(link, nombreArchivo, metodoD)
#'
#' @param link direccion donde se encuentra el archivo a descargar
#' @param nombreArchivo que se le da al archivo una vez descargado
#' @param metodoD metodo de descarga
#'
#' @return descarga el archivo master y devuelve verdadero o falso en funcion de si ha podido descargarlo o no
#'
#' @examples
#' \dontrun{
#'
#' descargaMaster(link, nombreArchivo, metodoD)
#'
#'}
#'
#'@import R.utils
#'
descargaMaster <- function(link,
                           nombreArchivo,
                           metodoD) {
    tryCatch({
        utils::download.file(link, nombreArchivo, method = metodoD, quiet = TRUE)
        return(TRUE)
    }, error = function(e) {
                    return(FALSE)
                })
}

