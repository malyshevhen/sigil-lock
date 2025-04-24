defmodule SigilLock.Schema.RelationTuple do
  use Ecto.Schema
  import Ecto.Changeset

  schema "relation_tuples" do
    field(:subject_type, :string)
    field(:subject_id, :string)
    field(:relation, :string)
    field(:object_type, :string)
    field(:object_id, :string)

    belongs_to(:tenant, SigilLock.Schema.Tenant)

    timestamps()
  end

  def changeset(tuple, attrs) do
    tuple
    |> cast(attrs, [:subject_type, :subject_id, :relation, :object_type, :object_id, :tenant_id])
    |> validate_required([
      :subject_type,
      :subject_id,
      :relation,
      :object_type,
      :object_id,
      :tenant_id
    ])
    |> unique_constraint([
      :subject_type,
      :subject_id,
      :relation,
      :object_type,
      :object_id,
      :tenant_id
    ])
  end
end
