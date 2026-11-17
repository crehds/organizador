# Organizador

A task organizer built with Ruby on Rails. It started as the project of two Platzi courses (basic and intermediate Rails) and was later upgraded to Rails 8.1, covered with tests, and deployed on Railway.

**Try it:** press "Probar el demo" on the live app. It creates a temporary account of your own with sample data and signs you in; the account and its data are deleted after 24 hours.

## Features

- Tasks with a category, a due date, an owner, and participants with a role (responsible or follower), edited with nested forms.
- Notes on a task, added without a page reload (Turbo Streams).
- Permissions with CanCanCan: owners manage their tasks, participants can read them, everyone else is kept out.
- Sign in with Devise. There is no public sign-up: accounts are created from the terminal. The demo adds a one-click button that gives each visitor a temporary account of their own.
- Dates and framework messages follow the browser language (Spanish or English).
- Demo visitor accounts that are deleted after 24 hours, and a manual demo reset.

## Two installations: the demo and a private one

The same code runs the public demo and private installations with real data, each with its own database. The `DEMO_MODE` variable tells them apart:

| | `DEMO_MODE=true` (demo) | Any other value (private) |
|---|---|---|
| Sign-in page at `/` | A notice that the visitor's account is temporary, one line about the app, and the "Probar el demo" button; no sign-in form | The sign-in form only, in Spanish |
| "Probar el demo" (`POST /test`) | Creates a temporary visitor account with its own sample data and signs it in; `GET /test` goes to the sign-in page | Both answer like a route that does not exist |
| Demo banner | Shown to visitors | Not shown |
| Categories | Each user sees and uses only their own | Shared by every user |
| Task participants | Only the fictitious teammates, never another visitor | Any other user |
| Password sign-in (`POST /users/sign_in`) | Answers like a missing route, so accounts left from an older demo with the public seed password cannot be used | Devise's sign-in |
| Account page (`/users/edit`) | Locked for every account: visitors never know their random password | Each user changes their own password |
| `db:seed` and `db:prepare` | Create the fictitious teammates with random passwords | Print one line and create nothing, so a new database stays empty |
| Demo reset (`demo:reset`, `POST /demo/reset`) | Deletes everything and reloads the teammates | `demo:reset` aborts, the endpoint answers like a missing route, nothing is deleted |

When `DEMO_MODE` is unset, it is off in production and on in development and test.

### Creating accounts

Accounts are created from the terminal, in either mode:

```sh
bin/rails users:create EMAIL=someone@example.com
```

It prints the email and a random 16-character password once. It stops with a message and a non-zero exit when `EMAIL` is missing, invalid, or already taken.

No page offers sign-up, in either mode.

### The account page

Signed-in users change their password at `/users/edit`, confirming it with the current one. That is all the page does: email changes are ignored, accounts cannot be cancelled, and there is no "forgot password", because production sends no mail. In demo mode nobody can open it: visitors never know their random password.

## Stack

Ruby 3.4.12 · Rails 8.1.4.1 · PostgreSQL · Hotwire (Turbo and Stimulus) · esbuild and Sass with Bootstrap 5 · Sprockets · HAML · Simple Form · Devise · CanCanCan · Minitest

## What changed after the courses

- Upgraded from Rails 7.0.4 to 8.1.4.1 one version at a time, and from Ruby 3.1 to 3.4.12, with the test suite green at every step.
- Added an integration test suite for sign-in, the demo login, tasks, permissions, categories, and notes.
- Fixed bugs: a shell command run from a view, tasks and categories that could not be deleted, delete and sign-out links that Turbo ignored, notes that any signed-in user could add to any task, and a crash on unsupported browser languages.
- Added the demo reset and protected the demo account.
- Split the app into a public demo and private installations (`DEMO_MODE`), and replaced public sign-up with accounts created from the terminal.
- Gave each demo visitor a temporary account of their own, isolated from other visitors, in place of one shared account.

## Run it locally

Requirements: Ruby 3.4.12, Node with Yarn, and PostgreSQL with its client headers (`libpq-dev` on Ubuntu). `config/database.yml` connects through the local socket as your system user.

```sh
bundle install
yarn install
bin/rails db:prepare   # creates the databases and loads the demo data (DEMO_MODE defaults to true here)
bin/dev                # Rails plus the CSS and JS watchers, on http://localhost:3000
```

Development and tests do not need `config/master.key`; production reads it from `RAILS_MASTER_KEY`.

## Tests

```sh
bin/rails test
```

Fixtures avoid foreign keys, so the database role does not need to be a PostgreSQL superuser.

## Demo visitor accounts

"Probar el demo" creates an account with a random email and password, which nobody sees, copies the sample categories and tasks into it, and signs the visitor in. The tasks' participants are fictitious teammates from `db/seeds.rb`, whose passwords are random too, so nobody can sign in as them. Signing out or closing the browser ends the visit: the account cannot be opened again.

Each press first deletes visitor accounts older than 24 hours with their categories, tasks, participations and notes, so the demo cleans itself without a scheduled job. One address can create 10 accounts per hour.

## Demo reset

Only in demo mode, both commands delete all data, visitor accounts included, and reload `db/seeds.rb` (the teammates) in one transaction:

- `bin/rails demo:reset`
- `POST /demo/reset` with the header `Authorization: Bearer <DEMO_RESET_TOKEN>`. When `DEMO_RESET_TOKEN` is not set, the route answers like any route that does not exist.

## Deploy the demo on Railway

Railway builds the app with Railpack, which detects Rails, installs the Node packages, and runs `assets:precompile`.

1. Create a project from this GitHub repository and add a PostgreSQL service.
2. Set these variables on the web service:
   - `RAILS_ENV` = `production`
   - `RAILS_MASTER_KEY` = the contents of `config/master.key`
   - `DATABASE_URL` = `${{Postgres.DATABASE_URL}}`
   - `DEMO_MODE` = `true`. Set it on the demo service before deploying a version that reads it: without it, production runs as a private installation and the live demo loses `/test`.
   - `DEMO_RESET_TOKEN` = a long random value, for example from `openssl rand -hex 32`
3. In the service settings, set the pre-deploy command to `bin/rails db:prepare demo:reset` and the health check path to `/up`. Every deploy then starts the demo clean, before the new version takes traffic: the teammates get new random passwords and the visitor accounts are deleted. This also matters when you upgrade an older demo whose accounts still have the public password "123456". Use this command only on the demo service: outside demo mode `demo:reset` aborts, and the deploy fails.
4. Generate a public domain.
5. To restart the demo between deploys, call the reset endpoint:

   ```sh
   curl -X POST https://<your-domain>/demo/reset -H "Authorization: Bearer <DEMO_RESET_TOKEN>"
   ```

## Deploy a private installation on Railway

A private installation runs the same code with its own database and sleeps when nobody uses it.

1. Add a second web service from this repository, in a new environment or project, with its own PostgreSQL service. Never point it at the demo's database.
2. Set `RAILS_ENV`, `RAILS_MASTER_KEY`, and `DATABASE_URL` (the new PostgreSQL) as for the demo. Leave `DEMO_MODE` and `DEMO_RESET_TOKEN` unset.
3. Set the pre-deploy command to `bin/rails db:prepare`, which creates the tables and no data, and the health check path to `/up`.
4. Turn on Serverless in the service settings. The service sleeps several minutes after its last request, and the first request after that can be slow or fail once.
5. Create the first account from a shell on the service, then sign in with the printed password and change it at `/users/edit`:

   ```sh
   railway ssh
   bin/rails users:create EMAIL=you@example.com
   ```
