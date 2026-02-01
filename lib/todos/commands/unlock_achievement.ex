defmodule Todos.Commands.UnlockAchievement do
  @enforce_keys [:achievement_id, :user_id, :achievement_type, :title, :description]
  defstruct [:achievement_id, :user_id, :achievement_type, :title, :description]
end
