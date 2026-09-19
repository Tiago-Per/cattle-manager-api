# cattle-manager-api

[![CI](https://github.com/Tiago-Per/cattle-manager-api/actions/workflows/ci.yml/badge.svg)](https://github.com/Tiago-Per/cattle-manager-api/actions/workflows/ci.yml)

REST API for a cattle herd management app aimed at small-scale producers. It replaces the paper notebook: the producer records animals and events, and the API returns them along with a few labeled date estimates. The frontend lives in a separate repository, `cattle-manager-app`.

## Scope

**V1**

- Animal CRUD: identification, category, sex, birth date, status
- Events per animal: vaccination, weight, breeding (with an optional pregnancy check result)
- Date estimates, always labeled as estimates in the response (calving and estrus are implemented; the weaning suggestion is not yet)
- WhatsApp reminders for upcoming events (the job and a log-only delivery adapter exist; no real provider is connected and the job is not scheduled yet)

**Out of scope**

- Financial management
- Multi-user, collaborators, roles
- Genealogy and pedigree tracking
- Hardware or IoT integration (scales, RFID, sensors)
- Compliance or legal features (CAR, tax documents)
- Sheep, goats, or any non-bovine species

## What the app does not do

The app records what the producer enters. It never suggests vaccination protocols, medication, target weights, or any other veterinary guidance. Vaccination schedules are entirely user-defined.

The date estimates are averages, not predictions:

| Estimate | Formula |
|---|---|
| Expected calving date | breeding date + 283 days |
| Next estrus estimate | breeding date + 21 days |
| Weaning suggestion | birth date + 6 months (not implemented yet) |

Each estimate is `nil` when its input date is missing. Responses that include an estimate carry a `disclaimer` field.

## Stack

- Ruby on Rails 8.1, API-only
- Ruby 4.0.1
- PostgreSQL
- Devise and devise-jwt for token authentication
- Solid Queue for background jobs
- RSpec and FactoryBot for tests

## Local setup

Requirements: Ruby 4.0.1 (see `.ruby-version`) and a running PostgreSQL.

```bash
bin/setup                # installs gems, prepares the database, starts the server
bin/setup --skip-server  # same, without starting the server
bundle exec rspec        # run the test suite
bundle exec rubocop      # lint
```

**Credentials.** A fresh clone has no `config/master.key`, and the committed `config/credentials.yml.enc` was encrypted with the author's key, so it cannot be decrypted. To run locally, replace it with your own:

```bash
rm config/credentials.yml.enc
bin/rails credentials:edit   # creates config/master.key and a new credentials file
```

In the editor, add a `devise_jwt_secret_key` entry (any long random string, for example the output of `bin/rails secret`). Never commit `config/master.key`.

`DEVISE_JWT_SECRET_KEY` takes precedence over the credentials. If it is set, the credentials are not read for the JWT secret; CI uses this to run the tests without the master key.

**`json` is pinned to `~> 2.7`.** With `json` 3.x, `ActiveSupport::JSON.decode` breaks on Rails 8.1 because of a change in the arity of `parse`, and JSON request bodies stop being parsed. Do not upgrade it until Rails supports it.

## Running the reminder job manually

`SendRemindersJob` is not scheduled yet, so run it by hand with a date window:

```bash
bin/rails runner 'SendRemindersJob.perform_now(Date.current, 7.days.from_now.to_date)'
```

It sends one message per user who has `whatsapp_opt_in` set and a `phone_number`, and only when something falls inside the window. The delivery adapter is `Notifications::Adapters::Log`, which writes the message to the Rails logger, so the output appears in `log/development.log`:

```bash
grep "Notifications::Adapters::Log" log/development.log
```

Each user is sent at most one reminder per exact window (`reminders_sent` has a unique index on user and window), so running the same window twice sends nothing the second time.

## API overview

All routes are under `/api/v1`. Every route except signup and login requires a JWT in the `Authorization: Bearer <token>` header. The token is returned in the `Authorization` response header on login. Users only see their own animals and events; another user's record returns `404`.

| Method | Path | Description |
|---|---|---|
| POST | `/signup` | Create a user |
| POST | `/login` | Authenticate and receive a token |
| DELETE | `/logout` | Revoke the current user's tokens |
| GET | `/animals` | List the user's animals |
| POST | `/animals` | Create an animal |
| GET | `/animals/:id` | Show an animal |
| PATCH/PUT | `/animals/:id` | Update an animal |
| DELETE | `/animals/:id` | Delete an animal (fails while it has events) |
| GET | `/animals/:animal_id/events` | List an animal's events, newest first |
| POST | `/animals/:animal_id/events` | Create an event for an animal |
| GET | `/events/:id` | Show an event |
| PATCH/PUT | `/events/:id` | Update an event |
| DELETE | `/events/:id` | Delete an event |

`GET /up` is the health check. Validation failures return `422` with an `errors` object.

## Architecture decisions

**String-backed enums.** Enums are stored as strings, not integers, so the database is readable when debugging and reordering values cannot silently change meaning.

**Hard delete with `restrict_with_error`.** Records are deleted for real, and an animal that still has events cannot be deleted (`422`). There is no soft delete because there is no requirement to recover or audit removed data, and a status field (`active`, `sold`, `deceased`) already covers animals that leave the herd.

**One `events` table with nullable type-specific columns.** Vaccination, weight, and breeding share one table; each type-specific column (`weight_kg`, `product_name`, `sire_identification`, `due_on`, the pregnancy check fields) is validated to be present where its type needs it (`due_on` and the check date stay optional) and rejected on the other types. Separate tables would mean three near-identical endpoints and a union query for the timeline, and `jsonb` would move the validations out of the schema for only three event types.

**`JTIMatcher` instead of a JWT denylist.** Each user has a `jti` column, and a token is valid only while its `jti` matches. There is no denylist table to grow or clean up. The tradeoff is that logging out rotates the `jti`, which invalidates the tokens of every device the user is logged in on, not just the current one.

**JWT secret resolution order.** The app reads `DEVISE_JWT_SECRET_KEY` first and falls back to `Rails.application.credentials.devise_jwt_secret_key!`, which raises if neither is set. CI and any future deployment can therefore run with an environment variable, without the master key being distributed.

**Calving estimates require a confirmed pregnancy check.** A calving date is returned only when the result is `confirmed`. A date computed from a breeding with no diagnosis is speculation and would trigger false reminders when a producer records several breedings without diagnosing any of them. The estrus estimate is `nil` only for `confirmed`, and it is kept for `negative`. The reminder scopes (`calving_due_between`, `estrus_due_between`) apply the same filtering in SQL as the Ruby methods, so the API and the reminders agree.

**Dashboard aggregation is left to the client.** The API has no herd summary endpoint. Herds at this scale are small enough for the client to count by category from the list endpoints, which keeps the API surface narrow.
