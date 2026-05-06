---
name: accessibility-audit
description: >
  Audit Vue 3 + Quasar components for WCAG 2.1 AA accessibility compliance in My Zodiac AI.
  Use when the user asks to "check accessibility", "WCAG audit", "проверь доступность",
  "a11y check", "accessibility review", "проверь контраст", "keyboard navigation check",
  or wants to verify ARIA attributes, color contrast, screen reader support, and keyboard navigation.
---

# Accessibility Audit — My Zodiac AI

Audit Vue/Quasar component code for WCAG 2.1 AA compliance, with special attention to the Cosmic Glass design system's visual effects and mobile Capacitor context.

## Activation

Trigger when checking components for accessibility compliance — not for visual design or UX quality (those are separate agents).

## Analysis Process

### 1. Identify Target

Locate target component(s) to audit.

### 2. Read Source Files

For each component, read:
- The `.vue` SFC (template + script + style)
- SCSS files for color values and contrast
- CSS custom property definitions in `front/src/css/`

### 3. Perceivable (WCAG Principle 1)

#### 1.1.1 Non-text Content
- All `<img>` tags have meaningful `alt` attributes (not "image" or empty for decorative images)
- Icon-only buttons have `aria-label` or visually hidden text
- SVG icons have `role="img"` and `aria-label`, or `aria-hidden="true"` if decorative
- Quasar `<q-icon>` used for decoration has `aria-hidden="true"`

#### 1.3.1 Info and Relationships
- Headings use proper hierarchy (`<h1>` → `<h2>` → `<h3>`, no skipped levels)
- Form inputs have associated `<label>` elements (or `aria-label` / `aria-labelledby`)
- Lists use `<ul>`/`<ol>`/`<li>`, not divs styled as lists
- Tables use `<th>` for headers, `scope` attributes where needed
- ARIA landmarks: `<main>`, `<nav>`, `<aside>`, `<header>`, `<footer>` used correctly

#### 1.4.3 / 1.4.6 Color Contrast
- Normal text (< 18px / < 14px bold): contrast ratio >= 4.5:1
- Large text (>= 18px / >= 14px bold): contrast ratio >= 3:1
- **Special attention for glass surfaces**: text on `backdrop-filter` backgrounds must maintain contrast against the WORST-CASE underlying content
- Gold text (`--color-accent-cosmic-gold`) on dark backgrounds: verify ratio
- Cosmic glass surfaces: check `rgba()` background opacity provides sufficient contrast

#### 1.4.11 Non-text Contrast
- UI component borders >= 3:1 against adjacent colors
- Focus indicators >= 3:1 against surrounding background
- Glass surface borders (`rgba(106, 82, 47, 0.3)`) may be too low contrast

### 4. Operable (WCAG Principle 2)

#### 2.1.1 Keyboard Access
- All interactive elements reachable via Tab key
- Custom components (`AppCard`, `AppButton`, `GlassPanel`) with click handlers have `tabindex="0"` and keyboard event handlers
- No keyboard traps — can Tab into and out of all components
- Quasar dialogs (`q-dialog`) trap focus correctly and release on close

#### 2.4.3 Focus Order
- Tab order follows visual layout (top→bottom, left→right)
- No `tabindex` values > 0 (use 0 or -1 only)
- Modal dialogs trap focus within themselves

#### 2.4.7 Focus Visible
- All focusable elements have visible focus indicator
- Glass interactive elements: check if `liquid-glass-interactive` includes focus styles (not just hover/active)
- Custom focus styles contrast sufficiently against glass backgrounds
- `outline: none` is NEVER used without a replacement focus style

#### 2.5.5 Touch Target Size
- Touch targets >= 44x44 CSS pixels (WCAG), project uses 48px minimum on mobile
- Check `min-height`/`min-width` on interactive elements within `@media (max-width: 768px)`
- Spacing between adjacent touch targets >= 8px

### 5. Understandable (WCAG Principle 3)

#### 3.2.1 Predictable Behavior
- No unexpected context changes on focus
- Form submissions don't happen without explicit user action
- Dialogs don't open unexpectedly

#### 3.3.1 / 3.3.2 Error Identification and Labels
- Form validation errors described in text (not color alone)
- Error messages associated with inputs via `aria-describedby`
- Required fields marked with both visual indicator and `aria-required="true"`

### 6. Robust (WCAG Principle 4)

#### 4.1.2 Name, Role, Value
- Custom components expose correct ARIA roles
- Quasar components: verify `role` attributes on custom wrappers
- Dynamic content changes announced via `aria-live` regions
- Expandable sections use `aria-expanded`

### 7. Reduced Motion

- `@media (prefers-reduced-motion: reduce)` blocks exist for:
  - Glass transitions (`liquid-glass-interactive` hover/press effects)
  - Vue `<Transition>` animations
  - CSS keyframe animations
  - Auto-playing animations or carousels
- Reduced motion blocks set `transition: none !important` and `animation: none !important`

### 8. Glass-Specific Accessibility Concerns

| Issue | Check |
|-------|-------|
| Text readability on glass | Glass `backdrop-filter` can make text hard to read over busy backgrounds |
| Glass borders | Low-opacity borders may be invisible to low-vision users |
| Glass animation | Hover/press transforms can cause motion sickness |
| Glass layering | Nested glass degrades clarity — verify max 1 layer |
| Specular highlight | `::before` highlight shouldn't interfere with content readability |

## Output Format

```markdown
## Accessibility Audit: [Component/Page Name]
**Standard:** WCAG 2.1 AA | **Date:** [Date]

### Summary
**Total issues:** [X] | 🔴 Critical: [X] | 🟡 Major: [X] | 🟢 Minor: [X]

### Perceivable
| # | Issue | WCAG | Severity | Location | Fix |
|---|-------|------|----------|----------|-----|
| 1 | ... | 1.4.3 | 🔴 | file:line | ... |

### Operable
| # | Issue | WCAG | Severity | Location | Fix |
|---|-------|------|----------|----------|-----|
| 1 | ... | 2.1.1 | 🟡 | file:line | ... |

### Understandable
| # | Issue | WCAG | Severity | Location | Fix |
|---|-------|------|----------|----------|-----|
| 1 | ... | 3.3.2 | 🟢 | file:line | ... |

### Robust
| # | Issue | WCAG | Severity | Location | Fix |
|---|-------|------|----------|----------|-----|
| 1 | ... | 4.1.2 | 🟡 | file:line | ... |

### Glass-Specific Issues
| # | Issue | Severity | Location | Fix |
|---|-------|----------|----------|-----|
| 1 | ... | 🔴 | file:line | ... |

### Reduced Motion
| Component | Has @media block | Transitions disabled | Animations disabled |
|-----------|-----------------|---------------------|-------------------|
| [Name] | ✅/❌ | ✅/❌ | ✅/❌ |

### Priority Fixes
1. **[Critical fix]** — Affects [who] and blocks [what]
2. **[Major fix]** — Improves [what] for [who]
3. **[Minor fix]** — Nice to have

### Score: [X]/100
```
