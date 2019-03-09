.onAttach <- function(libname, pkgname) {
    packageStartupMessage("Hola caracola")
}

.onLoad <- function(libname, pkgname) {
    op <- options()
    op.devtools <- list(
        devtools.path = "~/R-dev",
        devtools.install.args = "",
        devtools.name = "Ana",
        devtools.desc.author = "Ana Guarida <ana.guardia@gmail.com> [aut, cre]",
        devtools.desc.license = "GPL-3",
        devtools.desc.suggests = NULL,
        devtools.desc = list()
    )
    toset <- !(names(op.devtools) %in% names(op))
    if(any(toset)) options(op.devtools[toset])

    invisible()
}
