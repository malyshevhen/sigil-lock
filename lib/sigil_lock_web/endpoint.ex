defmodule SigilLockWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :sigil_lock

  # The session plug is not needed for an API-only application
  # plug Plug.Session,
  #   store: :cookie,
  #   key: "_sigil_lock_key",
  #   signing_salt: "..."

  # Serve static files from the priv/static dir.
  # In production, this would be handled by a web server.
  # plug Plug.Static,
  #   at: "/",
  #   from: :sigil_lock,
  #   gzip: false # Set to true in production

  # Code reloading can be enabled by passing the `:code_reloader`
  # option above. For example:
  #
  #     use Phoenix.Endpoint, otp_app: :sigil_lock, code_reloader: true
  #
  # The relevant code goes in lib/sigil_lock_web/dev.ex.

  # Watch static and templates for browser reloading.
  # if code_reloading? do
  #   plug Phoenix.LiveReload.Plug
  #   plug Phoenix.CodeReloader
  #   plug Phoenix.Ecto.CheckRepoStatus, otp_app: :sigil_lock
  # end

  # Plug for handling request parsers (JSON, URL-encoded, etc.)
  # This is now handled in the router pipelines
  # plug Plug.Parsers,
  #   parsers: [:urlencoded, :multipart, :json],
  #   pass: ["*/*"],
  #   json_decoder: Jason

  # Plug for logging requests
  plug Plug.Logger

  # Plug for telemetry (optional, but good for monitoring)
  plug Plug.Telemetry, event_prefix: [:phoenix, :endpoint]

  # Plug for security headers (optional for API, but good practice)
  # plug Plug.SSL, rewrite_on: [:x_forwarded_proto]
  # plug Plug.SecureHeaders, %{
  #   csp: [
  #     default_src: "'self'",
  #     script_src: "'self'",
  #     style_src: "'self'",
  #     img_src: "'self'",
  #     font_src: "'self'",
  #     connect_src: "'self'",
  #     frame_ancestors: "'none'"
  #   ],
  #   x_frame_options: "DENY",
  #   x_content_type_options: "nosniff",
  #   x_xss_protection: "1; mode=block",
  #   strict_transport_security: "max-age=31536000; includeSubDomains",
  #   referrer_policy: "no-referrer"
  # }

  # Plug for routing requests to the router
  plug SigilLockWeb.Router
end
