defmodule Pleroma.Web.AdminControl.AdminControlController do
  use Pleroma.Web, :controller

  @descriptions Pleroma.Docs.JSON.compiled_descriptions()

  plug(:put_root_layout, {Pleroma.Web.AdminControl.AdminControlView, :layout})
  plug(:put_layout, false)

  defp label_for(%{label: label}), do: label
  defp label_for(_), do: "Unknown"

  def config_headings do
    @descriptions
    |> Enum.map(&label_for(&1))
    |> Enum.sort()
  end

  def config_values(%{"heading" => heading}) do
    IO.inspect(heading)

    possible_values =
      @descriptions
      |> Enum.filter(fn section -> label_for(section) == heading end)

    possible_values
  end

  def config_values(_), do: []

  def index(conn, params) do
    IO.inspect(params)
    render(conn, :index, config_values: config_values(params), config_headings: config_headings())
  end
end
