# claude-openclaw-bridge

A Claude Code skill that bridges to an OpenClaw agent via its OpenAI-compatible API.

## What it does

Relays user requests to a remote OpenClaw instance and returns responses verbatim. Any capabilities, skills, or tools available on the OpenClaw agent become accessible from within Claude Code.

## Triggers

- "Ask OpenClaw ..."
- "OpenClaw mode on" / "OpenClaw mode off" (relay mode toggle)
- `/openclaw-bridge`

## Environment Variables

| Variable | Required | Example |
|----------|----------|---------|
| `OPENCLAW_BASE_URL` | yes | `http://127.0.0.1:18789/v1` |
| `OPENCLAW_MODEL` | yes | `openclaw:main` |
| `OPENCLAW_API_KEY` | yes | `sk-your-key` |
| `OPENCLAW_ASSISTANT_NAME` | no | `YOUR_ASSISTANT_NAME` (defaults to `OpenClaw`) |

Set these in your shell profile or `.env` before launching Claude Code.

## Installation

```bash
make install
```

This copies `SKILL.md` to `~/.claude/skills/openclaw-bridge/`.

To remove:

```bash
make uninstall
```

## Relay Mode

Say "OpenClaw mode on" to enter relay mode -- all subsequent messages are forwarded to the OpenClaw agent automatically. Say "OpenClaw mode off" to return to normal Claude Code behavior. This is session-scoped and does not persist.

## Enabling OpenAI-Compatible Endpoints

The bridge communicates with OpenClaw using the **OpenAI Chat Completions API** format. Any OpenClaw instance that exposes an OpenAI-compatible `/v1/chat/completions` endpoint will work.

### What the bridge expects

- **POST** `${OPENCLAW_BASE_URL}/chat/completions`
- Standard request body: `{ "model": "<model>", "messages": [{ "role": "user", "content": "..." }] }`
- Bearer token authentication via `Authorization: Bearer ${OPENCLAW_API_KEY}`
- Standard response: `{ "choices": [{ "message": { "content": "..." } }] }`

### Configuring your OpenClaw instance

1. **Enable the OpenAI-compatible server** in your OpenClaw configuration. The exact steps depend on your OpenClaw version, but generally you need to start the API server with an OpenAI-compatible endpoint enabled (commonly on a local port like `18789`).
2. **Set a model identifier** that your OpenClaw instance recognizes (e.g. `openclaw:main`).
3. **Generate or configure an API key** for authentication. Even for local-only access, an API key is recommended.
4. **Verify the endpoint** is reachable:

```bash
curl -s "${OPENCLAW_BASE_URL}/chat/completions" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${OPENCLAW_API_KEY}" \
  -d '{"model": "'"${OPENCLAW_MODEL}"'", "messages": [{"role": "user", "content": "hello"}]}' \
  | jq .choices[0].message.content
```

If you get a response, the bridge is ready to use.

## Security Considerations

OpenClaw is often sandboxed and isolated from your main environment, and may have access to sensitive or personal data that you would not normally expose to Claude Code. The bridge creates a path between these two worlds, so it is important to be deliberate about when and how it is active.

### 1. Scope environment variables with `direnv`

If you only want the bridge available in certain project directories (rather than globally in every shell session), use [direnv](https://direnv.net/) to scope the environment variables:

1. Create a `.envrc` file in a trusted top-level directory (an example is provided in `.envrc.example`):

   ```bash
   export OPENCLAW_BASE_URL=http://127.0.0.1:18789/v1
   export OPENCLAW_MODEL="openclaw:main"
   export OPENCLAW_API_KEY=your_key_here
   ```

2. Run `direnv allow` in that directory to activate it. The variables will only be loaded when you `cd` into that directory tree, and will be unloaded when you leave.

This prevents the `OPENCLAW_API_KEY` and other credentials from being globally present in every terminal session, limiting the attack surface to directories you have explicitly approved.

### 2. Be intentional with the relay mode toggle

Relay mode (`OpenClaw mode on` / `OpenClaw mode off`) forwards **all** your messages to the OpenClaw agent for the duration of the session. This is convenient but easy to forget about:

- Turn relay mode **off** when you no longer need it.
- Remember that relay mode is session-scoped -- it does not persist across sessions, but it remains active for the entire current session if not explicitly turned off.
- Be mindful of what you type while relay mode is active. Anything that is not clearly a Claude Code command will be sent to OpenClaw.

### 3. Take extra care with `/remote-control` sessions

Claude Code's `/remote-control` feature allows external control of your session, which when combined with the OpenClaw bridge becomes especially powerful -- an external process can now interact with your OpenClaw instance through the remote session. This also means:

- **Always turn off the remote control session when you are done.** Do not leave it open for extended periods.
- A remote session with the bridge enabled effectively gives the remote controller access to anything OpenClaw can reach, which may include personal data and other information managed by your OpenClaw agent.
- Treat an open remote-control session with the bridge enabled as a privileged access point and close it promptly.

## Design

- Single-turn relay only -- OpenClaw manages its own conversation history
- No system prompt injected -- OpenClaw has its own persona
- Responses displayed verbatim, no summarization/e
