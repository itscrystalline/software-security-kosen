# Lesson Plan — Week 13: Cloud & Container Security

| | |
|---|---|
| **Course** | Software Security 2 (02005094, KOSEN-KMITL) |
| **Week / date** | 13 · ⬚ |
| **Contact time** | 150 min = 10 quiz + 15 explanation & demo + 120 supervised lab (in class: Tasks 1, 2, 4; before class: Task 0; homework: Tasks 3, 5) |
| **Lab folder** | `labs/week13-cloud-container` |
| **Slides** | `slides/week13.md` |
| **Standards** | OWASP 2025 **A02 Security Misconfiguration** · CWE-732 (incorrect permission assignment), CWE-16 (configuration), CWE-526 (secret in an environment variable), CWE-798 (hard-coded credential — OWASP files this under A07), CWE-250, CWE-538, CWE-269, CWE-1104 |
| **CLOs addressed** | **CLO3** remediate · **CLO4** operate security tooling (the course specification's weekly-schedule row for Week 13), plus **CLO5** evaluate & communicate and **CLO6** evidence & ethics through the recurring worksheet parts |

---

## 1. Session objectives

By the end of this week a student can:

**Knowledge (K)**
- K1 — State the shared-responsibility model in the form `harden.md` uses — "the cloud provider secures *of* the cloud; you secure what you put *in* it" — and give one concrete example of each side for an S3-backed app.
- K2 — Explain why `"Action": "*"` / `"Resource": "*"` violates least privilege, and distinguish CWE-269 (improper privilege management) from CWE-732 (incorrect permission assignment) on that policy.
- K3 — Explain why `FROM python:latest` is both a security and a reproducibility problem (CWE-1104 / CWE-16), how an `@sha256:` digest pin fixes it, and what a distroless base removes relative to `python:3.11-slim`.

**Skills (P)**
- P1 — Run the lab's scanner (`bash scan.sh`, or `trivy config` directly) and record a baseline finding count against `Dockerfile.insecure`.
- P2 — Produce the six-row defect → CWE → Trivy rule/severity table for `Dockerfile.insecure`, writing "manual review — no Trivy rule" for the three defects no Trivy Dockerfile check covers.
- P3 — Explain how `ENV API_TOKEN` / `AWS_SECRET_ACCESS_KEY` are recovered from a shipped image via `docker history` / `docker inspect`, and write the `.dockerignore` entries that stop `COPY . .` leaking `.git` / `.env` (CWE-538).
- P4 — Re-scan `Dockerfile.hardened`, capture the reduced finding count, and map every Task-1 defect to its fix (digest pin, multi-stage venv, distroless runtime, `USER 65532:65532`, no secrets in `ENV`, copy only `app.py`).
- P5 — Show that the IAM rewrite scopes `s3:GetObject` to `arn:aws:s3:::lab-app-bucket/app/*` and adds the `s3:prefix` `Condition`, and list the deploy-time flags from `harden.md` (`--read-only`, `--cap-drop ALL`, `--security-opt no-new-privileges`).
- P6 — Tally the hunt: one flag per misconfiguration found **and** fixed (6 container + 3 IAM = 9), and name the single biggest-risk misconfiguration with a reason.

**Attitude (A)**
- A1 — Scan, exploit and harden only these lab files or systems they own / are authorised to test; never point Trivy or these techniques at third-party cloud accounts or images without written permission ([ETHICS.md](../../ETHICS.md), worksheet ethics note).
- A2 — Submit identity-stamped evidence that is their own work, and be able to reproduce it live on request.
- A3 — Treat AI-generated security advice as something to be verified, not trusted.

## 2. Key ideas (the through-line)

Cloud breaches are rarely clever zero-days; they are defaults nobody changed. The provider's half of
the contract is well-run infrastructure — the customer's half is configuration, and configuration is
where the failures happen. That is why misconfiguration sits at **A02** in OWASP 2025. Every artifact
in this lab is the same mistake in a different medium: a permission granted wider than the job needs
(`Action: *` on `Resource: *`, `chmod -R 777`, running as root), or a boundary that was never drawn
(a secret baked into an image layer, an unpinned base image, a `COPY . .` that sweeps in `.git`).
The fix is always to grant the minimum, on the minimum, under the right conditions — and then to
*prove* it with a re-scan, because "we hardened it" is a claim and the before/after finding count is
evidence. Week 12 was what you build with; this week is where you run it.

## 3. Prior knowledge and preparation

- **Students, before class:** Docker Desktop running (Week 1 *Lab 0*); skim last week's recap
  (supply chain).
- **Instructor, before class:**
  - Pre-pull the scanner — `docker pull aquasec/trivy:latest` — and let Trivy download its checks
    bundle on your connection. If you plan to demo the optional CVE step, also build the image
    (`docker build -f Dockerfile.hardened -t week13-hardened:lab .`) **and then run** `scan.sh`'s
    step [2/2] against it (`docker run --rm -v /var/run/docker.sock:/var/run/docker.sock
    aquasec/trivy:latest image week13-hardened:lab`) so the ~100 MiB vulnerability database is
    already cached — `docker build` alone never invokes Trivy and does not populate that cache; a
    room of students pulling both at once is the standard way to lose twenty minutes.
  - **`bash scan.sh` alone is now sufficient and correct for all of Tasks 0, 1 and 4 — verified
    8 Oct 2026, superseding the "run both commands" guidance below.** Commit `d487869` (31 Jul 2026)
    widened `scan.sh`'s filter to `MEDIUM,HIGH,CRITICAL` and digest-pinned `Dockerfile.hardened`'s
    distroless stage, after this lesson plan was written. Reproduced today: filtered (`bash scan.sh`)
    = `Dockerfile.insecure` **4** (MEDIUM 1, HIGH 1, CRITICAL 2), `Dockerfile.hardened` **0**.
    `DS-0001` (the unpinned `:latest`) now appears in `scan.sh`'s own output — the unfiltered-command
    workaround in §8 rows 1–2 is no longer needed and should not be announced; doing so would make the
    hardened "after" file look un-clean (the unfiltered count is 1, not the old 2 — see §8) and
    undermine Task 4's point that it is clean. See §8 rows 1–2 for the full correction.
  - Have the offline fallback ready (`docker save` / `docker load` of `aquasec/trivy:latest`).
- **Prerequisite concepts:** what a Docker image layer is; how to read an AWS IAM policy document
  (`Effect` / `Action` / `Resource` / `Condition`).

## 4. Pre-class material and in-class explanation — 10 min quiz + 15 min demo

**Before class (students).** The concept material is pre-class: students study `slides/week13.md`
and answer the worksheet's **Part 2** questions from it before the class starts. The slides carry
what the 120-min lecture used to teach:

| Block | Content |
|---|---|
| Core concepts | Shared responsibility ("cloud secures *of* the cloud; you secure *in* the cloud"; defaults are rarely safe). IAM & least privilege on the worked example `{ "Effect":"Allow", "Action":"*", "Resource":"*" }` — blast radius, then its rewrite as read-only on one bucket. Secrets management: a secret in an image layer is in every copy of that image forever; `docker history` reveals it; inject at runtime from a vault and rotate (callback to Gitleaks, Week 2) |
| Deep dive + real cases | Storage and network exposure — public buckets, open ports (`0.0.0.0/0` on a database port), default credentials; encrypt at rest and in transit; private by default. Container image hardening: what `trivy config` finds (misconfiguration) versus what `trivy image` finds (CVEs in the base). Kubernetes awareness only — pod security, network policies, RBAC; a privileged pod ≈ host root; mounted service-account tokens are a lateral-movement prize. Two real incidents of the two types the worksheet's Part 4 Q2 names — a public S3 bucket leak and an over-permissive IAM role (⬚ instructor's chosen incidents) |
| Defences | The least-privilege rewrite line by line: enumerate only the actions used (`s3:GetObject`), scope to a specific ARN and prefix, add a `Condition`. Digest pin instead of `:latest`; multi-stage build with the dependencies installed in a stage you throw away; distroless runtime; `USER 65532:65532`; no secrets in `ENV` plus a `.dockerignore`. Deploy-time hardening from `harden.md`: `--read-only --cap-drop ALL --security-opt no-new-privileges`, `--memory` / `--pids-limit`, never `--privileged`, never mount the Docker socket into untrusted containers |

