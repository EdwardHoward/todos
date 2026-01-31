defmodule Todos.Commands.CreateTodo do
  @type t() :: %__MODULE__{
          todo_id: String.t(),
          user_id: String.t(),
          content: String.t()
        }

  defstruct [
    :todo_id,
    :user_id,
    :content
  ]
end
