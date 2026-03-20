# Skill: Advanced Researcher

> **Version**: 2.0
> **Last Updated**: 2026-03-19
> **Purpose**: Establish a production-grade framework for providing accurate, up-to-date technical answers by combining local documentation, web search, and cross-reference validation

---

## Table of Contents

1. [Core Principles](#core-principles)
2. [Workflow Pipeline](#workflow-pipeline)
3. [Tool Selection Matrix](#tool-selection-matrix)
4. [Research Methodology](#research-methodology)
5. [Documentation Sources](#documentation-sources)
6. [Cross-Reference Protocol](#cross-reference-protocol)
7. [Version Compatibility Verification](#version-compatibility-verification)
8. [Knowledge Management](#knowledge-management)
9. [Error Handling & Fallbacks](#error-handling--fallbacks)
10. [Verification & Validation](#verification--validation)
11. [Best Practices Checklist](#best-practices-checklist)

---

## Core Principles

| Principle                 | Description                                                           | Anti-Pattern to Avoid                                            |
| :------------------------ | :------------------------------------------------------------------- | :-------------------------------------------------------------- |
| **Local-First**           | Check cached/local documentation before web search                 | Jumping to web search without checking available documentation |
| **Multi-Source Validation** | Never rely on a single source; always cross-reference            | Accepting first result without verification                    |
| **Version-Aware**         | Always verify against specific project versions                    | Providing generic answers that don't account for version differences |
| **Current-First**         | Prioritize recent documentation; note deprecations                 | Citing outdated documentation that has been replaced           |
| **Context Preservation**  | Maintain the original question context in answers                  | Providing fragmented information without full context          |
| **Traceability**          | Document all sources with URL and retrieval date                   | Providing answers without citable sources                      |

---

## Workflow Pipeline

### Phase 1: Question Analysis

**Objective**: Understand the exact requirements and context of the research question

#### Actions

1. **Parse question intent**
   - Identify core technical concept
   - Determine scope (single concept vs multiple related concepts)
   - Note specific version requirements if mentioned

2. **Identify technology stack**
   - Framework/libraries mentioned
   - Runtime versions (Node, Python, etc.)
   - Build tools or package managers

3. **Classify question type**
   - API usage question
   - Best practices inquiry
   - Breaking change inquiry
   - Troubleshooting question

#### Output

- Clear understanding of question scope
- Technology stack identified
- Question type classification

### Phase 2: Local Documentation Search

**Objective**: Check cached/local documentation for existing answers

#### Actions

1. **Query context7**
   - Search for specific API methods or concepts
   - Check for version-specific documentation
   - Look for existing cached documentation

2. **Local file search**
   - Search `.ai/docs/` directory
   - Check for project-specific documentation
   - Review local API references

3. **Knowledge base check**
   - Review any existing documentation indexes
   - Check for cached answers to similar questions
   - Identify gaps in local documentation

#### Output

- Local documentation results (if any)
- Identified gaps in local documentation
- List of sources needing web verification

### Phase 3: Web Search

**Objective**: Find recent, relevant documentation from authoritative sources

#### Actions

1. **Construct search queries**
   - Use specific queries with version numbers
   - Include keywords like "breaking changes", "migration", "upgrade"
   - Target official documentation sites

2. **Execute searches**
   - Use `brave-search` for web queries
   - Search official documentation first
   - Check community discussions and GitHub issues

3. **Source evaluation**
   - Verify source authority (official docs > community docs > blogs)
   - Check publication date
   - Look for version-specific information

#### Output

- List of relevant sources with URLs
- Publication dates noted
- Source authority ratings

### Phase 4: Cross-Reference Validation

**Objective**: Verify findings against multiple sources

#### Actions

1. **Compare answers**
   - Look for consistency across sources
   - Note any contradictions
   - Identify authoritative sources

2. **Version verification**
   - Confirm version compatibility
   - Identify breaking changes for target versions
   - Check migration guides

3. **Community validation**
   - Check GitHub issues for reported bugs
   - Review Stack Overflow answers with high scores
   - Check changelogs for version-specific information

#### Output

- Validated answer with multiple sources
- Version compatibility confirmed
- Identified potential issues

### Phase 5: Answer Synthesis

**Objective**: Compile and present a comprehensive answer

#### Actions

1. **Draft answer**
   - Include all validated information
   - Cite all sources
   - Note any uncertainties

2. **Version context**
   - Specify applicable versions
   - Note deprecated features
   - Provide upgrade paths if applicable

3. **Examples**
   - Provide code examples where relevant
   - Include both working and non-working examples
   - Document common pitfalls

#### Output

- Complete, cited answer
- Version compatibility note
- Code examples and references

---

## Tool Selection Matrix

| Task                              | Primary Tool       | Fallback                   | When to Use                                      | Notes                                       |
| :-------------------------------- | :----------------- | :------------------        | :---------------------------------------------- | :--------------------------------------       |
| Query local docs                  | `context7`         | Search `.ai/docs/`         | First check for cached documentation             | Fastest method when docs exist                |
| Search web for APIs               | `brave-search`     | Manual web search          | Find current API documentation                   | Use official docs first                      |
| Search for breaking changes       | `brave-search`     | GitHub repo search         | Find migration guides and changes                | Search "library version breaking changes"   |
| Check GitHub issues               | `brave-search`     | GitHub web UI              | Find reported bugs and solutions                 | Search "library issue site:github.com"      |
| Read documentation pages          | `crawl4ai`         | `http_request` + manual    | Extract content from web pages                   | For pages not in cache                       |
| File search within docs           | `search_files`     | `grep` via CLI             | Find specific patterns in local docs             | Use for pattern matching                     |
| Document listing                  | `list_directory`   | `ls` via CLI               | Explore documentation structure                  | `ls -lh .ai/docs/`                          |
| Web browsing                      | `playwright`       | `crawl4ai`                 | Interactive sites or SPAs                        | For sites requiring JavaScript               |
| Version lookup                    | `context7` + `brave-search` | Manual search       | Find version-specific information                | Cross-reference for accuracy                 |

---

## Research Methodology

### Search Query Construction

#### API Documentation Queries

| Query Type                  | Example Query                                    |
| :------------------         | :------------------                              |
| **API method**              | `"express.js get method site:expressjs.com"`   |
| **Configuration option**    | `"react usestate configuration site:react.dev"`|
| **Error message**           | `"mongodb connection error site:mongodb.com"`  |

#### Breaking Change Queries

| Query Type                  | Example Query                                    |
| :------------------         | :------------------                              |
| **Version upgrade**         | `"next.js 15 breaking changes"`                |
| **Deprecation notice**      | `"node.js 20 deprecated features"`             |
| **Migration guide**         | `"webpack 5 migration guide"`                  |

#### Troubleshooting Queries

| Query Type                  | Example Query                                    |
| :------------------         | :------------------                              |
| **Error solution**          | `"npm ERR! ERESOLVE resolve site:stackoverflow.com"` |
| **Configuration issue**     | `"docker port mapping not working"`            |
| **Build error**             | `"vite build error TypeScript"`                |

### Source Evaluation Checklist

| Source Type       | Reliability | Verification Method                     |
| :-------------    | :--------- | :---------                            |
| **Official docs** | High      | Official domain, maintained by team   |
| **Library repo**  | High      | GitHub/GitLab repo, issue tracking    |
| **Stack Overflow**| Medium    | High score, accepted answer           |
| **Blog posts**    | Low       | Check date, author credentials        |
| **Community wikis**| Medium   | Verify with official sources          |

### Information Hierarchy

1. **Primary sources**: Official documentation, library repositories
2. **Secondary sources**: Stack Overflow, community wikis, tutorials
3. **Tertiary sources**: Blog posts, forums, discussions

Always prefer primary sources when available.

---

## Documentation Sources

### Official Documentation Domains

| Technology        | Official Domain                            | Notes                              |
| :-------------    | :----------                                | :--------                          |
| **Node.js**       | `nodejs.org`                               | LTS versions documented            |
| **React**         | `react.dev`                                | Recent version focus               |
| **Express.js**    | `expressjs.com`                            | Stable API                         |
| **Next.js**       | `nextjs.org`                               | Version-specific docs              |
| **Docker**        | `docs.docker.com`                          | Comprehensive documentation        |
| **TypeScript**    | `typescriptlang.org`                       | Language reference                 |
| **PostgreSQL**    | `postgresql.org/docs`                      | Version-specific docs              |
| **MongoDB**       | `docs.mongodb.com`                         | Atlas and server docs              |
| **Vite**          | `vitejs.dev`                               | Configuration reference            |
| **npm**           | `docs.npmjs.com`                           | CLI and registry docs              |

### Documentation Structure

Official documentation typically includes:

```
/docs/
├── getting-started/       # Installation and setup
├── guides/               # Step-by-step tutorials
├── api/                  # API reference
├── concepts/             # Conceptual explanations
├── examples/             # Code examples
├── migration/            # Upgrade guides
├── troubleshooting/      # Common issues and solutions
└── contributing/         # Development guidelines
```

---

## Cross-Reference Protocol

### Three-Source Validation Rule

For any critical piece of information:

1. **Source 1**: Official documentation
2. **Source 2**: GitHub repository (README, issues)
3. **Source 3**: Community consensus (Stack Overflow, forums)

All three should align for confident answers.

### Cross-Reference Checklist

| Check                     | Action                                     |
| :--------                 | :--------                                  |
| **API behavior**          | Check docs, source code, and examples      |
| **Breaking changes**      | Check changelog, release notes, issues     |
| **Configuration options** | Check docs, default config file, examples  |
| **Error messages**        | Check docs, issues, and solution posts     |

### Documenting Conflicts

When sources disagree:

```markdown
## Research Result: [Topic]

### Sources
1. **Official docs** ([link]): States [claim A]
2. **GitHub issue** ([link]): Reports [claim B]
3. **Stack Overflow** ([link]): Confirms [claim B]

### Conclusion
Claim B is correct; official docs appear outdated.
Recommendation: Follow the GitHub issue and Stack Overflow answers.

### Recommendation
Check [link] for updates on official docs.
````

---

## Version Compatibility Verification

### Version-Specific Search Patterns

Always search with version context:

| Search Pattern                  | Example Query                                    |
| :------------------             | :------------------                              |
| **API with version**            | `"express 4.x res.json site:expressjs.com"`   |
| **Breaking changes by version** | `"react 19 breaking changes"`                  |
| **Deprecation by version**      | `"node 22 deprecated globals"`                 |

### LTS Support Matrix

| Runtime    | Current LTS     | End of Life     | Recommendation               |
| :--------- | :---------      | :---------      | :---------                   |
| **Node.js**| v20.x (Hydrogen)| Apr 2026        | Use v20 for new projects     |
| **Node.js**| v18.x (Gallium)| Apr 2025        | Maintain existing v18 apps   |
| **Python** | v3.12.x         | Oct 2028        | Use v3.12 for new projects   |
| **Python** | v3.11.x         | Oct 2027        | Maintain existing v3.11 apps |

### Compatibility Matrix Template

```markdown
## Compatibility Check: [Feature/Package]

### Project Environment
- Node.js: v20.x (LTS)
- Python: v3.12.x
- Package Manager: npm v10.x

### Feature Requirements
- [Feature] requires [Version Range]
- [Package] has known issues in [Version Range]

### Compatibility Status
| Component      | Project Version | Required Range | Compatible | Notes               |
| :---------     | :---------      | :---------     | :--------- | :---------          |
| Node.js        | v20.x           | v18+           | Yes        |                     |
| [Package]      | v1.2.3          | v1.2.0+        | Yes        |                     |
| [Feature]      | n/a             | v2.0.0+        | No         | Requires v2.0.0+   |

### Recommendation
[Status: Compatible / Not Compatible / Requires Update]
```

---

## Knowledge Management

### Documentation Index Template

Maintain an index of researched topics:

```markdown
# Knowledge Base Index

## Topics Researched

| Date       | Topic                          | Sources                                   | Status    |
| :--------- | :---------                     | :---------                                | :---------|
| 2026-03-19 | Express.js route parameters    | expressjs.com, Stack Overflow             | Complete  |
| 2026-03-19 | Next.js 15 app router migration| nextjs.org, GitHub issues                 | Complete  |

## Templates Used
- [Version Compatibility Template]
- [Cross-Reference Template]
- [Documentation Index Template]
```

### Research Log Format

Every research session should log:

```markdown
## Research Log

- **Timestamp**: YYYY-MM-DD HH:MM:SS
- **Question**: [Original question]
- **Technologies**: [Node, React, etc.]
- **Versions**: [Specific versions checked]
- **Sources Queried**: [List of sources]
- **Answers Found**: [Summary of findings]
- **Confidence Level**: [High/Medium/Low]
- **Follow-up Required**: [Yes/No]
```

### Knowledge Retention

- Update local documentation when new information is found
- Document common patterns for reuse
- Maintain version-specific notes
- Update templates based on new research patterns

---

## Error Handling & Fallbacks

### Common Error Scenarios

| Error Scenario            | Immediate Action                                   | Escalation Path                                                  |
| :------------------------ | :------------------------------------------------- | :--------------------------------------------------------------- |
| **No local docs found**   | Proceed directly to web search with refined query   | Expand search scope, try alternative phrasing                  |
| **Conflicting sources**   | Prioritize official docs, note discrepancies        | Escalate to user for decision on conflicting information       |
| **Version-specific docs missing** | Search general docs, note version caveats      | Search GitHub issues for version-specific issues              |
| **API not documented**    | Check source code, test examples, infer from usage  | Check GitHub repo for type definitions or examples            |
| **Search timeout**        | Reduce query specificity, try alternative phrasing  | Use broader search terms, check common documentation sites     |
| **Source inaccessible**   | Retry, check for mirrors, use archive               | Search for cached version on Wayback Machine                  |

### Retry Strategy

```zsh
# Pattern: Retry search with different terms
# If first query fails, try:
# 1. More specific query
# 2. Alternative phrasing
# 3. Target different documentation sources
```

### Logging Requirements

Every research session should log:

```markdown
## Research Log

- **Timestamp**: YYYY-MM-DD HH:MM:SS
- **Question**: [Original question]
- **Technologies**: [List]
- **Versions**: [Specific versions]
- **Local Search**: [Results from context7/docs]
- **Web Search**: [Queries used]
- **Sources Found**: [List with URLs]
- **Validation**: [Cross-reference results]
- **Confidence**: [High/Medium/Low]
- **Answer**: [Summary with citations]
````

---

## Verification & Validation

### Automated Checks

Run these after completing research:

#### Source Validation Checklist

- [ ] At least 3 sources consulted (when possible)
- [ ] Official documentation checked
- [ ] GitHub repository reviewed for issues
- [ ] Source publication dates verified
- [ ] Version-specific information confirmed

#### Answer Validation Checklist

- [ ] All claims cited with source
- [ ] Version compatibility verified
- [ ] Examples provided where applicable
- [ ] Alternative approaches documented
- [ ] Known limitations noted

#### Cross-Reference Validation Checklist

- [ ] Official docs and GitHub aligned
- [ ] Community sources consistent
- [ ] No contradictory information present
- [ ] Version-specific notes included

### Manual Verification

When uncertainty exists:

1. **Code verification**: Run examples to confirm behavior
2. **Documentation review**: Check official docs directly
3. **Version testing**: Test with actual project versions if possible
4. **Peer review**: Have another agent verify findings

### Success Criteria

Research is successful when:

- All claims are properly cited
- Version compatibility is confirmed
- Multiple sources validate findings
- Clear answer provided with examples
- Limitations and caveats documented

---

## Best Practices Checklist

### Pre-Research Checklist

- [ ] Question fully understood
- [ ] Technology stack identified
- [ ] Version numbers noted
- [ ] Question type classified

### During Research Checklist

- [ ] Local docs searched first
- [ ] Multiple sources consulted
- [ ] Version-specific queries used
- [ ] Conflicts documented
- [ ] Sources cited with URLs

### Post-Research Checklist

- [ ] All claims cited
- [ ] Version compatibility confirmed
- [ ] Examples provided
- [ ] Knowledge base updated
- [ ] Research log completed

### Emergency Stop Checklist

If encountering unexpected issues:

- [ ] **Check sources**: Are they accessible?
- [ ] **Verify queries**: Are they specific enough?
- [ ] **Review version**: Is version information correct?
- [ ] **Report**: Document exactly what failed and when

---

## Quick Reference

### Common Research Templates

#### API Research Template

```markdown
## API: [Name]

### Official Documentation
[URL]

### Version Compatibility
- Available in: [Version Range]
- Deprecated in: [Version] (if applicable)

### Usage Example
```[lang]
// Your code here
```

### Notes
[Any important notes or caveats]
```

#### Breaking Change Research Template

```markdown
## Breaking Change: [Description]

### Versions Affected
- Introduced: [Version]
- Deprecated: [Version] (if applicable)

### Migration Guide
1. [Step 1]
2. [Step 2]
3. [Step 3]

### Sources
- [Official docs](URL)
- [GitHub issue](URL)
```

### Research Query Examples

| Need                              | Query to Use                                             |
| :--------                         | :--------                                                |
| Find Express.js API               | `"express.js router.all site:expressjs.com"`            |
| Check Next.js version             | `"next.js 15 app router site:nextjs.org"`               |
| Find error solution               | `"ECONNREFUSED 127.0.0.1:3000 site:stackoverflow.com"`  |
| Check deprecation                 | `"node.js fs.promises site:nodejs.org"`                 |

---

## Revision History

| Version | Date       | Changes                                                                 |
| :------ | :--------- | :---------------------------------------------------------------------- |
| 1.0     | Initial    | Minimal 3-point workflow outline                                       |
| 2.0     | 2026-03-19 | Complete rewrite: added principles, workflow pipeline, tool matrix, research methodology, documentation sources, cross-reference protocol, version compatibility verification, knowledge management, error handling, verification, and best practices |

---

**End of Advanced Researcher Skill**