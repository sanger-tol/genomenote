# sanger-tol/genomenote: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [[1.0.0](https://github.com/sanger-tol/genomenote/releases/tag/1.0.0)] - Czechoslovakian Wolfdog - [2023-05-19]

Initial release of sanger-tol/genomenote, created with the [nf-core](https://nf-co.re/) template.

### Enhancements & fixes

- Created with nf-core/tools template v2.8.0.
- Subworkflow to create HiC contact maps using Cooler.
- Subworkflow to create summary table using BUSCO, MerquryFK, NCBI datasets, and Samtools.

### Parameters

| Old parameter | New parameter |
| ------------- | ------------- |
|               | --input       |
|               | --binsize     |
|               | --kmer_size   |
|               | --lineage_db  |
|               | --fasta       |

> **NB:** Parameter has been **updated** if both old and new parameter information is present. </br> **NB:** Parameter has been **added** if just the new parameter information is present. </br> **NB:** Parameter has been **removed** if new parameter information isn't present.

### Software dependencies

Note, since the pipeline is using Nextflow DSL2, each process will be run with its own [Biocontainer](https://biocontainers.pro/#/registry). This means that on occasion it is entirely possible for the pipeline to be using different versions of the same tool. However, the overall software dependency changes compared to the last release have been listed below for reference.

| Dependency        | Old version | New version                              |
| ----------------- | ----------- | ---------------------------------------- |
| bedtools          |             | 2.30.0                                   |
| busco             |             | 5.4.3                                    |
| cooler            |             | 0.8.11                                   |
| fastk             |             | f18a4e6d2207539f7b84461daebc54530a9559b0 |
| merquryfk         |             | 8ae344092df5dcaf83cfb7f90f662597a9b1fc61 |
| ncbi-datasets-cli |             | 14.2.2                                   |
| Nextflow          |             | 23.04.0                                  |
| nf-core/tools     |             | 2.8.0                                    |
| R                 |             | 4.2.0                                    |
| samtools          |             | 1.17                                     |

> **NB:** Dependency has been **updated** if both old and new version information is present. </br> **NB:** Dependency has been **added** if just the new version information is present. </br> **NB:** Dependency has been **removed** if version information isn't present.
