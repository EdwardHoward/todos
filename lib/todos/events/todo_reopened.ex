defmodule Todos.Events.TodoReopened do
  @derive Jason.Encoder

  defstruct [:todo_id]
end
