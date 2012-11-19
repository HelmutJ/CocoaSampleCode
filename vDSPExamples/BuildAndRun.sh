#!/bin/csh -e

echo ""
echo "Building examples."
xcodebuild -configuration Default \
    -project vDSPExamples.xcodeproj \
    -target "All Examples"

echo ""
echo "Running Demonstrate."
./build/Default/Demonstrate

echo ""
echo "Running DTMF.DFT."
./build/Default/DTMF.DFT "159#"

echo ""
echo "Running DTMF.FFT."
./build/Default/DTMF.FFT "159#"
