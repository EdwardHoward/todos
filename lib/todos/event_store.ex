defmodule Todos.EventStore do
  use EventStore, otp_app: :todos

  def init(config) do
    {:ok, config}
  end
end
