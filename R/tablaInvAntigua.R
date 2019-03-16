library(stringi)
library(stringr)

tablaInvAntigua <- function(txtData){

   ## informationTable antigua
   pattern <- "NAME OF ISSUER|</TABLE>"
   dfpos = as.data.frame(stringr::str_locate_all(txtData, pattern)[[1]])
   pto1 <- dfpos[1, 1]
   pto2 <- dfpos[2, 1] - 2
   
   informationTable <- stringr::str_trim(substr(txtData, pto1, pto2))  
   txtLines <- stringi::stri_split_lines(informationTable)[[1]]
   marca <- max(grep("---", txtLines))
   fieldpos <- as.data.frame(stringr::str_locate_all(stringr::str_trim(txtLines[marca]), " -")[[1]])
   fieldpos <- fieldpos$start
   fieldpos <- c(fieldpos, nchar(txtLines[marca]))
   txtLines2 <- txtLines[-c(1:marca)]
   
   iTabla <- data.frame()
   campos <- c("nameOfIssuer", "titleOfClass", "cusip", "value", "shrsOrPrnAmt.sshPrnamt", "shrsOrPrnAmt.sshPrnamtType",
               "putCall", "investmentDiscretion", "otherManager", "votingAuthority.Sole", "votingAuthority.Shared", 
               "votingAuthority.None")
   
   for (i in 1:length(campos)){
      if (i > 1){
         iTabla <- cbind(iTabla, stringr::str_trim(substr(txtLines2, fieldpos[i-1] + 1, fieldpos[i])))
         colnames(iTabla)[i] <- campos[i]
      } else{
         iTabla <- data.frame(stringr::str_trim(substr(txtLines2, 1, fieldpos[i])))
         colnames(iTabla) <- campos[i]
      }
   }
   infoTabla <- iTabla[nchar(as.character(iTabla$cusip)) == 9, ]
   return(infoTabla) 
}