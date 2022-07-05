# Pleroma: A lightweight social networking server
# Copyright © 2017-2022 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Pleroma.Web.ActivityPub.MRF.UnlistUndescribedMedia do
  alias Pleroma.User
  @moduledoc "Unlists posts with media that does not have a description, written by foxes@myfriendsare.gay"
  @behaviour Pleroma.Web.ActivityPub.MRF.Policy

  require Pleroma.Constants

  defp check_media(%{"attachment" => attachments}),
  do: not Enum.all?(attachments, fn x -> x["name"] != nil && x["name"] |> String.trim() != "" end)
  defp check_media(_),
  do: false

  def filter(
        %{
          "type" => "Create",
          "to" => to,
          "cc" => cc,
          "actor" => actor,
          "object" => object
        } = message
      ) do
    user = User.get_cached_by_ap_id(actor)
    undescribed = check_media(object)

    # unlist
    if undescribed and Enum.member?(to, Pleroma.Constants.as_public()) do
      to = List.delete(to, Pleroma.Constants.as_public()) ++ [user.follower_address]
      cc = List.delete(cc, user.follower_address) ++ [Pleroma.Constants.as_public()]

      object =
        object
        |> Map.put("to", to)
        |> Map.put("cc", cc)

      message =
        message
        |> Map.put("to", to)
        |> Map.put("cc", cc)
        |> Map.put("object", object)

      {:ok, message}
    else
      {:ok, message}
    end
  end



  @impl true
  def filter(message), do: {:ok, message}

  @impl true
  def describe, do: {:ok, %{}}
end
