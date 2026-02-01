defmodule Todos.Events.AchievementUnlocked do
  @derive Jason.Encoder
  defstruct [
    :achievement_id,
    :user_id,
    :achievement_type,
    :title,
    :description,
    :unlocked_at
  ]
end
