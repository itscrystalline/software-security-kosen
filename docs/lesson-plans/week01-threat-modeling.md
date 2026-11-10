# Lesson Plan — Week 1: Security Mindset & Threat Modeling

| | |
|---|---|
| **Course** | Software Security 2 (02005094, KOSEN-KMITL) |
| **Week / date** | 1 · ⬚ |
| **Contact time** | 150 min = 10 quiz + 15 explanation & demo + 125 supervised lab (in class: Tasks 0, 1, 2, 3, 3b, 4; homework: Tasks 5, 6, 7, 8) |
| **Lab folder** | `labs/week01-threat-modeling` |
| **Slides** | `slides/week01.md` |
| **Standards** | OWASP 2025 **A06 Insecure Design** · CWE-501 (Trust Boundary Violation) |
| **CLOs addressed** | **CLO1** model · **CLO6** ethics & evidence (course specification §6, Week 1 row: "1, 6"). The worksheet's recurring *Audit the AI* and *EiPE + Prompt Problem* parts additionally carry **CLO5** per specification §4. |

---

## 1. Session objectives

By the end of this week a student can:

**Knowledge (K)**
- K1 — Define the CIA triad and give one concrete failure example for each of the three properties.
- K2 — Explain what a *trust boundary* is, why data crossing one deserves extra scrutiny, and what "attack surface" means — naming two things that increase it in a web app.
- K3 — Map each STRIDE letter to its threat and to the security property it violates.
- K4 — State what "Secure by Design" (CISA) means and how it differs from bolting security on after release; locate a weakness in the OWASP Top 10, MITRE CWE and ATT&CK landscape.

**Skills (P)** — this week is *modelling only*; the worksheet's ethics note is explicit that students **analyse design, they do not attack the app**.
- P1 — Draw a data-flow diagram of the sample app: the external entity (web client), the process (Flask app), the data stores (`notes.db` SQLite and the `uploads/` store), the flows for `/notes`, `/upload` and `/files/<name>`, with the Internet→app trust boundary marked as a dashed line.
- P2 — Complete a per-element S/T/R/I/D/E grid grounded in the actual code of `sample-app/app.py`.
- P3 — Play the "Elevation of Privilege" deck against their own DFD and record every threat they can tie to a real element or flow.
- P4 — Write attacker personas and abuse cases, and convert threats into testable security requirements phrased as acceptance criteria ("the system must … so that …").
- P5 — Rank the top 5 threats by likelihood × impact, propose one concrete mitigation each, and sketch the secure design for the riskiest flow (`secure_filename`, store outside web root, allow-list extensions).

**Attitude (A)**
- A1 — Work within [ETHICS.md](../../ETHICS.md), which every student signs an acknowledgment of in Week 1; run the sample app only on their own VM/localhost.
- A2 — Submit evidence that is identifiably their own — every screenshot or diagram carries their `whoami` / login email / student ID and a timestamp — and be able to reproduce it live on request.
- A3 — Treat an AI-generated security answer as something to critique and verify, not to trust.

## 2. Key ideas (the through-line)

Security is not a feature you add — it is a property you design for. Defenders must close every
hole; an attacker needs one. The consequence is a method rather than a checklist of bugs: draw the
system as data flowing between components, mark every place data crosses from one privilege level
to another, and interrogate each of those crossings with a fixed vocabulary (STRIDE) so nothing is
forgotten. That is what makes this week's flaws *design* flaws — OWASP A06 Insecure Design,
CWE-501 Trust Boundary Violation — and design flaws are cheapest to fix before the code that
carries them exists. Everything the rest of the term exploits, this week names in advance.

## 3. Prior knowledge and preparation

- **Students, before class:** per the lab README, environment setup **is Lab 0** and is done
  *before class* — install Docker Desktop plus Burp Suite Community or OWASP ZAP (a Linux VM is an
  optional fallback), and verify with `docker run hello-world` and `git --version`. Also the
  one-time Week 1 setup in [SUBMISSION.md](../../SUBMISSION.md): create a GitHub account, **fork**
  the course repo and `git clone` the fork — SUBMISSION.md needs the repository "on your own machine
  before Week 1" — plus Lab 0. Its last step, signing in to `ctf.zcr.ai` with the account slip
  students are given, has no stated timing: ⬚ (no source says when the slips are handed out).
