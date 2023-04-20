# Parameters

## Input / output options

Define where the pipeline should find input data and save output data.

### `--input`

This can either be a Tree of Life organism ID or a path to comma-separated file containing information about the samples in the experiment. `required`

### `--project`

If Tree of Life organism ID is provided as `input`, then the corresponding `project` directory should be given here. For example: "/lustre/scratch124/tol/projects/darwin"

### `--fasta`

If a samplesheet is provided as `input`, then the path to the genome fasta file should be provided. Unmasked genomes are preferred.

> If you don't have the appropriate alignment index available this will be generated for you automatically.
>
> pattern: `^\S+\.fn?a(sta)?(\.gz)?$`

### `--outdir`

The output directory where the results will be saved. You have to use absolute paths to storage on Cloud infrastructure. default: `./results`. `required`

### `--email`

Email address for completion summary.

> Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits. If set in your user config file (`~/.nextflow/config`) then you don't need to specify this on the command line for every run.
>
> pattern: `^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$`

### `--multiqc_title`

MultiQC report title. Printed as page header, used for filename if not otherwise specified.

## Institutional config options

Parameters used to describe centralised config profiles. These should not be edited.

> The centralised nf-core configuration profiles use a handful of pipeline parameters to describe themselves. This information is then printed to the Nextflow log when you run a pipeline. You should not need to change these values when you run a pipeline.

### `--custom_config_version`

Git commit id for Institutional configs. default: `master`.

### `--custom_config_base`

Base directory for Institutional configs. default: `https://raw.githubusercontent.com/nf-core/configs/master`.

> If you're running offline, Nextflow will not be able to fetch the institutional config files from the internet. If you don't need them, then this is not a problem. If you do need them, you should download the files from the repo and tell Nextflow where to find them with this parameter.

### `--config_profile_name`

Institutional config name.

### `--config_profile_description`

Institutional config description.

### `--config_profile_contact`

Institutional config contact information.

### `--config_profile_url`

Institutional config URL link.

## Max job request options

Set the top limit for requested resources for any single job.

> If you are running on a smaller system, a pipeline step requesting more resources than are available may cause the Nextflow to stop the run with an error. These options allow you to cap the maximum resources requested by any single job so that the pipeline will run on your system.
>
> Note that you can not _increase_ the resources requested by any job using these options. For that you will need your own configuration file. See the [nf-core website](https://nf-co.re/usage/configuration) for details.

### `--max_cpus`

Maximum number of CPUs that can be requested for any single job. default: `16`.

> Use to set an upper-limit for the CPU requirement for each process. Should be an integer e.g. `--max_cpus 1`.

### `--max_memory`

Maximum amount of memory that can be requested for any single job. default: `'128.GB'`.

> Use to set an upper-limit for the memory requirement for each process. Should be a string in the format integer-unit e.g. `--max_memory '8.GB'`.
>
> pattern: `^\d+(\.\d+)?\.?\s*(K|M|G|T)?B$`

### `--max_time`

Maximum amount of time that can be requested for any single job. default: `'240.h'`.

> Use to set an upper-limit for the time requirement for each process. Should be a string in the format integer-unit e.g. `--max_time '2.h'`.
>
> pattern: `^(\d+\.?\s*(s|m|h|day)\s*)+$`

## Generic options

Less common options for the pipeline, typically set in a config file.

> These options are common to all nf-core pipelines and allow you to customise some of the core preferences for how the pipeline runs.
>
> Typically these options would be set in a Nextflow config file loaded for all pipeline runs, such as `~/.nextflow/config`.

### `--help`

Display help text.

### `--email_on_fail`

Email address for completion summary, only when pipeline fails.

> An email address to send a summary email to when the pipeline is completed - ONLY sent if the pipeline does not exit successfully.
>
> pattern: `^([a-zA-Z0-9_\-\.]+)@([a-zA-Z0-9_\-\.]+)\.([a-zA-Z]{2,5})$`

### `--plaintext_email`

Send plain-text email instead of HTML.

### `--max_multiqc_email_size`

File size limit when attaching MultiQC reports to summary emails. default: `'25.MB'`.

### `--monochrome_logs`

Do not use coloured log outputs.

### `--multiqc_config`

Custom config file to supply to MultiQC.

### `--tracedir`

Directory to keep pipeline Nextflow logs and reports. default: `'${params.outdir}/pipeline_info'`.

### `--validate_params`

Boolean whether to validate parameters against the schema at runtime. default: `1`.

### `--show_hidden_params`

Show all params when using `--help`.

> By default, parameters set as hidden in the schema are not shown on the command line when a user runs with --help. Specifying this option will tell the pipeline to show all parameters.

### `--enable_conda`

Run this workflow with Conda. You can also use `-profile conda` instead of providing this parameter.
