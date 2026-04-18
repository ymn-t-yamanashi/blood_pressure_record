defmodule BloodPressureRecordWeb.SharedFormatting do
  @moduledoc false

  def format_date(%Date{} = date), do: Calendar.strftime(date, "%Y/%m/%d")

  def format_datetime(%NaiveDateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y/%m/%d %H:%M")
end
