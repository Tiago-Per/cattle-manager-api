# CLAUDE.md

Guidance for Claude Code when working in this repository.

## Project

`cattle-manager-api` — REST API for a cattle herd management app aimed at
small-scale producers. It is a **digital notebook replacement**, not a
decision-support or technical tool.

Frontend lives in a separate repo: `cattle-manager-app` (React + Vite).

This is primarily a portfolio project. Favor clear, idiomatic, well-tested
code over clever abstractions. Scope is deliberately narrow — resist
expanding it.

## Stack

- Ruby on Rails 8.1.3.1, API-only mode
- PostgreSQL
- Solid Queue for background jobs (Rails 8 default — **not** Sidekiq)
- Devise + devise-jwt for token auth (frontend is a separate SPA)
- RSpec + FactoryBot for tests
- WhatsApp delivery via Twilio or Z-API (not yet decided)

## Scope

In scope for V1:

- Animal CRUD: identification, category, birth date, sex, status
- Events per animal: vaccination, weight, breeding
- Estimated calculations (see Domain rules below)
- WhatsApp reminders for due/pending events
- Simple herd summary: counts by category, pending items

Out of scope — do not build, do not suggest building:

- Financial management
- Multi-user / collaborators / roles
- Genealogy or pedigree tracking
- Hardware or IoT integration (scales, RFID, sensors)
- Compliance or legal features (CAR, tax documents)
- Sheep, goat, or any non-bovine support

Offline-first (Capacitor + Dexie.js, client-generated UUIDs, last-write-wins)
is a **future phase**. Don't design for it now, but avoid choices that would
make it impossible later.

## Domain rules

These three calculations are the only estimates the app produces:

| Calculation | Formula |
|---|---|
| Expected calving date | breeding date + 283 days |
| Next estrus estimate | last event + 21 days |
| Weaning suggestion | birth date + 6 months |

Rules:

- Every estimate must be explicitly labeled as an estimate in the API
  response. Never present one as an authoritative date.
- All three return `nil` when their input date is missing. `birth_date` is
  optional by design — producers often buy animals with unknown birth dates.
  Never let a missing date raise.
- `category` (`calf`, `heifer`, `cow`, `bull`, `steer`) is a **manual,
  user-editable field**. Do not derive it from age or infer transitions
  between categories — the thresholds vary by breed and production system.
- **Never invent agronomy or veterinary data.** No vaccination protocols,
  no breed-specific figures, no medication dosages, no target weights. If a
  task seems to need one, stop and flag that it requires a real source.
  Vaccination schedules are entirely user-defined.

## Conventions

- All code in English: variables, methods, classes, comments, commit
  messages, migration names.
- Enums are stored as **strings**, not integers, so the database is readable
  during debugging. Use the Rails 8 positional syntax: `enum :status, {...}`.
  The `enum status: {...}` keyword form was removed in Rails 8.
- Keep business logic in models. Introduce service objects only when a model
  method genuinely doesn't fit — not preemptively.
- No `rescue nil`, no silent failures.

## Testing

Every feature ships with specs in the same change. This is not optional.

The suite should stay small and deliberate. The whole V1 fits in roughly
three spec files:

- `spec/models/animal_spec.rb` — non-trivial validations only: the
  category-vs-sex rule, uniqueness of `identification`, future `birth_date`.
- Estimate calculations — each of the three, with both the normal case and
  the missing-date case returning `nil`.
- `spec/requests/animals_spec.rb` — one happy path and one failure path per
  endpoint. Assert status code and JSON shape, not internals.

Do not write:

- Controller specs (redundant with request specs)
- Tests for framework behavior (`belongs_to`, enum-generated `cow?`)
- Tests for factories, or for getters and setters with no logic

Spec descriptions must state the business rule, not the mechanics:
`it "rejects category 'cow' for a male animal"`, not `it "is invalid"`.

For the estimate calculations, write the spec before the implementation —
they're pure functions and the edge cases are easier to reason about up front.

Do not add SimpleCov or chase a coverage percentage.

## Commands

```bash
bin/rails db:create db:migrate
bin/rails server
bundle exec rspec
bundle exec rubocop
```

## Working style

- Prefer the simplest solution that satisfies the requirement. Don't add
  abstractions, gems, or configuration until there's a concrete need.
- When a requirement is ambiguous, ask instead of guessing.
- Never commit `config/master.key` or any credential.
