defmodule PodcastsApi.Repo.Migrations.DescriptionBigger255 do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      modify :description, :text
    end
  end
end
