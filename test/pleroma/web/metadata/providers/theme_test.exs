# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.Metadata.Providers.OpenGraphTest do
  use Pleroma.DataCase
  alias Pleroma.Web.Metadata.Providers.Theme

  setup do: clear_config([Pleroma.Web.Metadata.Providers.Theme, :theme_color], "configured")

  test "it renders the theme-color meta tag" do
    result = Theme.build_tags(%{})

    assert {:meta, [name: "theme-color", content: "configured"], []} in result
  end
end