**Before-class task.** The worksheet: "Run Task 0's baseline scan before class, so the lab starts on
Task 1."

| Task | Student does | Evidence produced |
|---|---|---|
| **Task 0 — Onboarding (15 min, before class)** | `docker version`; `cd labs/week13-cloud-container`; `bash scan.sh`; record the **baseline finding count** against `Dockerfile.insecure` (the IAM JSON is not scanned — it is reviewed by hand in Task 2) | Screenshot of the baseline scan + the count |

**In class**

| Time | Block | Content | Method |
|---|---|---|---|
| 0:00–0:10 | Weekly quiz + today's goal | ~10-min retrieval quiz on Week 12 (supply chain), answered on the Google Form; today's goal; the bridge from the slides — "supply chain → what you build with; today → where you run it", and A02:2025 is now #2 | Individual quiz, lowest 1–2 dropped |
| 0:10–0:25 | Explanation + live demo | Rewrite `{ "Effect":"Allow", "Action":"*", "Resource":"*" }` live as read-only on one bucket, blast radius first; then `Dockerfile.insecure` and `Dockerfile.hardened` side by side. Brief the game — "Misconfig Hunt" **as the worksheet implements it**: 9 flags = 6 container defects in `Dockerfile.insecure` + 3 IAM defects in `iam-policy-insecure.json`; a flag counts only when the misconfiguration is found **and** fixed. Say explicitly that the IAM policies are reviewed by hand — Trivy does not scan them — and correct the slide verbally: it still says `trivy config` scans the IAM JSON, and lists a bucket round the lab does not ship (§8) | Live rewrite of the policy on the projector + instruction |

