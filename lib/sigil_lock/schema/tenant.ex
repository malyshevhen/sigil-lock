defmodule SigilLock.Schema.Tenant do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tenants" do
    field(:name, :string)
    field(:slug, :string)
    field(:settings, :map, default: %{})

    timestamps()
  end

  def changeset(tenant, attrs) do
    tenant
    |> cast(attrs, [:name, :slug, :settings])
    |> validate_required([:name, :slug])
    |> unique_constraint(:slug)
  end
end
