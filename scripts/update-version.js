#!/usr/bin/env node

/**
 * Updates the version in a pubspec.yaml file
 * Usage: node update-version.js <path-to-pubspec.yaml> <new-version>
 */

const fs = require('fs');
const path = require('path');

// Get arguments
const args = process.argv.slice(2);
if (args.length !== 2) {
  console.error('Usage: node update-version.js <path-to-pubspec.yaml> <new-version>');
  process.exit(1);
}

const pubspecPath = args[0];
const newVersion = args[1];

// Validate inputs
if (!fs.existsSync(pubspecPath)) {
  console.error(`Error: File not found: ${pubspecPath}`);
  process.exit(1);
}

if (!/^\d+\.\d+\.\d+/.test(newVersion)) {
  console.error(`Error: Invalid version format: ${newVersion}`);
  console.error('Expected format: X.Y.Z or X.Y.Z-prerelease');
  process.exit(1);
}

try {
  // Read the pubspec.yaml file
  const content = fs.readFileSync(pubspecPath, 'utf8');

  // Replace the version line
  // This regex matches "version: X.Y.Z" or "version: X.Y.Z-anything"
  const updatedContent = content.replace(
    /^version:\s+.+$/m,
    `version: ${newVersion}`
  );

  // Write back to file
  fs.writeFileSync(pubspecPath, updatedContent, 'utf8');

  console.log(`✅ Successfully updated ${pubspecPath} to version ${newVersion}`);
} catch (error) {
  console.error(`Error updating version: ${error.message}`);
  process.exit(1);
}