**Checks for understanding during the demo**
- During the policy rewrite: cold-call *"what does a `*:*` policy cost you if that key leaks?"*
- Before the lab starts: *"name one thing that is the provider's job and one that is yours, for an
  S3-backed app"* (this is Part 2 Q1, answered before class, in miniature).
- After the side-by-side Dockerfiles: *"which of the six defects would a scanner never tell you about?"*

## 5. Supervised lab — 120 min in class + homework

Targets: the files in `labs/week13-cloud-container/` — `Dockerfile.insecure` (the "before"),
`Dockerfile.hardened` (the "after"), `iam-policy-insecure.json` / `iam-policy-leastpriv.json`, and
`harden.md` (the misconfig → fix mapping students cite IDs from). **There is no `docker compose` file
this week** — the kickoff is `bash scan.sh` (Task 0, run before class — §4), and the graded evidence
is scanner output plus code review, not a running web app. Per task, students submit the command(s)
they ran, the relevant output or finding line, an identity-stamped screenshot, and a 2–3 sentence
mitigation citing the CWE.

Only the worksheet's *in class* tasks run here (worksheet Part 3; [AGENDA.md](../../AGENDA.md),
*How each worksheet is split*). The instructor circulates, checks evidence and reasoning, and runs
2–3 **viva spot-checks** — a student reproduces and explains an exploit or fix live.

| Time | Task | Student does | Evidence produced |
|---|---|---|---|
| 0:25–1:05 | **Task 1 — Misconfig Hunt: container image (40 min)** | Read each `# DEFECT:` comment in `Dockerfile.insecure`, then locate the matching Trivy finding where one exists — only 3 of the 6 (unpinned `:latest`, runs as root, secrets in `ENV`) map to a rule (`DS-0001`, `DS-0002`, `DS-0031`); `COPY . .`, `chmod -R 777` and the unpinned `pip install` are found by code review | Completed 6-row table: defect → CWE → Trivy rule/severity, using the IDs from `harden.md`, with "manual review — no Trivy rule" where none exists |
| 1:05–1:35 | **Task 2 — Misconfig Hunt: IAM (30 min)** | Read `iam-policy-insecure.json`; identify the `Action:*` / `Resource:*` / no-`Condition` problems and map them to CWE-269 / CWE-732 | 3-row table + one sentence on the blast radius if these credentials leak |
| 1:35–2:25 | **Task 4 — Hardened-Dockerfile + least-priv-IAM defense (50 min)** | (a) Re-run `bash scan.sh` (or `trivy config`) and capture the **reduced** count for `Dockerfile.hardened`, confirming the IAM fix manually by diffing `iam-policy-leastpriv.json` against the insecure policy; (b) point to the fix for each Task-1 defect (digest pin, multi-stage venv, distroless runtime, `USER 65532:65532`, no secrets in `ENV`, copy only `app.py`); (c) confirm the rewrite scopes `s3:GetObject` to `arn:aws:s3:::lab-app-bucket/app/*` and adds the `s3:prefix` `Condition`; (d) list the extra runtime flags from `harden.md` | Before/after finding counts **labelled with the command that produced them**, the defect→fix mapping, and the diffed policy/Dockerfile with one sentence per fix |
| 2:25–2:30 | **Slack — feedback and catch-up (5 min)** | Students who fell behind on an in-class task catch up | Instructor feedback on the evidence so far |

