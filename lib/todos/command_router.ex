defmodule Todos.CommandRouter do
  use Commanded.Commands.Router

  alias Todos.Aggregates.Todo
  alias Todos.Commands.{CreateTodo, CompleteTodo, ReopenTodo}

  identify Todo, by: :todo_id

  dispatch CreateTodo, to: Todo
  dispatch CompleteTodo, to: Todo
  dispatch ReopenTodo, to: Todo
end
