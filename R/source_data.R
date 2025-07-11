#' Load plain-text data and RData from a URL (either http or https)
#'
#' \code{source_data} loads plain-text or RDATA formatted data stored at a URL
#' (both http and https) into R.
#' @param url The data's URL. To distinguish between plain-text and RDATA the
#' \code{url} must end in a distinguishing file extension.
#' @param rdata logical. Whether or not the data set is an \code{.RDATA} file.
#' If not specified than \code{source_url} will attempt to determine whether or
#' not the file is an \code{.RDATA} file from the URL's extension.
#' @param sha1 Character string of the file's SHA-1 hash, generated by
#' \code{source_data}. Note if you are using data stored using Git, this is not
#' the file's commit SHA-1 hash.
#' @param cache logical. Whether or not to cache the data so that it is not
#' downloaded every time the function is called.
#' @param clearCache logical. Whether or not to clear the downloaded data from
#' the cache.
#' @param sep The separator method for the plain-text data. For example, to load
#' comma-separated values data (CSV) use \code{sep = ","}. To load
#' tab-separated values data (TSV) use \code{sep = "\t"}. Only relevant for
#' plain-text data.
#' @param header Logical, whether or not the first line of the file is the
#' header (i.e. variable names).
#' @param stringsAsFactors logical. Convert all character columns to factors?
#' @param envir the environment where the data should be loaded.
#' @param ... additional arguments passed to \code{\link[data.table]{fread}} or
#' \code{\link{load}} as relevant.
#'
#' @return a data frame
#'
#' @details Loads plain-text data (e.g. CSV, TSV) or RDATA from a URL. Works with
#' both HTTP and HTTPS sites. Note: the URL you give for the \code{url} argument
#' must be for the RAW version of the file. The function should work to download
#' plain-text data from any secure URL (https), though I have not verified this.
#'
#' From the \code{source_url} documentation: "If a SHA-1 hash is specified with
#' the \code{sha1} argument, then this function will check the SHA-1 hash of the
#' downloaded file to make sure it matches the expected value, and throw an error
#' if it does not match. If the SHA-1 hash is not specified, it will print a
#' message displaying the hash of the downloaded file. The purpose of this is to
#'  improve security when running remotely-hosted code; if you have a hash of
#' the file, you can be sure that it has not changed."
#' @examples
#' \dontrun{
#' # Download electoral disproportionality data stored on GitHub
#' # Note: Using shortened URL created by bitly
#' DisData <- source_data("http://bit.ly/156oQ7a")
#'
#' # Check to see if SHA-1 hash matches downloaded file
#' DisDataHash <- source_data("http://bit.ly/Ss6zDO",
#'    sha1 = "dc8110d6dff32f682bd2f2fdbacb89e37b94f95d")
#' }
#' @source Originally based on source_url from the Hadley Wickham's devtools
#' package.
#' @seealso \code{\link[httr]{GET}}, \code{\link[data.table]{fread}}, and \code{\link{load}}
#' @importFrom data.table fread
#' @importFrom digest digest
#' @importFrom httr GET stop_for_status text_content content
#' @importFrom R.cache saveCache loadCache findCache
#' @export

source_data <-function(url,
                    rdata,
                    sha1 = NULL,
                    cache = FALSE,
                    clearCache = FALSE,
                    sep = "auto",
                    header = "auto",
                    stringsAsFactors = FALSE,
                    envir = parent.frame(),
                    ...)
{
    stopifnot(is.character(url), length(url) == 1)

    if (missing(rdata)){
        rdata_patterns <- c('(.*\\/)([^.]+).rdata', '(.*\\/)([^.]+).rda')
        rdata <- grepl(paste(rdata_patterns, collapse = '|'), url,
                       ignore.case = TRUE)
    }


    temp_file <- tempfile()
    on.exit(unlink(temp_file))

    key <- as.list(url)
    if (isTRUE(clearCache)){
        Found <- findCache(key = key)
        if (is.null(Found)){
            message('Data not in cache. Nothing to remove.')
        }
        else if (!is.null(Found)){
            message('Clearing data from cache.\n')
            file.remove(Found)
        }
    }

    if (isTRUE(cache)){
        data <- loadCache(key)
        if (!is.null(data)){
            message('Loading cached data.\n')
            return(data);
        }
        data <- download_data_intern(url = url, sha1 = sha1,
                                    temp_file = temp_file)
        if (!isTRUE(rdata)){
            data <- fread(data, sep = sep, header = header, data.table = F,
                               stringsAsFactors = stringsAsFactors, ...)
        }
        else if (isTRUE(rdata)){
            data <- load(data, envir = envir, ...)
        }
        saveCache(data, key = key)
        data;
    }
    else if (!isTRUE(cache)){
        data <- download_data_intern(url = url, sha1 = sha1,
                                    temp_file = temp_file)
        if (!isTRUE(rdata)){
            data <- fread(data, sep = sep, header = header, data.table = F,
                               stringsAsFactors = stringsAsFactors, ...)
        }
        else if (isTRUE(rdata)){
            data <- load(data, envir = envir, ...)
        }
        return(data)
    }
}
