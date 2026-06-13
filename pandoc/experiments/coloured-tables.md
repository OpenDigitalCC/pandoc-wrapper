---
title: Table Styling Comparison
date: 25/03/2026
header-includes:
  - \definecolor{accent}{HTML}{32707E}
  - \definecolor{dgrey}{HTML}{555555}
  - \definecolor{surface}{HTML}{F8F9FA}
brand: plain
---

# 1. Plain Pandoc pipe table

This is what Pandoc generates from markdown. No column width control, no coloured header.

| Phase | Actions | Deliverable |
|-------|---------|-------------|
| Requirements | Define product context (users, environments, data), "non-negotiable" security defaults, and top risks/abuse cases; establish clear criteria for addressing risks. | 1-page Security Context & Assumptions + short Security Requirements Checklist (including secure defaults). |
| Design | Maintain one architecture diagram with trust boundaries; do a lightweight threat model on the top 5--10 abuse cases; decide the critical design controls. | Architecture + trust-boundary diagram + Top threats & mitigations (bulleted list). |
| Development | Build secure defaults into code/config; enforce dependency hygiene; protect secrets; require PR review for security-sensitive changes; automate SAST/dependency scanning. | CI evidence (pipeline logs) + lightweight Secure coding / PR checklist. |

# 2. Raw tabularx

Full control over column widths, coloured header, alternating rows, bold in cells.

```{=latex}
\begingroup
\small
\renewcommand{\arraystretch}{1.4}
\rowcolors{2}{accent!5}{white}
\begin{tabularx}{\textwidth}{
  >{\bfseries\raggedright\arraybackslash}p{2.5cm}
  >{\raggedright\arraybackslash}X
  >{\raggedright\arraybackslash}p{4.5cm}
}
\rowcolor{accent}
\textcolor{white}{\textbf{Phase}} &
\textcolor{white}{\textbf{Actions}} &
\textcolor{white}{\textbf{Deliverable}} \\

Requirements &
Define product context (users, environments, data), ``non-negotiable'' security defaults, and top risks/abuse cases; establish clear criteria for addressing risks based on the product's intended purpose, expected use, and security impact. &
1-page \textbf{Security Context \& Assumptions} + short \textbf{Security Requirements Checklist} (including secure defaults). \\

Design &
Maintain one architecture diagram with \textbf{trust boundaries}; do a lightweight threat model on the top 5--10 abuse cases; decide the critical design controls (authn/authz, update mechanism, secrets, logging). &
\textbf{Architecture + trust-boundary diagram} + Top threats \& mitigations (bulleted list). \\

Development / Implementation &
Build secure defaults into code/config; enforce dependency hygiene; protect secrets; require PR review for security-sensitive changes; automate SAST/dependency scanning as part of CI. &
CI evidence (pipeline logs) + lightweight \textbf{Secure coding / PR checklist} (often a repo file). \\

Testing \& acceptance &
Run automated security checks (SAST/dependency, basic DAST where relevant); ensure default configuration is validated; run targeted pen test when potential risk triggers hit. &
\textbf{Release security checklist} (pass/fail + exceptions) + documented \textbf{known issues/residual risk}. \\

Deployment \& integration &
Ensure secure provisioning/enrolment, least-privilege runtime config, and monitoring of key ``health/security'' indicators; treat updates as controlled change management. &
\textbf{Deployment hardening checklist} + \textbf{Rollback plan} + minimal monitoring/alert list. \\

Maintenance \& disposal &
Define patch intake + SLAs, vulnerability monitoring, incident handling, and an end-of-support/EOL plan; ensure secure disposal (data erasure, credential revocation). &
\textbf{Vuln \& patch process} (1 page) + \textbf{EOL/disposal note} + maintained risk register updates. \\

Development / Implementation &
Build secure defaults into code/config; enforce dependency hygiene; protect secrets; require PR review for security-sensitive changes; automate SAST/dependency scanning as part of CI. &
CI evidence (pipeline logs) + lightweight \textbf{Secure coding / PR checklist} (often a repo file). \\

Testing \& acceptance &
Run automated security checks (SAST/dependency, basic DAST where relevant); ensure default configuration is validated; run targeted pen test when potential risk triggers hit. &
\textbf{Release security checklist} (pass/fail + exceptions) + documented \textbf{known issues/residual risk}. \\

Deployment \& integration &
Ensure secure provisioning/enrolment, least-privilege runtime config, and monitoring of key ``health/security'' indicators; treat updates as controlled change management. &
\textbf{Deployment hardening checklist} + \textbf{Rollback plan} + minimal monitoring/alert list. \\

Maintenance \& disposal &
Define patch intake + SLAs, vulnerability monitoring, incident handling, and an end-of-support/EOL plan; ensure secure disposal (data erasure, credential revocation). &
\textbf{Vuln \& patch process} (1 page) + \textbf{EOL/disposal note} + maintained risk register updates. \\

\end{tabularx}
\endgroup
```

