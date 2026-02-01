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

## Process Manager Patterns

Process managers coordinate long-running business processes across multiple aggregates. They listen to events and dispatch commands to orchestrate sagas.

### Event Routing with `interested?/1`

The `interested?/1` callback determines which events this process manager handles:

- `{:start!, instance_uuid}` - Start new process manager instance
- `{:continue!, instance_uuid}` - Route to existing instance
- `{:stop, instance_uuid}` - Stop instance after handling event
- `false` - Ignore this event

```elixir
def interested?(%TodoCompleted{user_id: user_id}), do: {:start!, user_id}
def interested?(%AchievementUnlocked{user_id: user_id}), do: {:continue!, user_id}
def interested?(_event), do: false
```

### State Management with `handle/2`

The `handle/2` callback processes events and optionally dispatches commands:

**Return Values:**
- `commands` - Single command or list of commands to dispatch
- `{commands, new_state}` - Commands with explicit state update
- `new_state` - Only update state, no commands
- **NEVER** return `{[], new_state}` - Empty list causes "unregistered command" error

```elixir
# Pattern 1: Dispatch commands with state update
def handle(%__MODULE__{} = state, %TodoCompleted{}) do
  new_state = %{state | completed_count: state.completed_count + 1}
  
  case check_achievements(new_state) do
    [] -> new_state  # No commands, return state only
    commands -> {commands, new_state}  # Return commands with state
  end
end

# Pattern 2: Only update state (no commands)
def handle(%__MODULE__{} = state, %AchievementUnlocked{achievement_type: type}) do
  %{state | unlocked: [type | state.unlocked]}
end
```

### State Updates with `apply/2`

The `apply/2` callback updates process manager state from events. If omitted, state doesn't change:

```elixir
def apply(%__MODULE__{} = state, %TodoCompleted{}) do
  %{state | completed_count: state.completed_count + 1}
end
```

### Error Handling with `error/3`

The `error/3` callback handles command dispatch failures:

- `:retry` - Retry immediately with same context
- `{:retry, delay_ms, context}` - Retry after delay with updated context
- `{:stop, reason}` - Stop process manager (will restart if supervised)
- `:skip` - Ignore error and continue

```elixir
def error({:error, :validation_failed}, _failed_command, _failure_context) do
  :skip  # Skip validation errors, continue process
end

def error({:error, :timeout}, failed_command, %{attempts: attempts} = context) when attempts < 3 do
  {:retry, 1000, %{context | attempts: attempts + 1}}
end

def error(error, _command, _context) do
  {:stop, error}  # Stop on unknown errors
end
```

**Critical:** Default error handling returns `:stop`, which can cause restart loops if supervisor strategy is `:restart`. Consider implementing custom error/3 for production.

### Common Pitfalls

1. **Empty Command Lists**: Never return `{[], state}` from `handle/2`. Return `state` instead.
2. **Missing interested?/1**: All events return `false` by default. Must explicitly route.
3. **Restart Loops**: Default `:stop` on errors + supervisor `:restart` = infinite loop.
4. **State Mutations**: Use `apply/2` for event-driven state changes, `handle/2` for command-driven logic.

## Testing Event Sourced Features

When testing command/event flows, verify:
- Command validation in aggregate tests
- Event emission from aggregate.execute/2
- State updates from aggregate.apply/2
- Projection updates from projector
- LiveView integration via `Phoenix.LiveViewTest`

For more Phoenix/LiveView conventions, see `AGENTS.md`.
