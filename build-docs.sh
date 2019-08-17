#!/bin/sh

#
# Build reference documentation
#

# Requires sourcekitten at https://github.com/jpsim/SourceKitten.git

# Change directory to where this script is located
cd "$(dirname ${BASH_SOURCE[0]})"

# SourceKitten needs .build/debug.yaml, so let's build the package.
rm -rf .build
swift build

# The output will go in refdocs/
# Make sure /refdocs is in .gitignore
rm -rf docs/SQLiteKit
mkdir -p "docs/SQLiteKit"

sourcekitten doc --spm-module SQLiteKit > SQLiteKitDocs.json

jazzy \
  --clean \
  --swift-version 5.1.0 \
  --sourcekitten-sourcefile SQLiteKitDocs.json \
  --author Apparata \
  --author_url http://apparata.se \
  --github_url https://github.com/apparata/SQLiteKite \
  --output "docs/SQLiteKit" \
  --readme "README.md" \
  --theme fullwidth \
  --source-directory .

rm SQLiteKitDocs.json

open "docs/SQLiteKit/index.html"
