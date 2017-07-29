defmodule PodcastsApi.Repo.Migrations.CreatePlaylist do
  use Ecto.Migration

  def change do
    create table(:playlists) do
      add :title, :string
      add :user_id, references(:users, on_delete: :nothing)

      timestamps()
    end
    create index(:playlists, [:user_id])

  end
end
