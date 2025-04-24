defmodule SigilLock.Schema.User do
  use Ecto.Schema
  import Ecto.Changeset

  schema "users" do
    field(:external_id, :string)
    field(:email, :string)
    field(:metadata, :map, default: %{})

    belongs_to(:tenant, SigilLock.Schema.Tenant)

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:external_id, :email, :metadata, :tenant_id])
    |> validate_required([:external_id, :tenant_id])
    |> unique_constraint([:external_id, :tenant_id])
  end
end
