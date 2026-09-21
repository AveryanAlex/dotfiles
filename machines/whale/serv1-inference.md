# serv1 inference SSH tunnel

`serv1-inference.service` connects as `averyan` to serv1 through mole's Nebula
SSH proxy (`10.57.1.42:3122`) and forwards to `127.0.0.1:19088` on serv1.

- On whale: `http://127.0.0.1:28001`.
- From LiteLLM: `http://10.90.95.1:28001/v1` for an OpenAI-compatible backend.
- Only the LiteLLM bridge can reach the non-loopback listener.

The backend serves `qwen38-flash-next-uncensored`. LiteLLM's existing alias
`qwen3.8-flash-uncensored` uses `openai/qwen38-flash-next-uncensored` with API base
`http://10.90.95.1:28001/v1`.

The dedicated SSH key is encrypted in `serv1-inference-ssh.age` for alex and
whale, with its ACL in the root `secrets.nix`. Agenix and systemd `LoadCredential`
provide it to the service. The serv1 host key is pinned in the Nix module.

The public key on serv1 is restricted with:

```text
restrict,port-forwarding,permitopen="127.0.0.1:19088",command="/bin/false"
```

SSH keepalives detect connection loss, and systemd retries indefinitely every
15 seconds. The backend itself must listen on serv1 port 19088; the tunnel does
not start it. The WebSocket relay, its nginx route, token, and serv2 user service
have been removed.

```sh
systemctl status serv1-inference
journalctl -u serv1-inference -n 30
curl --fail http://127.0.0.1:28001/v1/models
sudo podman exec litellm-app python -c 'import urllib.request; print(urllib.request.urlopen("http://10.90.95.1:28001/v1/models", timeout=15).read().decode())'
```

Deploy the current working tree with `./deploy.sh whale switch`.

Verified on 2026-09-11: the backend returned `42` for `17 + 25` both directly
on serv1 and through a streamed LiteLLM completion. Concurrent model-list
requests also succeeded from the LiteLLM container through the SSH tunnel.
Subsequent completion probes timed out (120 seconds through LiteLLM, 30 seconds
directly on serv1), while model-list requests continued to work. At that point
vLLM reported two running requests and two waiting for capacity. The SSH tunnel
remained active without restarts; successful inference was verified, but response
latency under the current backend load is not consistently bounded.
