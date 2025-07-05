defmodule TaskEntry do
  @derive [Jason.Encoder]
  defstruct [:id, :description, :priority, :due_date, :completed]
end
