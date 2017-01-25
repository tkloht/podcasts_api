defmodule PodcastsApi.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users) do
      add :username, :string
      add :email, :string
      add :password_hash, :string

      timestamps()
    end

    create index(:users, [:username], unique: true)

  end
end
