defmodule Pleroma.Web.AdminControl.AdminControlView do
  use Pleroma.Web, :html
  require Logger

  embed_templates "admin_control_html/*"

  defp atomize(":" <> key), do: String.to_existing_atom(key)

  defp value_of(%{config_value: %{key: child_key}, parent_key: parent_key}) when is_binary(parent_key) do

    parent_atom = atomize(parent_key)
    child_atom = atomize(child_key)
    Pleroma.Config.get([parent_atom, child_atom])
    |> to_string()
  end

  attr :config_value, :map, required: true
  attr :parent_key, :string, required: false
  def config_value(%{config_value: %{type: :group} = value} = assigns) do
    ~H"""
    <div class="config-group">
      <h3 class="config-group-title text-2xl"><%= @config_value.label %></h3>
      <p class="ml-2"><%= @config_value.description %></p>
      <div class="ml-3">
        <%= for child_value <- @config_value.children do %>
          <.config_value config_value={child_value} parent_key={@config_value.key} />
        <% end %>
      </div>
    </div>
    """
  end

  def config_value(%{config_value: %{type: :integer, key: key} = value} = assigns) do
    value = value_of(assigns)
    assigns = assign(assigns, value: value, key: key)

    ~H"""
    <div>
      <label for={@key} class="block text-sm font-medium leading-6 text-white"><%= @config_value.label %></label>
      <div class="mt-2">
        <input type="number" name={@key} id={@key} value={@value} class="block w-full rounded-md border-0 bg-white/5 py-1.5 text-white shadow-sm ring-1 ring-inset ring-white/10 focus:ring-2 focus:ring-inset focus:ring-indigo-500 sm:text-sm sm:leading-6">
      </div>
      <p class="mt-2 text-sm text-gray-500"><%= @config_value.description %></p>
    </div>
    """
  end


  def config_value(%{config_value: %{type: :string, key: key} = value} = assigns) do
    value = value_of(assigns)
    assigns = assign(assigns, value: value, key: key)
    ~H"""
    <div>
      <label for={@key} class="block text-sm font-medium leading-6 text-white"><%= @config_value.label %></label>
      <div class="mt-2">
        <input type="text" name={@key} id={@key} value={@value} class="block w-full rounded-md border-0 bg-white/5 py-1.5 text-white shadow-sm ring-1 ring-inset ring-white/10 focus:ring-2 focus:ring-inset focus:ring-indigo-500 sm:text-sm sm:leading-6">
      </div>
      <p class="mt-2 text-sm text-gray-500"><%= @config_value.description %></p>
    </div>
    """
  end

  def config_value(%{config_value: %{type: :boolean, key: key} = value} = assigns) do
    value = value_of(assigns) == "true"
    assigns = assign(assigns, value: value, key: key)
    ~H"""
    <div>
      <label for={@key} class="block text-sm font-medium leading-6 text-white"><%= @config_value.label %></label>

      <div class="mt-2">

        <p class="mt-2 text-sm text-gray-500"><input type="checkbox" name={@key} id={@key} checked={@value} class="rounded-md px-2"> <%= @config_value.description %></p>

      </div>
    </div>
    """
  end
  def config_value(%{config_value: %{type: {:list, :string}} = value} = assigns) do
    value = value_of(assigns)
    assigns = assign(assigns, value: value)
    ~H"""
    <div class="config-group">
      <h3 class="config-group-title"><%= @config_value.label %></h3>
      <span class="ml-2"><%= @config_value.description %></span>
      <%= @value %>
    </div>
    """
  end

  def config_value(assigns) do
    Logger.info("Cannot render config!")
    IO.inspect(assigns)
    ~H"""
    Cannot render
    """
  end

  attr :config_values, :list, required: true
  def config_values(%{config_values: config_values} = assigns) do
    ~H"""
    <div class="config-values text-white">
      <%= for value <- @config_values do %>
        <.config_value config_value={value} />
      <% end %>
    </div>
    """
  end
end
