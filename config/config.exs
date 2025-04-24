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

# Configures the repository
config :sigil_lock, SigilLock.Repo,
  hostname: System.get_env("APP_POSTGRES_HOST", "localhost"),
  username: System.get_env("APP_POSTGRES_USER", "sigil_lock"),
  password: System.get_env("APP_POSTGRES_PASSWORD", "password"),
  database: System.get_env("APP_POSTGRES_DB", "sigil_lock"),
  port: System.get_env("APP_POSTGRES_PORT", "5432"),
  ssl: String.to_existing_atom(System.get_env("APP_POSTGRES_SSL", "false")),
  ssl_opts: [],
  show_sensitive_data_on_connection_error: true

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
  jwks_uri: System.get_env("KC_JWKS_URI", "")

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{config_env()}.exs"
