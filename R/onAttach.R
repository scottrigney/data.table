# nocov start

.onAttach <- function(libname, pkgname) {
  # Runs when attached to search() path such as by library() or require()
  if (!interactive()) return()
  v = packageVersion("data.table")
  d = read.dcf(system.file("DESCRIPTION", package="data.table"), fields = c("Packaged", "Built", "Revision"))
  if (is.na(d[1L])) {
    if (is.na(d[2L])) {
      return() # Packaged, Built fields does not exists
    } else {
      d = unlist(strsplit(d[2L], split="; "))[3L]
      g = if (is.na(d[3L])) "" else paste0(" (",d[3L],")")
    }
  } else {
      d = d[1L]
      g = ""
  }
  dev = as.integer(v[1L, 3L]) %% 2L == 1L  # version number odd => dev
  packageStartupMessage("data.table ", v, if(dev)paste0(" IN DEVELOPMENT built ",d,g), "  Latest news: http://r-datatable.com")
  if (dev && (Sys.Date() - as.Date(d))>28)
    packageStartupMessage("**********\nThis development version of data.table was built more than 4 weeks ago. Please update: data.table::update.dev.pkg()\n**********")
  if (!.Call(ChasOpenMP))
    packageStartupMessage("**********\nThis installation of data.table has not detected OpenMP support. It should still work but in single-threaded mode. If this is a Mac, please ensure you are using R>=3.4.0 and have followed our Mac instructions here: https://github.com/Rdatatable/data.table/wiki/Installation. This warning message should not occur on Windows or Linux. If it does, please file a GitHub issue.\n**********")
}

dcf.lib = function(pkg, field){
  # get DESCRIPTION metadata field from local library
  stopifnot(is.character(pkg), is.character(field), length(pkg)==1L, length(field)==1L)
  dcf = system.file("DESCRIPTION", package=pkg)
  if (nzchar(dcf)) read.dcf(dcf, fields=field)[1L] else NA_character_
}

dcf.repo = function(pkg, repo, field){
  # get DESCRIPTION metadata field from remote PACKAGES file
  stopifnot(is.character(pkg), is.character(field), length(pkg)==1L, length(field)==1L, is.character(repo), length(repo)==1L, field!="Package")
  idx = file(file.path(contrib.url(repo),"PACKAGES"))
  on.exit(close(idx))
  dcf = read.dcf(idx, fields=c("Package",field))
  if (!pkg %in% dcf[,"Package"]) stop(sprintf("There is no %s package in provided repository.", pkg))
  dcf[dcf[,"Package"]==pkg, field][[1L]]
}

update.dev.pkg = function(object="data.table", repo="https://Rdatatable.github.io/data.table", field="Revision", ...){
  pkg = object
  # perform package upgrade when new Revision present
  stopifnot(is.character(pkg), length(pkg)==1L, !is.na(pkg),
            is.character(repo), length(repo)==1L, !is.na(repo),
            is.character(field), length(field)==1L, !is.na(field))
  una = is.na(ups<-dcf.repo(pkg, repo, field))
  upg = una | !identical(ups, dcf.lib(pkg, field))
  if (upg) utils::install.packages(pkg, repos=repo, ...)
  if (una) cat(sprintf("No commit information found in DESCRIPTION file for %s package. Unsure '%s' is correct field name in PACKAGES file in your devel repository '%s'.\n", pkg, field, file.path(repo, "src","contrib","PACKAGES")))
  cat(sprintf("R %s package %s %s (%s)\n",
              pkg,
              c("is up-to-date at","has been updated to")[upg+1L],
              dcf.lib(pkg, field),
              utils::packageVersion(pkg)))
}

# nocov end
