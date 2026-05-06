# Deep Research Report Template

Use this template for generating the final research report. Adapt sections based on available data.

## Template Variables

- `[FEATURE_NAME]` — name of the feature being researched
- `[DATE]` — current date in YYYY-MM-DD format
- `[LANG]` — report language (match user's language)

## Section Guidelines

### Executive Summary
- Maximum 3 paragraphs
- Lead with the strongest finding
- End with clear recommendation (build / skip / defer / simplify)
- Include estimated effort range

### Competitor Analysis
For each competitor, capture:
- **App name & platform** (iOS/Android/Web)
- **How they implement the feature** — specific screens, flows
- **What works well** — user reviews, ratings mentioning the feature
- **What's missing** — gaps, complaints
- **Monetization model** — free/premium/subscription, price point
- **App Store rating** and relevant review excerpts

Minimum 5 competitors for direct, 3 for indirect.

### UI/UX Analysis
- Describe specific screens and interactions, not abstract concepts
- Reference competitor implementations as examples
- Include recommended color scheme, layout, animation patterns
- Propose a user flow with entry points from existing My Zodiac AI screens
- Consider mobile-first (Capacitor) constraints

### Technical Analysis
For each library/tool:
- **npm/pip package name** with exact version
- **Weekly downloads** or GitHub stars
- **Last updated** date
- **Bundle size** (for frontend)
- **TypeScript support** — native, @types, none
- **License** — MIT, Apache, commercial
- **Integration complexity** — drop-in, moderate, heavy

### Codebase Integration
Reference actual file paths from the My Zodiac AI codebase:
- Backend: `back/src/modules/` — which module owns this feature
- Frontend: `front/src/` — which FSD layer/slice
- Shared: types, enums, configs that need updates
- Database: new collections/schemas needed
- Events: EDA events to emit/listen

### Metrics & Impact
If PostHog data available:
- Current DAU, WAU, MAU
- Feature-adjacent engagement (e.g., horoscope views if adding numerology)
- Retention curves
- Conversion funnels

If no PostHog data:
- Use industry benchmarks
- Note data gaps explicitly

### Risk Assessment
Standard risk matrix:
| Risk | Probability (1-5) | Impact (1-5) | Score | Mitigation |
Each risk must have a concrete mitigation strategy.
