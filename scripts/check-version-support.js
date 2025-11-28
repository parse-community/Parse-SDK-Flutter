#!/usr/bin/env node

/**
 * Check Version Support Script
 *
 * This script checks if Dart/Flutter versions are approaching end-of-life (EOL)
 * based on the 6-month support window policy. It helps maintain the README
 * compatibility tables and identify versions that need to be dropped.
 *
 * Usage:
 *   node scripts/check-version-support.js
 *   node scripts/check-version-support.js --json  # Output as JSON
 */

const SUPPORT_WINDOW_MONTHS = 6;

// Dart version releases (update this manually as new versions are released)
const DART_RELEASES = [
  { version: '3.2', latest: '3.2.6', releaseDate: '2023-11-15' },
  { version: '3.3', latest: '3.3.4', releaseDate: '2024-02-15' },
  { version: '3.4', latest: '3.4.4', releaseDate: '2024-05-15' },
  { version: '3.5', latest: '3.5.3', releaseDate: '2024-08-15' },
];

// Flutter version releases (update this manually as new versions are released)
const FLUTTER_RELEASES = [
  { version: '3.16', latest: '3.16.9', releaseDate: '2023-11-15' },
  { version: '3.19', latest: '3.19.6', releaseDate: '2024-02-15' },
  { version: '3.22', latest: '3.22.3', releaseDate: '2024-05-15' },
  { version: '3.24', latest: '3.24.3', releaseDate: '2024-08-15' },
];

/**
 * Calculate end-of-support date for a version
 * @param {string} nextReleaseDate - Release date of next significant version
 * @returns {Date} End-of-support date
 */
function calculateEOL(nextReleaseDate) {
  const date = new Date(nextReleaseDate);
  date.setMonth(date.getMonth() + SUPPORT_WINDOW_MONTHS);
  return date;
}

/**
 * Format date as YYYY-MM-DD
 * @param {Date} date
 * @returns {string}
 */
function formatDate(date) {
  return date.toISOString().split('T')[0];
}

/**
 * Format date as human-readable (e.g., "Jan 2025")
 * @param {Date} date
 * @returns {string}
 */
function formatHumanDate(date) {
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return `${months[date.getMonth()]} ${date.getFullYear()}`;
}

/**
 * Check version support status
 * @param {Array} releases - Array of release objects
 * @param {string} framework - 'Dart' or 'Flutter'
 * @returns {Array} Array of version status objects
 */
function checkVersionSupport(releases, framework) {
  const today = new Date();
  const results = [];

  for (let i = 0; i < releases.length; i++) {
    const release = releases[i];
    const nextRelease = releases[i + 1];

    const releaseDate = new Date(release.releaseDate);
    const eolDate = nextRelease ? calculateEOL(nextRelease.releaseDate) : null;

    const daysUntilEOL = eolDate ? Math.floor((eolDate - today) / (1000 * 60 * 60 * 24)) : null;

    let status = 'supported';
    let warning = null;

    if (eolDate) {
      if (today >= eolDate) {
        status = 'expired';
        warning = `Support expired on ${formatHumanDate(eolDate)}`;
      } else if (daysUntilEOL <= 30) {
        status = 'expiring-soon';
        warning = `Support expires in ${daysUntilEOL} days`;
      } else if (daysUntilEOL <= 60) {
        status = 'warning';
        warning = `Support expires in ${Math.floor(daysUntilEOL / 30)} month(s)`;
      }
    }

    results.push({
      framework,
      version: release.version,
      latest: release.latest,
      releaseDate: release.releaseDate,
      eolDate: eolDate ? formatDate(eolDate) : 'N/A',
      eolHuman: eolDate ? formatHumanDate(eolDate) : 'N/A',
      daysUntilEOL,
      status,
      warning,
      compatible: status !== 'expired'
    });
  }

  return results;
}

/**
 * Generate README-compatible markdown table
 * @param {Array} results - Version status results
 * @returns {string} Markdown table
 */
function generateMarkdownTable(results) {
  let table = '| Version | Latest Version | End of Support | Compatible |\n';
  table += '|---------|----------------|----------------|------------|\n';

  for (const result of results) {
    const version = result.framework === 'Dart'
      ? `Dart ${result.version}`
      : `Flutter ${result.version}`;
    const compatible = result.compatible ? '✅ Yes' : '❌ No';
    table += `| ${version} | ${result.latest} | ${result.eolHuman} | ${compatible} |\n`;
  }

  return table;
}

