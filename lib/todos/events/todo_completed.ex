defmodule Todos.Events.TodoCompleted do
  @derive [Jason.Encoder]

  defstruct [
    :todo_id,
    :user_id
  ]
end
