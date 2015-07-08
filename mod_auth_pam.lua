-- PAM authenticator module for Prosody

-- Uses portions of lua-pwauth:
-- <https://github.com/devurandom/lua-pwauth>

-- Copyright (c) 2012 Dennis Schridde
-- Copyright (c) 2015 J. King <http://jkingweb.ca/>

-- Permission is hereby granted, free of charge, to any person obtaining 
-- a copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation 
-- the rights to use, copy, modify, merge, publish, distribute, sublicense, 
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:

-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.

-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
-- IN THE SOFTWARE.

local pam = require "pam"; -- <https://github.com/devurandom/lua-pam>
local new_sasl = require "util.sasl".new;

local log = module._log;
local host = module.host;

local provider = {};

function provider.pam_conversation(messages, userdata)
	local username, password = userdata[1], userdata[2]
	local responses = {}
	for i, message in ipairs(messages) do
		local msg_style, msg = message[1], message[2]
		if msg_style == pam.PROMPT_ECHO_OFF then
			-- Assume PAM asks us for the password
			responses[i] = {password, 0}
		elseif msg_style == pam.PROMPT_ECHO_ON then
			-- Assume PAM asks us for the username
			responses[i] = {username, 0}
		elseif msg_style == pam.ERROR_MSG then
			responses[i] = {"", 0}
		elseif msg_style == pam.TEXT_INFO then
			responses[i] = {"", 0}
		else
			return nil, "Unsupported conversation style."
		end
	end
	return responses
end

function provider.pam_authenticate(service, username, password)
	local userdata = {username, password}
	local handle, err = pam.start(service, username, {provider.pam_conversation, userdata})
	if not handle then
		return nil, err
	end
	local success, err = handle:authenticate()
	if not success then
		log("debug" "Error from PAM service: "..err)
		return nil, err
	end
	local success, err = handle:endx(pam.SUCCESS)
	if not success then
		log("debug" "Error from PAM service: "..err)
		return nil, err
	end
	return true
end


function provider.test_password(username, password)
	local append = module:get_option_boolean("auth_append_host");
	local service = module:get_option_string("auth_pam_service", "system-auth");
	local testname = username;
	if append then
		testname = username.."@"..host;
	end
	log("debug", "Authenticating user '"..testname.."' using PAM service '"..service.."'");
	return provider.pam_authenticate(service, testname, password);
end

function provider.get_password(username)
	return nil, "Passwords are not available from PAM authenticator";
end

function provider.set_password(username, password)
	-- This should be possible, but Prosody doesn't 
	-- seem to support requiring the old password?
	return nil, "Password changing is not available from PAM authenticator";
end

function provider.user_exists(username)
	return true;
end

function provider.users()
	return nil, "Account list is not available from PAM authenticator";
end

function provider.create_user(username, password)
	return nil, "Account creation is not available from PAM authenticator";
end

function provider.delete_user(username)
	return nil, "Account deletion is not available from PAM authenticator";
end

function provider.get_sasl_handler()
	return new_sasl(module.host, {
		plain_test = function(sasl, username, password, realm)
			return provider.test_password(username, password), true
		end;
	});
end

	
module:provides("auth", provider);

