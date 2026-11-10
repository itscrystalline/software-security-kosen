# Lesson Plan — Week 20: Examination Feedback & Course Reflection

| | |
|---|---|
| **Course** | Software Security 2 (02005094, KOSEN-KMITL) |
| **Week / date** | 20 · ⬚ |
| **Contact time** | 150 min, one continuous block (`AGENDA.md`, *Week 20 — Examination feedback & course reflection*): assessment feedback 45 + corrections 45 + recurring misconceptions 35 + course reflection 25 |
| **Lab folder** | None — course specification §6, row 20 lists no lab folder, and `labs/` has no Week 20 folder |
| **Slides** | None — `slides/` has no Week 20 deck. Whether one is needed: ⬚ |
| **Type** | **Feedback & reflection — no new content and nothing graded** (`AGENDA.md`; `syllabus.md` §5) |
| **Covers** | The final assessments: the Week 18 written exam and the Week 19 capstone CTF (`AGENDA.md`, Week 20, 0:00–0:45) |
| **CLOs addressed** | **CLO5** evaluate & communicate (course specification §6, row 20: "Corrections + reflection on the CLOs"). Nothing is assessed for marks this week |

> **This plan quotes no exam question, no answer and no flag.** The Week 18 Form A paper is public
> (`labs/week18-final-written/exam.md`); the keys, Form B, the item bank and the CTF answers are
> instructor-only and are referenced here by path only.

---

## 1. Session objectives

By the end of this session a student can:

**Knowledge (K)**
- K1 — State, for each final-exam item and CTF challenge they lost marks on, what the correct
  reasoning was.
- K2 — Name the misconceptions the cohort shared on the final assessments, and the evidence that
  refutes each one.

**Skills (P)**
- P1 — Rework their weakest items and explain the corrected reasoning aloud, as an attack →
  root cause → fix argument rather than a recalled answer.
- P2 — Connect their own assessment evidence (worksheets, exams, CTF, project) to the course
  learning outcomes CLO1–CLO6 (course specification §3).

**Attitude (A)**
- A1 — Treat a lost mark as information about their reasoning, not as a verdict.
- A2 — Keep the integrity rules of the course: no exam key, Form B item or CTF flag is copied out
  of the room.

## 2. Key ideas (the through-line)

The final assessments measured each student once; this week is where that measurement becomes
useful to them. Nothing is graded, so students can be honest about what they did not understand.
The work is the same loop the course has run every week — find the flaw, explain why it worked,
fix it and show the fix holds — applied to their own exam answers instead of a vulnerable app. The
session ends by stepping back from single items to the course learning outcomes, so each student
leaves with an evidence-based picture of what they can now do and what still needs work.

## 3. Prior knowledge and preparation

- **Students, before class:** bring the feedback they were given on the Week 18 paper and the
  Week 19 capstone CTF. How feedback reaches them, and whether marked scripts are returned or only
  shown, is **⬚** (not recorded in this repository).
- **Instructor, before class:**
  - **Marking done.** The Week 18 paper marked (`week18-final-written.md` §7) and the Week 19 CTF
    scored (`week19-final-ctf-capstone.md` §5). Whether the marking timeline allows that before
    Week 20 is **⬚**.
  - **Item analysis done.** The Week 18 item analysis (`week18-final-written.md` §8) gives the
    cohort-wide failures that drive the 1:30–2:05 misconceptions block. Bring the per-item and
    per-challenge solve rates, not names.
  - **Know which form was sat.** Check the Week 18 invigilation record for which form each section
    sat (`week18-final-written.md` §5), and whether any make-up sitting is still to come (see §7).
  - **CLO map to hand.** Have the course specification §3 CLO table and the §4 CLO → assessment
    alignment ready for the 2:05–2:30 reflection.
- **Prerequisite:** the final assessments have been sat.

## 4. Session run-sheet — 150 min

The four blocks below are `AGENDA.md`'s (*Week 20 — Examination feedback & course reflection
(150 min)*). There is no break. AGENDA gives no finer breakdown inside a block; where this plan
needs one, it is **⬚**.

| Time | Block | Content |
|---|---|---|
| 0:00–0:45 | **Assessment feedback** | Walk through the final written exam and the capstone CTF |
| 0:45–1:30 | **Corrections** | Students rework their weakest items and explain the corrected reasoning |
| 1:30–2:05 | **Recurring misconceptions** | Class discussion |
| 2:05–2:30 | **Course reflection** | Students connect their assessment evidence to the course learning outcomes |

### 4.1 Assessment feedback — 0:00–0:45

Walk through the Week 18 written paper and the Week 19 capstone CTF. The split of the 45 minutes
between the two is **⬚**.

- **Written exam.** Go section by section and lead with the items the item analysis flagged
  (`week18-final-written.md` §8): near-universal wrong first, then the split items. For each,
  model the answer the marking scheme rewarded — name the **fix** and the CWE, not just the bug,
  which is the score-saver the Week 8 and Week 18 proctor decks both give.
- **Capstone CTF.** Show the per-challenge solve counts and walk the challenges few teams solved:
  the vulnerable mechanism, the exploit path, and the control that stops it. Treat it as a
  remediation walk-through, not a flag reveal.
- Present Form B items on the projector only. They are not handed out — see §7.

### 4.2 Corrections — 0:45–1:30

