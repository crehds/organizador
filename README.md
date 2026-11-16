# Organizador

A task organizer built with Ruby on Rails. It started as the project of two Platzi courses (basic and intermediate Rails) and was later upgraded to Rails 8.1, covered with tests, and deployed on Railway.

**Try it:** open `/test` on the live app to sign in as the demo user, no password needed.

## Features

- Tasks with a category, a due date, an owner, and participants with a role (responsible or follower), edited with nested forms.
- Notes on a task, added without a page reload (Turbo Streams).
- Permissions with CanCanCan: owners manage their tasks, participants can read them, everyone else is kept out.
- Sign up and sign in with Devise, plus a one-click demo login at `/test`.
- Dates and framework messages follow the browser language (Spanish or English).
- A demo reset that removes what visitors leave behind and reloads the demo data.

## Stack

Ruby 3.4.12 · Rails 8.1.4.1 · PostgreSQL · Hotwire (Turbo and Stimulus) · esbuild and Sass with Bootstrap 5 · Sprockets · HAML · Simple Form · Devise · CanCanCan · Minitest

## What changed after the courses

- Upgraded from Rails 7.0.4 to 8.1.4.1 one version at a time, and from Ruby 3.1 to 3.4.12, with the test suite green at every step.
- Added an integration test suite for sign-in, the demo login, tasks, permissions, categories, and notes.
- Fixed bugs: a shell command run from a view, tasks and categories that could not be deleted, delete and sign-out links that Turbo ignored, notes that any signed-in user could add to any task, and a crash on unsupported browser languages.
- Added the demo reset and protected the demo account.

## Run it locally

Requirements: Ruby 3.4.12, Node with Yarn, and PostgreSQL with its client headers (`libpq-dev` on Ubuntu). `config/database.yml` connects through the local socket as your system user.

```sh
bundle install
yarn install
bin/rails db:prepare   # creates the databases and loads the demo data
bin/dev                # Rails plus the CSS and JS watchers, on http://localhost:3000
```

Development and tests do not need `config/master.key`; production reads it from `RAILS_MASTER_KEY`.

## Tests

```sh
bin/rails test
```

Fixtures avoid foreign keys, so the database role does not need to be a PostgreSQL superuser.

## Demo reset

Both commands delete all data, visitor accounts included, and reload `db/seeds.rb` in one transaction:

- `bin/rails demo:reset`
- `POST /demo/reset` with the header `Authorization: Bearer <DEMO_RESET_TOKEN>`. When `DEMO_RESET_TOKEN` is not set, the route answers like any route that does not exist.

The demo account (`johan@tasker.com`) cannot be edited or cancelled, so `/test` keeps working.

## Deploy on Railway

Railway builds the app with Railpack, which detects Rails, installs the Node packages, and runs `assets:precompile`.

1. Create a project from this GitHub repository and add a PostgreSQL service.
2. Set these variables on the web service:
   - `RAILS_ENV` = `production`
   - `RAILS_MASTER_KEY` = the contents of `config/master.key`
   - `DATABASE_URL` = `${{Postgres.DATABASE_URL}}`
   - `DEMO_RESET_TOKEN` = a long random value, for example from `openssl rand -hex 32`
3. In the service settings, set the pre-deploy command to `bin/rails db:prepare` and the health check path to `/up`.
4. Generate a public domain.
5. Load the demo data once:

   ```sh
   curl -X POST https://<your-domain>/demo/reset -H "Authorization: Bearer <DEMO_RESET_TOKEN>"
   ```
