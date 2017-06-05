defmodule PodcastsApi.Repo.Migrations.DescriptionFields do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      add :itunes_summary, :text
      add :content_encoded, :text
    end
  end
end
