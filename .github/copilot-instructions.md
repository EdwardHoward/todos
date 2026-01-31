# Todos - Event Sourced Phoenix App

This is a **Phoenix LiveView + Event Sourcing (CQRS)** todo application built with Commanded.

## Architecture Overview

This app uses **CQRS/Event Sourcing** via the Commanded library:

- **Commands** (`lib/todos/commands/`) - Write operations (CreateTodo, CompleteTodo, ReopenTodo)
- **Events** (`lib/todos/events/`) - Immutable facts that happened (TodoCreated, TodoCompleted, TodoReopened)
- **Aggregates** (`lib/todos/aggregates/`) - Business logic that validates commands and emits events
- **Projectors** (`lib/todos/projectors/`) - Build read models from events (writes to Postgres via Ecto)
- **Projections** (`lib/todos/projections/`) - Read-optimized Ecto schemas (separate from aggregates)

**Data Flow:**
1. LiveView dispatches command → `CommandedApp.dispatch(command)`
2. Command routes to Aggregate via `CommandRouter`
3. Aggregate validates & returns Event(s)
4. Event persists to EventStore (separate Postgres DB)
5. Projector subscribes to events & updates read model (Todos.Repo)
6. PubSub broadcasts update → LiveView refreshes UI

## Critical Setup Commands

```bash
# Initial setup (creates BOTH databases - read & event store)
mix deps.get
mix event_store.create -e Todos.EventStore  # Event store DB
mix event_store.init -e Todos.EventStore    # Event store schema
mix ecto.create                              # Read model DB
mix ecto.migrate                             # Read model migrations

# Development
mix phx.server

# When changing event store schema
mix event_store.drop -e Todos.EventStore
mix event_store.create -e Todos.EventStore
mix event_store.init -e Todos.EventStore
```

**Two databases are required:**
- `todos_eventstore_dev` - EventStore for immutable event log
- `todos_dev` - Postgres for read models (projections)

## Project-Specific Patterns

### Adding New Features (Event Sourced)

When adding a new command/event flow:

1. **Define Command** in `lib/todos/commands/my_command.ex`
2. **Define Event** in `lib/todos/events/my_event.ex`
3. **Update Aggregate** `lib/todos/aggregates/todo.ex`:
   - Add `execute/2` clause for command → event
   - Add `apply/2` clause for event → state update
4. **Register in Router** `lib/todos/command_router.ex`
5. **Update Projector** `lib/todos/projectors/todo_projector.ex` to handle event
6. **Dispatch from LiveView** via `CommandedApp.dispatch(command)`

### Authentication & Routing

- **Auth system uses `current_scope` NOT `current_user`**
- Access user in templates/LiveViews: `@current_scope.user`
- Routes requiring auth go in `:require_authenticated_user` live_session
- Always pass `current_scope={@current_scope}` to `<Layouts.app>`

### LiveView Conventions

- **Always** start templates with: `<Layouts.app flash={@flash} current_scope={@current_scope}>`
- Subscribe to PubSub in mount: `Phoenix.PubSub.subscribe(Todos.PubSub, "todos")`
- Handle projection updates via `handle_info(:todos_updated, socket)`
- Use pattern matching for `current_scope.user` in handle_event:
  ```elixir
  def handle_event("create", params, %{assigns: %{current_scope: %{user: %{id: user_id}}}} = socket)
  ```

### UUIDs & Database Types

- Todo IDs are UUIDs (`:binary_id` in migrations)
- User IDs in todos are also `:binary_id` (not FK to users table)
- Generate with `Commanded.UUID.uuid4()`
- EventStore handles UUID serialization automatically

### Common Gotchas

1. **Missing EventStore setup** - If you see `DBConnection.EncodeError`, run `mix event_store.init`
2. **Projector not registered** - Must be in supervision tree (`application.ex`)
3. **PubSub not broadcasting** - Check projector's PubSub broadcast in project functions
4. **current_scope errors** - Ensure route is in correct `live_session` scope

## Key Files

- `lib/todos/application.ex` - Supervision tree (CommandedApp, Projector, PubSub)
- `lib/todos/commanded_app.ex` - Commanded application config
- `lib/todos/command_router.ex` - Routes commands to aggregates
- `lib/todos_web/live/todo_live/index.ex` - Main LiveView
- `config/dev.exs` - EventStore & Repo database configs

## Testing Event Sourced Features

When testing command/event flows, verify:
- Command validation in aggregate tests
- Event emission from aggregate.execute/2
- State updates from aggregate.apply/2
- Projection updates from projector
- LiveView integration via `Phoenix.LiveViewTest`

For more Phoenix/LiveView conventions, see `AGENTS.md`.
