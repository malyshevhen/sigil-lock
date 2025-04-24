defmodule SigilLock.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use WithDb.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      alias SigilLock.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import SigilLock.DataCase
    end
  end

  setup tags do
    SigilLock.DataCase.setup_sandbox(tags)
    :ok
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(SigilLock.Repo, shared: not tags[:async])
    on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end

  @doc """
  Helper to create a tenant for use in tests.
  """
  def create_tenant(attrs \\ %{}) do
    %SigilLock.Accounts.Tenant{}
    |> SigilLock.Accounts.Tenant.changeset(
      Map.merge(%{name: "Test Tenant #{System.unique_integer()}"}, attrs)
    )
    |> SigilLock.Repo.insert!()
  end

  @doc """
  Helper to create a valid relation tuple with a user subject.
  Requires a tenant_id.
  """
  def create_user_relation_tuple(tenant_id, attrs \\ %{}) do
    base_attrs = %{
      tenant_id: tenant_id,
      object_type: "doc",
      object_id: "test_doc_#{System.unique_integer()}",
      relation: "viewer",
      subject_user_id: "user_#{System.unique_integer()}"
    }

    %SigilLock.Authz.RelationTuple{}
    |> SigilLock.Authz.RelationTuple.changeset(Map.merge(base_attrs, attrs))
    |> SigilLock.Repo.insert!()
  end

  @doc """
  Helper to create a valid relation tuple with a userset subject.
  Requires a tenant_id.
  """
  def create_userset_relation_tuple(tenant_id, attrs \\ %{}) do
    base_attrs = %{
      tenant_id: tenant_id,
      object_type: "folder",
      object_id: "test_folder_#{System.unique_integer()}",
      relation: "parent",
      subject_set_object_type: "group",
      subject_set_object_id: "test_group_#{System.unique_integer()}",
      subject_set_relation: "member"
    }

    %SigilLock.Authz.RelationTuple{}
    |> SigilLock.Authz.RelationTuple.changeset(Map.merge(base_attrs, attrs))
    |> SigilLock.Repo.insert!()
  end
end
