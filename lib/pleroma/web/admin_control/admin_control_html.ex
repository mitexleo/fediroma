defmodule Pleroma.Web.AdminControl.AdminControlView do
  use Pleroma.Web, :html

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

  def config_value(%{config_value: %{type: :integer} = value} = assigns) do
    value = value_of(assigns)
    assigns = assign(assigns, value: value)

    ~H"""
    <div class="config-group">
      <h3 class="config-group-title"><%= @config_value.label %></h3>
      <p class="ml-2"><%= @config_value.description %></p>
      <input type="number" value={@value} class="form-input text-black rounded" />
    </div>
    """
  end


  def config_value(%{config_value: %{type: :boolean} = value} = assigns) do
    value = value_of(assigns) == "true"
    assigns = assign(assigns, value: value)
    ~H"""
    <div class="config-group">
      <h3 class="config-group-title"><%= @config_value.label %></h3>
      <span class="ml-2"><%= @config_value.description %></span>
      <input type="checkbox" checked={@value} class="form-input" />
    </div>
    """
  end

  def config_value(assigns) do
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
