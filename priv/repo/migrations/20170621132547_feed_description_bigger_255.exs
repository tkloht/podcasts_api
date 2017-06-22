defmodule PodcastsApi.Repo.Migrations.FeedDescriptionBigger255 do
  use Ecto.Migration

  def change do
      alter table(:feeds) do
        modify :description, :text
      end
    end
end

