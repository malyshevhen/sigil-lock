defmodule SigilLock.Schema.Resource do
  use Ecto.Schema
  import Ecto.Changeset

  schema "resources" do
    field(:external_id, :string)
    field(:type, :string)
    field(:metadata, :map, default: %{})
    field(:parent_id, :string, virtual: true)

    belongs_to(:tenant, SigilLock.Schema.Tenant)
    belongs_to(:parent_resource, SigilLock.Schema.Resource, foreign_key: :parent_resource_id)

    timestamps()
  end

  def changeset(resource, attrs) do
    resource
    |> cast(attrs, [:external_id, :type, :metadata, :tenant_id, :parent_resource_id])
    |> validate_required([:external_id, :type, :tenant_id])
    |> unique_constraint([:external_id, :type, :tenant_id])
  end
end
