---
name: design-system-tokens
description: >
  Audit the Cosmic Glass design system tokens and component consistency in My Zodiac AI.
  Use when the user asks to "check design system", "audit tokens", "проверь токены",
  "design system consistency", "проверь дизайн систему", "token audit",
  or wants to verify CSS custom properties, SCSS mixin usage, naming conventions,
  and component variant completeness.
---

# Design System Token Audit — My Zodiac AI

Audit CSS custom properties, SCSS mixins, and component libraries for consistency, naming, coverage, and adherence to the Cosmic Glass design system.

## Activation

Trigger when auditing the design system itself — tokens, mixins, component variants, naming conventions. Not for reviewing a specific screen's visual quality (that's design-critique).

## Analysis Process

### 1. Source of Truth Files

Read these files first — they define the system:

| File | Purpose |
|------|---------|
| `front/src/css/_mixins-redesign.scss` | All Liquid Glass mixins |
| `front/src/css/_utilities-cosmic.scss` | Utility classes |
| `front/src/css/COSMIC-DESIGN-SYSTEM.md` | Design system docs |
| `front/src/css/quasar-variables.scss` | Quasar theme overrides |
| `front/src/css/app.scss` | Global styles and CSS custom properties |

### 2. Token Coverage Audit

Scan the entire `front/src/` directory for hardcoded values that should use tokens:

#### Colors
Search for: `#[0-9a-fA-F]{3,8}`, `rgb(`, `rgba(`, `hsl(`
- Flag any hardcoded color not in a CSS custom property definition
- Expected pattern: `var(--color-*)` everywhere except token definitions

#### Spacing
Search for: `margin:`, `padding:`, `gap:` with pixel/rem values
- Flag values that don't match the spacing scale
- Expected: `var(--spacing-*)` or Quasar's `q-pa-*`, `q-ma-*`, `q-gutter-*`

#### Border Radius
Search for: `border-radius:` with hardcoded values
- Expected: `var(--border-radius-*)` tokens
- Allowed: values inside mixin definitions themselves

#### Shadows
Search for: `box-shadow:` with hardcoded values
- Expected: `var(--shadow-*)` or mixin-generated shadows
- Flag custom shadows outside of mixin files

#### Typography
Search for: `font-size:`, `font-weight:`, `line-height:` with hardcoded values
- Expected: project type scale tokens or Quasar typography classes

#### Blur
Search for: `backdrop-filter:`, `filter: blur(` with hardcoded values
- Expected: `var(--blur-*)` or `var(--backdrop-blur-*)` tokens
- Exception: inside mixin definitions

### 3. Naming Convention Audit

Check all CSS custom properties follow the naming scheme:

```
--{category}-{subcategory}-{variant}

Categories:
  --color-bg-*          background colors
  --color-text-*        text colors
  --color-accent-*      accent/brand colors
  --color-border-*      border colors
  --border-radius-*     border radius
  --shadow-*            shadows
  --shadow-cosmic-*     cosmic-themed shadows
  --blur-*              blur values
  --backdrop-blur-*     backdrop-filter blur
  --spacing-*           spacing scale
  --duration-*          animation durations
  --ease-*              easing curves
```

Flag tokens that don't follow this pattern.

### 4. Component Variant Completeness

For each shared UI component in `front/src/shared/ui/`:

| Component | Check |
|-----------|-------|
| AppCard | Does it have: default, cosmic-glass, cosmic-glass-gold, cosmic-glass-purple variants? |
| AppButton | Does it have: default, glass, outlined, text variants? |
| AppModal | Does it have: default, cosmic-glass variants? |
| [Others] | Document all variants and check consistency |

For each variant, verify:
- TypeScript interface includes the variant string
- SCSS class exists: `.component--variant`
- Mixin import: `@import '@/css/mixins-redesign'`
- Light theme override: `[data-theme='light']` block
- Reduced motion: `@media (prefers-reduced-motion: reduce)` block
- Interactive state: `liquid-glass-interactive` where appropriate

### 5. SCSS Mixin Usage Audit

Verify mixin usage patterns:

**Correct import:**
```scss
@import '@/css/mixins-redesign';
```

**Anti-patterns to flag:**
- Importing mixins from other component files
- Duplicating mixin logic instead of using `@include`
- Using `backdrop-filter` without the `-webkit-` prefix (outside of mixins)
- Overriding mixin-generated properties inline

### 6. Design System Documentation Sync

Compare actual code state to `COSMIC-DESIGN-SYSTEM.md`:
- Are all documented tokens actually defined in CSS?
- Are all defined tokens documented?
- Do documented component variants match actual implementations?
- Are any undocumented tokens in use?

## Output Format

```markdown
## Design System Token Audit
**Date:** [Date] | **Files scanned:** [X]

### Summary
| Category | Defined Tokens | Hardcoded Values Found | Coverage |
|----------|---------------|----------------------|----------|
| Colors | [X] | [X] instances | [X]% |
| Spacing | [X] | [X] instances | [X]% |
| Border Radius | [X] | [X] instances | [X]% |
| Shadows | [X] | [X] instances | [X]% |
| Typography | [X] | [X] instances | [X]% |
| Blur | [X] | [X] instances | [X]% |

### Hardcoded Values (Top Offenders)
| File | Line | Property | Value | Should Use |
|------|------|----------|-------|-----------|
| ... | ... | ... | `#fff` | `var(--color-text-*)` |

### Naming Convention Issues
| Token | Issue | Suggested Name |
|-------|-------|---------------|
| `--custom-bg` | Missing category prefix | `--color-bg-custom` |

### Component Variant Completeness
| Component | Variants | TS Types | SCSS | Light Theme | Reduced Motion | Score |
|-----------|----------|----------|------|-------------|----------------|-------|
| AppCard | 4/4 | ✅ | ✅ | ⚠️ | ✅ | 9/10 |
| AppButton | 3/4 | ✅ | ⚠️ | ❌ | ❌ | 5/10 |

### Mixin Usage Issues
| File | Issue | Fix |
|------|-------|-----|
| ... | Wrong import path | Use `@import '@/css/mixins-redesign'` |

### Documentation Sync
| Issue | Type | Detail |
|-------|------|--------|
| Token `--blur-xxl` used but undocumented | Missing doc | Add to COSMIC-DESIGN-SYSTEM.md |

### Priority Actions
1. **[Most impactful fix]**
2. **[Second priority]**
3. **[Third priority]**

### Overall Score: [X]/100
```
