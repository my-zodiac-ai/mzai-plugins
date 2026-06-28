---
name: nuxt-state
description: >
  State in Nuxt — useState vs Pinia, SSR-safe shared state (no cross-request leakage), and where
  to keep server vs client state. Use for "shared state in Nuxt", "Pinia in Nuxt", "useState",
  "SSR state leak", "глобальный стейт Nuxt", "состояние между страницами".
x-scope: adapter:nuxt
x-stack: nuxt
---

# Nuxt State (adapter)

## Choose
| Need | Use |
|------|-----|
| Small shared reactive value, SSR-safe | `useState(key, init)` |
| Structured store with actions/getters | Pinia (`@pinia/nuxt`), `defineStore` |
| Per-request server data | compute in `server/` and pass via `useFetch` payload — not a module global |

## Rules
1. **Never use module-level `let`/singletons for request state** — on the server they're shared across
   all users (cross-request leakage). Use `useState`/Pinia, which Nuxt isolates per request.
2. **Stable keys** for `useState` so SSR value hydrates on the client.
3. **Don't put secrets in state** — state serializes into the SSR HTML payload.
4. **Pinia stores**: keep them serializable; hydration uses the SSR snapshot.
5. **Derive, don't duplicate** — prefer getters/computed over copying fetched data into state.

## Example
```ts
// composables/useTheme.ts — SSR-safe shared value
export const useTheme = () => useState<'light' | 'dark'>('theme', () => 'light')

// stores/cart.ts — Pinia
export const useCart = defineStore('cart', {
  state: () => ({ items: [] as Item[] }),
  getters: { total: (s) => s.items.reduce((n, i) => n + i.price, 0) },
  actions: { add(i: Item) { this.items.push(i) } },
})
```
