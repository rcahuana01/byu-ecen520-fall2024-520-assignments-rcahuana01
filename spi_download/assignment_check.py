#!/usr/bin/python3

# Manages file paths
import pathlib
import sys

# Add to the system path the "resources" directory relative to the script that was run
resources_path = pathlib.Path(__file__).resolve().parent.parent  / 'resources'
sys.path.append( str(resources_path) )

import test_suite_520
import repo_test

def main():

    tester = test_suite_520.build_test_suite_520("spi_download",  min_err_commits = 5, max_repo_files = 30)
    tester.add_make_test("synth_adxl362_cntrl")
    tester.add_make_test("sim_top")
    tester.add_make_test("sim_top_100")
    tester.add_make_test("gen_bit")
    tester.add_make_test("gen_bit_100")
    tester.add_build_test(repo_test.file_exists_test(["spi_adxl362.bit", "spi_adxl362_100.bit",]))
    tester.run_tests()

if __name__ == "__main__":
    main()