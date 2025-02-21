defmodule DemoGen.Commands.SetClock do
  use DemoGen, command_name: "set_clock"

  @timex_options [:s, :m, :h, :D, :M, :Y]

  @impl DemoGen.Command
  def run(args, %{time: t} = context) when is_map(args) and is_map(context) do
    {:ok, Map.put(context, :time, set_time(t, args))}
  end

  def set_time(t, args) do
    Enum.reduce(@timex_options, t, fn opt, t ->
      set_time(t, opt, Map.get(args, opt))
    end)
  end

  def set_time(t, :s, nil), do: t
  def set_time(t, :s, {:number, s}), do: Timex.set(t, second: s)

  def set_time(t, :m, nil), do: t
  def set_time(t, :m, {:number, m}), do: Timex.set(t, minute: m)

  def set_time(t, :h, nil), do: t
  def set_time(t, :h, {:number, h}), do: Timex.set(t, hour: h)

  def set_time(t, :D, nil), do: t
  def set_time(t, :D, {:number, d}), do: Timex.set(t, day: d)

  def set_time(t, :M, nil), do: t
  def set_time(t, :M, {:number, m}), do: Timex.set(t, month: m)

  def set_time(t, :Y, nil), do: t
  def set_time(t, :Y, {:number, y}), do: Timex.set(t, year: y)
end
