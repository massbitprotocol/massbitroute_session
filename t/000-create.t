use Test::Nginx::Socket::Lua 'no_plan';

repeat_each(1);

no_shuffle();

# plan tests => blocks() * repeat_each() * 2;
$ENV{TEST_NGINX_HTML_DIR} ||= html_dir();
$ENV{TEST_NGINX_BINARY} =
"/massbit/massbitroute/app/src/sites/services/api/bin/openresty/nginx/sbin/nginx";
our $main_config = <<'_EOC_';
load_module /massbit/massbitroute/app/src/sites/services/session/bin/openresty/nginx/modules/ngx_http_link_func_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/session/bin/openresty/nginx/modules/ngx_http_geoip2_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/session/bin/openresty/nginx/modules/ngx_stream_geoip2_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/session/bin/openresty/nginx/modules/ngx_http_vhost_traffic_status_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/session/bin/openresty/nginx/modules/ngx_http_stream_server_traffic_status_module.so;
      load_module /massbit/massbitroute/app/src/sites/services/session/bin/openresty/nginx/modules/ngx_stream_server_traffic_status_module.so;

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
    include /massbit/massbitroute/app/src/sites/services/gateway/etc/_session.conf;

location /_api_key {
   rewrite /(.*) / break;
   access_by_lua_file /massbit/massbitroute/app/src/sites/services/session/src/_gateway_test.lua;
}
location /api/v1 {
    encrypted_session_key abcdefghijmbrbaysaklmnopqrstuvwo;
    encrypted_session_iv 123mbrbaysao4567;
    encrypted_session_expires 30d; # in sec
    # include /massbit/massbitroute/app/src/sites/services/session/cors.conf;
    set $app_root _APP_ROOT_;
    default_type application/json;
    limit_except OPTIONS POST GET HEAD {
        deny all;
    }
    access_by_lua_file /massbit/massbitroute/app/src/sites/services/session/src/filter-jsonrpc-access.lua;
}

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
POST /_api_key
{"id": "blockNumber", "jsonrpc": "2.0", "method": "eth_getBlockByNumber", "params": ["latest", false]}
--- response_body eval
qr/"result":true/
--- no_error_log