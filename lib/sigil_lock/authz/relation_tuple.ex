defmodule SigilLock.Authz.RelationTuple do
  @moduledoc """
  Represents a Zanzibar-style relation tuple: object#relation@subject
  This is the core authorization data structure.
  """
  use Ecto.Schema
  import Ecto.Changeset
  alias SigilLock.Accounts.Tenant

  # Use binary_id (UUID) for primary keys
  @primary_key {:id, :binary_id, autogenerate: true}
  # Ensure foreign keys referencing this table also use binary_id
  @foreign_key_type :binary_id

  # Define the database table name
  schema "relation_tuples" do
    # --- Object ---
    # The type of resource (e.g., "document", "folder")
    field(:object_type, :string)
    # The specific identifier of the resource (e.g., "doc123", "folder-abc")
    field(:object_id, :string)

    # --- Relation ---
    # The relationship (e.g., "viewer", "editor", "member")
    field(:relation, :string)

    # --- Subject (Split representation) ---
    # If the subject is a direct user, this holds their ID.
    field(:subject_user_id, :string)
    # If the subject is a userset (object#relation), these fields define it.
    field(:subject_set_object_type, :string)
    field(:subject_set_object_id, :string)
    field(:subject_set_relation, :string)

    # --- Association ---
    # Each tuple belongs to exactly one tenant.
    # The foreign key field `tenant_id` links to the `tenants` table.
    belongs_to(:tenant, Tenant, type: :binary_id)

    # --- Timestamps ---
    # Only track insertion time, updates are generally not expected/meaningful
    # for immutable relation tuples. If a relationship changes, you typically
    # delete the old tuple and insert a new one.
    timestamps(updated_at: false)
  end

  @doc """
  Builds a changeset for a RelationTuple struct.
  Validates the structure and integrity of the tuple data.
  """
  def changeset(tuple \\ %__MODULE__{}, attrs) do
    tuple
    # Cast incoming attributes to the schema fields
    |> cast(attrs, [
      :tenant_id,
      :object_type,
      :object_id,
      :relation,
      :subject_user_id,
      :subject_set_object_type,
      :subject_set_object_id,
      :subject_set_relation
    ])
    # Foreign key constraint
    |> foreign_key_constraint(:tenant_id, name: :relation_tuples_tenant_id_fkey)
    # Unique constraint
    |> unique_constraint(
      [
        :tenant_id,
        :object_type,
        :object_id,
        :relation,
        :subject_set_object_type,
        :subject_set_object_id,
        :subject_set_relation
      ],
      name: :uq_relation_tuples_userset_subject
    )
    |> unique_constraint(
      [:tenant_id, :object_type, :object_id, :relation, :subject_user_id],
      name: :uq_relation_tuples_user_subject
    )
    # Validate that required fields common to all tuples are present
    |> validate_required([
      :tenant_id,
      :object_type,
      :object_id,
      :relation
    ])
    # Apply custom validation logic for the subject part
    |> validate_subject_definition()
  end

  # Custom validation function to ensure the subject part of the tuple is valid.
  # Mirrors the logic of the `chk_subject_defined` constraint in the database.
  defp validate_subject_definition(changeset) do
    # Get the current values or changes for the subject fields
    user_id = get_field(changeset, :subject_user_id)
    set_type = get_field(changeset, :subject_set_object_type)
    set_id = get_field(changeset, :subject_set_object_id)
    set_rel = get_field(changeset, :subject_set_relation)

    # Helper checks for non-blank strings (treat nil and "" as blank)
    is_present = fn val -> !is_nil(val) and val != "" end

    is_user_subject = is_present.(user_id)

    is_userset_subject_complete =
      is_present.(set_type) and is_present.(set_id) and is_present.(set_rel)

    is_userset_subject_partial =
      (is_present.(set_type) or is_present.(set_id) or is_present.(set_rel)) and
        not is_userset_subject_complete

    cond do
      # Error: Both user and userset info provided
      is_user_subject and (is_userset_subject_complete or is_userset_subject_partial) ->
        add_error(changeset, :subject_user_id, "cannot be set when a subject set is also defined")

      # Error: Partial userset info provided (must be all or none)
      is_userset_subject_partial ->
        add_error(
          changeset,
          :subject_set_object_type,
          "all subject set fields (type, id, relation) must be provided together, or all must be blank"
        )

      # Error: Neither user nor userset info provided
      not is_user_subject and not is_userset_subject_complete ->
        add_error(
          changeset,
          :subject_user_id,
          "either subject_user_id or a complete subject set (type, id, relation) must be defined"
        )

      # Valid: EITHER a user subject OR a complete userset subject is defined
      true ->
        changeset
    end
  end
end
