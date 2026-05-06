---
name: ux-ui-review
description: >
  Review UX/UI quality of Vue 3 + Quasar components in My Zodiac AI.
  Use when the user asks to "review UX", "check usability", "проверь юзабилити",
  "review user flow", "check UI states", "проверь состояния",
  or wants feedback on navigation, user flows, microcopy, and component states.
---

# UX/UI Review — My Zodiac AI

Analyze Vue/Quasar component code for usability, user flow quality, state completeness, and microcopy within the My Zodiac AI application.

## Activation

Trigger when reviewing components for usability and interaction quality — not for visual design or accessibility compliance (those are separate agents).

## Analysis Process

### 1. Identify Target

Same as design-critique: locate the target component, page, or feature flow.

### 2. Read Source Files

For the target, read:
- The `.vue` SFC (template + script + style)
- Store/composable files in `front/src/shared/lib/` or feature stores
- Router configuration if navigation is involved (`front/src/app/router/`)
- Any related API service files

### 3. User Flow Analysis

Map the interaction flow within the component:

| Check | What to Look For |
|-------|-----------------|
| Entry points | How does the user arrive at this screen? Are all entry paths handled? |
| Primary action | Is the main CTA obvious and reachable within 1-2 taps? |
| Secondary actions | Are supporting actions discoverable but not competing with primary? |
| Exit paths | Can the user go back, cancel, or dismiss? Is there always a way out? |
| Dead ends | Are there states where the user can't proceed or go back? |
| Progressive disclosure | Is complexity revealed gradually or dumped all at once? |

### 4. Component State Completeness

Check that ALL required states are implemented:

**Every data-driven component MUST have:**
- ✅ **Loading state** — skeleton, spinner, or placeholder while data loads
- ✅ **Empty state** — meaningful message + CTA when no data exists
- ✅ **Error state** — user-friendly error message + retry action
- ✅ **Success state** — confirmation feedback for user actions
- ✅ **Default/populated state** — the normal state with data

**Interactive elements MUST have:**
- ✅ **Default** — resting state
- ✅ **Hover** — visual feedback on hover (desktop)
- ✅ **Active/Pressed** — visual feedback during interaction
- ✅ **Disabled** — clearly non-interactive appearance + `aria-disabled`
- ✅ **Focus** — visible focus ring for keyboard navigation

Search the template for: `v-if`, `v-else`, `v-show`, loading/error/empty conditionals. Flag any missing states.

### 5. Navigation & Routing

- Back navigation works correctly (browser back button, swipe back on mobile)
- Deep links are supported where appropriate
- Route guards prevent access to invalid states
- Page transitions are smooth (check `<RouterView>` transition configuration)
- Breadcrumbs or navigation context is clear

### 6. Microcopy & Text Quality

Review all user-facing text in the template:

| Check | What to Look For |
|-------|-----------------|
| CTAs | Start with verbs: "Save", "Continue", "View Horoscope" — not "Submit" or "OK" |
| Error messages | Structure: What happened + Why + How to fix |
| Empty states | Structure: What this is + Why empty + How to start |
| Confirmation dialogs | Action-labeled buttons: "Delete Account" / "Keep Account" — not "OK" / "Cancel" |
| Labels | Clear, concise, no jargon |
| Placeholders | Helpful examples, not labels repeated |
| Tooltips | Add context, don't repeat what's visible |

### 7. Mobile Responsiveness (Capacitor)

- Touch targets >= 48px minimum height/width on mobile
- No hover-dependent interactions without touch alternatives
- Swipe gestures have visible affordances
- Bottom sheet patterns used instead of dropdowns on mobile
- Haptic feedback wired for important interactions (`useHaptics()`)
- No tiny text below 14px on mobile

### 8. Performance UX

- Large lists use virtual scrolling (`QVirtualScroll` or `QInfiniteScroll`)
- Images have loading placeholders and appropriate sizing
- No layout shift after data loads (reserved space / skeletons)
- Debounced search/filter inputs
- Optimistic UI updates where appropriate

## Output Format

```markdown
## UX/UI Review: [Component/Page Name]

### Overall Usability Score: [X]/100

### User Flow
| Finding | Severity | Location | Recommendation |
|---------|----------|----------|----------------|
| ... | 🔴/🟡/🟢 | file:line | ... |

### State Completeness
| Component | Loading | Empty | Error | Success | Default | Missing |
|-----------|---------|-------|-------|---------|---------|---------|
| [Name] | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ | ✅/❌ | [What] |

### Microcopy Issues
| Text | Location | Issue | Suggested Fix |
|------|----------|-------|---------------|
| "Submit" | file:line | Generic CTA | "Save Horoscope" |

### Mobile/Capacitor
| Finding | Severity | Location | Recommendation |
|---------|----------|----------|----------------|
| ... | ... | ... | ... |

### Performance UX
| Finding | Severity | Location | Recommendation |
|---------|----------|----------|----------------|
| ... | ... | ... | ... |

### What Works Well
- [Positive observation]
- ...

### Priority Recommendations
1. **[Most impactful fix]** — [Why and how]
2. **[Second priority]** — [Why and how]
3. **[Third priority]** — [Why and how]
```
