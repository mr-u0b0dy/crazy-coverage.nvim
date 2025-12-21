#!/usr/bin/env python3
"""
Optional CI configuration helper for GitHub Actions.
Place .github/workflows/test.yml to run tests automatically.
"""

import os
import subprocess

def run_tests():
    """Run the full test suite."""
    print("Testing crazy-coverage.nvim...")
    
    # Run legacy tests first (no plenary dependency)
    result = subprocess.run([
        "nvim",
        "--headless",
        "-u", "NONE",
        "+lua dofile('test/run_tests.lua')",
        "+qa"
    ], cwd=os.getcwd())
    
    return result.returncode == 0

if __name__ == "__main__":
    success = run_tests()
    exit(0 if success else 1)
