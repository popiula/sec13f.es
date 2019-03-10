#' Carga en la base de datos el indice de formularios
#'
#' \code{indice13f} descarga la informacion del archivo 'master' trimestral de la SEC para
#'  los anos solicitados, los une y carga la informacion en la base de datos de mongoDB.
#'  Si la coleccion esta vacia carga todos los registros del indice y si no esta vacia,
#'  carga solo los que aun no estan en ese indice en mongoDB.
#'
#' La funcion indice13f toma como input del usuario el ano o los anos, y descarga
#' el archivo trimestral 'master' de la SEC que contiene un listado de los formularios enviados.
#' La direccion de la que lo descarga es : https://www.sec.gov/Archives/edgar/full-index/.
#' Une los listados de todos los trimestres en uno y lo carga en una coleccion de mongoDB.
#' Tambien devuelve un dataframe con el contenido que ha cargado en mongo.
#'
#' El dataframe contiene las siguientes variables:
#' 'accessionNumber' 'cik' 'companyName' 'formType' 'dateFiled' 'edgarLink'
#'
#' Utiliza la funcion: descargaMaster.R de este paquete
#'
#' @param periodo el ano en numero entero o vector de n?meros enteros para los que se quiere
#' descargar el archivo 'master'.
#' @param nombreBD nombre de la base de datos de mongo en la que se va a guardar la coleccion que contiene el indice
#' @param mongoURL url de la base de datos de mongo, Por defecto, "mongodb://localhost:27017")
#'
#' @return devuelve un dataframe con los datos del indice master
#'
#' @examples
#' \dontrun{
#' master <- indice13f(periodo = 2014:2019,
#'                     nombreBD = "sec13f",
#'                     mongoURL = "mongodb://localhost:27017"
#'                     )
#'
#' ## Descarga un listado de los formularios enviados entre 2013 y 2018.
#' }
#'
#' @import mongolite
#' @import R.utils
#' @import stringr
#'
#' @export
indice13f <- function(periodo = lubridate::year(Sys.Date()),
                      nombreBD = paste0(format(Sys.Date(), "%Y%m%d"), "sec13f"),
                      mongoURL = "mongodb://localhost:27017") {
    
    if (!is.numeric(periodo)) {
        cat("El formato para el periodo es aaaa o un array de anos como 2016:2018.")
        return()
    }
    # si no se pone nada en ano actualiza el indice, si se pone algo lo genera nuevo

    # Check the download compatibility based on OS
    if (nzchar(Sys.which("libcurl"))) {
        metodoD <- "libcurl"
    } else if (nzchar(Sys.which("wget"))) {
        metodoD <- "wget"
    } else if (nzchar(Sys.which("curl"))) {
        metodoD <- "curl"
    } else {
        metodoD <- "auto"
    }

    # options(warn = -1)

    estado <- data.frame()
    master <- data.frame()  # inicializo master que es el data frame que va a contener el listado completo

    for (i in 1:length(periodo)) {
        year <- periodo[i]
        submaster <- data.frame()
        quarterloop <- 4

        # Find the number of quarter completed in that year
        if (year == format(Sys.Date(), "%Y")) {
            quarterloop <- ceiling(as.integer(format(Sys.Date(), "%m"))/3)
        }

        for (quarter in 1:quarterloop) {
            # save downloaded file as specific name
            archivoComprimido <- paste0(year, "QTR", quarter, "master.gz")
            archivo <- paste0(year, "QTR", quarter, "master")

            # form a link to download master file
            link <- paste0("https://www.sec.gov/Archives/edgar/full-index/", year, "/QTR", quarter, "/master.gz")

            res <- descargaMaster(link, archivoComprimido, metodoD)

            if (isTRUE(res)) {
                # Unzip gz file
                R.utils::gunzip(archivoComprimido, destname = archivo, temporary = FALSE, skip = FALSE, overwrite = TRUE, remove = TRUE)
                cat("Trimestre ", quarter, " de ", year, "-> descarga correcta.\n")

                # Removing ''' so that scan with '|' not fail due to occurrence of ''' in company name
                data <- gsub("'", "", readLines(archivo))

                # Find line number where header description ends
                header.end <- grep("--------------------------------------------------------", data)

                # writting back to storage
                writeLines(data, archivo)

                d <- scan(archivo, what = list("", "", "", "", ""), flush = F, skip = header.end, sep = "|", quiet = T)

                # Remove punctuation characters from company names
                companyName <- gsub(pattern = "[[:punct:]]", replacement = " ", d[[2]], perl = T)

                data <- data.frame(accessionNumber = stringr::str_sub(d[[5]], -24, -5), cik = d[[1]], companyName = companyName, formType = d[[3]],
                  dateFiled = d[[4]], edgarLink = d[[5]])

                data <- data[stringr::str_detect(data$formType, "13F-HR"), ]
                data$dateFiled <- as.Date(data$dateFiled)
                submaster <- rbind(submaster, data)
                file.remove(archivo)
                estado <- rbind(estado, data.frame(filed = paste0("Trimestre ", quarter, " de ", year), estado = "-> Descarga correcta",
                  formularios = nrow(data), inversores = length(unique(data$cik))))
            } else {
                estado <- rbind(estado, data.frame(filed = paste0("Trimestre ", quarter, " de ", year), estado = "-> Problema con el servidor",
                  formularios = 0, inversores = 0))
            }
        }
        master <- rbind(master, submaster)
    }
    conexion <- mongolite::mongo(collection = "indice", db = nombreBD, url = mongoURL)
    # si la coleccion esta vacia entonces
    if (is.null(conexion$info()$stats$count)) {
        conexion$insert(master)
        conexion$index(add = "{\"accessionNumber\" : 1}")
    } else {
        masterAnterior <- conexion$find(query = "{}", fields = "{\"accessionNumber\" : true}"  #query = '{}', fields = '{'accessionNumber' : true, '_id': true}'
)
        master <- master[!(master$accessionNumber %in% masterAnterior$accessionNumber), ]
        conexion$insert(master)
    }

    print(estado)

    return(master)
}
