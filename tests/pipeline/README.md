# Pipeline Tests

This directory contains tests for verifying the correctness of pipeline outputs.

## Test Structure

The test suite includes the following components:

1. `test_outputs.py`: Main test script that verifies:
   - MultiQC report generation
   - Contact map generation and validity
   - Genome statistics calculation
   - Annotation statistics
   - Output directory structure
   - Metadata generation

2. `requirements.txt`: Python dependencies required for running the tests

3. `test_config.yml`: Configuration file specifying:
   - Test data paths
   - Expected output locations
   - Quality thresholds

## Running Tests

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the tests:
   ```bash
   pytest test_outputs.py -v
   ```

## Adding New Tests

To add new tests:

1. Add new test functions to `test_outputs.py`
2. Update `test_config.yml` if new configuration is needed
3. Add any new dependencies to `requirements.txt`

## Test Data

Test data should be placed in the `tests/data` directory. The test suite expects:
- A test Hi-C alignment file
- A test genome FASTA file
- Any other necessary input files

## Continuous Integration

These tests are automatically run in the CI pipeline to ensure pipeline outputs remain valid. 