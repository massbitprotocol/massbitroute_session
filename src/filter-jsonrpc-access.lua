local set_var = ndk.set_var

-- local cjson = require("cjson")

-- local function empty(s)
--     return s == nil or s == ""
-- end

local _token = ngx.var.arg_token
local _host = ngx.var.arg_host
local _scheme = ngx.var.scheme
if not _token or not _host then
    ngx.exit(ngx.HTTP_BAD_REQUEST)
end

local _id = set_var.set_encrypt_session(_token)
local _session = set_var.set_encode_base32(_id)
ngx.header.location = _scheme .. "://" .. _host .. "/" .. _token .. "/?session=" .. _session
ngx.exit(308)

return
