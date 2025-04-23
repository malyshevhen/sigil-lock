defmodule SigilLock.Domain.IdentityTest do
  use ExUnit.Case, async: true
  doctest SigilLock.Domain.Identity

  # Import the module under test
  alias SigilLock.Domain.Identity

  # --- Test Data ---
  # Helper function to create a base set of valid claims
  defp valid_claims_base do
    %{
      "preferred_username" => "testuser",
      "email" => "test@example.com",
      "email_verified" => true,
      "realm_access" => %{"roles" => ["user", "tester"]},
      # String audience
      "aud" => "test-client",
      "iss" => "http://issuer.com/realms/test",
      "sub" => "subject-uuid-123",
      "jti" => "jwt-id-abc",
      # Set expiration to 1 hour from now
      "exp" => trunc(DateTime.to_unix(DateTime.utc_now()) + 3600)
    }
  end

  # --- Tests for from_claims/1 ---

  test "from_claims/1 successfully creates identity with valid claims (string audience)" do
    claims = valid_claims_base()

    assert {:ok,
            %Identity{
              username: "testuser",
              email: "test@example.com",
              email_verified: true,
              roles: ["user", "tester"],
              audience: "test-client",
              issuer: "http://issuer.com/realms/test",
              subject: "subject-uuid-123",
              jti: "jwt-id-abc",
              # Capture expires_at for separate check
              expires_at: expires_at
            }} = Identity.from_claims(claims)

    # Verify expires_at is a DateTime and roughly correct
    assert %DateTime{} = expires_at
    assert DateTime.compare(expires_at, DateTime.utc_now()) == :gt
  end

  test "from_claims/1 successfully creates identity with valid claims (list audience)" do
    claims = Map.put(valid_claims_base(), "aud", ["client-a", "client-b"])

    assert {:ok, %Identity{audience: ["client-a", "client-b"]}} = Identity.from_claims(claims)
  end

  test "from_claims/1 successfully creates identity without optional jti claim" do
    claims = Map.delete(valid_claims_base(), "jti")

    assert {:ok, %Identity{jti: nil}} = Identity.from_claims(claims)
  end

  test "from_claims/1 returns error for missing required claim (e.g., username)" do
    claims = Map.delete(valid_claims_base(), "preferred_username")
    assert {:error, {:missing_claim, "preferred_username"}} == Identity.from_claims(claims)
  end

  test "from_claims/1 returns error for missing required claim (e.g., exp)" do
    claims = Map.delete(valid_claims_base(), "exp")
    assert {:error, {:missing_claim, "exp"}} == Identity.from_claims(claims)
  end

  test "from_claims/1 returns error for invalid email_verified type" do
    claims = Map.put(valid_claims_base(), "email_verified", "not-a-boolean")

    assert {:error, {:invalid_type, "email_verified", "Expected boolean"}} ==
             Identity.from_claims(claims)
  end

  test "from_claims/1 returns error for invalid exp type" do
    claims = Map.put(valid_claims_base(), "exp", "not-an-integer")

    assert {:error, {:invalid_type, "exp", "Expected integer or string"}} ==
             Identity.from_claims(claims)
  end

  test "from_claims/1 returns error for invalid exp value (cannot convert to DateTime)" do
    # Provide a timestamp that DateTime.from_unix! might reject (e.g., excessively large)
    # Note: The exact range depends on the system, using a very large negative number
    claims = Map.put(valid_claims_base(), "exp", -9_999_999_999_999_999_999)
    # The error comes from DateTime.from_unix inside the `with`
    assert {:error, {:invalid_type, "exp", "Expected UNIX timestamp"}} ==
             Identity.from_claims(claims)
  end

  test "from_claims/1 returns error for invalid audience type (integer)" do
    claims = Map.put(valid_claims_base(), "aud", 123)

    assert {:error, {:invalid_type, "aud", "Expected string or list of strings"}} ==
             Identity.from_claims(claims)
  end

  test "from_claims/1 returns error for invalid audience type (list with non-string)" do
    claims = Map.put(valid_claims_base(), "aud", ["client-a", 123])

    assert {:error, {:invalid_type, "aud", "Expected string or list of strings"}} ==
             Identity.from_claims(claims)
  end

  test "from_claims/1 returns error for invalid jti type" do
    # Put an integer instead of string
    claims = Map.put(valid_claims_base(), "jti", 12345)

    assert {:error, {:invalid_type, "jti", "Expected string or nil"}} ==
             Identity.from_claims(claims)
  end

  test "from_claims/1 handles missing realm_access gracefully (empty roles)" do
    claims = Map.delete(valid_claims_base(), "realm_access")
    assert {:ok, %Identity{roles: []}} = Identity.from_claims(claims)
  end

  test "from_claims/1 handles missing roles within realm_access gracefully (empty roles)" do
    # realm_access exists, but no "roles" key
    claims = Map.put(valid_claims_base(), "realm_access", %{})
    assert {:ok, %Identity{roles: []}} = Identity.from_claims(claims)
  end

  test "from_claims/1 handles non-list roles within realm_access gracefully (empty roles)" do
    claims = Map.put(valid_claims_base(), "realm_access", %{"roles" => "not-a-list"})
    # The filter `&is_string/1` inside from_claims will result in an empty list here
    assert {:ok, %Identity{roles: []}} = Identity.from_claims(claims)
  end

  test "from_claims/1 handles list with non-string roles within realm_access (filters them out)" do
    claims =
      Map.put(valid_claims_base(), "realm_access", %{"roles" => ["user", 123, "admin", nil]})

    # The filter `&is_string/1` inside from_claims will keep only strings
    assert {:ok, %Identity{roles: ["user", "admin"]}} = Identity.from_claims(claims)
  end
end