- **Lab 0 is pre-class.** `labs/week01-threat-modeling/README.md` says "**Before class** — Set up
  your environment … This *is* **Lab 0**"; [syllabus.md](../../syllabus.md) says to do it
  "**before** the first class — class time is for the lab itself"; SUBMISSION.md lists it in the
  one-time setup needed before Week 1. [AGENDA.md](../../AGENDA.md) no longer budgets setup time in
  class: its Week 1 lab is Tasks 0–4 at 125 min, the whole lab block, and Worksheet 1's Task 0
  budgets 5 minutes. Only the speaker notes in `slides/week01.md` still place Lab 0 "~ start of
  lab" — the same notes still describe a ~2 h lecture and a 3 h lab, so they predate the 150-min
  class.
- **Instructor, before class:** pull `python:3.12-slim` ahead of the session (`docker compose build`
  or `docker compose up --build` once in the lab folder — `docker compose pull` is a no-op here
  since `docker-compose.yml`'s only service has a `build:` key and no `image:` key, verified);
  obtain the "Elevation of Privilege" deck in printed or virtual form (link in
  [readings.md](../../readings.md)) — or plan to run the built-in digital deck instead, which needs
  no prep at all (embedded in Worksheet Task 3, playable on any shared screen); have the ETHICS.md
  acknowledgment ready to sign; confirm host port 8080 is free (see §8).
- **Lab prerequisites (worksheet Part 3):** "Docker + Docker Compose in your VM; a drawing tool
  (draw.io / paper + photo); the Elevation of Privilege deck (print or virtual)."
- **Prerequisite concept:** what an HTTP endpoint is, and enough Python to read a 43-line Flask file.

## 4. Pre-class material and in-class explanation — 10 min quiz + 15 min demo

**Before class (students).** The concept material is pre-class: students study `slides/week01.md`
and answer the worksheet's **Part 2** questions from it before the class starts. They also finish
Lab 0 and fork and clone the course repo (SUBMISSION.md's one-time setup, §3). The slides carry what
the 120-min lecture used to teach:

| Block | Content |
|---|---|
| Core concepts | What "secure" means — Confidentiality / Integrity / Availability, one concrete example each; attacker vs. defender asymmetry (defenders must close every hole, attackers need one) and misuse cases vs. use cases; trust boundary = where data crosses between components of different privilege (`browser \| (boundary) \| server \| (boundary) \| database`); attack surface = every input an attacker can reach (HTTP params, headers, cookies, file uploads, APIs, env vars, dependencies) |
| Vulnerability deep-dive + real cases | The worked example the whole method hangs on — the `/upload` endpoint: `Browser --(file)--> [Flask app] --save f.filename--> uploads/`, served back by `/files/<name>`; it crosses the Internet→app boundary and the app trusts *both* the file bytes and the attacker-controlled filename. Then the STRIDE table (letter → threat → property violated) and the full STRIDE pass on that one element: S no auth, T overwrite another user's file, R no logs, I `../` filename, D no size limit, E upload and then request an executable file. Close with the landscape they will cite all term: OWASP Top 10 (2025), OWASP LLM Top 10 (2025), MITRE CWE, MITRE ATT&CK. **Real-world design-flaw breach used as the case: ⬚** — the repo names none; Worksheet 1 Part 4 Q2 requires each student to bring one, so pick a case you are willing to be held to. |
| Defences / secure coding | Secure by Design (CISA): safety is the vendor's job, on by default; shift from "patch later" to designing out the bug class; the industry and government push toward memory-safe languages (revisited in Week 11); why some bugs are design flaws rather than coding slips → **A06 Insecure Design**; the cost gap between fixing at design time and fixing in production. Then the course's AI policy slide (AI is allowed and must be disclosed; it hallucinates APIs/CVEs and writes insecure code; you are graded on understanding — live re-demos, per-student flags, weekly *Audit the AI*) and the three key takeaways. |

**In class**

| Time | Block | Content | Method |
|---|---|---|---|
| 0:00–0:10 | Weekly quiz + course framing | `quizzes/weekly/week01.md`; no prior teaching week to recap, so the slot carries course framing (break then defend, per-student flags, live scoreboard, weekly *Audit the AI*) and the ETHICS.md acknowledgment, signed here — see the note below the table | Individual quiz; course-framing slide ("How this course works"); signed acknowledgment |
| 0:10–0:25 | Explanation + live demo | Walk the `/upload` endpoint on the board — `Browser --(file)--> [Flask app] --save f.filename--> uploads/`, served back by `/files/<name>`, across the Internet→app boundary — and let the class call out each STRIDE line before revealing it ("6 threats from ONE endpoint — now imagine the whole app"); then the secure design it points to (`secure_filename`, store outside web root, allow-list extensions). This week is modelling only: students model the flaw, they do not attack it; any live demonstration stays instructor-side and promises no read-side traversal (§8). Brief the game — "Elevation of Privilege": Microsoft's free STRIDE card deck, played against the sample app's DFD; each valid threat tied to a real element or flow scores a point; outcome is a team-built STRIDE model; the digital deck in Worksheet Task 3 needs no printing | Board walk-through on the projector |

> **Note — the Week 1 quiz slot.** AGENDA.md mandates a ~10-minute retrieval quiz at the start of
> every teaching week (low-stakes, lowest 1–2 dropped), and `quizzes/weekly/week01.md` exists (6
> questions: 5 MCQ + 1 short answer, individual). But Week 1 has no prior teaching week to retrieve
> from, and `quizzes/README.md` states that a weekly quiz covers "that week's lecture material" —
> which students have studied from the slides before class, but which at 0:00 has not yet been
> discussed in class. **How the Week 1 quiz is run is ⬚**: no public repo source states a Week-1
> convention (diagnostic pre-test, moved later in the class, or otherwise). The Week 1 one-time
> business has a home either way: the ETHICS.md acknowledgment — "Every student signs an
> acknowledgment of this policy in Week 1" — is signed in this slot, and SUBMISSION.md's one-time
> setup (fork and clone the course repo, Lab 0) is done before class; when students sign in to
> `ctf.zcr.ai` with their account slip is ⬚ (§3).

**Checks for understanding during the demo**
- Have the class list the inputs of a login page, then name that list as its attack surface.
- During the `/upload` walk-through: let students call out threats before each line is revealed — a silent room here means the DFD task will stall.
- Before the lab starts: cold-call two students for *"give me one STRIDE threat for a login page."*

## 5. Supervised lab — 125 min in class + homework

Target: `docker compose up --build` in `labs/week01-threat-modeling` → `http://localhost:8080`
(worksheet Part 3, verbatim):

```bash
cd labs/week01-threat-modeling
docker compose up --build           # starts sample-app on http://localhost:8080
curl -s -X POST localhost:8080/notes -H 'Content-Type: application/json' \
     -d '{"owner":"alice","body":"hello"}'   # observe behavior, do not attack
curl -s localhost:8080/notes

echo "demo file" > demo.txt
curl -s -X POST localhost:8080/upload -F "file=@demo.txt"   # observe behavior, do not attack
curl -s localhost:8080/files/demo.txt
```

Source to model: `sample-app/app.py`. Template to fill: `THREAT-MODEL-TEMPLATE.md` — copy it, do
not edit the original. What to submit per task: the threat/element identified + a screenshot (DFD,
table, or running app) + a 2–3 sentence mitigation.

Only the worksheet's *in class* tasks run here (worksheet Part 3; [AGENDA.md](../../AGENDA.md),
*How each worksheet is split*). The instructor circulates, checks evidence and reasoning, and runs
2–3 **viva spot-checks** — a student walks through and explains their own DFD/STRIDE model live.
Week 1 is AGENDA's named exception to the in-class rule: its subject-sheet Method line is modelling
only, so the lab ends on Task 4 and the rank-and-fix Task 8 is homework. The six in-class tasks fill
the 125 min exactly, so there is no slack row.

| Time | Task | Student does | Evidence produced |
|---|---|---|---|
| 0:25–0:30 | **Task 0 — Onboarding (5 min)** | `docker compose up`, hit `/notes` and `/files/<name>`, read `sample-app/app.py` | Screenshot of the running app + the JSON response |
| 0:30–0:55 | **Task 1 — Draw the DFD (25 min)** | Identify the external entity (web client), the process (Flask app), the data store (`notes.db` SQLite), the `uploads/` store, and the flows for `/notes`, `/upload`, `/files/<name>`; mark the Internet→app trust boundary with a dashed line | DFD image embedded in their copy of the template |
| 0:55–1:25 | **Task 2 — STRIDE the elements (30 min)** | Fill the S/T/R/I/D/E grid per element, grounded in real code: `/notes` accepts a client-supplied `owner` with no auth (Spoofing); `/upload` saves raw `f.filename` — arbitrary file write (Tampering) — and echoes the resolved save path back in its response (Information disclosure); `/files/<name>` reads it back but is comparatively defended (see Task 5); no logging anywhere (Repudiation) | Completed STRIDE table |
| 1:25–1:45 | **Task 3 — Elevation of Privilege game (20 min)** | Play the EoP deck against their DFD — or the digital deck embedded in the worksheet, same 78 cards, same rule; each card tied to a real element or flow scores a point; record every valid threat | List of carded threats + score |
| 1:45–2:10 | **Task 3b — Systems-level pass (25 min)** | A second pass over the **whole** diagram, after trying the worksheet's `trust-boundary` simulation: list every boundary one request crosses from the client to `notes.db` and back, and which crossing has no check; assume the Flask process, then the `uploads/` store, is fully owned and note what each reaches; chain two "low" findings as `A → B → consequence`; finish "Even if every element-level mitigation in Task 8 is implemented, this system still fails if ___." | The boundary list, two owned-element reachability notes, one written chain, and the system claim |
| 2:10–2:30 | **Task 4 — Abuse cases & attacker personas (20 min)** | Define 2 personas (e.g. a curious logged-in user; an anonymous internet attacker) and write 2 abuse cases each against the sample app, tied to DFD elements | 4 abuse cases |

**Homework — submitted with the worksheet before the start of the next week's class**

| Task | Student does | Evidence produced |
|---|---|---|
| **Task 5 — Path-traversal deep-dive (25 min)** | Trace `/upload` → `/files/<name>`; explain how `../` in a filename escapes `uploads/`; sketch the secure design (`secure_filename`, store outside web root, allow-list extensions) | The data flow + secure-design note |
| **Task 6 — Threat-model the project target (30 min)** | Stop the sample app first (`docker compose down` — both apps bind host port 8080), then run **NoteVault** (`cd ../../project/starter-app && docker compose up`), draw a quick DFD, list the top 3 STRIDE threats they would investigate | NoteVault DFD + top-3 threats (reused in the [project report](../../project/REPORT-TEMPLATE.md)) |
| **Task 7 — Security requirements (15 min)** | Write 3 security requirements as acceptance criteria ("the system must … so that …"), each mapped to a threat from Task 2 or Task 6 | 3 testable security requirements |
| **Task 8 — Defend / fix it: rank & mitigate (25 min)** | Rank the top 5 threats by likelihood × impact; propose one concrete mitigation each (e.g. auth on `/notes`, `secure_filename()` + allowlist for `/upload`, request logging for Repudiation, size/rate limits for DoS); then pick one and implement it in their fork | Top-5 table with mitigations in their template copy; for the implemented one, the diff (commit hash on their `wk01` branch), the request that succeeded before the change and is refused after (both outputs), and 2–3 sentences on whether it closes the class or only the instance |
| **Part 4, *Audit the AI*, *Comprehension & Prompt*** | Reflection; critique an AI-written exploit or fix; *Explain-in-Plain-English* and *Prompt Problem* | Written answers |

Worksheet PDF → `learn.zcr.ai/submit`; work pushed → GitHub. Due before the start of the next week's class; late work loses 10% per started day and reaches 0 after 10 days (`syllabus.md` §6).

**Formative checkpoints.** Task 0's `/files/<name>` returns **404 until something has been
uploaded** (verified). The worksheet's setup block uploads `demo.txt` first, so a student reporting
"the app is broken" here has skipped those lines or asked for a file that was never uploaded — a
good 30-second teaching moment about the `/upload` → `/files/<name>` pairing they will analyse in
Task 5 (homework). A student still without a DFD at 0:55 should be given the four elements verbally
and made to draw only the flows and the boundary. Before the room leaves, remind everyone that
Task 6 (homework) starts with `docker compose down` in the lab folder (§8) — the worksheet now says
so in the task — or NoteVault will fail to start.

## 6. Assessment for this week

| Instrument | Evidence | Outcome | Weight |
|---|---|---|---|
| Worksheet 1, Parts 1–4 | DFD, STRIDE table, EoP findings, systems-level pass (Task 3b), abuse cases, security requirements, top-5 ranking + mitigations with one implemented fix and its before/after evidence (Task 8, homework), reflection, screenshots | K1–K4, P1–P5, A2 | Part of the 30% worksheet component |
| Weekly quiz (start of class) | `quizzes/weekly/week01.md` score | K2–K4 — the item set does **not** examine K1 (CIA), which is evidenced only by Worksheet 1 Part 2 Q1 | Part of the 10% quiz/participation component |
| Viva spot-check (during the lab) | Live reproduction and explanation of their own model | P1–P5, A2 | Pass/flag for follow-up |
| Personalised flag | None this week — the worksheet's Evidence & Integrity section reads "**N/A — this week has no arena challenge, so no flag is issued.**" | A2 | Not issued in Week 1 |
| ETHICS.md acknowledgment | Signed acknowledgment (Week 1, per ETHICS.md) | A1 | Compliance gate, not a mark |

The worksheet's own 100-point rubric governs: *Lecture questions (Part 2)* 20 · *Exploitation +
evidence (DFD + STRIDE table + EoP findings + screenshots)* 40 · *Defense (top-5 ranking +
mitigations)* 25 · *Reflection (CWE/OWASP mapping + breach + best mitigation)* 15. Task 6's output
(homework) feeds the term project, whose threat model is due in Week 7.

## 7. Materials

- Lab: `labs/week01-threat-modeling/` — `README.md`, `worksheet.md`, `THREAT-MODEL-TEMPLATE.md`, `docker-compose.yml`, `sample-app/app.py`
- Slides: `slides/week01.md`
- Weekly quiz: `quizzes/weekly/week01.md`
- Signature game: Microsoft *Elevation of Privilege* (STRIDE card deck) — https://www.microsoft.com/en-us/download/details.aspx?id=20303
- Reading: OWASP Threat Modeling Cheat Sheet — https://cheatsheetseries.owasp.org/cheatsheets/Threat_Modeling_Cheat_Sheet.html
- Project target for Task 6 (homework): `project/starter-app/` (NoteVault) · [project/README.md](../../project/README.md)
- Submission channels: [SUBMISSION.md](../../SUBMISSION.md) · Rules of engagement: [ETHICS.md](../../ETHICS.md)

## 8. Risks and contingencies

| Risk | Mitigation |
|---|---|
| **Port 8080 is double-booked by the course's own files.** `labs/week01-threat-modeling/docker-compose.yml` publishes `8080:5000` and `project/starter-app/docker-compose.yml` publishes `8080:8080`. Starting NoteVault for Task 6 (homework) while the Week 1 app is still up fails with `Bind for 0.0.0.0:8080 failed: port is already allocated` (reproduced). | Repeat it before the room leaves (the worksheet's Task 6 now says so too): `docker compose down` in `labs/week01-threat-modeling` first. A student who wants both up at once must override the published port in one of the two compose files. The same error appears if anything else on the host already holds 8080 — check with `docker ps` before class. |
| **NoteVault is a heavy pull at Task 6 (homework).** `project/starter-app/Dockerfile` is `FROM python:3.12` — the full image, not `-slim`. The room no longer downloads it mid-lab, but on a slow connection it still stalls the task. | Tell students to build NoteVault before they sit down to Task 6; pre-pull `python:3.12` on the lab machines alongside `python:3.12-slim` for students who do the homework there. |
| **Task 6's command (homework) omits `TEAM_ID`.** `project/README.md` specifies `export TEAM_ID=<your-team-name>` before the first build; the worksheet's Task 6 command does not, so the marker seeds as `unassigned` (the compose default). | Expected in Week 1 — teams are not chosen until Week 4 per the project timeline. Tell students the `unassigned` marker is fine now and must be set before the Week 7 threat-model submission. |
| **Docker Desktop is not installed on the day**, although Lab 0 is pre-class (§3) — the slide speaker notes still say "~ start of lab", so some students may expect to do it in class. | Say before Week 1 that Lab 0 is done before class. Week 1's lab has no slack, so setup run in class displaces a task: if it has to happen, budget it against the worksheet's tasks explicitly rather than silently overrunning. The optional Kali/Ubuntu VM is the documented fallback for hosts that cannot run Docker at all; `labs/toolbox` (itself a Docker image — it needs Docker to build) is a documented fallback only for hosts that can run Docker but lack native clang/libFuzzer/gdb tooling (course-specification.md §10). |
| **The Elevation of Privilege deck is not in the room.** Task 3 has a hard 20-minute slot and the physical deck is a printed dependency fetched from a Microsoft Download Center page — printing, or classroom network, can fail. *(Largely closed as of the digital deck below — keep this row for the rare case where the platform itself is unreachable.)* | Worksheet Task 3 embeds a built-in digital deck (`/sim/eop-deck`, same 78 cards) directly on the page — no printing, no separate download, works on any one shared screen/projector. Use it as the default, not a fallback. If the platform itself is down, Task 3 degrades to a timed STRIDE-category round-robin against the DFD, but say so openly rather than pretending the game ran. |
| **Task 0 looks broken:** `/files/<name>` returns 404 until a file has been uploaded (verified). | Answer once to the whole room; use it to introduce the `/upload` → `/files/<name>` pairing that Task 5 (homework) analyses. |
| **A student "tests" the traversal instead of modelling it.** The worksheet's ethics note for this week is *modelling only*. For accuracy if it is demonstrated on the projector: the **write** side is real — an upload sent with `filename=../evil.txt` lands at `/app/evil.txt`, outside `uploads/` (reproduced against the lab image, Flask 3.1.3 / Werkzeug 3.1.8) — but a **read**-side traversal through `/files/<name>` is not reachable (404, including URL-encoded), because Flask's `<name>` converter does not match `/`. Do not promise students a working read-side traversal. | Keep any demonstration instructor-side on the projector; students model, they do not attack. Re-state ETHICS.md rule 1. |
| **A team finishes the DFD and STRIDE grid well before 1:25.** | Extension: STRIDE the `notes.db` data store and the flows *between* elements, not just the endpoints; or start homework Task 6's NoteVault DFD early (after `docker compose down`). |
| Copied DFDs / STRIDE tables between students | Evidence & Integrity requires `whoami` / login email / student ID and a timestamp in every screenshot and diagram; viva spot-check the pair. |

## 9. Post-teaching reflection

*Complete after the session — this also feeds the course's engagement data.*

- Attendance / completion: ⬚
- Time actually taken per task (vs. plan), and how the in-class / homework split worked: ⬚
- Where Lab 0 actually landed (before class / in class), and what it cost: ⬚
- Where the class got stuck, and what unblocked them: ⬚
- Misconception that showed up in the *Explain-in-Plain-English* answers: ⬚
- Quality of the *Audit the AI* critiques (did students catch the planted flaw?): ⬚
- Did the Elevation of Privilege round surface threats the students had missed in Task 2?: ⬚
- Anything to change before this week runs again: ⬚
