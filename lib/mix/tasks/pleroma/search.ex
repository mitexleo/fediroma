# Pleroma: A lightweight social networking server
# Copyright © 2017-2021 Pleroma Authors <https://pleroma.social/>
# SPDX-License-Identifier: AGPL-3.0-only

defmodule Mix.Tasks.Pleroma.Search do
  use Mix.Task
  import Mix.Pleroma
  import Ecto.Query
  alias Pleroma.Activity
  alias Pleroma.Pagination
  alias Pleroma.User
  alias Pleroma.Hashtag

  @shortdoc "Manages elasticsearch"

  def run(["import", "activities" | _rest]) do
    start_pleroma()

    Elasticsearch.Index.Bulk.upload(Pleroma.Search.Elasticsearch.Cluster, 
	"activities",
	Pleroma.Config.get([Pleroma.Search.Elasticsearch.Cluster, :indexes, :activities]))
    #from(a in Activity, where: not ilike(a.actor, "%/relay"))
    #|> where([a], fragment("(? ->> 'type'::text) = 'Create'", a.data))
    #|> Activity.with_preloaded_object()
    #|> Activity.with_preloaded_user_actor()
    #|> get_all(:activities)
  end

  defp get_all(query, index, max_id \\ nil) do
    params = %{limit: 1000}

    params =
      if max_id == nil do
        params
      else
        Map.put(params, :max_id, max_id)
      end

    res =
      query
      |> Pagination.fetch_paginated(params)

    if res == [] do
      :ok
    else
      res
      |> Enum.map(fn x -> Pleroma.Search.Elasticsearch.add_to_index(x) end)

      get_all(query, index, List.last(res).id)
    end
  end
end
