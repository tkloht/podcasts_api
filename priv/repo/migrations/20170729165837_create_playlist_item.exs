defmodule PodcastsApi.Repo.Migrations.CreatePlaylistItem do
  use Ecto.Migration

  def change do
    create table(:playlist_items) do
      add :playlist_id, references(:playlists, on_delete: :nothing)
      add :episode_id, references(:episodes, on_delete: :nothing)

      timestamps()
    end
    create index(:playlist_items, [:playlist_id])
    create index(:playlist_items, [:episode_id])

  end
end
