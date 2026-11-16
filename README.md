# Organizador

A task organizer built with Ruby on Rails. It started as the project of two Platzi courses (basic and intermediate Rails) and was later upgraded to Rails 8.1, covered with tests, and deployed on Railway.

**Try it:** open `/test` on the live app to sign in as the demo user, no password needed.

## Features

- Tasks with a category, a due date, an owner, and participants with a role (responsible or follower), edited with nested forms.
- Notes on a task, added without a page reload (Turbo Streams).
- Permissions with CanCanCan: owners manage their tasks, participants can read them, everyone else is kept out.
- Sign in with Devise. There is no public sign-up: accounts are created from the terminal. The demo adds a one-click login at `/test`.
- Dates and framework messages follow the browser language (Spanish or English).
- A demo reset that removes what visitors leave behind and reloads the demo data.

## Two installations: the demo and a private one

The same code runs the public demo and private installations with real data, each with its own database. The `DEMO_MODE` variable tells them apart:

| | `DEMO_MODE=true` (demo) | Any other value (private) |
|---|---|---|
| Landing page | "Probar el demo" and "Iniciar sesión" | "Iniciar sesión" only |
| `/test` one-click demo login | Signs visitors in as the shared demo account | Answers like a route that does not exist |
| Demo banner | Shown for `johan@tasker.com` | Not shown |
| Account page (`/users/edit`) | Locked for every account, because the seeded passwords are public | Each user changes their own password |
| `db:seed` and `db:prepare` | Load the demo data | Print one line and create nothing, so a new database stays empty |
| Demo reset (`demo:reset`, `POST /demo/reset`) | Deletes everything and reloads the demo data | `demo:reset` aborts, the endpoint answers like a missing route, nothing is deleted |

When `DEMO_MODE` is unset, it is off in production and on in development and test.

### Creating accounts

Accounts are created from the terminal, in either mode:

```sh
bin/rails users:create EMAIL=someone@example.com
```

It prints the email and a random 16-character password once. It stops with a message and a non-zero exit when `EMAIL` is missing, invalid, or already taken.

No page offers sign-up, in either mode.

### The account page

Signed-in users change their password at `/users/edit`, confirming it with the current one. That is all the page does: email changes are ignored, accounts cannot be cancelled, and there is no "forgot password", because production sends no mail. In demo mode nobody can open it: every account comes from `db/seeds.rb` with a public password.

## Stack

Ruby 3.4.12 · Rails 8.1.4.1 · PostgreSQL · Hotwire (Turbo and Stimulus) · esbuild and Sass with Bootstrap 5 · Sprockets · HAML · Simple Form · Devise · CanCanCan · Minitest

## What changed after the courses

- Upgraded from Rails 7.0.4 to 8.1.4.1 one version at a time, and from Ruby 3.1 to 3.4.12, with the test suite green at every step.
- Added an integration test suite for sign-in, the demo login, tasks, permissions, categories, and notes.
- Fixed bugs: a shell command run from a view, tasks and categories that could not be deleted, delete and sign-out links that Turbo ignored, notes that any signed-in user could add to any task, and a crash on unsupported browser languages.
- Added the demo reset and protected the demo account.
- Split the app into a public demo and private installations (`DEMO_MODE`), and replaced public sign-up with accounts created from the terminal.

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

## Demo reset

Only in demo mode, both commands delete all data, visitor accounts included, and reload `db/seeds.rb` in one transaction:

- `bin/rails demo:reset`
- `POST /demo/reset` with the header `Authorization: Bearer <DEMO_RESET_TOKEN>`. When `DEMO_RESET_TOKEN` is not set, the route answers like any route that does not exist.

No account can change its password in demo mode, so `/test` and the seeded users keep working for every visitor.

## Deploy the demo on Railway

Railway builds the app with Railpack, which detects Rails, installs the Node packages, and runs `assets:precompile`.

1. Create a project from this GitHub repository and add a PostgreSQL service.
2. Set these variables on the web service:
   - `RAILS_ENV` = `production`
   - `RAILS_MASTER_KEY` = the contents of `config/master.key`
   - `DATABASE_URL` = `${{Postgres.DATABASE_URL}}`
   - `DEMO_MODE` = `true`. Set it on the demo service before deploying a version that reads it: without it, production runs as a private installation and the live demo loses `/test`.
   - `DEMO_RESET_TOKEN` = a long random value, for example from `openssl rand -hex 32`
3. In the service settings, set the pre-deploy command to `bin/rails db:prepare` and the health check path to `/up`.
4. Generate a public domain.
5. Load the demo data once:

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
