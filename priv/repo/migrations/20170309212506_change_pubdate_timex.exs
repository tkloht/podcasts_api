defmodule PodcastsApi.Repo.Migrations.ChangePubdateTimex do
  use Ecto.Migration

  def change do
    execute("CREATE TYPE datetimetz AS ( dt timestamptz, tz varchar );")

    alter table(:episodes) do
      remove :pubDate
      add :pubDate, :datetimetz
    end
  end
end
