# Todos

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies (deps.get, ecto.setup, event_store.setup, assets.setup, assets.build)

* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

You can create a user account by clicking "Sign up" on the home page. Use the mailbox at (http://localhost:4000/dev/mailbox) to confirm the account.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

* Official website: https://www.phoenixframework.org/
* Guides: https://hexdocs.pm/phoenix/overview.html
* Docs: https://hexdocs.pm/phoenix
* Forum: https://elixirforum.com/c/phoenix-forum
* Source: https://github.com/phoenixframework/phoenix


mix deps.get
mix event_store.setup
mix ecto.setup

## Commanded
Commanded is a CQRS/ES framework for Elixir.
* Docs: https://hexdocs.pm/commanded

**Commands** - represent the intent to perform an action. They are sent to aggregates to request state changes. (lib/todos/commands)
  * CreateTodo - create a new todo item.
  * CompleteTodo - mark a todo item as completed.
  * ReopenTodo - reopen a completed todo item.
  * UnlockAchievement - unlock an achievement for a user.

**Events** - represent state changes that have occurred in the system. They are stored in the event store and can be used to reconstruct the state of aggregates. (lib/todos/events)
  * TodoCreated - a new todo item has been created.
  * TodoCompleted - a todo item has been marked as completed.
  * TodoReopened - a completed todo item has been reopened.
  * AchievementUnlocked - an achievement has been unlocked for a user.

**Aggregates** - are the core building blocks of a CQRS/ES system. They encapsulate business logic and handle commands to produce events. Aggregates validate state changes and enforce invariants. (e.g. if a todo is already completed, it cannot be completed again) (lib/todos/aggregates)
  * Todo
  * Achievement

**Projectors** - are Ecto schema modules that represent read models in the database. (lib/todos/projectors)
  * Todo
  * Achievement

**Projections** - are used to create read models from events. They listen to events and update the read models accordingly.(lib/todos/projections)
  * TodoProjection
  * AchievementProjection

**Process Managers** - are used to manage long-running business processes that span multiple aggregates. They listen to events and send commands to aggregates as needed. (lib/todos/process_managers)
  * AchievementProcessManager - listens for TodoCompleted events and sends UnlockAchievement commands when certain criteria are met.