defmodule Todos.Aggregates.Achievement do
  defstruct [:achievement_id, :user_id, :achievement_type, :unlocked_at]

  alias Todos.Commands.UnlockAchievement
  alias Todos.Events.AchievementUnlocked

  # Execute: unlock a new achievement
  def execute(%__MODULE__{achievement_id: nil}, %UnlockAchievement{} = cmd) do
    %AchievementUnlocked{
      achievement_id: cmd.achievement_id,
      user_id: cmd.user_id,
      achievement_type: cmd.achievement_type,
      title: cmd.title,
      description: cmd.description,
      unlocked_at: DateTime.utc_now()
    }
  end

  # Prevent unlocking the same achievement twice
  def execute(%__MODULE__{}, %UnlockAchievement{}) do
    {:error, :already_unlocked}
  end

  # Apply: update aggregate state from event
  def apply(%__MODULE__{} = state, %AchievementUnlocked{} = event) do
    %{state |
      achievement_id: event.achievement_id,
      user_id: event.user_id,
      achievement_type: event.achievement_type,
      unlocked_at: event.unlocked_at
    }
  end
end
