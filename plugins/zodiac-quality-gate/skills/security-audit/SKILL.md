---
name: security-audit
description: >
  Audit code for security vulnerabilities, secrets exposure, dependency CVEs, injection attacks,
  authentication/authorization flaws, and OWASP Top 10 issues. Use when the user asks to
  "check security", "security audit", "find vulnerabilities", "проверь безопасность",
  "найди уязвимости", "CVE check", "secrets scan", "OWASP review", or before deploying
  to production. Also trigger proactively when code touches auth, payments, user input,
  or API endpoints.
---

# Security Audit

Comprehensive security review covering application code, dependencies, secrets, and infrastructure configuration.

## Scope Detection

1. **Code scope** — determine target files/modules from context
2. **If full project** — prioritize: auth > payments > API endpoints > user input handlers > everything else

## Audit Dimensions

### 1. OWASP Top 10 (Application)

| Category | What to check |
|---|---|
| **Injection** | SQL/NoSQL injection in Mongoose queries, command injection, template injection |
| **Broken Auth** | JWT misuse, missing token rotation, weak password rules, session fixation |
| **Sensitive Data** | Secrets in code, unencrypted PII, logging sensitive data, missing GDPR anonymization |
| **XXE / Deserialization** | Unsafe JSON.parse on untrusted input, prototype pollution |
| **Broken Access Control** | Missing guards on endpoints, IDOR vulnerabilities, privilege escalation |
| **Security Misconfiguration** | CORS misconfiguration, verbose error messages in prod, debug mode |
| **XSS** | Unescaped user input in templates, innerHTML usage, v-html without sanitization |
| **CSRF** | Missing CSRF tokens on state-changing requests, SameSite cookie misconfiguration |
| **Known Vulnerabilities** | Outdated dependencies with known CVEs |
| **Insufficient Logging** | Missing audit trails for security events, no rate limiting |

### 2. Secrets & Credentials

Scan for:
- Hardcoded API keys, tokens, passwords in source code
- `.env` files committed to git
- Secrets in logs, error messages, or API responses
- Missing environment variable validation at startup

**Pattern**: `Grep` for common secret patterns:
- `(?i)(api[_-]?key|secret|password|token|credential|auth).*[=:]\s*['"][^'"]{8,}`
- Base64-encoded strings that look like tokens
- Private keys (RSA, EC)

### 3. Dependency Vulnerabilities

Check:
- Run `pnpm audit` or check `package-lock.json` for known CVEs
- Flag dependencies with no recent updates (>2 years = warning)
- Flag dependencies with <100 weekly downloads (supply chain risk)
- Check for typosquatting risk on unusual package names

### 4. Authentication & Authorization

- JWT secret strength and rotation
- Token expiration configuration
- Guard coverage on all protected routes
- Role-based access control consistency
- Rate limiting on auth endpoints

### 5. Input Validation

- DTO validation completeness (class-validator decorators)
- File upload restrictions (size, type, content validation)
- Request size limits
- Parameter sanitization

### 6. Infrastructure Security

- HTTPS enforcement
- Security headers (Helmet, HSTS, CSP)
- Cookie security flags (HttpOnly, Secure, SameSite)
- CORS whitelist (not wildcard in production)
- Redis/MongoDB connection security

## Severity Classification

| Level | Definition | Examples |
|---|---|---|
| **Critical** | Exploitable now, data breach risk | Hardcoded secrets, SQL injection, broken auth |
| **High** | Exploitable with moderate effort | XSS, CSRF, IDOR |
| **Medium** | Defense-in-depth gap | Missing rate limiting, verbose errors |
| **Low** | Best practice deviation | Missing security headers, outdated non-critical deps |

## Output Format

```markdown
# Security Audit Report

## Summary
- **Risk Level**: CRITICAL / HIGH / MEDIUM / LOW
- **Critical**: N | **High**: N | **Medium**: N | **Low**: N
- **Scope**: [what was audited]

## Critical Findings
### [SEC-001] Hardcoded API key in ai-manager.service.ts
- **File**: `back/src/modules/ai/ai-manager/ai-manager.service.ts:23`
- **Category**: Sensitive Data Exposure
- **Impact**: API key exposed in source code, could be extracted from git history
- **Fix**: Move to environment variable, rotate the compromised key immediately
- **CVSS**: 9.1

## Dependency Vulnerabilities
| Package | Version | CVE | Severity | Fix |
|---|---|---|---|---|
| example-pkg | 1.2.3 | CVE-2024-XXXX | High | Upgrade to 1.2.4 |

## Recommendations (prioritized)
1. [Immediate] Rotate compromised secrets
2. [This sprint] Fix Critical and High findings
3. [Next sprint] Address Medium findings
4. [Backlog] Low-priority improvements
```
