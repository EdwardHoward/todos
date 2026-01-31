defmodule Todos.Events.TodoCreated do
  @derive [Jason.Encoder]

  defstruct [
    :todo_id,
    :user_id,
    :content
  ]
end
