/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Increasing the number of CPUs often gives diminishing returns, so we increase it
    following a logarithm curve. Example:
        - 0 < value <= 1: start + step
        - 1 < value <= 2: start + 2*step
        - 2 < value <= 4: start + 3*step
        - 4 < value <= 8: start + 4*step
    In order to support re-runs, the step increase may be multiplied by the attempt
    number prior to calling this function.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Modified logarithm function that doesn't return negative numbers
def positive_log(value, base) {
    if (value <= 1) {
        return 0
    } else {
        return Math.log(value)/Math.log(base)
    }
}

def log_increase_cpus(start, step, value, base) {
    return start + step * (1 + Math.ceil(positive_log(value, base)))
}