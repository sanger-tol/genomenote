process HAPLOTYPE_COMPLETENESS {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.20--h7132678_1' :
        'quay.io/biocontainers/samtools:1.20--h7132678_1' }"

    input:
    path kmer_db
    path fasta_files
    path merqury_output

    output:
    path "*.completeness.tsv", emit: completeness
    path "versions.yml", emit: versions

    script:
    def args = task.ext.args ?: ''
    """
    #!/usr/bin/env python3
    import os
    import sys
    import pandas as pd
    from pathlib import Path

    def calculate_haplotype_completeness(kmer_db, fasta_files, merqury_output):
        # Read MerquryFK output
        merqury_df = pd.read_csv(merqury_output, sep='\\t')
        
        # Calculate total k-mers
        total_kmers = merqury_df['Total'].sum()
        
        # Calculate found k-mers for each haplotype
        haplotype_kmers = {}
        for fasta in fasta_files:
            haplotype = Path(fasta).stem
            haplotype_df = merqury_df[merqury_df['Assembly'].str.contains(haplotype)]
            haplotype_kmers[haplotype] = haplotype_df['Found'].sum()
        
        # Calculate completeness percentages
        results = []
        for haplotype, found in haplotype_kmers.items():
            completeness = (found / total_kmers) * 100
            results.append({
                'Assembly': haplotype,
                'Region': 'all',
                'Found': found,
                'Total': total_kmers,
                '% Covered': completeness
            })
        
        # Calculate combined completeness
        combined_found = sum(haplotype_kmers.values())
        results.append({
            'Assembly': 'combined',
            'Region': 'all',
            'Found': combined_found,
            'Total': total_kmers,
            '% Covered': (combined_found / total_kmers) * 100
        })
        
        return pd.DataFrame(results)

    # Process inputs
    kmer_db = Path("$kmer_db")
    fasta_files = [str(f) for f in Path("$fasta_files").glob("*.fasta*")]
    merqury_output = Path("$merqury_output")

    # Calculate completeness
    results = calculate_haplotype_completeness(kmer_db, fasta_files, merqury_output)
    
    # Save results
    results.to_csv("haplotype.completeness.tsv", sep='\\t', index=False)

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        python: \$(python --version | sed 's/Python //g')
        pandas: \$(python -c "import pandas as pd; print(pd.__version__)")
    END_VERSIONS
    """
} 