defmodule SigilLock.Accounts.Tenant do
  @moduledoc """
  Represents a tenant in the multi-tenant system.
  All resources and relations are scoped to a tenant.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "tenants" do
    # Define fields corresponding to the columns in the 'tenants' table
    field(:name, :string)
    # Add other tenant-specific fields here if needed
    # field :status, :string
    # field :plan_id, :string

    # Define relationships if needed for Ecto queries or associations.
    # Example: A tenant has many relation tuples. Useful if you want to easily
    # query all tuples for a tenant via Ecto, or for cascading deletes managed
    # by Ecto (though the DB foreign key already handles this).
    # has_many :relation_tuples, MyApp.Authz.RelationTuple,
    #   foreign_key: :tenant_id,
    #   on_delete: :delete_all # Or rely on DB's ON DELETE CASCADE

    # Automatically manage inserted_at and updated_at timestamps
    timestamps()
  end

  @doc """
  Builds a changeset for a Tenant struct.
  Used for validating and casting data before database operations.
  """
  def changeset(tenant \\ %__MODULE__{}, attrs) do
    tenant
    |> cast(attrs, [:name])
    |> validate_required([:name])

    # Add other validations as needed (e.g., format, length)
    # |> validate_length(:name, max: 255)
  end
end
