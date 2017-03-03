defmodule PodcastsApi.Repo.Migrations.Feed do
  use Ecto.Migration

  def change do
    create table(:feeds) do
      add :source_url, :string
      add :title, :string
      add :description, :string
      add :link, :string
      add :image_url, :string

      timestamps()
    end
  end
end
