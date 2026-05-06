---
name: tech-stack-research
description: >
  Research libraries, APIs, and technical tools for implementing a feature.
  Use when the user asks "какие библиотеки для", "tech stack research",
  "best libraries for", "npm packages for", "API для", "технические возможности",
  or needs to evaluate technical options for a feature implementation.
---

# Tech Stack Research

Research and recommend the best libraries, APIs, and technical tools for implementing
the requested feature in the My Zodiac AI stack (NestJS 11 + Vue 3 + Quasar + TypeScript 5.9).

## Process

### 1. Research Libraries

Use WebSearch to find:
- `"[feature]" npm package typescript`
- `"[feature]" javascript library 2025`
- `"[feature]" nestjs module`
- `"[feature]" vue 3 component library`
- `"[feature]" API service`
- GitHub trending/awesome lists: `awesome-[feature]`

### 2. Evaluate Each Option

For every library/API found, check:

**Technical Fit:**
| Field | Check |
|-------|-------|
| TypeScript support | Native types? @types package? None? |
| Bundle size | For frontend libs — check bundlephobia.com |
| Tree-shakeable | Does it support tree-shaking? |
| ESM support | Native ESM or CJS only? |
| Node.js compatibility | Works with Node 20+? |
| Vue 3 compatible | For frontend — Vue 3 composition API support? |
| License | MIT/Apache (preferred) vs commercial |
| Maintenance | Last commit date, open issues, release frequency |
| Community | Stars, weekly downloads, Stack Overflow presence |

**Quality Signals:**
- npm weekly downloads trend (growing/stable/declining)
- GitHub stars and star history
- Number of open issues vs closed
- Test coverage (if visible)
- Documentation quality
- Breaking changes history

### 3. Research APIs & Data Sources

If the feature needs external data:
- Available APIs (REST, GraphQL, WebSocket)
- Pricing models (free tier limits, paid plans)
- Rate limits and quotas
- Data accuracy and freshness
- Geographic coverage
- Authentication methods
- SDK availability for Node.js/TypeScript

### 4. Produce Recommendation

**Library Comparison Table:**

| Library | Stars | Downloads/wk | Size | TS | License | Last Update | Verdict |
|---------|-------|-------------|------|-----|---------|-------------|---------|

**Recommended Stack:**
- Primary library choice with justification
- Fallback option
- Required complementary packages
- Backend vs frontend split

**Integration Notes:**
- How to install and configure
- Required environment variables
- Peer dependencies
- Potential conflicts with existing packages in My Zodiac AI

**Architecture Fit:**
- Where it fits in NestJS module structure (backend)
- Where it fits in FSD structure (frontend)
- Event-driven patterns it can integrate with
- Caching strategy (Redis integration)

## Rules

- ALWAYS check npmjs.com and GitHub for real stats — don't guess
- Prefer libraries with native TypeScript support
- Prefer well-maintained libraries (updated within last 6 months)
- Consider bundle size impact for frontend libraries
- Flag any license incompatibilities
- Check for known security vulnerabilities (npm audit)
- Consider the existing tech stack — don't recommend React libraries for a Vue app
