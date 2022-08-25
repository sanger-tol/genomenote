# ![nf-core/genomenote](docs/images/sanger-tol-genomenote_logo.png#gh-light-mode-only) ![nf-core/genomenote](docs/images/sanger-tol-genomenote_logo.png#gh-dark-mode-only)

<!-- [![GitHub Actions CI Status](https://github.com/nf-core/genomenote/workflows/nf-core%20CI/badge.svg)](https://github.com/nf-core/genomenote/actions?query=workflow%3A%22nf-core+CI%22) --> 
<!-- [![GitHub Actions Linting Status](https://github.com/nf-core/genomenote/workflows/nf-core%20linting/badge.svg)](https://github.com/nf-core/genomenote/actions?query=workflow%3A%22nf-core+linting%22) -->
<!-- [![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/genomenote/results) -->
[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.6785935-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.6785935)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A522.04.0-23aa62.svg?labelColor=000000)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23genomenote-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/genomenote)
[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)
[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/genomenote** is a bioinformatics best-practice analysis pipeline for generating contact maps and statistics from aligned HiC reads and a genome fasta.

The pipeline is built using [Nextflow](https://www.nextflow.io), a workflow tool to run tasks across multiple compute infrastructures in a very portable manner. It uses Docker/Singularity containers making installation trivial and results highly reproducible. The [Nextflow DSL2](https://www.nextflow.io/docs/latest/dsl2.html) implementation of this pipeline uses one container per process which makes it much easier to maintain and update software dependencies. Where possible, these processes have been submitted to and installed from [nf-core/modules](https://github.com/nf-core/modules) in order to make them available to all nf-core pipelines, and to everyone within the Nextflow community!

Prior to release, automated tests are run on the pipeline using full-sized dataset from a small, medium and large genome on the Wellcome Sanger Institute (WSI) compute farm. This ensures that the pipeline has sensible resource allocation defaults set to run on real-world datasets, and permits the persistent storage of results to benchmark between pipeline releases and other analysis sources.

## Pipeline summary

### Genome

1. Unmask genome if masked
2. Create genome index if does not exists ([samtools faidx](https://www.htslib.org/doc/samtools-faidx.html))
3. Filter genome index

### Aligned HiC Reads

1. Convert to BAM if in CRAM format
2. Conver to BED ([bedtools bamtobed](https://bedtools.readthedocs.io/en/latest/content/tools/bamtobed.html))
3. Sort BED
4. Filter BED to create pairs
5. Sort BED pairs

### Contact maps

1. `.cool` file using genome index, sorted BED pairs and bin size (default: 1000) ([cooler cload pairs](https://cooler.readthedocs.io/en/latest/cli.html#cooler-cload-pairs))
2. `.mcool` file using `.cool` map ([cooler zoomify](https://cooler.readthedocs.io/en/latest/cli.html#cooler-zoomify))

## Quick Start

1. Install [`Nextflow`](https://www.nextflow.io/docs/latest/getstarted.html#installation) (`>=22.04.0`)

2. Install any of [`Docker`](https://docs.docker.com/engine/installation/), [`Singularity`](https://www.sylabs.io/guides/3.0/user-guide/) (you can follow [this tutorial](https://singularity-tutorial.github.io/01-installation/)), [`Podman`](https://podman.io/), [`Shifter`](https://nersc.gitlab.io/development/shifter/how-to-use/) or [`Charliecloud`](https://hpc.github.io/charliecloud/) for full pipeline reproducibility _(you can use [`Conda`](https://conda.io/miniconda.html) both to install Nextflow itself and also to manage software within pipelines. Please only use it within pipelines as a last resort; see [docs](https://nf-co.re/usage/configuration#basic-configuration-profiles))_.

3. Download the pipeline and test it on a minimal dataset with a single command:

   ```console
   nextflow run sanger-tol/genomenote -profile test,YOURPROFILE --outdir <OUTDIR>
   ```

   Note that some form of configuration will be needed so that Nextflow knows how to fetch the required software. This is usually done in the form of a config profile (`YOURPROFILE` in the example command above). You can chain multiple config profiles in a comma-separated string.

   > - The pipeline comes with config profiles called `docker`, `singularity`, `podman`, `shifter`, `charliecloud` and `conda` which instruct the pipeline to use the named tool for software management. For example, `-profile test,docker`.
   > - Please check [nf-core/configs](https://github.com/nf-core/configs#documentation) to see if a custom config file to run nf-core pipelines already exists for your Institute. If so, you can simply use `-profile <institute>` in your command. This will enable either `docker` or `singularity` and set the appropriate execution settings for your local compute environment.
   > - If you are using `singularity`, please use the [`nf-core download`](https://nf-co.re/tools/#downloading-pipelines-for-offline-use) command to download images first, before running the pipeline. Setting the [`NXF_SINGULARITY_CACHEDIR` or `singularity.cacheDir`](https://www.nextflow.io/docs/latest/singularity.html?#singularity-docker-hub) Nextflow options enables you to store and re-use the images from a central location for future pipeline runs.
   > - If you are using `conda`, it is highly recommended to use the [`NXF_CONDA_CACHEDIR` or `conda.cacheDir`](https://www.nextflow.io/docs/latest/conda.html) settings to store the environments in a central location for future pipeline runs.

4. Start running your own analysis!

   ```console
   nextflow run sanger-tol/genomenote --input samplesheet.csv --outdir <OUTDIR> --genome /path/to/genome.fasta -profile <docker/singularity/podman/shifter/charliecloud/conda/institute>
   ```

## Documentation

The nf-core/genomenote pipeline comes with documentation about the pipeline [usage](decs/usage.md) and [parameters](decs/parameters.med).

## Credits

sanger-tol/genomenote was originally written by @priyanka-surana.

We thank the following people for their extensive assistance in the development of this pipeline:

– @mcshane and @yumisims for providing software/tool details

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#genomenote` channel](https://sangertreeoflife.slack.com/channels/pipelines).

## Citations

If you use sanger-tol/genomenote for your analysis, please cite it using the following doi: [10.5281/zenodo.6785935](https://doi.org/10.5281/zenodo.6785935)

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
