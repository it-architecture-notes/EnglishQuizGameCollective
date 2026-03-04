---
name: flutter-qa
description: Flutter QA standards for widget and unit test coverage analysis. Use when auditing Flutter code against requirements, reviewing test coverage gaps, or assessing whether requirements are adequately tested.
---

# Flutter QA Standards

Use this skill as the source of truth for classifying coverage quality and severity in Flutter QA audits.

## What Counts as "Covered"

### Widget Test Coverage
A requirement is widget-tested if test/ contains a test that:
- Pumps the relevant widget with `tester.pumpWidget`
- Asserts on the specific behaviour described in the requirement
- Covers at least: render, interaction, and one error/empty state

If a test only verifies rendering (or only a happy path interaction), classify it as partial coverage.

### Unit Test Coverage
A requirement is unit-tested if test/ contains a test that:
- Directly instantiates the relevant class or calls the function
- Tests the happy path AND at least one failure/edge case
- Uses dependency injection / mocks for external services

If a requirement is covered only through widget tests and lacks direct logic tests where business logic exists, classify as partial coverage.

## Severity Classification for Gaps
- 🔴 **CRITICAL** — requirement has no implementation in lib/
- 🟠 **HIGH** — implementation exists, zero test coverage
- 🟡 **MEDIUM** — partially tested (happy path only, missing error cases)
- 🟢 **LOW** — well tested, minor edge case missing

## What to Check in Every Widget
- Renders without throwing on valid data
- Displays the correct text/labels specified in requirements
- Correct behaviour on empty / null data
- Loading and error states handled

## What to Check in Every Unit Class
- Happy path returns expected value
- Throws or returns error on bad input
- Boundary values (empty string, zero, max int, etc.)

## Requirement Mapping Rules
- Split requirement text into atomic acceptance criteria before auditing.
- Map each criterion to at least one implementation location in `lib/` (or mark as not implemented).
- Map tests to criteria using explicit assertions, not test names alone.
- Prefer evidence over assumption: if no clear assertion exists, mark as not covered.

## Output Expectations
- Produce a coverage matrix with one row per requirement ID.
- Include implementation evidence (file path) and test evidence (widget/unit test path).
- Include severity using the scheme in this skill.
- Prioritize and explain top gaps by user impact and regression risk.

## QA Report Format (exact structure)

```markdown
## 📋 Requirements Coverage Report
**Date:** <today YYYY-MM-DD>
**Requirements file:** <path used, e.g. .cursor/context/active-progress-context.md>
**Flutter test status:** <pass/fail count from `flutter test`>

---

## Coverage Matrix

| ID | Requirement | Implemented? | Widget Test | Unit Test | Severity |
|----|-------------|:---:|:---:|:---:|:---:|
| REQ-001 | <short description> | ✅ lib/x.dart | ✅ test/x_test.dart | ❌ | 🟠 HIGH |
| REQ-002 | <short description> | ✅ lib/y.dart | ❌ | ❌ | 🟠 HIGH |
| REQ-003 | <short description> | ❌ | ❌ | ❌ | 🔴 CRITICAL |

---

## Summary
- Total requirements: N
- Fully covered (widget + unit): N
- Partially covered: N
- No tests at all: N
- Not implemented: N

---

## 🔥 Top 5 Test Gaps (Priority Order)

1. **REQ-00X — <name>** `lib/path/to/file.dart`
   Gap: <what's missing and why it matters>

2. ...

---

## Existing Tests Found
List any test files discovered in test/ and what requirements they map to.
```

## Integration Contract (tester-qa agent)
When the `tester-qa` agent runs, it should:
1. Read this skill before any analysis.
2. Apply these coverage definitions to every requirement row.
3. Use this severity model exactly in the final report.
4. Use the report format in this skill exactly (single source of truth).
