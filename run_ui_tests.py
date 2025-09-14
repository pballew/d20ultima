#!/usr/bin/env python3
"""
UI Test Automation Script
Runs the Godot UI tests and processes the results
"""

import os
import subprocess
import sys
import time
import glob

def run_ui_tests():
    """Run the UI tests using Godot"""
    print("Starting UI Test Automation...")
    print("=" * 50)
    
    # Path to Godot executable (adjust as needed)
    godot_path = "Godot_v4.4.1-stable_win64.exe"
    
    # Check if Godot executable exists
    if not os.path.exists(godot_path):
        print(f"ERROR: Godot executable not found at {godot_path}")
        print("Please ensure Godot is in the current directory or update the path")
        return False
    
    # Run tests in headless mode
    test_scene = "res://tests/UITestRunner.tscn"
    cmd = [godot_path, "--headless", "--path", ".", test_scene]
    
    print(f"Running command: {' '.join(cmd)}")
    print("This may take a few minutes...")
    
    try:
        # Run the tests
        start_time = time.time()
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=120)
        end_time = time.time()
        
        execution_time = end_time - start_time
        print(f"\nTest execution completed in {execution_time:.2f} seconds")
        
        # Print test output
        if result.stdout:
            print("\nTest Output:")
            print("-" * 30)
            print(result.stdout)
        
        if result.stderr:
            print("\nErrors/Warnings:")
            print("-" * 30)
            print(result.stderr)
        
        # Process test reports
        process_test_reports()
        
        return result.returncode == 0
        
    except subprocess.TimeoutExpired:
        print("ERROR: Tests timed out after 2 minutes")
        return False
    except Exception as e:
        print(f"ERROR: Failed to run tests: {e}")
        return False

def process_test_reports():
    """Process and display test report summaries"""
    print("\nProcessing Test Reports...")
    print("=" * 30)
    
    # Get user data directory (this varies by OS)
    user_data_paths = [
        os.path.expanduser("~/.local/share/godot/app_userdata/Ultima-Style RPG/"),
        os.path.expanduser("~/AppData/Roaming/Godot/app_userdata/Ultima-Style RPG/"),
        os.path.expanduser("~/Library/Application Support/Godot/app_userdata/Ultima-Style RPG/")
    ]
    
    report_files = []
    for path in user_data_paths:
        if os.path.exists(path):
            pattern = os.path.join(path, "*test_report*.txt")
            report_files.extend(glob.glob(pattern))
    
    if not report_files:
        print("No test report files found")
        print("Reports should be in Godot's user data directory")
        return
    
    # Sort by modification time (newest first)
    report_files.sort(key=os.path.getmtime, reverse=True)
    
    print(f"Found {len(report_files)} test report(s)")
    
    # Display the most recent comprehensive report
    for report_file in report_files:
        if "comprehensive" in os.path.basename(report_file).lower():
            print(f"\nDisplaying: {os.path.basename(report_file)}")
            print("=" * 50)
            try:
                with open(report_file, 'r') as f:
                    content = f.read()
                    print(content)
                break
            except Exception as e:
                print(f"Error reading report file: {e}")

def main():
    """Main function"""
    print("Ultima-Style D20 RPG - UI Test Automation")
    print("=" * 60)
    
    # Check if we're in the right directory
    if not os.path.exists("project.godot"):
        print("ERROR: project.godot not found")
        print("Please run this script from the game's root directory")
        sys.exit(1)
    
    # Run the tests
    success = run_ui_tests()
    
    if success:
        print("\n✅ UI tests completed successfully!")
        sys.exit(0)
    else:
        print("\n❌ UI tests failed or encountered errors")
        sys.exit(1)

if __name__ == "__main__":
    main()
