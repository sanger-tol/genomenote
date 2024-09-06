# sanger-tol/genomenote: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [[1.2.1](https://github.com/sanger-tol/genomenote/releases/tag/1.2.1)] - Pyrenean Mountain Dog (patch 1) - [2024-07-12]

### Enhancements & fixes

- Bugfix: Now handles missing fields in `ncbi datasets` genome report

## [[1.2.0](https://github.com/sanger-tol/genomenote/releases/tag/1.2.0)] - Pyrenean Mountain Dog - [2024-05-01]

### Enhancements & fixes

- Updated the MerquryFK resources to cope with mistletoe (the pipeline as a
  whole is not yet fully compatible with mistletoe, though).
- Updated the Busco resources to better deal with large genomes.
- Round the chromosome lengths to 2 decimal points.
- The pipeline is now publishing the Busco output directories.
- The pipeline now generates a contact map for each Hi-C sample (instead of
  randomly picking one) and reports them all in the CSV.
- The Hi-C contact map is now ordered according to the karyotype (as defined in
  the assembly record) by default, and added the `--cool_order` option to
  override it.

### Software dependencies

Note, since the pipeline is using Nextflow DSL2, each process will be run with its own [Biocontainer](https://biocontainers.pro/#/registry). This means that on occasion it is entirely possible for the pipeline to be using different versions of the same tool. However, the overall software dependency changes compared to the last release have been listed below for reference.

| Dependency | Old version | New version |
| ---------- | ----------- | ----------- |
| busco      | 5.4.3       | 5.5.0       |

> **NB:** Dependency has been **updated** if both old and new version information is present. </br> **NB:** Dependency has been **added** if just the new version information is present. </br> **NB:** Dependency has been **removed** if version information isn't present.

### Parameters

| Old parameter | New parameter |
| ------------- | ------------- |
|               | --cool_order  |

## [[1.1.2](https://github.com/sanger-tol/genomenote/releases/tag/1.1.2)] - Golden Retriever (patch 2) - [2024-04-29]

### Enhancements & fixes

- Bugfix: the BAM still needs to be filtered with `-F0x400`

## [[1.1.1](https://github.com/sanger-tol/genomenote/releases/tag/1.1.1)] - Golden Retriever (patch 1) - [2024-02-26]

### Enhancements & fixes

- Stopped forcing the `eutheria_odb10` BUSCO lineage to be used for all mammals.
  This to synchronise this pipeline with the [BlobToolKit pipeline](https://github.com/sanger-tol/blobtoolkit).

## [[1.1.0](https://github.com/sanger-tol/genomenote/releases/tag/1.1.0)] - Golden Retriever - [2024-01-04]

### Enhancements & fixes

- The pipeline now queries the NCBI Taxonomy API rather than
  [GoaT](https://goat.genomehubs.org/api) to establish the list of lineages on
  which to run BUSCO. The possible lineages are now defined [in the pipeline
  configuration](assets/mapping_taxids-busco_dataset_name.eukaryota_odb10.2019-12-16.txt)
  but can be overridden with the `--lineage_tax_ids` parameter.
- The pipeline will now immediately fail if the assembly can't be retrieve by
  the [datasets](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/)
  command-line tool.
- Pipeline information is now outputted in `pipeline_info/genomenote/` instead
  of `genomenote_info/`.
- `maxRetries` increased to 5 to cope with large datasets.
- BUSCO now runs in "scratch" mode, i.e. off a temporary directory, as the
  number of files it creates could otherwise overwhelm a network filesystem.
- `SORT`, `FASTK`, and `MERQURYFK`, can now put their temporary files in the
  work directory rather than `/tmp`. Turn that on with the `--use_work_dir_as_temp`
  flag.
- The memory requirement of `SORT` is adjusted to account for some overheads
  and avoid the job to be killed.
- All resource requirements (memory, time, CPUs) now fit the actual usage. This
  is achieved by automatically adjusting to the size of the input whenever
  possible.
- Genomes with sequences longer than 2 Gbp are now supported thanks to
  upgrading FastK and MerquryFK.
- Fixed a bug that was causing the Completeness to be reported as 0 in the
  statistics CSV file, when the k-mer database was constructed from BAM files.
- QV/Completeness can now be computed off 10X sequencing data.
- Minimal version of Nextflow downgraded to 23.04 to 22.10. 22.10 is tested as
  part of our continuous integration (CI) pipeline.
- The "test" profile now runs faster, thanks to tuning some Busco/Metaeuk
  parameters.
- The "test_full" profile is now tested automatically when updating the `dev`
  and `main` branches.
- The pipelines now support Hi-C alignment files in the BAM format.

### Parameters

| Old parameter | New parameter          |
| ------------- | ---------------------- |
|               | --lineage_tax_ids      |
|               | --use_work_dir_as_temp |

### Software dependencies

| Dependency  | Old version                                | New version                                |
| ----------- | ------------------------------------------ | ------------------------------------------ |
| `datasets`  | 14.2                                       | 15.12                                      |
| `FastK`     | `f18a4e6d2207539f7b84461daebc54530a9559b0` | `427104ea91c78c3b8b8b49f1a7d6bbeaa869ba1c` |
| `MerquryFK` | `8ae344092df5dcaf83cfb7f90f662597a9b1fc61` | `d00d98157618f4e8d1a9190026b19b471055b22e` |

## [[1.0.0](https://github.com/sanger-tol/genomenote/releases/tag/1.0.0)] - Czechoslovakian Wolfdog - [2023-05-18]

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
