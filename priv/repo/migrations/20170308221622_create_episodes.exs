defmodule PodcastsApi.Repo.Migrations.CreateEpisodes do
  use Ecto.Migration

  def change do
    create table(:episodes) do
      add :title, :string
      add :subtitle, :string
      add :link, :string
      add :pubDate, :utc_datetime
      add :guid, :string
      add :description, :string
      add :duration, :integer
      add :shownotes, :string
      add :enclosure, :string

      add :feed_id, :integer

      timestamps

    end

  end
end