/**
 * Main function
 */
function main() {
  const args = process.argv.slice(2);
  const jsonOutput = args.includes('--json');

  const dartResults = checkVersionSupport(DART_RELEASES, 'Dart');
  const flutterResults = checkVersionSupport(FLUTTER_RELEASES, 'Flutter');
  const allResults = [...dartResults, ...flutterResults];

  if (jsonOutput) {
    console.log(JSON.stringify({
      dart: dartResults,
      flutter: flutterResults,
      supportWindowMonths: SUPPORT_WINDOW_MONTHS,
      generatedAt: new Date().toISOString()
    }, null, 2));
    return;
  }

  // Human-readable output
  console.log('╔════════════════════════════════════════════════════════════════╗');
  console.log('║         Parse SDK Version Support Status Check                ║');
  console.log('╚════════════════════════════════════════════════════════════════╝\n');

  console.log(`Support Window: ${SUPPORT_WINDOW_MONTHS} months after next significant version\n`);

  // Dart versions
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📦 DART VERSIONS');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  for (const result of dartResults) {
    const icon = result.status === 'expired' ? '❌' :
                 result.status === 'expiring-soon' ? '⚠️' :
                 result.status === 'warning' ? '⚡' : '✅';

    console.log(`${icon} Dart ${result.version} (${result.latest})`);
    console.log(`   Release: ${result.releaseDate}`);
    console.log(`   EOL: ${result.eolHuman}`);
    if (result.warning) {
      console.log(`   ⚠️  ${result.warning}`);
    }
    console.log();
  }

  // Flutter versions
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📱 FLUTTER VERSIONS');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  for (const result of flutterResults) {
    const icon = result.status === 'expired' ? '❌' :
                 result.status === 'expiring-soon' ? '⚠️' :
                 result.status === 'warning' ? '⚡' : '✅';

    console.log(`${icon} Flutter ${result.version} (${result.latest})`);
    console.log(`   Release: ${result.releaseDate}`);
    console.log(`   EOL: ${result.eolHuman}`);
    if (result.warning) {
      console.log(`   ⚠️  ${result.warning}`);
    }
    console.log();
  }

  // Summary
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📊 SUMMARY');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  const expired = allResults.filter(r => r.status === 'expired').length;
  const expiringSoon = allResults.filter(r => r.status === 'expiring-soon').length;
  const warning = allResults.filter(r => r.status === 'warning').length;
  const supported = allResults.filter(r => r.status === 'supported').length;

  console.log(`✅ Supported: ${supported}`);
  console.log(`⚡ Warning (< 2 months): ${warning}`);
  console.log(`⚠️  Expiring Soon (< 1 month): ${expiringSoon}`);
  console.log(`❌ Expired: ${expired}`);
  console.log();

  if (expired > 0) {
    console.log('⚠️  ACTION REQUIRED: Remove expired versions from CI and README');
    console.log('   Create a major version bump PR to drop support for:');
    allResults.filter(r => r.status === 'expired').forEach(r => {
      console.log(`   - ${r.framework} ${r.version}`);
    });
    console.log();
  }

  if (expiringSoon > 0 || warning > 0) {
    console.log('ℹ️  FYI: Some versions approaching EOL');
    allResults.filter(r => r.status === 'expiring-soon' || r.status === 'warning').forEach(r => {
      console.log(`   - ${r.framework} ${r.version}: ${r.warning}`);
    });
    console.log();
  }

  // Markdown tables for README
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  console.log('📝 README MARKDOWN TABLES');
  console.log('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n');

  console.log('Dart Package (packages/dart/README.md):\n');
  console.log(generateMarkdownTable(dartResults));
  console.log();

  console.log('Flutter Package (packages/flutter/README.md):\n');
  console.log(generateMarkdownTable(flutterResults));
  console.log();

  // Exit code
  process.exit(expired > 0 ? 1 : 0);
}

// Run if called directly
if (require.main === module) {
  main();
}

module.exports = { checkVersionSupport, calculateEOL, generateMarkdownTable };
