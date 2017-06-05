defmodule PodcastsApi.Repo.Migrations.AddSearch do
  use Ecto.Migration

  def up do
    execute "CREATE extension if not exists pg_trgm;"
    execute "CREATE INDEX feed_title_trgm_index ON feeds USING gin (title gin_trgm_ops);"
  end

  def down do
    execute "DROP INDEX feed_title_trgm_index;"
  end
end
