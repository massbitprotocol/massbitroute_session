use Test::Nginx::Socket::Lua 'no_plan';

repeat_each(1);

no_shuffle();

# plan tests => blocks() * repeat_each() * 2;
$ENV{TEST_NGINX_HTML_DIR} ||= html_dir();
$ENV{TEST_NGINX_BINARY} =
"/massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/sbin/nginx";
our $main_config = <<'_EOC_';
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_http_geoip2_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_stream_geoip2_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_http_vhost_traffic_status_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_http_stream_server_traffic_status_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/modules/ngx_stream_server_traffic_status_module.so;
	

env BIND_ADDRESS;
_EOC_

our $http_config = <<'_EOC_';
  server_tokens off;
    map_hash_max_size 128;
    map_hash_bucket_size 128;
    server_names_hash_bucket_size 128;
    include /massbit/massbitroute/app/src/sites/services/session/bin/openresty/nginx/conf/mime.types;
    access_log /massbit/massbitroute/app/src/sites/services/session/logs/nginx/nginx-access.log;
    # tmp
    client_body_temp_path /massbit/massbitroute/app/src/sites/services/session/tmp/client_body_temp;
    fastcgi_temp_path /massbit/massbitroute/app/src/sites/services/session/tmp/fastcgi_temp;
    proxy_temp_path /massbit/massbitroute/app/src/sites/services/session/tmp/proxy_temp;
    scgi_temp_path /massbit/massbitroute/app/src/sites/services/session/tmp/scgi_temp;
    uwsgi_temp_path /massbit/massbitroute/app/src/sites/services/session/tmp/uwsgi_temp;
    lua_package_path '/massbit/massbitroute/app/src/sites/services/session/gbc/src/?.lua;/massbit/massbitroute/app/src/sites/services/session/lib/?.lua;/massbit/massbitroute/app/src/sites/services/session/src/?.lua;/massbit/massbitroute/app/src/sites/services/session/sites/../src/?.lua/massbit/massbitroute/app/src/sites/services/session/sites/../lib/?.lua;/massbit/massbitroute/app/src/sites/services/session/sites/../src/?.lua;/massbit/massbitroute/app/src/sites/services/session/bin/openresty/site/lualib/?.lua;;';
    lua_package_cpath '/massbit/massbitroute/app/src/sites/services/session/gbc/src/?.so;/massbit/massbitroute/app/src/sites/services/session/lib/?.so;/massbit/massbitroute/app/src/sites/services/session/src/?.so;/massbit/massbitroute/app/src/sites/services/session/sites/../src/?.so/massbit/massbitroute/app/src/sites/services/session/sites/../lib/?.so;/massbit/massbitroute/app/src/sites/services/session/sites/../src/?.so;/massbit/massbitroute/app/src/sites/services/session/bin/openresty/site/lualib/?.so;;';
            resolver 8.8.8.8 ipv6=off;
            variables_hash_bucket_size 512;
            #ssl
            lua_shared_dict auto_ssl 1m;
            lua_shared_dict auto_ssl_settings 64k;

            #lua
            lua_capture_error_log 32m;
            #lua_need_request_body on;
            lua_regex_match_limit 1500;
            lua_check_client_abort on;
            lua_socket_log_errors off;
            lua_shared_dict _GBC_ 1024k;
            lua_code_cache on;
        

#_INCLUDE_SITES_HTTPINIT_
    init_by_lua '\n    
	   require("framework.init")
	   local appKeys = dofile("/massbit/massbitroute/app/src/sites/services/session/tmp/app_keys.lua")
	   local globalConfig = dofile("/massbit/massbitroute/app/src/sites/services/session/tmp/config.lua")
	   cc.DEBUG = globalConfig.DEBUG
	   local gbc = cc.import("#gbc")
	   cc.exports.nginxBootstrap = gbc.NginxBootstrap:new(appKeys, globalConfig)
        

--_INCLUDE_SITES_LUAINIT_\n    ';
    init_worker_by_lua '\n    

        

--_INCLUDE_SITES_LUAWINIT_\n    ';
 
map $http_origin $allow_origin {
    include /massbit/massbitroute/app/src/sites/services/session/sites/../cors-whitelist.map;
    default '';
}
map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}
_EOC_

our $config = <<'_EOC_';

    set $namespace massbitroute_session;
    set $site_root /massbit/massbitroute/app/src/sites/services/session/sites/..;
    set $server_root /massbit/massbitroute/app/src/sites/services/session;
    set $redis_sock /massbit/massbitroute/app/src/sites/services/session/tmp/redis.sock;
    resolver 8.8.4.4 ipv6=off;
    client_body_buffer_size 512K;
    client_max_body_size 1G;
    include /massbit/massbitroute/app/src/sites/services/session/tmp/app_session_api_entry.conf;

_EOC_
run_tests();

__DATA__

=== Api create new

--- main_config eval: $::main_config
--- http_config eval: $::http_config
--- config eval: $::config
--- more_headers
Content-Type: application/json
--- request
POST /_internal_api/v2/?action=api.create
{
  "allow_methods" : {},
  "app_id" : "c237c346-7a0f-478b-bc0c-e3ca2522948f",
  "app_key" : "WJaEniHiudjuhLV7diHkDw",
  "blockchain" : "eth",
  "id" : "c237c346-7a0f-478b-bc0c-e3ca2522948f",
  "limit_rate_per_day" : 3000,
  "limit_rate_per_sec" : 100,
  "name" : "api-6",
  "network" : "mainnet",
  "status" : 1,
  "project_id" : "83260a9e-4e41-4293-abc5-fe47a2219534",
  "project_quota" : "100000",
  "partner_id" : "fc78b64c5c33f3f270700b0c4d3e7998188035ab",
  "sid" : "403716b0f58a7d6ddec769f8ca6008f2c1c0cea6",
  "user_id" : "b363ddf4-42cf-4ccf-89c2-8c42c531ac99"
}
--- response_body eval
qr/"result":true/
--- no_error_log

=== Check raw data if created or not

--- main_config eval: $::main_config
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /deploy/dapi/eth/mainnet/b363ddf4-42cf-4ccf-89c2-8c42c531ac99/c237c346-7a0f-478b-bc0c-e3ca2522948f
--- error_code: 200
--- response_body eval
qr/"id":"c237c346-7a0f-478b-bc0c-e3ca2522948f"/
--- no_error_log

=== Check ID conf if created or not

--- main_config eval: $::main_config
--- http_config eval: $::http_config
--- config eval: $::config
--- request
GET /deploy/dapiconf/nodes/eth-mainnet/c237c346-7a0f-478b-bc0c-e3ca2522948f.conf
--- error_code: 200
--- response_body: 
--- no_error_log
