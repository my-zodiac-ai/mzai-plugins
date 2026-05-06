---
name: feature-enhancement
description: >
  Suggest feature and UX improvements for My Zodiac AI screens and components.
  Use when the user asks to "suggest improvements", "what can be improved",
  "предложи улучшения", "как улучшить фичу", "enhance this feature",
  "что можно добавить", "UX improvements",
  or wants ideas for new functionality, better interactions, or engagement patterns
  based on astrology app best practices and modern UX trends.
---

# Feature Enhancement Suggestions — My Zodiac AI

Analyze existing Vue/Quasar screens and suggest actionable improvements to functionality, engagement, and user delight — grounded in the astrology/wellness app domain.

## Activation

Trigger when the user wants enhancement ideas — not for fixing bugs, accessibility, or design system compliance (those are separate agents).

## Analysis Process

### 1. Understand Current State

Read the target component/page and understand:
- What feature does it implement? (horoscope, compatibility, natal chart, etc.)
- What data does it display?
- What interactions are available?
- What is the user journey context (where do they come from, where do they go)?

### 2. Domain-Specific Enhancement Patterns

Apply astrology/wellness app best practices:

#### Personalization
| Pattern | Application |
|---------|------------|
| Zodiac-contextual content | Adapt UI elements, colors, icons based on user's sign |
| Time-aware greetings | Morning/evening affirmations tied to current planetary positions |
| Progressive profiling | Gradually collect birth time, location for more precise readings |
| Preference learning | Remember favorite topics (love, career, health) and prioritize |

#### Engagement
| Pattern | Application |
|---------|------------|
| Daily ritual hook | Push notification + new daily content to build habit |
| Streak mechanics | Track consecutive days of checking horoscope |
| Social sharing | Shareable cards for horoscope highlights, compatibility |
| Seasonal events | Special content for retrogrades, eclipses, new/full moons |
| Content teasing | Preview premium content with blur/glass overlay |

#### Delight Micro-interactions
| Pattern | Application |
|---------|------------|
| Constellation animations | Subtle star field parallax on scroll |
| Zodiac transitions | Sign-specific entry animations for content cards |
| Haptic feedback | Satisfying feedback on card reveals, swipes |
| Pull-to-refresh with theme | Cosmic animation during refresh |
| Celebration moments | Confetti/glow effects on positive horoscope readings |

#### Data Visualization
| Pattern | Application |
|---------|------------|
| Planetary wheel | Interactive natal chart visualization |
| Compatibility meters | Animated progress bars for compatibility scores |
| Transit timeline | Calendar view of upcoming planetary events |
| Mood tracking | Chart mood vs planetary positions over time |

### 3. Modern UX Patterns to Consider

| Pattern | Benefit | Implementation |
|---------|---------|---------------|
| Bottom sheet interactions | Mobile-native feel, one-handed use | Quasar `q-dialog` with `position="bottom"` |
| Card deck swipe | Engaging content browsing (Tinder-like) | Vue swipe library + glass cards |
| Skeleton loading | Perceived performance | `q-skeleton` with cosmic colors |
| Pull-to-refresh | Familiar mobile pattern | Quasar `q-pull-to-refresh` |
| Contextual actions | Long-press for options on mobile | Quasar `q-menu` + haptics |
| Segmented controls | Quick content filtering | Quasar `q-tabs` with glass variant |
| Floating action button | Quick access to primary action | `q-page-sticky` with glass style |

### 4. Competitive Insights

Reference patterns from leading astrology apps:
- **Co-Star**: Minimalist UI, push notification engagement, social comparisons
- **The Pattern**: Timeline-based planetary events, relationship analysis
- **Sanctuary**: Chat-based reading experience, personalized advice
- **TimePassages**: Detailed transit calendar, educational content

Suggest adaptations that fit My Zodiac AI's Cosmic Glass aesthetic.

### 5. Feasibility Assessment

For each suggestion, evaluate:
- **Impact** (High/Medium/Low) — how much it improves user experience
- **Effort** (High/Medium/Low) — implementation complexity
- **Dependencies** — what backend APIs, data, or libraries are needed
- **Fits existing architecture** — can it be added within FSD structure without major refactoring?

## Output Format

```markdown
## Feature Enhancement: [Component/Page Name]

### Current State Summary
[2-3 sentences about what exists and how it works]

### Quick Wins (High Impact, Low Effort)
| # | Enhancement | Impact | Effort | Description |
|---|------------|--------|--------|-------------|
| 1 | ... | 🟢 High | 🟢 Low | ... |

### Medium-Term Improvements
| # | Enhancement | Impact | Effort | Dependencies | Description |
|---|------------|--------|--------|-------------|-------------|
| 1 | ... | 🟢 High | 🟡 Med | ... | ... |

### Big Bets (High Impact, High Effort)
| # | Enhancement | Impact | Effort | Dependencies | Description |
|---|------------|--------|--------|-------------|-------------|
| 1 | ... | 🟢 High | 🔴 High | ... | ... |

### Engagement Opportunities
- [Pattern]: [How to apply it specifically to this screen]
- ...

### Competitive Edge
- [App X does Y] → [How My Zodiac AI can do it better with Cosmic Glass]
- ...

### Implementation Priority
1. **[Most impactful, quick win]** — [1-2 sentence implementation hint]
2. **[Second priority]** — ...
3. **[Third priority]** — ...
```
