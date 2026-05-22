#!/usr/bin/env node
// Usage: node batch/mark-pipeline-item.mjs <url> <replacement_line>
// Replaces the "- [ ] <url>..." line in data/pipeline.md with replacement_line.
import { readFileSync, writeFileSync } from 'fs';

const [,, url, ...rest] = process.argv;
const replacement = rest.join(' ');

if (!url || !replacement) {
  console.error('Usage: node batch/mark-pipeline-item.mjs <url> <replacement_line>');
  process.exit(1);
}

const path = 'data/pipeline.md';
const lines = readFileSync(path, 'utf8').split('\n');
let matched = false;

const updated = lines.map(line => {
  if (!matched && line.startsWith('- [ ]') && line.includes(url)) {
    matched = true;
    return replacement;
  }
  return line;
});

if (!matched) {
  console.error(`No pending item found for URL: ${url}`);
  process.exit(1);
}

writeFileSync(path, updated.join('\n'), 'utf8');
console.log(`Marked: ${url}`);
