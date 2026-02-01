defmodule Todos.CommandRouter do
  use Commanded.Commands.Router

  alias Todos.Aggregates.{Todo, Achievement}
  alias Todos.Commands.{CreateTodo, CompleteTodo, ReopenTodo, UnlockAchievement}

  identify Todo, by: :todo_id

  dispatch CreateTodo, to: Todo
  dispatch CompleteTodo, to: Todo
  dispatch ReopenTodo, to: Todo

  identify Achievement, by: :achievement_id

  dispatch UnlockAchievement, to: Achievement
end
