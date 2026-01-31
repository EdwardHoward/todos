defmodule Todos.CommandedApp do
  use Commanded.Application,
    otp_app: :todos,
    event_store: [
      adapter: Commanded.EventStore.Adapters.EventStore,
      event_store: Todos.EventStore
    ],
    pubsub: :local,
    registry: :local

  router(Todos.CommandRouter)
end
