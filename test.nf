#!/usr/bin/env nextflow

include { CONTACT_MAPS } from './subworkflows/local/contact_maps'

workflow {
    def meta = [:]
    meta.id = "mMelMel3"
    //meta.id = "gfLaeSulp1"
    meta.datatpye = "hic"
    //meta.outdir = "/lustre/scratch124/tol/projects/.sandbox_ps22/data/mammals/Meles_meles/analysis/mMelMel3.2_paternal_haplotype"
    bam = "/lustre/scratch124/tol/projects/.sandbox_ps22/data/mammals/Meles_meles/analysis/mMelMel3.2_paternal_haplotype/testing/mMelMel3_T1.bam"
    //bam = "/lustre/scratch123/tol/teams/tolit/users/ps22/pipelines/genomenote/data/gfLaeSulp1.bam"
    ch_bam = Channel.of([meta, bam])

    fasta="/lustre/scratch124/tol/projects/.sandbox_ps22/data/mammals/Meles_meles/analysis/mMelMel3.2_paternal_haplotype/assembly/indices/GCA_922984935.2.subset.unmasked.fasta"
    //fasta = "/lustre/scratch123/tol/teams/tolit/users/ps22/pipelines/genomenote/data/GCA_927399515.1.unmasked.fasta"
    ch_fai = Channel.of(fasta+".fai")

    ch_bin = Channel.of(params.bin)

    CONTACT_MAPS (ch_bam, ch_fai, ch_bin)
}
