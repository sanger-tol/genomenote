import os
import json
import pytest
from pathlib import Path
import pandas as pd
import cooler
import numpy as np

def test_multiqc_report_exists():
    """Test that MultiQC report exists and is not empty"""
    report_path = Path("results/multiqc/multiqc_report.html")
    assert report_path.exists(), "MultiQC report not found"
    assert report_path.stat().st_size > 0, "MultiQC report is empty"

def test_contact_maps():
    """Test that contact maps are properly generated"""
    cooler_dir = Path("results/cooler")
    assert cooler_dir.exists(), "Cooler directory not found"
    
    # Check that .cool files exist
    cool_files = list(cooler_dir.glob("*.cool"))
    assert len(cool_files) > 0, "No .cool files found"
    
    # Verify each .cool file
    for cool_file in cool_files:
        # Check if file is a valid cooler file
        try:
            c = cooler.Cooler(str(cool_file))
            # Basic checks
            assert c.info is not None, f"Invalid cooler file: {cool_file}"
            assert len(c.chromsizes) > 0, f"No chromosomes found in {cool_file}"
        except Exception as e:
            pytest.fail(f"Error reading cooler file {cool_file}: {str(e)}")

def test_genome_stats():
    """Test that genome statistics are properly calculated"""
    stats_path = Path("results/genome_stats.json")
    assert stats_path.exists(), "Genome statistics file not found"
    
    with open(stats_path) as f:
        stats = json.load(f)
    
    # Check required fields
    required_fields = ['assembly_size', 'n_contigs', 'n50', 'busco_score']
    for field in required_fields:
        assert field in stats, f"Missing required field: {field}"
        assert stats[field] is not None, f"Field {field} is None"
        if field != 'busco_score':
            assert stats[field] > 0, f"Invalid value for {field}: {stats[field]}"

def test_annotation_stats():
    """Test that annotation statistics are properly calculated"""
    anno_path = Path("results/annotation_stats.tsv")
    if anno_path.exists():
        df = pd.read_csv(anno_path, sep='\t')
        required_columns = ['gene_count', 'transcript_count', 'exon_count']
        for col in required_columns:
            assert col in df.columns, f"Missing required column: {col}"
            assert not df[col].isnull().any(), f"Null values found in {col}"

def test_output_structure():
    """Test that the output directory structure is correct"""
    required_dirs = [
        "results/multiqc",
        "results/cooler",
        "results/genome_stats",
        "results/annotation_stats"
    ]
    
    for dir_path in required_dirs:
        assert Path(dir_path).exists(), f"Required directory not found: {dir_path}"

def test_metadata():
    """Test that metadata files are properly generated"""
    meta_path = Path("results/metadata.json")
    assert meta_path.exists(), "Metadata file not found"
    
    with open(meta_path) as f:
        metadata = json.load(f)
    
    required_fields = ['assembly_accession', 'bioproject', 'biosample']
    for field in required_fields:
        assert field in metadata, f"Missing required metadata field: {field}"
        assert metadata[field], f"Empty value for metadata field: {field}"

if __name__ == "__main__":
    pytest.main([__file__]) 