---
title: Datatable Filter Test
date: 25/03/2026
brand: plain

---

# 1. Simple table (medium tone)

```datatable
columns: Phase | Actions | Deliverable
widths: 2.5cm | X | 4.5cm
bold: 1
tone: medium
---
Requirements | Define product context (users, environments, data), "non-negotiable" security defaults, and top risks/abuse cases. | 1-page **Security Context & Assumptions** + short **Security Requirements Checklist**.
Design | Maintain one architecture diagram with **trust boundaries**; do a lightweight threat model on the top 5--10 abuse cases. | **Architecture + trust-boundary diagram** + Top threats & mitigations.
Development | Build secure defaults into code/config; enforce dependency hygiene; protect secrets; require PR review for security-sensitive changes. | CI evidence (pipeline logs) + lightweight **Secure coding / PR checklist**.
Testing & acceptance | Run automated security checks (SAST/dependency, basic DAST where relevant); ensure default configuration is validated. | **Release security checklist** (pass/fail + exceptions) + documented **known issues/residual risk**.
Deployment & integration | Ensure secure provisioning/enrolment, least-privilege runtime config, and monitoring of key "health/security" indicators. | **Deployment hardening checklist** + **Rollback plan** + minimal monitoring/alert list.
Maintenance & disposal | Define patch intake + SLAs, vulnerability monitoring, incident handling, and an end-of-support/EOL plan. | **Vuln & patch process** (1 page) + **EOL/disposal note** + maintained risk register updates.
```

# 2. Strong tone

```datatable
columns: Component | Port | Protocol | Purpose
widths: 3cm | 2cm | 2cm | X
bold: 1
tone: strong
---
Dispatcher | 7443 | mTLS | Operational commands to agents
Dispatcher | 7444 | TLS | Agent pairing and certificate exchange
API Server | 8443 | HTTPS | REST API for automation and portals
Agent | 7443 | mTLS | Receives and executes dispatched scripts
```

## other examples

```datatable
columns: Language | Budget | Amount (per year) | Status
widths: 2.5cm | X | 3.5cm | 2.5cm
bold: 1, 2
tone: medium
---
Perl| Baseline | $100,000 | Active
 | Target | $200,000 | Active
Raku| Baseline | $40,000 | Active
 | Target | $100,000 | Active
```


# 3. Grey tone

```datatable
columns: Feature | Community Edition | Licensed Edition
widths: 4cm | X | X
tone: grey
---
mTLS dispatch | Yes | Yes
Agent pairing | Yes | Yes
Script allowlists | Yes | Yes
API server | No | Yes
Branded packaging | No | Yes
Priority support | No | Yes
```

# 4. Table with rowspans

```datatable
columns: Principle | CRA Essential requirement | Implementation support
widths: 3cm | 3.5cm | X
bold: 1, 2
tone: medium
---
Trust boundaries and Threat Modelling | ANNEX-1.PT1.1 | Supports identification and assessment of cybersecurity risks by making trust assumptions, assets, and attack paths explicit during design.
 | ANNEX-1.PT1.2.d | Supports protection from unauthorised access by clarifying where authentication and access controls are required between trust boundaries.
 | ANNEX-1.PT1.2.e | Supports confidentiality protections by identifying where data crosses trust boundaries and requires protection.
 | ANNEX-1.PT1.2.f | Supports integrity protection by identifying where data, commands, or configuration cross boundaries and may require integrity controls.
Least privilege | ANNEX-1.PT1.2.d | Supports protection from unauthorised access by limiting what authenticated users, services, and processes are permitted to access or perform.
 | ANNEX-1.PT1.2.f | Supports integrity protection by limiting which identities are authorised to modify data, programs, or configuration.
 | ANNEX-1.PT1.2.g | Supports data minimisation by limiting access to data to what is necessary for the intended purpose.
Strong identity and auth architecture | ANNEX-1.PT1.2.d | Supports access protection by defining how identities are authenticated and managed across interfaces.
 | ANNEX-1.PT1.2.l | Supports logging and monitoring of authentication and access-related activity.
Attack surface minimisation | ANNEX-1.PT1.2.b | Supports secure-by-default configurations by reducing enabled features and services at initial deployment.
```

# 5. Light tone, no bold columns

```datatable
columns: Date | Event | Location
widths: 2.5cm | X | 3.5cm
tone: light
caption: Foundation events 2025--2026
---
15/06/2025 | Perl Toolchain Summit | Lyon, France
22/08/2025 | The Perl and Raku Conference | Greenville, SC
10/10/2025 | London Perl Workshop | London, UK
14/03/2026 | German Perl Workshop | Frankfurt, Germany
```