# 3. Raw longtable (spans pages)

Same styling but uses longtable for content that may break across pages.

```{=latex}
\begingroup
\small
\renewcommand{\arraystretch}{1.4}
\rowcolors{2}{accent!5}{white}
\begin{longtable}{
  >{\bfseries\raggedright\arraybackslash}p{2.5cm}
  >{\raggedright\arraybackslash}p{7cm}
  >{\raggedright\arraybackslash}p{4.5cm}
}

% Header on first page
\rowcolor{accent}
\textcolor{white}{\textbf{Phase}} &
\textcolor{white}{\textbf{Actions}} &
\textcolor{white}{\textbf{Deliverable}} \\
\endfirsthead

% Header on continuation pages
\rowcolor{accent}
\textcolor{white}{\textbf{Phase}} &
\textcolor{white}{\textbf{Actions}} &
\textcolor{white}{\textbf{Deliverable}} \\
\endhead

% Footer on pages that continue
\multicolumn{3}{r}{\small\textit{continued on next page}} \\
\endfoot

% Final footer
\endlastfoot

Requirements &
Define product context (users, environments, data), ``non-negotiable'' security defaults, and top risks/abuse cases; establish clear criteria for addressing risks based on the product's intended purpose, expected use, and security impact. &
1-page \textbf{Security Context \& Assumptions} + short \textbf{Security Requirements Checklist} (including secure defaults). \\

Design &
Maintain one architecture diagram with \textbf{trust boundaries}; do a lightweight threat model on the top 5--10 abuse cases; decide the critical design controls (authn/authz, update mechanism, secrets, logging). &
\textbf{Architecture + trust-boundary diagram} + Top threats \& mitigations (bulleted list). \\

Development / Implementation &
Build secure defaults into code/config; enforce dependency hygiene; protect secrets; require PR review for security-sensitive changes; automate SAST/dependency scanning as part of CI environments (Agile/DevOps/DevSecOps). &
CI evidence (pipeline logs) + lightweight \textbf{Secure coding / PR checklist} (often a repo file). \\

Testing \& acceptance &
Run automated security checks (SAST/dependency, basic DAST where relevant); ensure default configuration is validated; run targeted pen test when potential risk triggers hit (e.g.\ in the case of a substantial modification).\par
\smallskip
\textit{Note: Security tests should be integrated into developer workflows and CI pipelines as early as possible (shift-left). Testing/Acceptance serves as a validation checkpoint, not the primary execution point for these controls.} &
\textbf{Release security checklist} (pass/fail + exceptions) + documented \textbf{known issues/residual risk}. \\

Deployment \& integration &
Ensure secure provisioning/enrolment, least-privilege runtime config, and monitoring of key ``health/security'' indicators; treat updates as controlled change management. &
\textbf{Deployment hardening checklist} + \textbf{Rollback plan} + minimal monitoring/alert list. \\

Maintenance \& disposal &
Define patch intake + SLAs, vulnerability monitoring, incident handling, and an end-of-support/EOL plan; ensure secure disposal (data erasure, credential revocation). &
\textbf{Vuln \& patch process} (1 page) + \textbf{EOL/disposal note} + maintained risk register updates. \\


Testing \& acceptance &
Run automated security checks (SAST/dependency, basic DAST where relevant); ensure default configuration is validated; run targeted pen test when potential risk triggers hit (e.g.\ in the case of a substantial modification).\par
\smallskip
\textit{Note: Security tests should be integrated into developer workflows and CI pipelines as early as possible (shift-left). Testing/Acceptance serves as a validation checkpoint, not the primary execution point for these controls.} &
\textbf{Release security checklist} (pass/fail + exceptions) + documented \textbf{known issues/residual risk}. \\

Deployment \& integration &
Ensure secure provisioning/enrolment, least-privilege runtime config, and monitoring of key ``health/security'' indicators; treat updates as controlled change management. &
\textbf{Deployment hardening checklist} + \textbf{Rollback plan} + minimal monitoring/alert list. \\

Maintenance \& disposal &
Define patch intake + SLAs, vulnerability monitoring, incident handling, and an end-of-support/EOL plan; ensure secure disposal (data erasure, credential revocation). &
\textbf{Vuln \& patch process} (1 page) + \textbf{EOL/disposal note} + maintained risk register updates. \\

\end{longtable}
\endgroup
```
