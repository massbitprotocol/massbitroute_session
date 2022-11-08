local cjson = require("cjson")
local set_var = ndk.set_var

local env = require("env")
local domain
local session_enable
local scheme = ngx.var.scheme

local session_enable = true

local function empty(s)
    return s == nil or s == ""
end

if session_enable then
    if empty(ngx.var.arg_session) then
        ngx.header.location =
            "/api/v1?host=" .. ngx.var.host .. "&token=" .. ngx.var.mbr_token

        return ngx.exit(308)
    else
        local _session = ngx.var.arg_session
        ngx.log(ngx.ERR, "session:" .. _session)
        local _token = set_var.set_decode_base32(_session)
        ngx.log(ngx.ERR, "token:" .. _token)
        local token = set_var.set_decrypt_session(_token)
        ngx.log(ngx.ERR, "token real:" .. token)
        ngx.log(ngx.ERR, "token arg:" .. ngx.var.mbr_token)
        if not token or token ~= ngx.var.mbr_token then
            ngx.header.location =
	       "/api/v1?host=" .. ngx.var.host .. "&token=" .. ngx.var.mbr_token
            return ngx.exit(308)
        end
    end
end
