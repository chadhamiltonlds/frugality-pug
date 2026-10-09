# Credentials

This file says what exists and how to use it. It never contains secret values.
Do not paste tokens, keys, or passwords into this repo, ever. Git history is permanent.

| Credential | Used for | Where it lives | How Claude uses it |
|---|---|---|---|
| GitHub access (chadhamiltonlds) | Read/push `frugality-pug`; read `priority-pusher-site` | Chad's claude.ai GitHub integration + Claude GitHub app on chadhamiltonlds | `add_repo` in the session. No token needed. Personal access tokens pasted in chat are ignored by the session. |
| Codemagic account | CI builds, TestFlight upload | Chad's Codemagic account (shared with Priority Pusher) | Edit `codemagic.yaml` in this repo. Claude cannot log in to Codemagic. |
| App Store Connect API key | Upload builds to TestFlight, signing | Codemagic: Teams > Integrations (encrypted) | Referenced by name in `codemagic.yaml`. The key itself is never in the repo. |
| Apple developer account | Certificates, bundle ID, App Store Connect entry | Family account, managed by Chad | None. Chad does the account steps. |
| Other API keys | none yet | n/a | The app uses no third-party services. |

## If a new secret is ever needed
1. Put it in Codemagic as an encrypted environment variable and reference it by name in `codemagic.yaml`.
2. Add a row above (name and purpose only).
3. Local files named `.env.local` or under `secrets/` are gitignored. Claude's workspace is wiped between sessions, so nothing stored there lasts.

## If Chad pastes a secret in chat
Use it only for that session, never write it to a file or commit it, and tell Chad it can be revoked afterward.
