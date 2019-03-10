#' Extrae informacion del archivo .txt que proporciona EDGAR (SEC).
#'
#' @param linkArchivo una direccion a un archivo de texto desde el directorio de trabajo.
#'
#' @return  devuelve una lista con 3 elementos, el primero es la parte descriptiva del formulario;
#' el segundo es la tabla de inversiones; y el tercero el numero de filas que tiene la tabla de inversiones
#'
#' @examples
#' \dontrun{
#' linkArchivo <- paste0("https://www.sec.gov/Archives/edgar/data/",
#'               "1167557/000108514619000779/0001085146-19-000779.txt")
#'
#' extraeDatos(linkArchivo)
#' 
#' ## No es necesario utilizar paste0, aqui se ha usado porque, si no,
#' ## la documentacion de R lo corta y no se ve la direccion completa.
#' }
#'
#' @import XML
#' @import stringr
#' @import readr
#'
extraeDatos <- function(linkArchivo) {
    # print('dentro funcion extraeDatos()') la siguiente funcion la uso para extraer la informacion de la parte del encabezado
    # que es HTML
    extractFromTags <- function(txtData, pattern) {
        # print('Dentro extractFromTags2()')
        dfpos <- as.data.frame(stringr::str_locate_all(txtData, pattern)[[1]])
        # strs_locate_all : Locate the position of patterns in a string.  necesita stringr
        pto1 <- dfpos[1, 2] + 2
        pto2 <- pto1 + 50
        if (is.na(pto1)) {
            return(NA)
        }
        subHTML <- stringr::str_trim(substr(txtData, pto1, pto2))  # saca 50 caracteres desde donde empieza el campo
        dfpos3 <- as.data.frame(stringr::str_locate_all(subHTML, "\n")[[1]])  # ubica \n
        pto3 <- dfpos3[1, 1]  # ubicacion de \n
        return(stringr::str_trim(substr(subHTML, 1, pto3)))  # recorta hasta que aparece \n
    }
    ## processNode #####################################################################################################
    processNode <- function(ele) {
        if (XML::xmlSize(ele) > 1) {
            return(XML::xmlApply(ele, processNode))
        } else {
            return(XML::xmlValue(ele))
        }
    }
    ## parseXML ######################################################################################################################
    parseXML <- function(xml_root, campos) {
        datos <- NULL
        datos <- unlist(XML::xmlApply(xml_root, processNode))
        datos <- datos[intersect(campos, names(datos))]
        datos[setdiff(campos, names(datos))] <- NA
        datos <- datos[campos]
        return(datos)
    }
    ## parse13f ####################################################################################################################
    parse13f <- function(xml_root, campos) {
        info <- XML::getNodeSet(xml_root, "//*[local-name() = 'infoTable']")
        infoTable <- NULL
        n <- length(info)
        for (i in 1:length(info)) {
            linea <- unlist(XML::xmlApply(info[[i]], processNode))
            linea <- linea[intersect(campos, names(linea))]
            linea[setdiff(campos, names(linea))] <- NA
            infoTable <- rbind(infoTable, linea)
            print(i)
        }
        return(list(infoTable, n))
    }
    ## CARGO EL TEXTO : txtData #####################################################################################
    txtData <- readr::read_file(linkArchivo)  # cargo el contenido del archivo de texto, funcion del paquete readr de tityverse
    ## HEADER ########################################################################################################
    ## print('Dentro Cover Page') Campos de la cara tula
    fields <- c("ACCEPTANCE-DATETIME", "ACCESSION NUMBER", "CONFORMED SUBMISSION TYPE", "PUBLIC DOCUMENT COUNT", "CONFORMED PERIOD OF REPORT",
        "FILED AS OF DATE", "DATE AS OF CHANGE", "EFFECTIVENESS DATE", "COMPANY CONFORMED NAME", "CENTRAL INDEX KEY", "IRS NUMBER",
        "STATE OF INCORPORATION", "FISCAL YEAR END", "FORM TYPE", "FORMER CONFORMED NAME", "DATE OF NAME CHANGE")
    n <- length(fields)
    headerdf <- data.frame(matrix(ncol = n, nrow = 1))
    colnames(headerdf) <- c("acceptanceDateTime", "accessionNumber", "submissionType", "docCount", "period", "filedDate", "changeDate",
        "effectivenessDate", "companyName", "CIK", "IRS", "state", "fiscalYear", "formType", "formerName", "dateOfNChange")
    for (i in 1:n) {
        headerdf[1, i] <- extractFromTags(txtData, fields[i])
        # saca el contenido de cada uno de los campos usando las etiquetas del texto HTML
    }
    ## A partir de aqui el codigo para extraer el XML ####################################################################
    pattern <- "<XML>|</XML>"
    dfpos = as.data.frame(stringr::str_locate_all(txtData, pattern)[[1]])
    pto1 <- dfpos[1, 2] + 1
    pto2 <- dfpos[2, 2] - 6
    pto3 <- dfpos[3, 2] + 1
    pto4 <- dfpos[4, 2] - 6
    # str_trim removes whitespace from start and end of string
    edgarSubmission <- stringr::str_trim(substr(txtData, pto1, pto2))
    informationTable <- stringr::str_trim(substr(txtData, pto3, pto4))  # str_trim removes whitespace from start and end of string
    rm(txtData)
    ## EDGAR SUBMISSION ###############################################################################################
    ## print('Dentro Summary')
    xmlfile <- XML::xmlParse(edgarSubmission)  # limpia y deja solo la estructura XML, es decir, construye el arbol XML
    # devuelve un XMLInternalDocument
    rm(edgarSubmission)
    root <- XML::xmlRoot(xmlfile)  # xml_root <- root
    rm(xmlfile)
    edgarSubmissiondf <- parseXML(root, campos = c("headerData.submissionType", "formData.coverPage.isAmendment", "formData.coverPage.reportType",
        "formData.summaryPage.otherIncludedManagersCount", "formData.summaryPage.tableEntryTotal", "formData.summaryPage.tableValueTotal"))

    names(edgarSubmissiondf) <- c("submissionType", "isAmendment", "reportType", "otherIncludedManagersCount", "tableEntryTotal",
        "tableValueTotal")
    rm(root)

    desdf <- as.data.frame(c(headerdf, edgarSubmissiondf))

    ## INFORMATIONTABLE (HOLDINGS) ###############################################################################################
    if (!is.na(informationTable)) {
        xmlfile <- XML::xmlParse(informationTable)  # limpia y deja solo la estructura XML, es decir, construye el arbol XML
        rm(informationTable)
        # devuelve un XMLInternalDocument
        root <- XML::xmlRoot(xmlfile)  # xml_root <- root
        rm(xmlfile)
        data <- parse13f(root, campos = c("nameOfIssuer", "titleOfClass", "cusip", "value", "shrsOrPrnAmt.sshPrnamt", "shrsOrPrnAmt.sshPrnamtType",
            "investmentDiscretion", "otherManager", "votingAuthority.Sole", "votingAuthority.Shared", "votingAuthority.None",
            "putCall"))
        informationTabledf <- as.data.frame(data[[1]], stringsAsFactors = F)
        desdf$tableEntryTotal2  <- data[[2]]
        rownames(informationTabledf) <- NULL
        rm(root)
        informationTabledf$accessionNumber <- headerdf$accessionNumber
    } else {
        informationTabledf <- informationTable
    }
    # devuelve dos dataframes
    return(list(desdf, informationTabledf))  # datos <- list(desdf, informationTabledf)
}
