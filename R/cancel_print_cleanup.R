#' Cancels a scheduled Slurm job
#'
#' This function cancels the specified Slurm job by invoking the Slurm 
#' \code{scancel} command. It does \emph{not} delete the temporary files 
#' (e.g. scripts) created by \code{\link{slurm_apply}} or 
#' \code{\link{slurm_call}}. Use \code{\link{cleanup_files}} to remove those 
#' files. 
#' 
#' @param slr_job A \code{slurm_job} object.
#' @seealso \code{\link{cleanup_files}}
#' @export
cancel_slurm <- function(slr_job) {
    if (!(class(slr_job) == "slurm_job")) stop("input must be a slurm_job")
    system(paste("scancel -n", slr_job$jobname))
}


#' Prints the status of a Slurm job and, if completed, its console/error output
#'
#' Prints the status of a Slurm job and, if completed, its console/error output.
#'
#' If the specified Slurm job is still in the queue or running, this function
#' prints its current status (as output by the Slurm \code{squeue} command).
#' The output displays one row by node currently running part of the job ("R" in
#' the "ST" column) and how long it has been running ("TIME"). One row indicates
#' the portions of the job still in queue ("PD" in the "ST" column), if any. 
#' 
#' If all portions of the job have completed or stopped, the function prints the 
#' console and error output, if any, generated by each node.
#' 
#' @param slr_job A \code{slurm_job} object.
#' @export
print_job_status <- function(slr_job) {
    if (!(class(slr_job) == "slurm_job")) stop("input must be a slurm_job")  
    stat <- suppressWarnings(
        system(paste("squeue -n", slr_job$jobname), intern = TRUE))
    if (length(stat) > 1) {
        cat(paste(c("Job running or in queue. Status:", stat), collapse = "\n"))
    } else {
        cat("Job completed or stopped. Printing console output below if any.\n")
        tmpdir <- paste0("_rslurm_", slr_job$jobname)
        out_files <- file.path(tmpdir, 
                               paste0("slurm_", 0:(slr_job$nodes - 1), ".out"))
        for (outf in out_files) {
            cat(paste("\n----", outf, "----\n\n"))
            cat(paste(readLines(outf), collapse = "\n"))
        }
    }
}  


#' Deletes temporary files associated with a Slurm job 
#'
#' This function deletes all temporary files associated with the specified Slurm
#' job, including files created by \code{\link{slurm_apply}} or 
#' \code{\link{slurm_call}}, as well as outputs from the cluster. These files
#' should be located in the \emph{_rslurm_[jobname]} folder of the current
#' working directory.
#' 
#' @param slr_job A \code{slurm_job} object.
#' @param wait Specify whether to block until \code{slr_job} completes.
#' @examples 
#' \dontrun{
#' sjob <- slurm_apply(func, pars)
#' print_job_status(sjob) # Prints console/error output once job is completed.
#' func_result <- get_slurm_out(sjob, "table") # Loads output data into R.
#' cleanup_files(sjob)
#' }
#' @seealso \code{\link{slurm_apply}}, \code{\link{slurm_call}}
#' @export
cleanup_files <- function(slr_job, wait = TRUE) {
    if (!(class(slr_job) == "slurm_job")) stop("input must be a slurm_job")
    if (wait) wait_for_job(slr_job)
    tmpdir <- paste0("_rslurm_", slr_job$jobname)
    if (!(tmpdir %in% dir())) stop(paste("folder", tmpdir, "not found"))
    unlink(tmpdir, recursive = TRUE)
}
