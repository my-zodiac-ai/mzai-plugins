---
name: design-critique
description: >
  Evaluate visual design quality of Vue 3 + Quasar components in My Zodiac AI.
  Use when the user asks to "critique this design", "review visual design",
  "check visual hierarchy", "покритикуй дизайн", "оцени визуал",
  or wants feedback on composition, glass effects, color palette, and typography.
---

# Design Critique — My Zodiac AI

Analyze Vue/Quasar component code for visual design quality within the Cosmic Glass design system.

## Activation

Trigger when reviewing screens, pages, or components for visual quality — not for UX flows or accessibility (those are separate agents).

## Analysis Process

### 1. Identify Target

Determine what to review:
- If a specific file/component is provided, read it directly
- If a page/screen name is given, locate it in `front/src/pages/` or `front/src/widgets/`
- If no target specified, ask the user

### 2. Read Source Files

For the target component, read:
- The `.vue` SFC (template + script + style)
- Any imported shared UI components from `front/src/shared/ui/`
- The SCSS imports, especially `@/css/mixins-redesign` and `@/css/_utilities-cosmic.scss`

### 3. Visual Hierarchy Check

Evaluate the template structure for clear information hierarchy:

| Check | What to Look For |
|-------|-----------------|
| Primary focal point | Is there one clear element that draws attention first? |
| Reading flow | Does the layout guide the eye top→bottom, left→right (or appropriate for RTL)? |
| Emphasis levels | Are headings, subheadings, body text clearly differentiated? |
| Whitespace usage | Is spacing between sections consistent and creating visual breathing room? |
| Z-index layering | Are overlapping elements layered correctly (modals > tooltips > content)? |

### 4. Glass System Compliance

Check that glass effects follow the Cosmic Glass design system:

**Required patterns:**
- Glass surfaces use `@include liquid-glass-base()`, `liquid-glass-gold()`, or `liquid-glass-purple()` — never custom `backdrop-filter`
- Interactive glass elements include `@include liquid-glass-interactive`
- Glass containers have `position: relative` and `overflow: hidden`
- `-webkit-backdrop-filter` is paired with `backdrop-filter`
- No glass-inside-glass nesting (max 1 layer depth)
- `prefers-reduced-motion` block exists for animated glass elements

**Token compliance:**
- Border radius uses `--border-radius-*` tokens, not hardcoded values
- Blur uses `--blur-*` or `--backdrop-blur-*` tokens
- Shadows use `--shadow-*` or `--shadow-cosmic-*` tokens
- Colors use `--color-bg-cosmic-*`, `--color-text-cosmic-*`, `--color-accent-cosmic-*` tokens

### 5. Color & Typography Consistency

- All colors reference CSS custom properties, no hardcoded hex/rgb
- Typography uses the project's type scale (check `front/src/css/` for defined scales)
- Gold accent = `--color-accent-cosmic-gold` for featured/premium elements
- Purple accent = `--color-accent-cosmic-purple` for mystic/accent elements
- Dark backgrounds use `--color-bg-cosmic-primary` through `--color-bg-cosmic-elevated`

### 6. Composition & Layout

- Component uses CSS Grid or Flexbox appropriately (no float hacks)
- Responsive breakpoints follow the project convention (check for `@media (max-width: 768px)`)
- Layout doesn't break at narrow widths — look for `min-width` constraints without responsive handling
- Quasar grid classes (`col-*`, `row`, `q-gutter-*`) used correctly

### 7. Animation & Motion

- Transitions use project duration tokens: `--duration-fast`, `--duration-normal`, `--duration-slow`
- Easing curves use project tokens: `--ease-smooth`, `--ease-bounce`
- Vue `<Transition>` components have appropriate `name` attributes
- No jarring or unexpected animations

## Output Format

Generate a markdown report:

```markdown
## Design Critique: [Component/Page Name]

### Overall Impression
[1-2 sentences: what works well and what's the biggest opportunity for improvement]

### Visual Hierarchy
| Finding | Severity | Location | Recommendation |
|---------|----------|----------|----------------|
| ... | 🔴 Critical / 🟡 Moderate / 🟢 Minor | file:line | ... |

### Glass System Compliance
| Finding | Severity | Location | Recommendation |
|---------|----------|----------|----------------|
| ... | ... | ... | ... |

### Color & Typography
| Finding | Severity | Location | Recommendation |
|---------|----------|----------|----------------|
| ... | ... | ... | ... |

### Composition & Layout
| Finding | Severity | Location | Recommendation |
|---------|----------|----------|----------------|
| ... | ... | ... | ... |

### Animation & Motion
| Finding | Severity | Location | Recommendation |
|---------|----------|----------|----------------|
| ... | ... | ... | ... |

### What Works Well
- [Positive observation with specific reference]
- ...

### Priority Recommendations
1. **[Most impactful fix]** — [Why and how]
2. **[Second priority]** — [Why and how]
3. **[Third priority]** — [Why and how]

### Score: [X]/100
```

## Severity Definitions

- 🔴 **Critical** — Breaks visual consistency, violates design system, or degrades user experience significantly
- 🟡 **Moderate** — Noticeable inconsistency or missed opportunity that should be fixed
- 🟢 **Minor** — Polish item, nice-to-have improvement
