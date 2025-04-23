import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :sigil_lock, SigilLockWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "cy/J2BpPMJTrzzpTNfu3Jd8vNEZNJ3KTCFw++zTwb5kymAb4grVUB32hojxELIUg",
  server: false

# In test we don't send emails
config :sigil_lock, SigilLock.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :debug

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Set Keycloak Client Mock
config :sigil_lock, keycloak_client: KeycloakClientMock
