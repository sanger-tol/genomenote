# sanger-tol/genomenote: Output

## Introduction

This document describes the output produced by the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory. The directories comply with Tree of Life's canonical directory structure.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [Contact maps](#contact-maps) – Contact matrix created using HiC sequencing data
- [Genome statistics](#genome-statistics) – Collated assembly information, genome statistics and alignment quality information
- [Annotation statistics](#annotation-statistics) - Statistics calculated on the annotated protein set for the assembly (if GFF annotation file is provided as input)
- [Annotation ancestral](#annotation-ancestral) - Ancestral linkage plots
- [BUSCO](#busco) - BUSCO results
- [BlobToolKit plots](#blobtoolkit-plots) - Static BlobToolKit plots
- [Genome Note](#genome-note) - Data for the generation of a genome-note article.
- [MultiQC](#multiqc) - Aggregate report describing results from the whole pipeline
- [Pipeline information](#pipeline-information) - Report metrics generated during the workflow execution

### Contact maps

This pipeline takes aligned HiC reads to create contact maps and chromosomal grids using both Cooler and PretextMap, enabling display on a [HiGlass server](https://higlass.io/), in PretextView, or via a pretext snapshot in your preferred image viewer.

<details markdown="1">
<summary>Output files</summary>

- `contact_maps/`
  - `<sample>/`: One directory per sample. If the sample name contains `/`, the path will be nested accordingly (e.g. `project/sample` becomes `project/sample/`).
    - `<assembly>.<datatype>.<specimen>.<run>.chromsizes`: chromosomal grid created from the `.cool` file
    - `<assembly>.<datatype>.<specimen>.<run>.cool`: initial contact matrix created
    - `<assembly>.<datatype>.<specimen>.<run>.mcool`: final contact matrix for upload
    - `<assembly>.<datatype>.<specimen>.<run>.pretext`: PretextMap for PretextView
    - `<assembly>.<datatype>.<specimen>.<run>.pretext.png`: Snapshot file made with Pretext

</details>

### Genome statistics

This pipeline collates (1) assembly information, statistics and chromosome details from NCBI datasets, (2) genome completeness from BUSCO, (3) consensus quality and k-mer completeness from MerquryFK, and (4) HiC primary mapped percentage from samtools flagstat.

<details markdown="1">
<summary>Output files</summary>

- `genome_stats/`
  - `<assembly>.gfastats.txt`: Assembly summary statistics for this sample, aggregating metrics collected throughout the pipeline run (e.g. contig count, N50, total length). Any `/` in the sample name is replaced with `.` in the filename.
  - `<datatype>/`
    - `<sample>/`: One directory per sample. If the sample name contains `/`, the path will be nested accordingly (e.g. `project/sample` becomes `project/sample/`).
      - `genomescope/`
        - `<assembly>.<datatype>.<specimen>.<run>.genomescope.(linear|log)_plot.png`: K-mer histogram plot on a linear or log scale.
        - `<assembly>.<datatype>.<specimen>.<run>.genomescope.transformed_(linear|log)_plot.png`: Transformed variant of the above plots, rescaled to improve interpretability.
        - `<assembly>.<datatype>.<specimen>.<run>.genomescope.model.txt`: Fitted GenomeScope model parameters, including estimated heterozygosity, repeat content, and ploidy.
        - `<assembly>.<datatype>.<specimen>.<run>.genomescope.summary.txt`: Human-readable summary of genome size and quality estimates derived from the model.
      - `merqury/`
        - `<assembly>.<datatype>.<specimen>.<run>.completeness.stats`: K-mer completeness score: the percentage of read k-mers found in the assembly, per haplotype.
        - `<assembly>.<datatype>.<specimen>.<run>.qv`: Assembly-level quality value (QV) score, analogous to a Phred score, reflecting base-level accuracy.
        - `<assembly>.<datatype>.<specimen>.<run>.spectra-asm.*.png`: K-mer spectra plots coloured by assembly haplotype, visually representing completeness and duplication.
        - `<assembly>.<datatype>.<specimen>.<run>.<target_assembly>.only.bed`: Genomic regions (BED) containing k-mers found only in this target haplotype and absent from the others.
        - `<assembly>.<datatype>.<specimen>.<run>.<target_assembly>.qv`: Per-target-haplotype quality value score.
        - `<assembly>.<datatype>.<specimen>.<run>.<target_assembly>.spectra-cn.*.png`: Copy-number spectra plots for this specific target haplotype, showing k-mer multiplicity distribution.

</details>

### Annotation statistics

This pipeline can generate statistics using AGAT and a BUSCO completeness score on the assembly annotation if a `genes` row is provided in the samplesheet. The annotation input should be a GFF3 file describing the annotated gene/protein set.

<details markdown="1">
<summary>Output files</summary>

- `genes/`
  - `<source>/` (`source` is `sample` of `genes` entry in input samplesheet)
    - `<assembly>.genes.<specimen>.agat.sqstats.txt`: AGAT basic annotation statistics (sequence stats).
    - `<assembly>.genes.<specimen>.agat.spstats.txt`: AGAT protein annotation statistics.
    - `<assembly>.genes.<specimen>.busco.<lineage>.short_summary.txt`: BUSCO scores in text format for protein completeness.
    - `<assembly>.genes.<specimen>.busco.<lineage>.short_summary.json`: BUSCO scores in JSON format for protein completeness.

</details>

### Annotation ancestral

This subworkflow uses ancestral linkage tables to plot locations of the putative ancestral chromosomes onto the input species.

<details markdown="1">
<summary>Output files</summary>

- `ancestral_plots/`
  - `<lineage>/`
    - `<ancestral_table_basename>/` (`ancestral_table_basename` is the basename of the ancestral table file provided, for example `Merian_elements_full_table`)
      - `<assembly>.<lineage>.<ancestral_table_basename>.buscopainter.pdf`: PDF copy of the ancestral plot.
      - `<assembly>.<lineage>.<ancestral_table_basename>.buscopainter.png`: PNG copy of the ancestral plot.

</details>

### BUSCO

BUSCO results generated by the pipeline (all BUSCO lineages that match the classification of the species).

<details markdown="1">
<summary>Output files</summary>

- `busco/`
  - `<lineage>`
    - `<assembly>.<lineage>.short_summary.{json|tsv|txt}`: BUSCO scores in various formats.
    - `<assembly>.<lineage>.full_table.tsv`: list and coordinates of BUSCO genes that could be found.
    - `<assembly>.<lineage>.missing_busco_list.tsv`: BUSCO genes that could not be found.
    - `<assembly>.<lineage>.{single,multi,fragmented}_busco_sequences.tar.gz`: sequence files of the annotated genes.

</details>

### Blobtoolkit Plots

- `blobtoolkit/`
  - `plots/`
    - `<assembly>.blob.png`: Standard GC vs coverage scatter plot showing all sequences in the assembly for contamination detection and quality assessment.
    - `<assembly>.blob_chr.png`: Chromosome-level blob plot filtered to show only assembled molecules, excluding unlocalized scaffolds.
    - `<assembly>.grid.png`: Grid-based positional visualization with genomic position on x-axis showing spatial distribution of sequences.
    - `<assembly>.grid_chr.png`: Chromosome-level grid plot combining positional layout with assembled molecule filtering for publication-quality visualization.

### Genome Note

Collection of various data into formats suitable for ingesting into a final genome-note article.

<details markdown="1">
<summary>Output files</summary>

- `genome_note/`
  - `<assembly>.csv`: collated genome statistics file
  - `<assembly>.{docx|xml}`: partially completed genome note template file
  - `<assembly>.genome_note_consistent.csv`: a file of genome metadata parameters pulled from various public data repositories where all source agree on the parameter value.
  - `<assembly>.genome_note_inconsistent.csv`: a file of genome metadata parameters, and their sources pulled from various public data repositories where the parameter value differs between data sources.

</details>

### MultiQC

<details markdown="1">
<summary>Output files</summary>

- `multiqc_report.html`: a standalone HTML file that can be viewed in your web browser.

</details>

[MultiQC](http://multiqc.info) is a visualization tool that generates a single HTML report summarising all samples in your project. Some of the pipeline results are visualised in the report and further statistics are available in the report data directory.

Results generated by MultiQC collate pipeline from supported tools e.g. BUSCO. The pipeline has special steps which also allow the software versions to be reported in the MultiQC output for future traceability. For more information about how to use MultiQC reports, see <http://multiqc.info>.

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
