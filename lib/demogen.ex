defmodule DemoGen do
  defmacro __using__(opts) do
    quote do
      @behaviour DemoGen.Command

      # Get command name from options
      @demogen_command_name Keyword.fetch!(unquote(opts), :command_name)

      def demogen_command_name, do: @demogen_command_name
    end
  end
end
