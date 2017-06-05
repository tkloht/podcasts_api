defmodule PodcastsApi.Repo.Migrations.AddSubscription do
  use Ecto.Migration

  def change do
    create table(:subscription) do

      add :feed_id, :integer
      add :user_id, :integer

      timestamps

    end
  end
end
