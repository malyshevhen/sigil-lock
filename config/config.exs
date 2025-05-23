# This file is responsible for configuring your application
# and its dependencies with the aid of the Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
import Config

config :sigil_lock,
  generators: [timestamp_type: :utc_datetime]

config :sigil_lock,
  ecto_repos: [SigilLock.Repo]

# Configures the endpoint
config :sigil_lock, SigilLockWeb.Endpoint,
  url: [host: "localhost"],
  adapter: Bandit.PhoenixAdapter,
  render_errors: [
    formats: [json: SigilLockWeb.ErrorJSON],
    layout: false
  ],
  pubsub_server: SigilLock.PubSub,
  live_view: [signing_salt: "M5C8t6v9"]

# Configures the mailer
#
# By default it uses the "Local" adapter which stores the emails
# locally. You can see the emails in your browser, at "/dev/mailbox".
#
# For production it's recommended to configure a different adapter
# at the `config/runtime.exs`.
config :sigil_lock, SigilLock.Mailer, adapter: Swoosh.Adapters.Local

# Configures Elixir's Logger
config :logger, :default_formatter,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Configure the JWKS URL for token verification
config :sigil_lock,
  jwks_uri:
    System.get_env(
      "KC_JWKS_URI",
      "http://localhost:8080/realms/sigil-lock/protocol/openid-connect/certs"
    )

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
