defmodule Todos.Projectors.AchievementProjector do
  use Commanded.Projections.Ecto,
    application: Todos.CommandedApp,
    repo: Todos.Repo,
    name: "AchievementProjector",
    consistency: :strong

  alias Todos.Events.AchievementUnlocked
  alias Todos.Projections.Achievement

  project(%AchievementUnlocked{} = event, _metadata, fn multi ->
    {:ok, unlocked_at, _} = DateTime.from_iso8601(event.unlocked_at)

    Ecto.Multi.insert(
      multi,
      :achievement,
      %Achievement{
        id: event.achievement_id,
        user_id: event.user_id,
        achievement_type: event.achievement_type,
        title: event.title,
        description: event.description,
        unlocked_at: DateTime.truncate(unlocked_at, :second)
      }
    )
  end)

  @impl Commanded.Projections.Ecto
  def after_update(%AchievementUnlocked{user_id: user_id} = event, _metadata, _changes) do
    Phoenix.PubSub.broadcast(
      Todos.PubSub,
      "achievements:#{user_id}",
      {:achievement_unlocked, event}
    )

    :ok
  end
end
