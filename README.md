# kubectl-port-forward-heaven

## What is this?

If work with kubernetes port forward utility often, you would know how frustrating it is when "the pipe keeps breaking" or other similar errors are encountered. This utility tries to solve this problem by continuously checking the connection for errors and re-establishes the connection if errors are observed.

Apart from that, it will also open the URL in the browser after doing a port-forward.

## Prereqs

This utility requires `inotifywait` for WSL and `fswatch` for Mac.

## How to configure?

- Below's a list of key-value pairs required in the `kpf-config.json` file for each service you want to port-forward to.

  ```json
  "flag": {
    "label": "",
    "namespace": "",
    "service": "",
    "local_port": "",
    "remote_port": "",
    "protocol": ""
  }
  ```

- Replace `flag` with the letter you want to use to invoke port forward via the script. Eg: setting flag to `f` will require you to invoke the script as `./kpf-heaven.sh -f`. Note that `h` is a reserved key and cannot be used as a value for the flag.
- Set `label` to any identifier. This is for your reference.
- `namespace` should be set to the service namespace.
- `service` should be set to "svc/\<service-name\>".
- `local_port` and `remote_port` are the port number for your local and remote service respectively.
- `protocol` should be set to either `https` or `http`. This will be used when opening the URL in your browser.

A sample `kpf-config.json` file is provided for reference.

Note: This utility uses `explorer.exe` on WSL and `Google Chrome` on Mac to open URLs.
