defmodule Exqlite.Queries do
  @moduledoc """
  The interface to manage cached prepared queries.
  """

  #
  # TODO: We should probably do some tracking on the number of statements being
  #       generated and culling the oldest cached value (LRU). In its current
  #       implementation, this could just have a run away memory leak if we are
  #       not careful.
  #

  alias Exqlite.Query

  @type t :: :ets.tid()

  @spec new(atom()) :: t()
  def new(name) do
    # TODO: Should this be set to :private?
    #
    # Ideally the only process that will be accessing this ets table would be
    # the connection that owns it.
    :ets.new(name, [:set, :public])
  end

  @spec put(t(), Query.t()) :: :error
  def put(_cache, %Query{name: ""}), do: :error

  @spec put(t(), Query.t()) :: :error
  def put(_cache, %Query{name: nil}), do: :error

  @spec put(t(), Query.t()) :: :error
  def put(_cache, %Query{ref: nil}), do: :error

  @spec put(t(), Query.t()) :: :ok | :error
  def put(cache, %Query{name: query_name, ref: ref}) do
    try do
      :ets.insert(cache, {query_name, {ref}})
    rescue
      ArgumentError -> :error
    else
      true -> :ok
    end
  end

  @spec delete(nil) :: :ok
  def delete(nil), do: :ok

  @spec delete(t()) :: :ok
  def delete(cache) do
    :ets.delete(cache)
    :ok
  end

  @spec delete(t(), Query.t()) :: :error
  def delete(_cache, %Query{name: nil}), do: :error

  @spec delete(t(), Query.t()) :: :error
  def delete(_cache, %Query{name: ""}), do: :error

  @spec delete(t(), Query.t()) :: :ok | :error
  def delete(cache, %Query{name: query_name}) do
    try do
      :ets.delete(cache, query_name)
    rescue
      ArgumentError -> :error
    else
      true -> :ok
    end
  end

  @spec get(t(), Query.t()) :: nil
  def get(_cache, %Query{name: nil}), do: nil

  @spec get(t(), Query.t()) :: nil
  def get(_cache, %Query{name: ""}), do: nil

  @doc """
  Gets an existing prepared query if it exists. Otherwise `nil` is returned.
  """
  @spec get(t(), Query.t()) :: Query.t() | nil
  def get(cache, %Query{name: query_name} = query) do
    try do
      :ets.lookup_element(cache, query_name, 2)
    rescue
      ArgumentError -> nil
    else
      {ref} ->
        %{query | ref: ref}
    end
  end

  @doc """
  Clears the entire prepared query cache.
  """
  @spec clear(t()) :: :ok
  def clear(cache) do
    :ets.delete_all_objects(cache)
    :ok
  end

  @spec size(nil) :: integer()
  def size(nil), do: 0

  @spec size(t()) :: integer()
  def size(cache) do
    :ets.info(cache) |> Keyword.get(:size, 0)
  end
end
