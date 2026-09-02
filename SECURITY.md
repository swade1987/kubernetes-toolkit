# Security Policy

## Supported versions

kubernetes-toolkit ships one rolling `latest` image, tagged per release; there's no long-term-support branch to track. Security fixes land on `main` and are published as the next tagged release.

## Reporting a vulnerability

Please report security issues privately rather than opening a public GitHub issue: use [GitHub's private vulnerability reporting](https://github.com/swade1987/kubernetes-toolkit/security/advisories/new) for this repository (Security tab → Report a vulnerability).

Include what you'd include in any good bug report: the affected version or commit, what you found, and how to reproduce it. We'll acknowledge new reports within 5 business days and aim to have a fix or mitigation plan within 30 days, depending on severity.

## Scope

The image bundles third-party Kubernetes tooling (kubectl, helm, and others) at pinned versions; a vulnerability in one of those tools upstream is best reported to that project directly, but a report that the image is shipping a version with a known, fixed CVE is in scope here. Reports about the image build, install scripts, or the CI/release pipeline are also in scope.