**Homework — submitted with the worksheet before the start of the next week's class**

| Task | Student does | Evidence produced |
|---|---|---|
| **Task 3 — Secrets & storage (25 min)** | Build the insecure image (`docker build -f Dockerfile.insecure -t week13-insecure:lab .`, per the worksheet's setup); explain how `ENV API_TOKEN` / `AWS_SECRET_ACCESS_KEY` are exposed via `docker history --no-trunc week13-insecure:lab` (or `docker inspect`); propose where they belong instead (secrets manager / mounted secret / orchestrator secret, per `harden.md`) | 2–3 sentence remediation + the `.dockerignore` entries that stop `COPY . .` leaking `.git` / `.env` (CWE-538) |
| **Task 5 — Flag tally (20 min)** | Score the hunt: one flag per misconfiguration found **and** fixed (6 container + 3 IAM = 9) | Flag count + the single biggest-risk misconfiguration and why |
| **Part 4, *Audit the AI*, *Comprehension & Prompt*** | Reflection; critique an AI-written exploit or fix, quoting the exact bad line; *Explain-in-Plain-English* and *Prompt Problem* | Written answers |

Worksheet PDF → `learn.zcr.ai/submit`; hardened artifacts → GitHub. Due before the start of the next week's class; late work loses 10% per started day and reaches 0 after 10 days (`syllabus.md` §6).

**Formative checkpoints.**
- As of commit `d487869` (31 Jul 2026), `bash scan.sh` filters to `MEDIUM,HIGH,CRITICAL` and all
  three Trivy-mappable rules (`DS-0001`, `DS-0002`, `DS-0031`) already appear in its output —
  verified 8 Oct 2026. If a student reports one missing, check their command/flags first; it is no
  longer an expected gap in the lab.
- Task 1's table has six rows but only three scanner findings. A student waiting for `COPY . .`,
  `chmod -R 777` and the unpinned `pip install` to light up should be sent back to the `# DEFECT:`
  comments in `Dockerfile.insecure` and told to write "manual review — no Trivy rule". The point of
  the task is that a clean scan is not a clean image.
- Task 2 produces **no scanner output at all**, by design — the deliverable is a three-row table
  written from reading the JSON. Students who keep re-running Trivy hoping for an IAM finding have
  misread the task; `scan.sh`'s own header comment says so.
- Task 4's "before" count is Task 0's baseline, which students bring from before class. `scan.sh`
  scans both Dockerfiles in one run, so the Task 4 re-run shows the insecure count again; a student
  who skipped Task 0 still owes its screenshot.
- Task 4 alone carries a dedicated 25-point Defense line (on top of its share of Part 3's 40-point
  Tasks-0–5 lump sum). A student behind at 1:35 should move to Task 4 now and come back to Task 2
  in the slack or at home.
- Insist the before/after counts name the command that produced them; the two commands give
  different numbers (§8, row 2).

## 6. Assessment for this week

| Instrument | Evidence | Outcome | Weight |
|---|---|---|---|
| Worksheet 13, Part 2 (lecture questions) | Five written answers with CWE / A02 reasoning | K1–K3 | 20 of the worksheet's 100 |
| Worksheet 13, Part 3 (Tasks 0–5) | Commands, Trivy output, screenshots, the defect and IAM tables | P1–P3, P6, A2 | 40 of 100 |
| Defence — Task 4 hardening | Before/after counts, per-defect fix mapping, diffed policy and Dockerfile | K3, P4, P5 | 25 of 100 |
| Worksheet 13, Part 4 (reflection) | Line → CWE → A02 mapping, real incident, best-mitigation argument | K1, K2, A3 | 15 of 100 |
| Weekly quiz (start of class) | Quiz score (Week 12 retrieval) | — | Part of the 10% quiz/participation component |
| Viva spot-check (during the lab) | Live reproduction and explanation | P2, P4, A2 | Pass/flag for follow-up |

The worksheet total feeds the 30% weekly-worksheet component. *Audit the AI* counts toward the
Defence + Reflection score, as the worksheet states; *Explain-in-Plain-English* and *Prompt Problem*
are graded on prompt precision and verification (per the worksheet's Comprehension & Prompt section)
and are folded into the same score as instructor policy, not a worksheet-stated rule. Partial credit
is available where a student maps and justifies a fix correctly but could not get the scan to run.

## 7. Materials

- Lab: `labs/week13-cloud-container/` — `Dockerfile.insecure`, `Dockerfile.hardened`, `harden.md`,
  `iam-policy-insecure.json`, `iam-policy-leastpriv.json`, `scan.sh`, `app.py`, `requirements.txt`,
  `worksheet.md`, `README.md`
- Slides: `slides/week13.md`
- Tooling: `aquasec/trivy:latest` (pulled and run in throwaway containers by `scan.sh`)
- Reading list ([readings.md](../../readings.md), W13): OWASP Docker Security Cheat Sheet ·
  NIST SP 800-190 · CIS Benchmarks · AWS Well-Architected Security Pillar. The lab README also links
  the Kubernetes security-concepts documentation.
- Submission channels: [SUBMISSION.md](../../SUBMISSION.md) · Rules of engagement: [ETHICS.md](../../ETHICS.md)

## 8. Risks and contingencies

| Risk | Mitigation |
|---|---|
| **RESOLVED 31 Jul 2026 (commit `d487869`), re-verified 8 Oct 2026 — superseded, kept for history.** `scan.sh` used to run `trivy config --severity HIGH,CRITICAL`, under which `DS-0001` (unpinned `:latest`, MEDIUM) never appeared | `scan.sh` now filters `MEDIUM,HIGH,CRITICAL`; `DS-0001` appears in its own output. The unfiltered-command workaround below is no longer needed — do not give it in class, it now shows a confusing non-zero "hardened" count (see next row) |
| **RESOLVED 31 Jul 2026, re-verified 8 Oct 2026 — superseded, kept for history.** Before/after counts used to differ by command | `scan.sh` alone is now correct for all counting: `Dockerfile.insecure` **4** (MEDIUM 1, HIGH 1, CRITICAL 2), `Dockerfile.hardened` **0**. (The distroless stage was digest-pinned in the same commit, so `DS-0001` no longer fires on the hardened file even unfiltered; the unfiltered count is now `Dockerfile.hardened` **1** — only `DS-0026`, LOW, missing `HEALTHCHECK` — not the old 2.) Still require the submitted pair to state its command and grade the delta + defect→fix mapping, not the absolute number — Trivy's checks bundle can move it again |
| **Students wait for an IAM finding that never comes.** Trivy's config scanner does not parse standalone AWS IAM policy JSON (verified: the scan reports `Detected config files num=2` — the two Dockerfiles only). `slides/week13.md` still describes the kickoff as "trivy config over Dockerfiles + IAM JSON" | Correct that slide line verbally when briefing the game (0:10–0:25); `worksheet.md` Task 2 and `scan.sh`'s header comment already say the IAM policies are reviewed manually |
| **The game brief promises a round the lab does not ship.** `README.md` and `slides/week13.md` list four rounds including "Storage: lock down a publicly-exposed bucket (provided as IaC/localstack)"; no localstack or IaC artifact exists in the lab folder, and the worksheet's tally is 6 container + 3 IAM = 9 flags, where "storage" means the `COPY . .` / `.dockerignore` leak (CWE-538) | Brief the game from the worksheet, not the slide: 9 flags, container + IAM. If a student asks for the bucket round, point them at Part 4 Q2 (a real public-bucket breach) as the written substitute |
| **Slow or failed pulls; Docker Hub rate limits** | Task 0 now runs before class, so most students pull on their own connection; a student who arrives without it pulls in class at 0:25, inside Task 1's time — the worksheet gives no fallback for a skipped Task 0 (⬚). Pre-pull `aquasec/trivy:latest`. The first `trivy config` downloads the checks bundle; the first `trivy image` downloads a ~100 MiB vulnerability database. Keep a `docker save` / `docker load` copy on a USB stick, and stagger the room if bandwidth is thin |
| **The optional CVE scan needs the Docker socket.** Step [2/2] of `scan.sh` mounts `-v /var/run/docker.sock:/var/run/docker.sock`, which fails on setups where the socket is elsewhere (rootless, Colima) | Step [2/2] is explicitly optional and all of Task 4's graded evidence comes from `trivy config`. `scan.sh` already prints a skip message when the image has not been built. Do not widen the task to depend on it |
| **`README.md`'s own documented CVE-scan command is broken — verified 8 Oct 2026, not previously flagged.** `docker run --rm aquasec/trivy image week13-hardened:lab` (as written in the README) fails with `failed to connect to the docker API at unix:///var/run/docker.sock` — it is missing the socket mount | Do not hand students the README's one-liner for the optional CVE scan; point them at `scan.sh` step [2/2] instead, which already includes `-v /var/run/docker.sock:/var/run/docker.sock` and works. (Fixed in the README itself, 8 Oct 2026.) |
| **Apple Silicon platform mismatch** | Verified 26 Jul 2026 on an arm64 Mac: `docker build -f Dockerfile.hardened -t week13-hardened:lab .` succeeds, the image reports Architecture `arm64` and `Config.User` `65532:65532`, and the container answers `{"app":"week13-demo","status":"ok"}`. The pinned build-stage digest is an OCI **image index** — `docker buildx imagetools inspect python:3.11-slim@sha256:cdbd05…` lists `linux/amd64` and `linux/arm64/v8` among its platforms — so it resolves on both halves of the room. Warn any student who refreshes it with the command in the Dockerfile comment (`docker buildx imagetools inspect python:3.11-slim`) to take that **index** digest, not one of the per-platform manifest digests underneath it, which would pin the build to a single architecture |
| **Port clash if anyone runs the demo app** | `app.py` binds `0.0.0.0:5000` and the Dockerfiles `EXPOSE 5000`; on macOS AirPlay Receiver squats host 5000, and on a busy machine 8080 may already be allocated (`Bind for 0.0.0.0:8080 failed: port is already allocated` happened while verifying this plan). No graded task needs a published port — if demoing, publish any free host port |
| **"Prove it runs as non-root" from inside the container fails.** The hardened runtime is distroless: no shell, so `docker run -it … sh` and `docker exec … sh` both fail | Have students use `docker image inspect --format '{{.Config.User}}' week13-hardened:lab` (verified: returns `65532:65532`), or cite `USER 65532:65532` in the Dockerfile plus the cleared `DS-0002` finding |
| **`docker compose up` muscle memory** | There is no compose file this week. The kickoff, per `README.md`, is `bash scan.sh` from inside `labs/week13-cloud-container` — Task 0, run before class |
| **A student finishes the hunt early** | Extensions: write the `.dockerignore` from Task 3 (itself homework) and show `COPY . .` no longer pulls `.git`; add the missing `HEALTHCHECK` and re-scan to clear `DS-0026`. (The "add a digest pin and watch `DS-0001` clear" extension is already done — the distroless `FROM` at `Dockerfile.hardened:42` is pinned as of 31 Jul 2026 — so it is no longer available as an early-finisher task) |
| **Copy-pasted tables between students** | The six defect rows are fixed by the file, so the tables converge — grade the mitigation sentences and the flag-tally reasoning, keep the identity-stamped screenshots, and viva spot-check any pair whose wording matches |

## 9. Post-teaching reflection

*Complete after the session — this also feeds the course's engagement data.*

- Attendance / completion: ⬚
- Time actually taken per task (vs. plan): ⬚
- Where the class got stuck, and what unblocked them: ⬚
- Misconception that showed up in the *Explain-in-Plain-English* answers: ⬚
- Quality of the *Audit the AI* critiques (did students catch the planted flaw?): ⬚
- Anything to change before this week runs again: ⬚
