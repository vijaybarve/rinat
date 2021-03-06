#' Download observations or info from a project
#'@description retrieve observations from a particular iNaturalist project. This function can be used to get either observations or information from a project by project name or ID
#'@param grpid Name of the group as an iNaturalist slug or group id
#'@param type character Either "observations" or "info"  Observations returns all observations, and "info" returns project details similar to what you can find on a project webpage.
#'@param raw logical TRUE or FALSE. If TRUE and searching for project info, returns the raw output of parsed JSON for that project. Otherwise just some basic information is returned as a list
#'@details An iNaturalist slug is usually the project as single string with words separated by hyphens. For instance, the project "State Flowers of the United States" has a slug of "state-flowers-of-the-united-states-eol-collection".  This can be extracted from the URL for the project usually. The state flowers project has the following URL http://www.inaturalist.org/projects/state-flowers-of-the-united-states-eol-collection
#'
#'@examples \dontrun{
#'  get_inat_obs_project(354, type = "observations")
#'  get_inat_obs_project("crows-in-vermont", type="info",raw=FALSE)
#'}
#'@import httr jsonlite
#'@export

get_inat_obs_project <- function(grpid, type = c("observations", "info"), raw = FALSE){
  argstring = switch(match.arg(type),
                     observations = "obs",
                     info = "info")
  url <- paste0("http://www.inaturalist.org/projects/",grpid,".json")
  xx <- fromJSON(content(GET(url), as = "text"))
  recs <- xx$project_observations_count

  ### Error handling for empty projects
  dat <- NULL
  if(is.null(recs))(return(dat))
  message(paste(recs," records\n"))

  if(argstring == "info"){
    output <- list()
    output[["title"]] <- xx$title
    output[["description"]] <- xx$description
    output[["slug"]] <- xx$slug
    output[["created_at"]] <- xx$created_at
    output[["id"]] <- xx$id
    output[["location"]] <- c(as.numeric(xx$lat),as.numeric(xx$long))
    output[["place_id"]] <- xx$place_id
    output[["taxa_number"]] <- xx$observed_taxa_count
    output[["taxa_count"]] <- xx$project_observations_count
    if(raw){
      output[["raw"]] <- xx
    }
    return(output)
  }
  else if (argstring == "obs") {
    per_page <- 200
    if (recs %% per_page == 0) {
      loopval <- recs %/% per_page
    }
    if (recs >= 10000) {
      warning(
        "Number of observations in project greater than current API limit.\nReturning the first 10000.\n"
      )
      loopval <- 10000 / per_page
    }
    else {
      loopval <- (recs %/% per_page) + 1
    }
    obs_list <- vector("list", loopval)
    for (i in 1:loopval) {
      url1 <-
        paste0(
          "http://www.inaturalist.org/observations/project/", grpid,
          ".json?page=", i,
          "&per_page=", per_page
        )
      if (i == 1) {
        message(paste0("0-", per_page))
      }
      if (i > 1) {
        message(paste0("-", i * per_page))
      }
      obs_list[[i]] <-
        fromJSON(content(GET(url1), as = "text"), flatten = TRUE)
    }
    project_obs <- do.call("rbind.fill", obs_list)
    return(project_obs)
  }
}
