defmodule Todos.Commands.CompleteTodo do
  @type t() :: %__MODULE__{
          todo_id: String.t()
        }

  defstruct [
    :todo_id
  ]
end
