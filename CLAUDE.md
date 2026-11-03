# Working rules for this repo

## Required tools

A computer with Docker/Compose, Git/GitHub and a browser. Python/C tools and Burp
Community or ZAP as required. Course slides, worksheets, sandbox targets, and
OWASP/CWE/secure-delivery references.

Everything that is not a GUI or a daemon comes from the repo's Nix flake — see
[Dev environment](#dev-environment-flake--direnv).

## Weekly plan

01. Security Mindset and Threat Modeling
02. Secure SDLC, Security Tooling and Fuzzing
03. Cryptography Used Correctly
04. Injection and Input Handling
05. XSS and Client-Side Security
06. Authentication, Sessions and Access Control
07. Review and Midterm Preparation
08. Midterm Written Examination
09. Midterm Practical Examination
10. API Security
11. Memory Safety and Exploitation
12. Software Supply-Chain Security
13. Cloud and Container Security
14. AI, LLM and Agentic Application Security
15. DevSecOps and Vulnerability Management
16. Capstone Studio and CTF Warm-up
17. Review and Final Preparation
18. Final Written Examination
19. Final Capstone CTF and Project Assessment
20. Examination Feedback and Course Reflection

## Dev environment: flake + direnv

`flake.nix` pins the non-container toolchain, so nothing needs a system package
manager: Python 3.12 with the live-quiz dependencies + pytest + pwntools,
gcc/clang/llvm/binutils/gdb/aflplusplus/checksec, rustc/cargo,
semgrep/gitleaks/trivy/cosign/syft/grype, sqlmap/nmap/nikto/ffuf/mitmproxy,
hashcat/john/openssl, docker client + compose, kubectl/kind, git/gh/curl/jq/yq/make,
pandoc + LibreOffice (`soffice`) + python-docx/python-pptx/openpyxl for `.docx`,
`.pptx` and `.xlsx` work.

```bash
direnv allow     # once per checkout; .envrc runs `use flake`
# or, without direnv:
nix develop
```

- `.direnv/` is git-ignored; `flake.lock` is committed. Bump it deliberately — the
  same pinning discipline Week 12 teaches.
- **Host-only, never in the flake:** the Docker daemon, Burp Suite Community / OWASP
  ZAP (GUI), WireGuard (kernel + root). Labs still run through `docker compose up`.
- Linux-only by design: Week 11 needs ptrace, `-no-pie` and `setarch -R`. On
  macOS/Windows follow Lab 0 (`labs/week01-threat-modeling/README.md`) and run the
  flake inside WSL2 if you want it locally.
- Python dependencies exist twice: `labs/live-quiz/requirements.txt` is the source of
  truth CI installs from, and `flake.nix` mirrors it in `python.withPackages`. Adding
  a dependency means editing both; the flake alone does not change what CI runs.

## When you change lab content, three things must move together

1. **`labs/weekNN-<slug>/`** — the student-facing worksheet / README / code.
2. **The curriculum monorepo** (`../KOSEN69 - curriculum/lessons/<slug>/`) holds a
   byte-identical copy. A parity gate enforces it:
   `cd "../KOSEN69 - curriculum" && .venv/bin/python -m pytest tests/ -q`
   Apply the *same* edit to both — don't `cp` the `.md` files, the monorepo copies
   carry template tokens (`{{ slot_label }}`, `{{ labpath }}`).
3. **`instructor/`** — the answer keys, quiz keys, exam keys and research
   instruments that grade that lab. **`instructor/` is git-ignored**, so nothing in
   CI or the diff will remind you. A worksheet fix that leaves its key stale means
   students get marked wrong for correct answers. Check the matching
   `instructor/quizzes/weekly/weekNN-answers.md`, `instructor/exams/*`, and
   `instructor/research/{planted-error-bank,pre-post-test}.md`.

## Never "fix" the deliberately vulnerable material

`labs/week*/`, `labs/toolbox/` and `project/starter-app/` are insecure on purpose —
old pins, root containers, planted secrets, SQL injection. They are the exercise.

- `.github/dependabot.yml` ignores those directories; do not merge a dependency
  bump there (it silently destroys the Week 12 SCA lesson and the term project).
- `security-ci` deliberately does not gate on them (`.semgrepignore`, Trivy
  `skip-dirs`, `.gitleaks.toml` allowlist). It *does* gate `labs/live-quiz`,
  `tools/` and the workflow itself — keep those clean rather than widening the
  exclusions.
- Planted secrets must stay detectable by the tool the worksheet names. Week 2's
  values were once undetectable by Gitleaks, which made a graded task impossible.

## Verify by running, not by reading

Payloads, expected tool output, crash messages, line-number citations and package
pins in a worksheet are all things students execute literally. Run the command
before you claim it works — several worksheet "facts" here turned out to be wrong
under reproduction (an SQLi payload that never bypassed login, a `docker compose
run` that skipped the Flask install, a hardened build that traps in
FORTIFY_SOURCE rather than the stack canary).

## Build artifacts

`make` in `labs/week11-memory-safety-exploitation` produces `vuln`, `vuln-*` and
`fuzz`. They are git-ignored; delete them rather than leaving them in the tree —
the monorepo parity gate compares every file in the lab directory.
