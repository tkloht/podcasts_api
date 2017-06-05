defmodule PodcastsApi.Repo.Migrations.DurationString do
  use Ecto.Migration

  def change do
    alter table(:episodes) do
      modify :duration, :string
    end
  end
end
