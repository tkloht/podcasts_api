defmodule PodcastsApi.Repo.Migrations.FeedHash do
  use Ecto.Migration

  def change do
    alter table(:feeds) do
      add :hash, :string
    end
  end
end
