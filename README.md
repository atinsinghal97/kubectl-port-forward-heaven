# kubectl-port-forward-heaven

## What is this?

If you work with kubernetes port forward utility often, you would know how frustrating it is when "the pipe keeps breaking" or other similar errors are encountered. This utility tries to solve this problem by continuously checking the connection for errors and re-establishes the connection if errors are observed.

Apart from that, this will also open the URL in your default browser after doing the initial port-forward (works only with WSL and Mac as of now).

## Prereqs

This utility requires `inotifywait` for WSL/Linux and `fswatch` for Mac.

## How to configure?

- Set the path to your local config file by setting `KPF_CONFIG_FILE` in [this file](export-env-var.sh#L3).
- Run `source export-env-var.sh` in terminal to set the environment variable. Make sure to add this to your bashrc or zshrc file if you want this change to be persistent. _(Tip: use the full path to the file when doing so.)_
- Below's a list of key-value pairs required in the config file for each service you want to port-forward to.

  ```json
  "flag": {
    "label": "",
    "namespace": "",
    "service": "",
    "local_port": "",
    "remote_port": "",
    "protocol": "",
    "open_browser": "",
    "require_namespace_suffix": ""
  }
  ```

- Replace `flag` with the letter you want to use to invoke port forward via the script. Flag can only be a single letter. Eg: setting flag to `f` will require you to invoke the script as `./kpf-heaven.sh -f`. Note that `h` and `d` are reserved keys and cannot be used as a value for the flag.
- Set `label` to any identifier. This is added to the help menu for your reference.
- `namespace` should be set to the service namespace.
- `service` should be set to "svc/\<service-name\>".
- `local_port` and `remote_port` are the port number for your local and remote service respectively.
- `protocol` should be set to either `https` or `http`. This will be used when opening the URL in your browser.
- `open_browser` can be set to either `true` or `false`. Set to `true` if you want to auto-open the url in the browser.
- `require_namespace_suffix` should either be set to `true` or `false`. Set it to `true` if you need to use a custom namespace suffix. The suffix is provided as an argument to the script after the app flag.

A sample config file is provided for reference [here](kpf-config-sample.json).
