mod_auth_pam for Prosody
========================

Description
-----------

`mod_auth_pam` is, as the name suggests, a PAM authentication module for [Prosody](http://prosody.im/), an XMPP server.  The module requires [lua-pam](https://github.com/devurandom/lua-pam/) to operate.

Installation
------------

First, [lua-pam](https://github.com/devurandom/lua-pam/) must be installed.  Compilation and installation instructions for lua-pam are out of scope for this document.

A PAM service must also be configured correctly.  The means of doing so are also out of scope for this document, but examples are readily available online.

Finally, simply follow the standard procedure for [installing Prosody modules](http://prosody.im/doc/installing_modules).  

Configuration
-------------

You will need to change the value of the `authentication` variable in prosody.cfg.lua to `pam`.  No further configuration is required, but depending on your set-up, the following options may need to be specified:

Option             | Default         | Description
------------------ | --------------- | -----------
`auth_pam_service` | `"system-auth"` | The PAM service to use, as usually configured in `/etc/pam.d/`
`auth_append_host` | `false`         | Whether to append the hostname to the client-supplied username to form a JID
