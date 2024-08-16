import Config

# Note we also include the path to a cache manifest
# containing the digested version of static files. This
# manifest is generated by the `mix assets.deploy` task,
# which you should run after static files are built and
# before starting your production server.
config :samuel_willis, SamuelWillisWeb.Endpoint,
  force_ssl: [
    hsts: true,
    host: nil,
    rewrite_on: [:x_forwarded_host, :x_forwarded_port, :x_forwarded_proto]
  ],
  cache_static_manifest: "priv/static/cache_manifest.json"

# Configures Swoosh API Client
config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: SamuelWillis.Finch

# Do not print debug messages in production
config :logger, level: :info

# Runtime production configuration, including reading
# of environment variables, is done on config/runtime.exs.
