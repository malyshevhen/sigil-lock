defmodule SigilLock.Accounts.TenantTest do
  # Use DataCase for DB access, async is fine here
  use SigilLock.DataCase, async: true

  alias SigilLock.Accounts.Tenant

  describe "changeset/2" do
    test "valid changeset with required fields" do
      attrs = %{name: "Valid Tenant Name"}
      changeset = Tenant.changeset(%Tenant{}, attrs)
      assert changeset.valid?
    end

    test "invalid changeset without required name" do
      # Missing name
      attrs = %{}
      changeset = Tenant.changeset(%Tenant{}, attrs)
      refute changeset.valid?
      assert %{name: ["can't be blank"]} = errors_on(changeset)
    end

    # Add more tests for other validations if you add them to Tenant schema
  end

  describe "database interactions" do
    test "can insert a valid tenant" do
      tenant = create_tenant(%{name: "Insertable Tenant"})
      assert tenant.id
      assert tenant.name == "Insertable Tenant"
    end
  end
end
