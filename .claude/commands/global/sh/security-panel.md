---
name: sh:security-panel
description: "Multi-expert security review panel with threat modeling, vulnerability analysis, scoring gate, and compliance assessment. Use when reviewing application security, infrastructure security, authentication, cryptography, or any security-sensitive design."
needs: [code-context, doc-lookup?]
---

# /sh:security-panel — Expert Security Review Panel

## Usage

```
/sh:security-panel [security_content|@file|@code] [--mode discussion|critique|socratic] [--evidence passive|active] [--focus threat-modeling|application-security|infrastructure|cryptography|compliance|supply-chain] [--experts "name1,name2"] [--iterations N] [--verbose]
```

## Verbosity

- **Silent (default)**: No expert deliberations. Output only: score table, FIPD-classified findings list, and auto-fix diff. Saves ~60-80% output tokens.
- **Verbose (`--verbose`)**: Full expert deliberations, cross-expert dialogue, reasoning traces, and detailed per-expert analysis before scores and findings.

Silent mode still performs full internal analysis — quality is preserved, only the output is compressed.

## Behavioral Flow

1. **Ingest**: Parse input — detect code, architecture diagrams, security policies, API specs, or threat models
2. **Classify**: Identify security domain (web app, API, infrastructure, mobile, cryptographic) and threat landscape
3. **Assemble Panel**: Select experts based on `--focus` area or use defaults. `--experts` override replaces defaults entirely. Max 6 experts per review.
4. **Conduct Review**: Run analysis in selected mode using each expert's distinct security methodology
5. **Gather Evidence** (if `--evidence active`): Experts inspect code for vulnerability patterns, configs, and dependencies
6. **Score**: Rate security posture across 5 dimensions (0-10 each), compute overall score
7. **Gate Check**: Overall score must be >= 7.0 to pass. Below threshold = security posture needs remediation

## Expert Panel (10 experts)

| Category | Expert | Domain |
|---|---|---|
| Threat Modeling | Adam Shostack | STRIDE, attack trees, data flow analysis, threat enumeration |
| Threat Modeling | Bruce Schneier | Security strategy, attack economics, cryptographic protocols, risk |
| Application Security | Tanya Janca | Secure SDLC, DevSecOps, OWASP Top 10, security automation |
| Application Security | Jim Manico | Secure coding, input validation, OWASP cheat sheets, auth patterns |
| Application Security | Thomas Ptacek | Cryptographic engineering, protocol analysis, vulnerability research |
| Infrastructure | Ivan Ristic | SSL/TLS, security headers, WAF, transport security |
| Infrastructure | Liz Rice | Container security, Kubernetes security, eBPF, runtime monitoring |
| Vulnerability & Disclosure | Katie Moussouris | Bug bounty, vulnerability disclosure, security.txt, security policy |
| Vulnerability & Disclosure | Troy Hunt | Breach analysis, credential security, OWASP awareness, password security |
| Threat Intelligence | Mikko Hyppönen | Cybercrime, nation-state threats, threat landscape, "if smart, vulnerable" |

## Analysis Modes

### Discussion Mode (`--mode discussion`)
Collaborative security analysis. Experts explore threats, attack vectors, and defenses through dialogue. Cross-expert validation of security assumptions. Default mode.

### Critique Mode (`--mode critique`)
Systematic review with severity-classified findings (CRITICAL / MAJOR / MINOR). Each finding includes: expert attribution, CWE/OWASP mapping, specific remediation, priority ranking, and quality impact. Best paired with `--evidence active`.

### Socratic Mode (`--mode socratic`)
Adversarial questioning to develop security thinking. Experts pose threat scenarios, challenge assumptions, and probe for blind spots. No direct answers — forces the developer to think like an attacker.

## Evidence Modes

- `--evidence passive` (default): Expert opinions based on provided content only. No tool calls.
- `--evidence active`: Experts inspect code for vulnerability patterns, configuration weaknesses, and dependency CVEs. Produces evidence-backed findings with CWE/OWASP references.

## Focus Areas

- **threat-modeling**: DFD, trust boundaries, STRIDE, attack trees, adversary profiling. Lead: Adam Shostack. Experts: Shostack, Schneier, Hyppönen
- **application-security**: OWASP Top 10, injection, auth, session, input validation. Lead: Jim Manico. Experts: Manico, Janca, Ptacek, Hunt
- **infrastructure**: Container security, K8s, TLS, headers, cloud IAM, secrets. Lead: Liz Rice. Experts: Rice, Ristic, Schneier
- **cryptography**: Algorithm selection, key management, protocol design, side-channels. Lead: Thomas Ptacek. Experts: Ptacek, Schneier, Ristic
- **compliance**: SOC2/GDPR/HIPAA/PCI-DSS, policies, audit trails, disclosure programs. Lead: Tanya Janca. Experts: Janca, Moussouris, Schneier, Hyppönen
- **supply-chain**: Dependency scanning, SBOM, image provenance, CI/CD security, build integrity. Lead: Tanya Janca. Experts: Janca, Rice, Hunt

## Scoring Gate

5 dimensions, each scored 0-10:

| Dimension | Description |
|---|---|
| Threat Coverage | Threat model completeness, attack surface understanding, adversary modeling |
| Defense Depth | Layered defenses, security controls at each boundary, fail-secure design |
| Compliance | Regulatory coverage, policy enforcement, audit readiness |
| Code Security | Secure coding patterns, injection prevention, auth/authz correctness |
| Incident Readiness | Monitoring, detection, response capability, breach notification plan |

**Pass threshold: overall score >= 7.0**

Output includes per-dimension scores, overall score, CWE/OWASP-mapped findings, expert consensus, and remediation roadmap (immediate / short-term / long-term).

## Output

Security review document containing:
- Multi-expert analysis with distinct security perspectives
- Evidence-backed findings (when `--evidence active`)
- CWE/OWASP/NIST reference mapping
- Per-dimension scores and overall quality score
- Pass/fail gate result
- Critical issues with severity classification
- Consensus points and disagreements
- Priority-ranked remediation recommendations

**SYNTHESIS ONLY** — this panel produces analysis, vulnerability findings, and remediation guidance. It does not modify code or configurations without explicit instruction.

**Next Step**: After review, remediate critical findings first. Use `/sc:architecture-panel` for structural changes. Use `/sc:spec-panel --focus compliance` for security requirements. Use `/sc:implement` when ready to fix.


## Auto-Fix Policy
Fix ALL findings automatically — high, medium, and low severity. Do not ask which findings to fix. Do not present a menu. Fix everything, then report what was changed.
