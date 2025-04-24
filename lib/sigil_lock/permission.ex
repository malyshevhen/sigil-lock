defmodule SigilLock.Permission do
  @moduledoc """
  Core permission checking logic using recursive CTEs for group membership and hierarchy traversal.
  """

  import Ecto.Query
  alias SigilLock.Repo
  alias SigilLock.Schema.RelationTuple

  @doc """
  Checks if a user has a specific permission on a resource.

  ## Examples

      iex> IAM.Permission.check("user", "123", "view", "document", "abc", tenant_id: 1)
      true
  """
  def check(subject_type, subject_id, permission, object_type, object_id, opts \\ []) do
    tenant_id = Keyword.fetch!(opts, :tenant_id)

    # Get the policy for this permission
    policy = get_policy(permission, object_type)

    # Check each relation defined in the policy
    Enum.any?(policy.relations, fn relation ->
      check_relation(subject_type, subject_id, relation, object_type, object_id, tenant_id)
    end)
  end

  @doc """
  Checks if a subject has a specific relation to an object.
  This handles direct relations, group membership, and hierarchy traversal.
  """
  def check_relation(subject_type, subject_id, relation, object_type, object_id, tenant_id) do
    # This query uses a recursive CTE to handle:
    # 1. Direct relations
    # 2. Group membership (user is member of group that has relation)
    # 3. Resource hierarchy (parent resource grants access to children)

    query = """
    WITH RECURSIVE relation_graph AS (
      -- Base case: direct relations
      SELECT subject_type, subject_id, relation, object_type, object_id
      FROM relation_tuples
      WHERE tenant_id = $1

      UNION

      -- Recursive case 1: Group membership
      SELECT rt.subject_type, rt.subject_id, rg.relation, rg.object_type, rg.object_id
      FROM relation_tuples rt
      JOIN relation_graph rg ON rt.object_type = 'group' AND rt.object_id = rg.subject_id
      WHERE rt.relation = 'member' AND rt.tenant_id = $1

      UNION

      -- Recursive case 2: Resource hierarchy
      SELECT rg.subject_type, rg.subject_id, rg.relation, r.type, r.external_id
      FROM resources r
      JOIN relation_graph rg ON r.parent_resource_id IS NOT NULL
                            AND r.parent_resource_id = (
                              SELECT id FROM resources
                              WHERE type = rg.object_type AND external_id = rg.object_id AND tenant_id = $1
                            )
      WHERE r.tenant_id = $1
    )

    SELECT EXISTS (
      SELECT 1 FROM relation_graph
      WHERE subject_type = $2 AND subject_id = $3
        AND relation = $4
        AND object_type = $5 AND object_id = $6
    );
    """

    result =
      Repo.query!(query, [tenant_id, subject_type, subject_id, relation, object_type, object_id])

    result.rows |> List.first() |> List.first()
  end

  @doc """
  Gets the policy definition for a specific permission on an object type.
  Policies define which relations grant a permission.
  """
  def get_policy(permission, object_type) do
    # This would typically be defined in configuration or database
    # For example:
    case {permission, object_type} do
      {"view", "document"} ->
        %{
          relations: ["viewer", "editor", "owner"]
        }

      {"edit", "document"} ->
        %{
          relations: ["editor", "owner"]
        }

      {"delete", "document"} ->
        %{
          relations: ["owner"]
        }

      {"view", "folder"} ->
        %{
          relations: ["viewer", "editor", "owner"]
        }

      # Add more permission definitions as needed
      _ ->
        %{relations: []}
    end
  end

  @doc """
  Creates a relation tuple.
  """
  def create_relation(subject_type, subject_id, relation, object_type, object_id, tenant_id) do
    %RelationTuple{}
    |> RelationTuple.changeset(%{
      subject_type: subject_type,
      subject_id: subject_id,
      relation: relation,
      object_type: object_type,
      object_id: object_id,
      tenant_id: tenant_id
    })
    |> Repo.insert()
  end

  @doc """
  Deletes a relation tuple.
  """
  def delete_relation(subject_type, subject_id, relation, object_type, object_id, tenant_id) do
    from(rt in RelationTuple,
      where:
        rt.subject_type == ^subject_type and
          rt.subject_id == ^subject_id and
          rt.relation == ^relation and
          rt.object_type == ^object_type and
          rt.object_id == ^object_id and
          rt.tenant_id == ^tenant_id
    )
    |> Repo.delete_all()
  end
end
