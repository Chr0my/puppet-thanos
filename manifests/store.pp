# @summary This class manages store service
#
# This class install Store as service store node giving access to blocks in a bucket provider.
#    Now supported GCS, S3, Azure, Swift and Tencent COS..
#
# @param ensure
#  State ensured from compact service.
# @param user
#  User running thanos.
# @param group
#  Group under which thanos is running.
# @param bin_path
#  Path where binary is located.
# @param log_level
#  Only log messages with the given severity or above. One of: [debug, info, warn, error, fatal]
# @param log_format
#  Output format of log messages. One of: [logfmt, json]
# @param tracing_config_file
#  Path to YAML file with tracing configuration. See format details: https://thanos.io/tracing.md/#configuration
# @param http_address
#  Listen host:port for HTTP endpoints.
# @param http_grace_period
#  Time to wait after an interrupt received for HTTP Server.
# @param grpc_address
#  Listen ip:port address for gRPC endpoints (StoreAPI). Make sure this address is routable from other components.
# @param grpc_grace_period
#  Time to wait after an interrupt received for GRPC Server.
# @param grpc_server_tls_cert
#  TLS Certificate for gRPC server, leave blank to disable TLS
# @param grpc_server_tls_key
#  TLS Key for the gRPC server, leave blank to disable TLS
# @param grpc_server_tls_client_ca
#  TLS CA to verify clients against. If no client CA is specified, there is no client verification on server side. (tls.NoClientCert)
# @param data_dir
#  Data directory in which to cache remote blocks.
# @param index_cache_config_file
#  Path to YAML file that contains index cache configuration.
#    See format details: https://thanos.io/components/store.md/#index-cache
# @param index_cache_size
#  Maximum size of items held in the index cache.
# @param chunck_pool_size
#  Maximum size of concurrently allocatable bytes for chunks.
# @param store_grpc_series_sample_limit
#  Maximum amount of samples returned via a single Series call. 0 means no limit.
#    NOTE: for efficiency we take 120 as the number of samples in chunk (it cannot be bigger than that),
#    so the actual number of samples might be lower, even
#    though the maximum could be hit.
# @param store_grpc_series_max_concurrency
#  Maximum number of concurrent Series calls.
# @param objstore_config_file
#  Path to YAML file that contains object store configuration. See format details: https://thanos.io/storage.md/#configuration
# @param sync_block_duration
#  Repeat interval for syncing the blocks between local and remote view.
# @param block_sync_concurrency
#  Number of goroutines to use when syncing blocks from object storage.
# @param min_time
#  Start of time range limit to serve. Thanos Store will serve only metrics, which happened later than this value.
#    Option can be a constant time in RFC3339 format or time duration relative to current time, such as -1d or 2h45m. Valid
#    duration units are ms, s, m, h, d, w, y.
# @param max_time
#  End of time range limit to serve. Thanos Store will serve only blocks, which happened eariler than this value.
#    Option can be a constant time in RFC3339 format or time duration relative to current time, such as -1d or 2h45m. Valid
#    duration units are ms, s, m, h, d, w, y.
# @param selector_relabel_config_file
#  Path to YAML file that contains relabeling configuration that allows selecting blocks.
#    It follows native Prometheus relabel-config syntax.
#    See format details: https://prometheus.io/docs/prometheus/latest/configuration/configuration/#relabel_config
# @param consistency_delay
#  Minimum age of all blocks before they are being read.
# @param ignore_deletion_marks_delay
#  Duration after which the blocks marked for deletion will be filtered out while fetching blocks.
#    The idea of ignore-deletion-marks-delay is to ignore blocks that are marked for deletion with some delay.
#    This ensures store can still serve blocks that are meant to be deleted but do not have a replacement yet.
#    If delete-delay duration is provided to compactor or bucket verify component,
#    it will upload deletion-mark.json file to mark after what duration the block should be deleted rather than
#    deleting the block straight away. If delete-delay is non-zero for compactor or bucket verify component,
#    ignore-deletion-marks-delay should be set to (delete-delay)/2 so that blocks marked for deletion are filtered out
#    while fetching blocks before being deleted from bucket. Default is 24h, half of the default value for --delete-delay on compactor.
# @param web_external_prefix
#  Static prefix for all HTML links and redirect URLs in the UI query web interface.
#    Actual endpoints are still served on / or the web.route-prefix.
#    This allows thanos UI to be served behind a reverse proxy that strips a URL sub-path.
# @param web_prefix_header
#  Name of HTTP request header used for dynamic prefixing of UI links and redirects.
#    This option is ignored if web.external-prefix argument is set.
#    Security risk: enable this option only if a reverse proxy in front of thanos is resetting the header.
#    The --web.prefix-header=X-Forwarded-Prefix option can be useful, for example,
#    if Thanos UI is served via Traefik reverse proxy with PathPrefixStrip option enabled, which sends the stripped
#    prefix value in X-Forwarded-Prefix header. This allows thanos UI to be served on a sub-path.
# @param max_open_files
#  Define how many open files the service is able to use
#  In some cases, the default value (1024) needs to be increased
# @param extra_params
#  Parameters passed to the binary, ressently released in latest version of Thanos.
# @example
#   include thanos::store
class thanos::store (
  Enum['present', 'absent']      $ensure                            = 'present',
  String                         $user                              = $thanos::user,
  String                         $group                             = $thanos::group,
  Stdlib::Absolutepath           $bin_path                          = $thanos::bin_path,
  Optional[Integer]              $max_open_files                    = undef,
  # Binary Parameters
  Thanos::Log_level              $log_level                         = 'info',
  Enum['logfmt', 'json']         $log_format                        = 'logfmt',
  Optional[Stdlib::Absolutepath] $tracing_config_file               = $thanos::tracing_config_file,
  String                         $http_address                      = '0.0.0.0:10902',
  String                         $http_grace_period                 = '2m',
  String                         $grpc_address                      = '0.0.0.0:10901',
  String                         $grpc_grace_period                 = '2m',
  Optional[Stdlib::Absolutepath] $grpc_server_tls_cert              = undef,
  Optional[Stdlib::Absolutepath] $grpc_server_tls_key               = undef,
  Optional[Stdlib::Absolutepath] $grpc_server_tls_client_ca         = undef,
  Optional[Stdlib::Absolutepath] $data_dir                          = undef,
  String                         $index_cache_size                  = '250MB',
  Optional[Stdlib::Absolutepath] $index_cache_config_file           = undef,
  String                         $chunck_pool_size                  = '2GB',
  Integer                        $store_grpc_series_sample_limit    = 0,
  Integer                        $store_grpc_series_max_concurrency = 20,
  Optional[Stdlib::Absolutepath] $objstore_config_file              = $thanos::storage_config_file,
  String                         $sync_block_duration               = '3m',
  Integer                        $block_sync_concurrency            = 20,
  Optional[String]               $min_time                          = undef,
  Optional[String]               $max_time                          = undef,
  Optional[Stdlib::Absolutepath] $selector_relabel_config_file      = undef,
  String                         $consistency_delay                 = '30m',
  String                         $ignore_deletion_marks_delay       = '24h',
  Optional[String]               $web_external_prefix               = undef,
  Optional[String]               $web_prefix_header                 = undef,
  # Extra parametes
  Hash                           $extra_params                      = {},
) {
  $_service_ensure = $ensure ? {
    'present' => 'running',
    default   => 'stopped'
  }

  thanos::resources::service { 'store':
    ensure         => $_service_ensure,
    bin_path       => $bin_path,
    user           => $user,
    group          => $group,
    max_open_files => $max_open_files,
    params         => {
      'log.level'                         => $log_level,
      'log.format'                        => $log_format,
      'tracing.config-file'               => $tracing_config_file,
      'http-address'                      => $http_address,
      'http-grace-period'                 => $http_grace_period,
      'grpc-address'                      => $grpc_address,
      'grpc-grace-period'                 => $grpc_grace_period,
      'grpc-server-tls-cert'              => $grpc_server_tls_cert,
      'grpc-server-tls-key'               => $grpc_server_tls_key,
      'grpc-server-tls-client-ca'         => $grpc_server_tls_client_ca,
      'data-dir'                          => $data_dir,
      'index-cache.config-file'           => $index_cache_config_file,
      'index-cache-size'                  => $index_cache_size,
      'chunk-pool-size'                   => $chunck_pool_size,
      'store.grpc.series-sample-limit'    => $store_grpc_series_sample_limit,
      'store.grpc.series-max-concurrency' => $store_grpc_series_max_concurrency,
      'objstore.config-file'              => $objstore_config_file,
      'sync-block-duration'               => $sync_block_duration,
      'block-sync-concurrency'            => $block_sync_concurrency,
      'min-time'                          => $min_time,
      'max-time'                          => $max_time,
      'selector.relabel-config-file'      => $selector_relabel_config_file,
      'consistency-delay'                 => $consistency_delay,
      'ignore-deletion-marks-delay'       => $ignore_deletion_marks_delay,
      'web.external-prefix'               => $web_external_prefix,
      'web.prefix-header'                 => $web_prefix_header,
    },
    extra_params   => $extra_params,
  }
}
