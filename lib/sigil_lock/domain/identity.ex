defmodule SigilLock.Domain.Identity do
  @moduledoc """
  Represents a validated user identity derived from JWT claims.

  This struct holds essential information about the authenticated user,
  extracted and validated from a JWT.
  """

  @type t :: %__MODULE__{
          username: String.t(),
          email: String.t(),
          email_verified: boolean(),
          roles: [String.t()],
          # Audience can be a string or list
          audience: String.t() | [String.t()],
          issuer: String.t(),
          subject: String.t(),
          # JWT ID, can be optional
          jti: String.t() | nil,
          expires_at: DateTime.t()
        }

  @enforce_keys [
    :username,
    :email,
    :email_verified,
    :roles,
    :audience,
    :issuer,
    :subject,
    :expires_at
    # :jti is not enforced as it might be optional in some JWTs
  ]
  defstruct [
    :username,
    :email,
    :email_verified,
    :roles,
    :audience,
    :issuer,
    :subject,
    :jti,
    :expires_at
  ]

  @doc """
  Attempts to create a new `t:t()` struct from a map of JWT claims.

  Validates the presence and basic types of required claims. Converts the
  expiration time (`exp`) to a `DateTime.t()`. Extracts roles from
  `realm_access.roles`.

  Returns `{:ok, identity}` on success or `{:error, reason}` if validation fails
  (e.g., missing claims, invalid types).

  ## Examples

      iex> claims = %{
      ...>   "preferred_username" => "alice",
      ...>   "email" => "alice@example.com",
      ...>   "email_verified" => true,
      ...>   "realm_access" => %{"roles" => ["user", "admin"]},
      ...>   "aud" => "account",
      ...>   "iss" => "http://keycloak/realms/myrealm",
      ...>   "sub" => "user-uuid-123",
      ...>   "jti" => "jwt-id-456",
      ...>   "exp" => trunc(DateTime.to_unix(DateTime.utc_now()) + 3600) # Expires in 1 hour
      ...> }
      iex> {:ok, identity} = SigilLock.Domain.Identity.from_claims(claims)
      iex> identity.username
      "alice"
      iex> identity.roles
      ["user", "admin"]
      iex> DateTime.compare(identity.expires_at, DateTime.utc_now())
      :gt

      iex> SigilLock.Domain.Identity.from_claims(%{"email" => "missing_other_fields@example.com"})
      {:error, {:missing_claim, "preferred_username"}}

      iex> SigilLock.Domain.Identity.from_claims(%{
      ...>   "preferred_username" => "alice",
      ...>   "email" => "alice@example.com",
      ...>   "email_verified" => "not_a_boolean", # Invalid type
      ...>   "realm_access" => %{"roles" => ["user", "admin"]},
      ...>   "aud" => "account",
      ...>   "iss" => "http://keycloak/realms/myrealm",
      ...>   "sub" => "user-uuid-123",
      ...>   "jti" => "jwt-id-456",
      ...>   "exp" => trunc(DateTime.to_unix(DateTime.utc_now()) + 3600)
      ...> })
      {:error, {:invalid_type, "email_verified", "Expected boolean"}}
  """
  @spec from_claims(map()) :: {:ok, t()} | {:error, atom() | tuple()}
  def from_claims(claims) when is_map(claims) do
    with {:ok, username} <- fetch_string(claims, "preferred_username"),
         {:ok, email} <- fetch_string(claims, "email"),
         {:ok, email_verified} <- fetch_boolean(claims, "email_verified"),
         # Use get_in for nested access, provide default empty list if path missing
         roles <- fetch_roles(claims),
         # Audience ('aud') can be a string or a list of strings according to RFC 7519
         {:ok, audience} <- fetch_audience(claims, "aud"),
         {:ok, issuer} <- fetch_string(claims, "iss"),
         {:ok, subject} <- fetch_string(claims, "sub"),
         # JTI is often optional, so use Map.get with type check
         jti <- Map.get(claims, "jti"),
         {:ok, jti} <- validate_optional_string(jti, "jti"),
         # Fetch and convert expiration time
         {:ok, expires_at} <- fetch_datetime(claims, "exp") do
      # If all steps in `with` succeed, build the struct
      identity =
        struct(__MODULE__, %{
          username: username,
          email: email,
          email_verified: email_verified,
          roles: roles,
          audience: audience,
          issuer: issuer,
          subject: subject,
          jti: jti,
          expires_at: expires_at
        })

      case validate(identity) do
        {:ok, _} -> {:ok, identity}
        {:error, reason} -> {:error, reason}
      end
    else
      # Handle errors from any step in the `with` block
      {:error, reason} -> {:error, reason}
    end
  end

  def is_verified?(%__MODULE__{email_verified: true}), do: true
  def is_verified?(%__MODULE__{email_verified: _}), do: false

  def is_expired?(%__MODULE__{expires_at: expires_at}),
    do: DateTime.compare(expires_at, DateTime.utc_now()) == :lt

  def validate(
        %__MODULE__{
          username: username,
          email: email,
          email_verified: email_verified,
          roles: roles,
          audience: audience,
          issuer: issuer,
          subject: subject,
          expires_at: _expires_at
        } = identity
      )
      when is_binary(username) and is_binary(email) and
             is_boolean(email_verified) and is_list(roles) and
             is_binary(issuer) and is_binary(subject) do
    with {:ok, _} <- validate_username(username),
         {:ok, _} <- validate_email(email),
         {:ok, _} <- validate_email_verification(identity),
         {:ok, _} <- validate_roles(roles),
         {:ok, _} <- validate_audience(audience),
         {:ok, _} <- validate_expiration(identity) do
      {:ok, identity}
    end
  end

  def validate(_), do: {:error, :invalid_identity_structure}

  # Individual validation functions
  defp validate_username(username) do
    if username |> String.trim() |> String.length() > 0 do
      {:ok, username}
    else
      {:error, {:invalid_username, "Username cannot be empty"}}
    end
  end

  defp validate_email(email) do
    if valid_email?(email) do
      {:ok, email}
    else
      {:error, {:invalid_email, "Email format is invalid"}}
    end
  end

  defp validate_email_verification(identity) do
    if is_verified?(identity) do
      {:ok, true}
    else
      {:error, {:email_not_verified, "Email must be verified"}}
    end
  end

  defp validate_roles(roles) do
    if Enum.all?(roles, &is_binary/1) do
      {:ok, roles}
    else
      {:error, {:invalid_roles, "All roles must be strings"}}
    end
  end

  defp validate_audience(audience) when is_binary(audience) do
    if audience == "" do
      {:error, {:invalid_audience, "Audience cannot be empty"}}
    else
      {:ok, audience}
    end
  end

  defp validate_audience(audience) when is_list(audience) do
    if Enum.all?(audience, &is_binary/1) do
      {:ok, audience}
    else
      {:error, {:invalid_audience, "All audience entries must be strings"}}
    end
  end

  defp validate_expiration(identity) do
    if not is_expired?(identity) do
      {:ok, true}
    else
      {:error, {:expired, "Identity has expired"}}
    end
  end

  # --- Private Helper Functions for Validation ---

  @spec fetch_roles(map()) :: [String.t()] | String.t()
  defp fetch_roles(map) do
    case get_in(map, ["realm_access", "roles"]) do
      roles when is_list(roles) -> roles |> List.wrap() |> Enum.filter(&is_binary/1)
      _ -> []
    end
  end

  @spec fetch_string(map(), String.t()) :: {:ok, String.t()} | {:error, tuple()}
  defp fetch_string(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) -> {:ok, value}
      {:ok, _} -> {:error, {:invalid_type, key, "Expected string"}}
      :error -> {:error, {:missing_claim, key}}
    end
  end

  @spec fetch_boolean(map(), String.t()) :: {:ok, boolean()} | {:error, tuple()}
  defp fetch_boolean(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_boolean(value) -> {:ok, value}
      {:ok, _} -> {:error, {:invalid_type, key, "Expected boolean"}}
      :error -> {:error, {:missing_claim, key}}
    end
  end

  # Handles 'aud' which can be a string or list of strings
  @spec fetch_audience(map(), String.t()) :: {:ok, String.t() | [String.t()]} | {:error, tuple()}
  defp fetch_audience(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} when is_binary(value) ->
        {:ok, value}

      {:ok, value} when is_list(value) ->
        if Enum.all?(value, &is_binary/1) do
          {:ok, value}
        else
          {:error, {:invalid_type, key, "Expected string or list of strings"}}
        end

      {:ok, _value} ->
        {:error, {:invalid_type, key, "Expected string or list of strings"}}

      :error ->
        {:error, {:missing_claim, key}}
    end
  end

  @spec fetch_datetime(map(), String.t()) :: {:ok, DateTime.t()} | {:error, tuple()}
  defp fetch_datetime(map, key) do
    case Map.fetch(map, key) do
      {:ok, value} -> parse_datetime(value)
      :error -> {:error, {:missing_claim, key}}
    end
  end

  @spec parse_datetime(integer() | String.t()) :: {:ok, DateTime.t()} | {:error, tuple()}
  defp parse_datetime(value) when is_integer(value) do
    case DateTime.from_unix(value) do
      {:ok, datetime} -> {:ok, datetime}
      {:error, _} -> {:error, {:invalid_type, "exp", "Expected UNIX timestamp"}}
    end
  end

  defp parse_datetime(value) when is_binary(value) do
    with {unix, _} <- Integer.parse(value) do
      parse_datetime(unix)
    else
      :error -> {:error, {:invalid_type, "exp", "Expected integer or string"}}
    end
  end

  defp parse_datetime(_value), do: {:error, {:invalid_type, "exp", "Expected integer or string"}}

  # Validates optional string fields like JTI
  @spec validate_optional_string(any(), String.t()) :: {:ok, String.t() | nil} | {:error, tuple()}
  defp validate_optional_string(nil, _key), do: {:ok, nil}
  defp validate_optional_string(value, _key) when is_binary(value), do: {:ok, value}

  defp validate_optional_string(_value, key),
    do: {:error, {:invalid_type, key, "Expected string or nil"}}

  defp valid_email?(email) do
    Regex.match?(~r/\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i, email)
  end
end
