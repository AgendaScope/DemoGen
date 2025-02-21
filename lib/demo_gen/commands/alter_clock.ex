defmodule DemoGen.Commands.AlterClock do
  use DemoGen, command_name: "alter_clock"

  @timex_options [:s, :m, :h, :D, :M, :Y]

  @impl DemoGen.Command
  def run(args, context) when is_map(args) and is_map(context) do
    t = Map.get(context, :time, DateTime.utc_now())
    {:ok, Map.put(context, :time, adjust_time(t, args))}
  end

  def adjust_time(t, args) do
    Enum.reduce(@timex_options, t, fn opt, t ->
      adjust_time(t, opt, Map.get(args, opt))
    end)
  end

  def adjust_time(t, :s, nil), do: t
  def adjust_time(t, :s, {:number, s}), do: Timex.shift(t, seconds: s)

  def adjust_time(t, :m, nil), do: t
  def adjust_time(t, :m, {:number, m}), do: Timex.shift(t, minutes: m)

  def adjust_time(t, :h, nil), do: t
  def adjust_time(t, :h, {:number, h}), do: Timex.shift(t, hours: h)

  def adjust_time(t, :D, nil), do: t
  def adjust_time(t, :D, {:number, d}), do: Timex.shift(t, days: d)

  def adjust_time(t, :M, nil), do: t
  def adjust_time(t, :M, {:number, m}), do: Timex.shift(t, months: m)

  def adjust_time(t, :Y, nil), do: t
  def adjust_time(t, :Y, {:number, y}), do: Timex.shift(t, years: y)
end
