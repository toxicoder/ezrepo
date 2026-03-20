# Skill: Documentation Scraper

> **Version**: 2.0
> **Last Updated**: 2026-03-19
> **Purpose**: Establish a production-grade framework for ingesting external documentation into the workspace as clean, structured Markdown

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Workflow Pipeline](#workflow-pipeline)
3. [Tool Selection Matrix](#tool-selection-matrix)
4. [Content Extraction Standards](#content-extraction-standards)
5. [Output Formatting](#output-formatting)
6. [Error Handling & Fallbacks](#error-handling--fallbacks)
7. [Verification & Validation](#verification--validation)
8. [Best Practices Checklist](#best-practices-checklist)

---

## Core Principles

| Principle                 | Description                                                           | Anti-Pattern to Avoid                                            |
| :------------------------ | :------------------------------------------------------------------- | :-------------------------------------------------------------- |
| **Clean Markdown First**  | Output must be human-readable Markdown without HTML artifacts       | Copy-pasting raw HTML, JavaScript, or CSS into documentation    |
| **Context Preservation**  | Maintain document structure: headings, code blocks, tables, links    | Flattening content into plain text without hierarchy           |
| **Source Attribution**    | Every document must include source URL and retrieval date            | Removing original link and timestamp                           |
| **Content Filtering**     | Remove navigation, footers, ads, and non-essential UI elements      | Including site chrome in documentation                         |
| **Structure Over Beauty** | Prioritize accurate semantic structure over visual styling           | Preserving CSS classes, inline styles, or layout divs          |
| **Audit Trail**           | Every scrape operation logged for traceability                      | Skipping version info or scraping history                      |

---

## Workflow Pipeline

### Phase 1: Target Identification

**Objective**: Accurately identify and validate the documentation source

#### Actions

1. **Extract URL from request**
   - Validate URL format (protocol, domain, path)
   - Check for trailing slashes and query parameters
   - Identify if URL points to documentation (doc, docs, api, guide patterns)

2. **Determine page type**
   - Simple static page (HTML with minimal JS)
   - SPA (React, Vue, Angular, single-page architecture)
   - Documentation portal (Docusaurus, MkDocs, Read the Docs, etc.)

3. **Initial viability check**
   - Verify HTTP status (200 OK)
   - Check for robots.txt restrictions
   - Confirm page contains documentation content (not just marketing)

#### Output

- Confirmed target URL (normalized)
- Page type classification
- Any detected obstacles

### Phase 2: Content Selection

**Objective**: Isolate the documentation content from surrounding UI

#### Actions

1. **Static pages (crawl4ai)**
   - Automatically detect article/main content selector
   - Fall back to common selectors: `article`, `.content`, `.main-content`, `#docs`, `.doc-content`

2. **SPA detection**
   - Check for SPA indicators: `<script id="__NEXT_DATA__">`, `data-reactroot`, Vue DevTools presence
   - If SPA detected, skip to Phase 3 (Playwright rendering)

3. **Content extraction strategy**
   - Remove: navigation, headers, footers, sidebars (unless navigation is part of docs)
   - Preserve: main article content, code blocks, inline examples
   - Normalize: convert relative links to absolute where possible

#### Output

- Clean HTML containing only documentation content
- List of removed elements (for transparency)

### Phase 3: Rendering (When Required)

**Objective**: Execute JavaScript to render dynamic content

#### Actions

1. **Playwright setup**
   - Launch browser with appropriate viewport
   - Set user agent to detect and handle bot blocks
   - Configure network interception to block non-essential resources

2. **Navigation strategy**
   - Wait for document ready state
   - Wait for key elements (code blocks, tables, etc.)
   - Scroll to trigger lazy-loaded content
   - Handle infinite scroll with timeout

3. **Dynamic content handling**
   - Click "Load more" or expand buttons
   - Wait for data-loaded states
   - Handle authentication redirects gracefully

#### Output

- Fully rendered HTML
- Performance metrics (load time, render time)

### Phase 4: Markdown Conversion

**Objective**: Transform HTML to clean, structured Markdown

#### Actions

1. **HTML-to-Markdown pipeline**
   - Use established converter (e.g., `turndown`, `page-to-markdown`)
   - Preserve semantic structure: h1-h6, paragraphs, lists, blockquotes

2. **Code block handling**
   - Detect language from `class="language-xyz"` or `class="lang-xyz"`
   - Fallback to plain text if no language specified
   - Preserve indentation and formatting

3. **Link processing**
   - Convert relative URLs to absolute using base href
   - Keep anchor links where appropriate
   - Handle documentation version links

4. **Image handling**
   - Convert relative image paths to absolute
   - Include alt text from original `alt` attribute
   - Note any broken images in footer

### Phase 5: Output & Storage

**Objective**: Save document with proper metadata and organization

#### Actions

1. **File naming convention**
   - Format: `{domain}-{path}-{timestamp}.md`
   - Example: `expressjs-com-guide-20260319-154321.md`
   - Replace special characters with hyphens

2. **Metadata header (YAML frontmatter)**
   ```yaml
   ---
   title: [Document Title]
   source_url: [Original URL]
   retrieved_at: [ISO 8601 timestamp]
   page_type: [static|spa|portal]
   keywords: [relevant tags]
   ---
   ```

3. **Save location**
   - Primary: `.ai/docs/{domain}/{clean-path}/`
   - Temporarily: `.ai/docs/tmp/` for immediate review
   - Final destination determined after review

#### Output

- Markdown file with frontmatter
- Clean title from `<title>` or H1
- Proper timestamp tracking

---

## Tool Selection Matrix

| Task                              | Primary Tool       | Fallback                   | When to Use                                      | Notes                                       |
| :-------------------------------- | :----------------- | :------------------        | :---------------------------------------------- | :--------------------------------------       |
| Initial page fetch (HTTP)         | `http_request`     | `curl` via CLI             | Quick HEAD/GET check before scraping             | Lightweight, no browser needed              |
| Static page scraping              | `crawl4ai`         | `brave-search` + manual    | Simple HTML pages, documentation portals         | Best for doc sites, API references          |
| SPA rendering                     | `playwright`       | `crawl4ai` (if it supports)| React/Vue/Angular docs, single-page applications | Requires headless browser, slower but accurate |
| Web search / discovery            | `brave-search`     | `context7`                 | Finding documentation URLs                       | Use when URL unknown from task              |
| HTML-to-Markdown conversion       | `crawl4ai` native  | Manual conversion          | After playwright or crawl4ai fetch               | Most tools have built-in markdown output    |
| File listing                      | `list_directory`   | `ls` via CLI               | Checking existing docs in `.ai/docs/`            | Verify no duplicate files                   |
| File writing                      | `write_file`       | `echo` via CLI             | Saving scraped Markdown                          | Use `write_to_file` for final output        |
| URL normalization                 | Built-in           | `sed` / `awk`              | Clean URLs, remove tracking params               | Standardize for consistent file naming      |

---

## Content Extraction Standards

### What to Remove

| Element               | Selector Patterns                                  | Reason                                    |
| :------------------ | :--------------------------------              | :-----------                              |
| Header/Navigation     | `header`, `.nav`, `.navbar`, `#header`, `.header` | Site-wide navigation not part of docs     |
| Footer                | `footer`, `.footer`, `#footer`, `.site-footer`    | Copyright, links to other sites           |
| Sidebars              | `.sidebar`, `.nav-sidebar`, `.docs-nav`           | Navigation structure (unless essential)   |
| Ads/Widgets           | `.ad`, `.ads`, `.widget`, `.sidebar-widget`       | Commercial content, irrelevant            |
| Social sharing        | `.share`, `.social-share`, `.sharing-buttons`     | UI elements, not documentation content    |
| Cookie banners        | `.cookie-banner`, `.cookie-consent`               | Legal notices, time-sensitive             |
| Newsletter popups     | `.newsletter`, `.popup`, `.modal`                 | Marketing content, interrupts reading     |

### What to Preserve

| Element               | Selector Patterns                                  | Priority                                  |
| :------------------ | :--------------------------------              | :-----------                              |
| Main content          | `article`, `.content`, `.main-content`, `#docs`   | HIGH - core documentation                 |
| API reference blocks  | `.api-section`, `.endpoint`, `.method`            | HIGH - code examples and parameters       |
| Code blocks           | `pre`, `code`, `.language-javascript`, etc.       | HIGH - code samples must be preserved     |
| Tables                | `table`, `.data-table`                            | MEDIUM - reference data                   |
| Images/figures        | `img`, `.screenshot`, `.diagram`                  | MEDIUM - visual documentation             |
| Footnotes             | `.footnote`, `.footnotes`                         | LOW - additional context                  |

### Code Block Standards

```markdown
// ✓ Correct: Language detected
```javascript
function example() {
  return "Hello, World!";
}
```

// ✓ Correct: No language specified
```text
npm install package-name
```

// ✗ Incorrect: HTML artifacts
<div class="highlight"><pre><code class="language-js">...</code></pre></div>
```

---

## Output Formatting

### File Structure

```
.ai/docs/
├── {domain}/
│   ├── {clean-path}/
│   │   ├── {filename}.md
│   │   └── images/
│   │       └── {screenshot}.png
│   └── tmp/
│       └── {timestamp}-{filename}.md
└── index.md          # Optional: master documentation index
```

### Filename Convention

- Format: `{domain}-{path-segments}-{timestamp}.md`
- Lowercase, hyphen-separated
- Timestamp: `YYYYMMDD-HHmmss`
- Examples:
  - `expressjs-com-guide-20260319-154321.md`
  - `reactjs-org-reference-20260319-140000.md`

### Markdown Frontmatter

```yaml
---
title: [Document Title from <title> or H1]
source_url: [Original absolute URL]
retrieved_at: [ISO 8601: YYYY-MM-DDTHH:MM:SSZ]
page_type: [static|spa|portal]
keywords: [comma, separated, tags]
---
```

### Document Footer

Every scraped document must include this footer:

```markdown
---

*Document scraped from {source_url} on {retrieved_at}*
*Last verified: {timestamp}*
```

### Code Block Language Detection

| HTML class               | Detected Language |
| :-----------            | :-----------      |
| `.language-javascript`   | javascript        |
| `.language-js`           | javascript        |
| `.language-python`       | python            |
| `.language-py`           | python            |
| `.language-rust`         | rust              |
| `.language-rs`           | rust              |
| `.language-go`           | go                |
| `.language-java`         | java              |
| `.language-c`            | c                 |
| `.language-css`          | css               |
| `.language-html`         | html              |
| `.language-json`         | json              |
| `.language-yaml`         | yaml              |
| `.language-bash`         | bash              |
| `.language-sh`           | shell             |
| `.language-sql`          | sql               |
| `.language-md`           | markdown          |
| `.language-tex`          | latex             |
| `.language-make`         | makefile          |
| `.language-dockerfile`   | dockerfile        |

If no language class detected, use `text` or `plain`.

---

## Error Handling & Fallbacks

### Common Error Scenarios

| Error Scenario            | Immediate Action                                   | Escalation Path                                                  |
| :------------------------ | :------------------------------------------------- | :--------------------------------------------------------------- |
| **403 Forbidden**         | Check robots.txt, add delay, retry with different user agent | Report to user; may require manual intervention or alternative source |
| **404 Not Found**         | Verify URL, check for redirects, look for alternative docs | Report exact URL that failed; suggest searching for updated URL |
| **500+ Server Error**     | Wait 5 seconds, retry up to 3 times with exponential backoff | Report after retries exhausted; suggest checking docs site status |
| **Timeout (>30s)**        | Increase timeout, simplify page load, remove images | Report; may need to use playwright with longer timeout          |
| **SPA Not Rendering**     | Verify JavaScript enabled, wait for key elements, scroll to trigger loads | Report with screenshots if possible                             |
| **Captcha Challenge**     | Stop scrape, report immediately                     | User may need to access site manually or find alternative       |
| **Authentication Required** | Stop scrape, report authentication requirement     | User may need to provide credentials or use public documentation |
| **No Content Found**      | Log what selectors were attempted, report empty result | User may need to provide more specific URL                      |

### Retry Strategy

```zsh
# Pattern: Exponential backoff
attempt=1
max_attempts=3
sleep_time=2

while [ $attempt -le $max_attempts ]; do
  # Try scrape
  if command_success; then
    break
  fi
  
  echo "Attempt $attempt failed. Retrying in $sleep_time seconds..."
  sleep $sleep_time
  sleep_time=$((sleep_time * 2))  # Double wait time
  attempt=$((attempt + 1))
done
```

### Logging Requirements

Every scrape should log:

```markdown
## Scraping Log

- **Timestamp**: YYYY-MM-DD HH:MM:SS
- **URL**: [target URL]
- **Method**: crawl4ai | playwright
- **Status**: success | failure
- **Page Type**: static | spa
- **Content Length**: [character count]
- **Warnings**: [any issues encountered]
- **Duration**: [time in seconds]
```

---

## Verification & Validation

### Automated Checks

Run these after each scrape:

#### Content Integrity Checklist

- [ ] **Title present**: Document has a meaningful `<title>` or H1
- [ ] **Structure intact**: Headings follow proper hierarchy (h1→h2→h3...)
- [ ] **Code blocks parsed**: No raw `<code>` tags in output
- [ ] **Links resolved**: No relative URLs without base context
- [ ] **Images absolute**: All image URLs are absolute paths
- [ ] **No HTML tags**: Outside of code blocks and frontmatter
- [ ] **Empty content**: Document has meaningful text (>100 chars)

#### Format Validation

- [ ] **YAML frontmatter valid**: Proper opening/closing `---`
- [ ] **Timestamp format**: ISO 8601 compliant
- [ ] **Filename safe**: No special characters, lowercase, hyphen-separated
- [ ] **Line endings**: Unix-style (`\n`)
- [ ] **Trailing whitespace**: None
- [ ] **Line length**: Under 80 characters (where reasonable)

### Manual Verification

When uncertainty exists:

1. **Read through output**: Does it make sense as documentation?
2. **Check code examples**: Can they be copied and executed?
3. **Verify links**: Do they point to valid destinations?
4. **Compare to source**: Does it match the original intent?

### Success Criteria

A scrape is considered successful when:

- Markdown is clean and readable without formatting issues
- All code blocks have correct syntax highlighting
- Document structure mirrors the original page
- Source attribution is present
- No site chrome (navigation, ads) in output
- File saved to correct location with proper naming

---

## Best Practices Checklist

### Pre-Scrape Checklist

- [ ] URL is valid and accessible
- [ ] No robots.txt restrictions detected
- [ ] Documentation type determined (static vs SPA)
- [ ] Appropriate tool selected (crawl4ai vs playwright)
- [ ] `.ai/docs/` directory exists or will be created

### During Scrape Checklist

- [ ] Browser launched (if using playwright)
- [ ] User agent set appropriately
- [ ] Network requests intercepted (optional, for performance)
- [ ] Wait conditions met before capture
- [ ] Scroll completed for lazy-loaded content

### Post-Scrape Checklist

- [ ] Markdown validated for HTML artifacts
- [ ] Code blocks have language classes
- [ ] Images have absolute URLs
- [ ] Frontmatter included and valid
- [ ] Filename follows convention
- [ ] File saved to correct directory
- [ ] Timestamp recorded
- [ ] Success criteria verified

### Emergency Stop Checklist

If encountering unexpected issues:

- [ ] **Check logs**: What was the last successful operation?
- [ ] **Verify network**: Can external sites be reached?
- [ ] **Test tools**: Run basic scrape to verify tool functionality
- [ ] **Check rates**: May have hit rate limits
- [ ] **Report**: Document exactly what failed and when

---

## Quick Reference

### Common Documentation Domains

| Domain              | Type    | Tool    | Notes                                  |
| :-----------       | :----- | :----- | :-----                                 |
| `expressjs.com`     | Static | crawl4ai | Simple HTML, no SPA                    |
| `reactjs.org`       | SPA    | playwright | React docs need JS rendering           |
| `nodejs.org`        | Static | crawl4ai | Basic documentation site               |
| `vuejs.org`         | SPA    | playwright | Vue documentation requires JS          |
| `developer.mozilla.org` | Static | crawl4ai | MDN uses static HTML for pages        |
| `axios-http.com`    | Static | crawl4ai | Simple documentation structure         |
| `nextjs.org`        | SPA    | playwright | Next.js docs are React-based SPA       |

### Quick Commands

```zsh
# Test URL accessibility
curl -s -I https://example.com/docs

# List scraped docs
ls -lh .ai/docs/

# View recently added docs
find .ai/docs/ -name "*.md" -mtime -1 -ls

# Check for empty files
find .ai/docs/ -name "*.md" -empty

# Validate YAML frontmatter (requires yq)
find .ai/docs/ -name "*.md" -exec yq eval '.' {} \; 2>/dev/null
```

### File Naming Examples

```
# Good filenames
expressjs-com-guide-20260319-154321.md
reactjs-org-tutorial-20260319-160000.md
nodejs-org-api-reference-20260319-143000.md

# Bad filenames (avoid)
guide.md                            # Not specific enough
react-docs.md                       # Missing domain and timestamp
2026-03-19.md                       # Not specific enough
```

### Error Codes Reference

| HTTP Code | Meaning              | Action                               |
| :--------- | :------------------- | :----------------------------------- |
| 200        | Success              | Proceed with scrape                  |
| 301/302    | Redirect             | Follow redirect, log new URL         |
| 403        | Forbidden            | Check robots.txt, retry with delay   |
| 404        | Not Found            | Report URL issue                     |
| 429        | Too Many Requests    | Wait and retry with backoff          |
| 500        | Server Error         | Retry with backoff                   |
| 503        | Service Unavailable  | Retry later                          |

---

## Revision History

| Version | Date       | Changes                                                                 |
| :------ | :--------- | :---------------------------------------------------------------------- |
| 1.0     | Initial    | Minimal 4-point workflow outline                                       |
| 2.0     | 2026-03-19 | Complete rewrite: added principles, workflow pipeline, tool matrix, content standards, formatting guidelines, error handling, verification, and best practices |

---

**End of Documentation Scraper Skill**