Each student picks their weakest items from the final written paper and the CTF, reworks them,
and explains the corrected reasoning — to the instructor, or to a peer the instructor then
spot-checks. How many items each student reworks, and whether pairs or individuals do the
explaining, is **⬚**.

- A correction states what the original answer got wrong, the corrected reasoning, and — for an
  exploit or fix item — how they would show empirically that the fix holds (CLO3's "demonstrate
  empirically that the original attack no longer succeeds").
- The instructor circulates, as in a teaching-week lab, and probes with the same question the
  course has asked all term: *"why this fix and not X?"*
- Nothing is re-marked. AGENDA records the week as "nothing graded", so a correction never changes
  a final-exam or CTF mark.

### 4.3 Recurring misconceptions — 1:30–2:05

A class discussion of the misconceptions the final assessments showed across the cohort.

- Start from the cohort-wide failures in the Week 18 item analysis and the CTF solve counts.
- Cross-check them against the misconception tables in `week07-review-midterm-prep.md` §6 and
  `week17-review-final-prep.md` §6. A misconception that survived the review week is the most
  useful thing to name today; record it for next cohort's review week (§8).
- For each one, ask the class for the evidence that refutes it — the line of code, the failing
  re-test, the scanner's actual rule set — the way the review weeks re-tested them.

### 4.4 Course reflection — 2:05–2:30

Each student connects their own assessment evidence to the course learning outcomes.

- Use the course specification §3 CLOs (CLO1 model · CLO2 exploit · CLO3 remediate · CLO4 operate
  tooling · CLO5 evaluate & communicate · CLO6 practise within ethical limits). §4 maps each
  assessment to the CLOs it evidences.
- Each student names, for each CLO, one piece of their own evidence from the term (a worksheet
  task, an exam item, a CTF challenge, a part of the term project) and says whether it shows the
  outcome met or not yet met.
- The output format — written, spoken, or collected — is **⬚**. It is not graded either way.

## 5. Assessment for this week

| Instrument | Evidence | Outcome | Weight |
|---|---|---|---|
| — | Corrections and CLO reflection, discussed in class | K1–K2, P1–P2 | **None** — nothing is graded this week (`AGENDA.md`, *Week 20*) |

No worksheet, no weekly quiz and no flag this week — nothing is submitted, to `learn.zcr.ai/submit`
or GitHub. The final marks come from the Week 18 and Week 19 instruments as already marked
(`syllabus.md` §6). Week 20 opens no new deadline. Work already late from earlier weeks still
follows the KOSEN late rule: −10% per started day, 0 after 10 days (`syllabus.md` §6).

## 6. Materials

- Paper, Form A (public): `labs/week18-final-written/exam.md`
- Capstone CTF paper: `labs/week19-final-ctf-capstone/ctf.md` and its `README.md`
- Lesson plans this week draws on: [Week 18](week18-final-written.md) (§5 forms, §7 marking,
  §8 item analysis) · [Week 19](week19-final-ctf-capstone.md) (§5 scoring) ·
  [Week 7](week07-review-midterm-prep.md) and [Week 17](week17-review-final-prep.md) (§6
  misconception tables)
- Outcomes: course specification §3 (CLOs) and §4 (CLO → assessment alignment) —
  [course-specification.md](../course-specification.md); [syllabus.md](../../syllabus.md) §2
- Instructor-only, **never published**: `instructor/exams/week18-final-written-answers.md`,
  `instructor/exams/week18-final-written-formB.md`,
  `instructor/exams/week18-final-written-formB-answers.md`, `instructor/exams/item-bank.md`,
  `instructor/GRADEBOOK.md`
- Rules of engagement: [ETHICS.md](../../ETHICS.md)

## 7. Risks and contingencies

| Risk | Mitigation |
|---|---|
| **Walking through Form B publishes it.** Once its items are discussed in class, Form B is as public as Form A (`week18-final-written.md` §5 already expects it to be rotated next cohort) | Show items on the projector; hand out no copies of Form B or of any key. If a make-up sitting is still to come, do not walk through the form that make-up will sit — which form that is depends on the open make-up decision in `week18-final-written.md` §5 (**⬚**) |
| **The CTF walk-through leaks reusable solutions.** Challenge solutions and flags carry over if a challenge is reused next cohort | Walk the mechanism and the fix, not flag values; the answer key stays in `instructor/` |
| **Marking is not finished by Week 20** | The 0:00–0:45 walk-through and the 0:45–1:30 corrections both need marked work. If only one assessment is marked, run the walk-through on that one; what replaces the missing half is **⬚** |
| **Students treat corrections as a re-mark request** | Say at 0:00 that nothing this week changes a mark (`AGENDA.md`: "nothing graded"); route any marking dispute to the institution's appeal procedure (**⬚**, not recorded in this repository) |
| **A discussion of misconceptions turns into naming students** | Present solve rates and item statistics for the cohort, never per-student results |

## 8. Post-teaching reflection

*Complete after the session — this also feeds the course's engagement data.*

- Attendance: ⬚
- Was marking of both final assessments finished in time for the walk-through?: ⬚
- Time actually taken per block (vs. plan): ⬚
- Misconceptions that survived the Week 17 review, to add to next cohort's review-week tables: ⬚
- CLOs students most often judged "not yet met", and what that suggests for the teaching weeks: ⬚
- Anything to change before this week runs again: ⬚
