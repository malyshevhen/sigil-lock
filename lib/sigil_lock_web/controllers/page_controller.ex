defmodule SigilLockWeb.PageController do
  use SigilLockWeb, :controller

  # Remove the 'home' action

  # Public API endpoint - accessible without a token
  def public_api(conn, _params) do
    json(conn, %{message: "This is a public endpoint. Anyone can access this."})
  end

  # Secure API endpoint - requires a valid JWT via the Authenticate Plug
  def secure_api(conn, _params) do
    # If we reach here, the Authenticate Plug has successfully verified the token
    # The authenticated user's claims might be available in conn.assigns if the Plug adds them
    # For this example, we'll just return a success message
    json(conn, %{
      message: "This is a secure endpoint. You accessed this with a valid token!",
      user_claims: conn.assigns[:user_claims]
    })
  end
end
