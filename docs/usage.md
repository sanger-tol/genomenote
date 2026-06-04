# sanger-tol/genomenote: Usage

## :warning: Please read this documentation on the sanger-tol website: [https://pipelines.tol.sanger.ac.uk/genomenote/usage](https://pipelines.tol.sanger.ac.uk/genomenote/usage)

> _Documentation of pipeline parameters is generated automatically from the pipeline schema and can no longer be found in markdown files._

## Introduction

The [sanger-tol/genomenote](https://pipelines.tol.sanger.ac.uk/genomenote) pipeline collates various sources of assembly statistics and information to support the publication of a Genome Note.

These typically include:

1. Assembly metadata from COPO, ENA, GoaT, GBIF and NCBI
2. Assembly information, statistics and chromosome details from NCBI datasets.
3. Genome completeness from BUSCO.
4. Annotation statistics from AGAT and completeness from BUSCO.
5. Consensus quality and k-mer completeness from MerquryFK - when high-quality reads are available.
6. Hi-C contact map and chromosomal grid using Cooler, as well as primary mapped percentage from samtools flagstat - when Hi-C reads are provided. These files can be displayed on a [HiGlass](http://higlass.io) server, like the one use by the [Sanger Institute](https://genome-note-higlass.tol.sanger.ac.uk/app).
7. Ancestral Plots are mappings of putative ancestral BUSCO genes onto the chromosomes of the input assembly.
8. Pretext map and snapshot

## Genome metadata input

The assembly accession for the genome you would like to analyse, optionally with the biosample accession(s) linked to this genome assembly.

```bash
--assembly '[assembly accession]'
--biosample_wgs '[biosample accession of the biosample used to produce the genomic sequence]'
--biosample_hic '[biosample accession of the biosample used to produce the HiC data]'
--biosample_rna '[biosample accession of the biosample used to produce the RNASeq data]
```

## Annotation input

If you want to generate statistics on the annotated gene set for the assembly, provide the annotation GFF3 as a `genes` row in the samplesheet.

The assembly region names used in the GFF3 file must match the assembly region names used in the assembly FASTA provided with `--fasta`.

For example:

```csv
ensembl.2024_04,genes,/path/to/annotation.gff3.gz
```

## Samplesheet input

You will need to create a samplesheet with information about the samples you would like to analyse before running the pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 3 columns, and a header row as shown in the examples below.

```bash
--input '[path to samplesheet file]'
```

### Multiple runs of the same sample

The `sample` identifiers have to be unique.

Use either `specimen` or `specimen/run` format:

- `specimen`: single run.
- `specimen/run`: multiple runs from the same specimen.

If `specimen/run` is used, both components must be non-empty and only one slash is allowed.

Below is an example for the same specimen sequenced using Hi-C and PacBio technology:

```csv title="samplesheet.csv"
sample,datatype,datafile
specimen1/run1,hic,/path/to/aligned/cram
specimen1/run2,pacbio,/path/to/unaligned/bam
specimen1,haplotype,/path/to/haplotype/assembly/fasta{.gz}
```

### Full samplesheet

The samplesheet can have as many columns as you desire, however, there is a strict requirement for the first 3 columns to match those defined in the table below.

A final samplesheet file including Hi-C, PacBio, haplotype and annotation input may look like this:

```csv title="samplesheet.csv"
sample,datatype,datafile
specimen1/run1,hic,/path/to/aligned/cram
specimen1/run2,pacbio,/path/to/unaligned/bam
specimen1,haplotype,/path/to/haplotype/assembly/fasta{.gz}
ensembl.2024_04,genes,/path/to/annotation.gff3.gz
```

| Column     | Description                                                                                                                                                                                                                                                                                  |
| ---------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`   | Sample identifier must be unique (slash `/` and `.` are treated equivalent). Please use `specimen/run` when multiple runs exist for one specimen. For annotation sets with datatype as `genes`, `sample` is source of genes (i.e., `ensembl.2024_04`). Sample names must not contain spaces. |
| `datatype` | Type of data. Must be `hic`, `pacbio`, `10x`, `haplotype`, or `genes` (annotation input).                                                                                                                                                                                                    |
| `datafile` | Full path to the data location.                                                                                                                                                                                                                                                              |

Here are the expected data files for each data type:

| `datatype`         | `datafile`                                                     |
| ------------------ | -------------------------------------------------------------- |
| `hic`              | Either `bam` or `cram` aligned reads                           |
| `pacbio` and `10x` | Either the FASTK `kmer` directory or the unaligned `bam` files |
| `haplotype`        | The Fasta file of the alternative haplotype                    |
| `genes`            | Annotation `gff3`/`gff3.gz` file (maximum one row)             |

An [example samplesheet](../assets/samplesheet.csv) has been provided with the pipeline.

## Running the pipeline

The typical command for running the pipeline is as follows:

```bash
nextflow run sanger-tol/genomenote --input samplesheet.csv --outdir <OUTDIR> --fasta genome.fasta --assembly GCA_922984935.2 -profile docker
```

This will launch the pipeline with the `docker` configuration profile. See below for more information about profiles.

Note that the pipeline will create the following files in your working directory:

```bash
work                # Directory containing the nextflow working files
<OUTDIR>            # Finished results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
# Other nextflow hidden files, eg. history of pipeline runs and old logs.
```

If you wish to repeatedly use the same parameters for multiple runs, rather than specifying each flag in the command, you can specify these in a params file.

Pipeline settings can be provided in a `yaml` or `json` file via `-params-file <file>`.

> [!WARNING]
> Do not use `-c <file>` to specify parameters as this will result in errors. Custom config files specified with `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources), other infrastructural tweaks (such as output directories), or module arguments (args).

The above pipeline run specified with a params file in yaml format:

```bash
nextflow run sanger-tol/genomenote -profile docker -params-file params.yaml
```

with:

```yaml title="params.yaml"
input: "./samplesheet.csv"
outdir: "./results/"
fasta: "./genome.fasta"
assembly: "GCA_922984935.2"
```

You can also generate such `YAML`/`JSON` files via [nf-core/launch](https://nf-co.re/launch).

### Updating the pipeline

When you run the above command, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version. When running the pipeline after this, it will always use the cached version if available - even if the pipeline has been updated since. To make sure that you're running the latest version of the pipeline, make sure that you regularly update the cached version of the pipeline:

```bash
nextflow pull sanger-tol/genomenote
```

### Reproducibility

It is a good idea to specify the pipeline version when running the pipeline on your data. This ensures that a specific version of the pipeline code and software are used when you run your pipeline. If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code since.

First, go to the [sanger-tol/genomenote releases page](https://github.com/sanger-tol/genomenote/releases) and find the latest pipeline version - numeric only (eg. `1.3.1`). Then specify this when running the pipeline with `-r` (one hyphen) - eg. `-r 1.3.1`. Of course, you can switch to another version by changing the number after the `-r` flag.

This version number will be logged in reports when you run the pipeline, so that you'll know what you used when you look back in the future. For example, at the bottom of the MultiQC reports.

To further assist in reproducibility, you can use share and reuse [parameter files](#running-the-pipeline) to repeat pipeline runs with the same settings without having to write out a command with every single parameter.

> [!TIP]
> If you wish to share such profile (such as upload as supplementary material for academic publications), make sure to NOT include cluster specific paths to files, nor institutional specific profiles.

## Core Nextflow arguments

> [!NOTE]
> These options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen)

### `-profile`

Use this parameter to choose a configuration profile. Profiles can give configuration presets for different compute environments.

Several generic profiles are bundled with the pipeline which instruct the pipeline to use software packaged using different methods (Docker, Singularity, Podman, Shifter, Charliecloud, Apptainer, Conda) - see below.

> [!IMPORTANT]
> We require the use of containers such as Docker or Singularity as Conda is _not_ supported. You will get the added benefit of full pipeline reproducibility.

The pipeline also dynamically loads configurations from [https://github.com/nf-core/configs](https://github.com/nf-core/configs) when it runs, making multiple config profiles for various institutional clusters available at run time. For more information and to check if your system is supported, please see the [nf-core/configs documentation](https://github.com/nf-core/configs#documentation).

Note that multiple profiles can be loaded, for example: `-profile test,docker` - the order of arguments is important!
They are loaded in sequence, so later profiles can overwrite earlier profiles.

If `-profile` is not specified, the pipeline will run locally and expect all software to be installed and available on the `PATH`. This is _not_ recommended, since it can lead to different results on different machines dependent on the computer environment.

- `docker`
  - A generic configuration profile to be used with [Docker](https://docker.com/)
- `singularity`
  - A generic configuration profile to be used with [Singularity](https://sylabs.io/docs/)
- `podman`
  - A generic configuration profile to be used with [Podman](https://podman.io/)
- `shifter`
  - A generic configuration profile to be used with [Shifter](https://nersc.gitlab.io/development/shifter/how-to-use/)
- `charliecloud`
  - A generic configuration profile to be used with [Charliecloud](https://charliecloud.io/)
- `apptainer`
  - A generic configuration profile to be used with [Apptainer](https://apptainer.org/)
- `wave`
  - A generic configuration profile to enable [Wave](https://seqera.io/wave/) containers. Use together with one of the above (requires Nextflow ` 24.03.0-edge` or later).
- `test`
  - A profile with a minimal configuration for automated testing
  - Includes links to test data so needs no other parameters
  - Runs within minutes
- `test_full`
  - A profile with a complete configuration for automated testing
  - Includes links to test data so needs no other parameters

### `-resume`

Specify this when restarting a pipeline. Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously. For input to be considered the same, not only the names must be identical but the files' contents as well. For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`. Use the `nextflow log` command to show previous run names.

### `-c`

Specify the path to a specific config file (this is a core Nextflow command). See the [nf-core website documentation](https://nf-co.re/usage/configuration) for more information.

## Custom configuration

### Resource requests

Whilst the default requirements set within the pipeline will hopefully work for most people and with most input data, you may find that you want to customise the compute resources that the pipeline requests. Each step in the pipeline has a default set of requirements for number of CPUs, memory and time. For most of the pipeline steps, if the job exits with any of the error codes specified [here](https://github.com/nf-core/rnaseq/blob/4c27ef5610c87db00c3c5a3eed10b1d161abf575/conf/base.config#L18) it will automatically be resubmitted with higher resources request (2 x original, then 3 x original). If it still fails after the third attempt then the pipeline execution is stopped.

To change the resource requests, please see the [max resources](https://nf-co.re/docs/usage/configuration#max-resources) and [tuning workflow resources](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) section of the nf-core website.

### Custom Containers

In some cases, you may wish to change the container or conda environment used by a pipeline steps for a particular tool. By default, nf-core pipelines use containers and software from the [biocontainers](https://biocontainers.pro/) or [bioconda](https://bioconda.github.io/) projects. However, in some cases the pipeline specified version maybe out of date.

To use a different container from the default container or conda environment specified in a pipeline, please see the [updating tool versions](https://nf-co.re/docs/usage/configuration#updating-tool-versions) section of the nf-core website.

### Custom Tool Arguments

A pipeline might not always support every possible argument or option of a particular tool used in pipeline. Fortunately, nf-core pipelines provide some freedom to users to insert additional parameters that the pipeline does not include by default.

To learn how to provide additional arguments to a particular tool of the pipeline, please see the [customising tool arguments](https://nf-co.re/docs/usage/configuration#customising-tool-arguments) section of the nf-core website.

### nf-core/configs

In most cases, you will only need to create a custom config as a one-off but if you and others within your organisation are likely to be running nf-core pipelines regularly and need to use the same settings regularly it may be a good idea to request that your custom config file is uploaded to the `nf-core/configs` git repository. Before you do this please can you test that the config file works with your pipeline of choice using the `-c` parameter. You can then create a pull request to the `nf-core/configs` repository with the addition of your config file, associated documentation file (see examples in [`nf-core/configs/docs`](https://github.com/nf-core/configs/tree/master/docs)), and amending [`nfcore_custom.config`](https://github.com/nf-core/configs/blob/master/nfcore_custom.config) to include your custom profile.

See the main [Nextflow documentation](https://www.nextflow.io/docs/latest/config.html) for more information about creating your own configuration files.

If you have any questions or issues please send us a message on [Slack](https://nf-co.re/join/slack) on the [`#configs` channel](https://nfcore.slack.com/channels/configs).

## Running in the background

Nextflow handles job submissions and supervises the running jobs. The Nextflow process must run until the pipeline is finished.

The Nextflow `-bg` flag launches Nextflow in the background, detached from your terminal so that the workflow does not stop if you log out of your session. The logs are saved to a file.

Alternatively, you can use `screen` / `tmux` or similar tool to create a detached session which you can log back into at a later time.
Some HPC setups also allow you to run nextflow within a cluster job submitted your job scheduler (from where it submits more jobs).

## Nextflow memory requirements

In some cases, the Nextflow Java virtual machines can start to request a large amount of memory.
We recommend adding the following line to your environment to limit this (typically in `~/.bashrc` or `~./bash_profile`):

```bash
NXF_OPTS='-Xms1g -Xmx4g'
```

## For internal Sanger use only

If you want to populate a genome notes template file with the key-value pairs generated by this pipeline you will need to pass the path to the template file as the "note_template" parameter. Templates may be either docx or xml format.
See the provided `assets/genome_note_template.docx` for an example

```bash
   --note_template '/path/to/template'
```

If you wish to run the optional step that writes the .mcool and .genome files produced by the contact_maps subworkflow to a kubernetes hosted higlass server you will need to set the parameter "upload_higlass_data" to true and provide the configuration information for the kubernetes deployment.

```bash
   --upload_higlass_data 'true'
   --higlass_upload_directory  '[Path to ingress directory for kubernetes]'
   --higlass_data_project_dir '[Directory structure to be used for Higlass data, suggestions is to use /<project-name>/<taxon-group>]'
   --higlass_deployment_name '[ Name of Higlass Deployment in kubernetes]'
   --higlass_namespace '[Name of the namespace used for Higlass Deployment in Kubernetes]'
   --higlass_kubeconfig '[path to kubeconfig file]'
```
