defmodule SigilLock.Repo.Migrations.CreateIAMTables do
  use Ecto.Migration

  def change do
    create table(:tenants) do
      add(:name, :string, null: false)
      add(:slug, :string, null: false)
      add(:settings, :map, default: "{}")

      timestamps()
    end

    create(unique_index(:tenants, [:slug]))

    create table(:users) do
      add(:external_id, :string, null: false)
      add(:email, :string)
      add(:metadata, :map, default: "{}")
      add(:tenant_id, references(:tenants, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(unique_index(:users, [:external_id, :tenant_id]))
    create(index(:users, [:tenant_id]))

    create table(:resources) do
      add(:external_id, :string, null: false)
      add(:type, :string, null: false)
      add(:metadata, :map, default: "{}")
      add(:tenant_id, references(:tenants, on_delete: :delete_all), null: false)
      add(:parent_resource_id, references(:resources, on_delete: :nilify_all))

      timestamps()
    end

    create(unique_index(:resources, [:external_id, :type, :tenant_id]))
    create(index(:resources, [:tenant_id]))
    create(index(:resources, [:parent_resource_id]))

    create table(:relation_tuples) do
      add(:subject_type, :string, null: false)
      add(:subject_id, :string, null: false)
      add(:relation, :string, null: false)
      add(:object_type, :string, null: false)
      add(:object_id, :string, null: false)
      add(:tenant_id, references(:tenants, on_delete: :delete_all), null: false)

      timestamps()
    end

    create(
      unique_index(:relation_tuples, [
        :subject_type,
        :subject_id,
        :relation,
        :object_type,
        :object_id,
        :tenant_id
      ])
    )

    create(index(:relation_tuples, [:tenant_id]))
    create(index(:relation_tuples, [:subject_type, :subject_id]))
    create(index(:relation_tuples, [:object_type, :object_id]))
  end
end
