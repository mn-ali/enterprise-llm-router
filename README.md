# 🚀 LiteLLM Proxy — Unified LLM Gateway

A Docker-based deployment of [LiteLLM Proxy](https://docs.litellm.ai/) providing a single OpenAI-compatible API gateway to 100+ LLM providers, fronted by **Cloudflare AI Gateway** for two-layer security.

## Architecture

```
Client App
   │  ① cf-aig-authorization (CF token) + Authorization (LiteLLM virtual key)
   ▼
┌─────────────────────────────────┐
│  Cloudflare AI Gateway          │  Layer 1 — auth, analytics, caching, rate limiting
│  gateway.ai.cloudflare.com      │
└──────────────┬──────────────────┘
               │  ② Forwards Authorization header
               ▼
┌─────────────────────────────────┐
│  LiteLLM Proxy (Railway)        │  Layer 2 — virtual keys, spend tracking, routing
│  https://<your-app>.railway.app │
└──────────────┬──────────────────┘
               │  ③ Injects real NAVY_API_KEY
               ▼
┌─────────────────────────────────┐
│  Navy AI (DeepSeek v3.2)        │  Layer 3 — actual LLM provider
└─────────────────────────────────┘
```

> **The real API keys never leave your server.**

---

## Features

- **Two-Layer Security** — Cloudflare AI Gateway + LiteLLM virtual keys
- **Unified API** — OpenAI-compatible `/chat/completions`, `/completions`, `/embeddings`
- **Admin UI** — Web dashboard at `/ui` for model management, key management, spend tracking
- **Cost Tracking** — Per-key and per-team spend tracking via PostgreSQL
- **Load Balancing** — Route between multiple deployments of the same model
- **Virtual Keys** — API keys with budgets, rate limits, and model access controls
- **Observability** — Cloudflare dashboard for request analytics, caching, and logging

---

## Cloudflare AI Gateway

### Configuration

| Setting | Value |
|---|---|
| Account ID | `ddebd88ecea4b732187ed293d664e070` |
| Gateway ID | `ai-api-router` |
| Gateway URL | `https://gateway.ai.cloudflare.com/v1/ddebd88ecea4b732187ed293d664e070/ai-api-router/compat` |
| CF AIG Token | Set in Cloudflare dashboard |
| Origin URL | Your Railway LiteLLM proxy URL |

> **Important:** In the Cloudflare AI Gateway dashboard, set the **origin/upstream URL** to your Railway deployment URL.

### Calling the API

#### Curl

```bash
curl -X POST https://gateway.ai.cloudflare.com/v1/ddebd88ecea4b732187ed293d664e070/ai-api-router/compat/chat/completions \
  --header 'cf-aig-authorization: Bearer <CF_AIG_TOKEN>' \
  --header 'Authorization: Bearer <LITELLM_VIRTUAL_KEY>' \
  --header 'Content-Type: application/json' \
  --data '{
    "model": "navy-deepseek",
    "messages": [{"role": "user", "content": "What is Cloudflare?"}]
  }'
```

#### Python (OpenAI SDK)

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://gateway.ai.cloudflare.com/v1/ddebd88ecea4b732187ed293d664e070/ai-api-router/compat",
    api_key="<LITELLM_VIRTUAL_KEY>",
    default_headers={
        "cf-aig-authorization": "Bearer <CF_AIG_TOKEN>"
    }
)

response = client.chat.completions.create(
    model="navy-deepseek",
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

#### Langchain

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    openai_api_base="https://gateway.ai.cloudflare.com/v1/ddebd88ecea4b732187ed293d664e070/ai-api-router/compat",
    openai_api_key="<LITELLM_VIRTUAL_KEY>",
    model="navy-deepseek",
    default_headers={
        "cf-aig-authorization": "Bearer <CF_AIG_TOKEN>"
    }
)

response = llm.invoke("Hello!")
```

### Auth Headers Explained

| Header | Purpose | Who validates it |
|---|---|---|
| `cf-aig-authorization: Bearer <token>` | Authenticates with Cloudflare gateway | Cloudflare |
| `Authorization: Bearer <key>` | LiteLLM virtual key (forwarded by CF) | LiteLLM Proxy |

---

## Available Model Aliases

| Alias | Provider | Model |
|-------|----------|-------|
| `navy-deepseek` | Navy AI | DeepSeek v3.2 |

> **Tip:** Add more models via `litellm_config.yaml` or the Admin UI at `/ui`.

---

## Railway Deployment

### Environment Variables

Set these in your Railway **LiteLLM service → Variables** tab:

| Variable | Value |
|---|---|
| `DATABASE_URL` | `${{Postgres.DATABASE_URL}}` |
| `LITELLM_MASTER_KEY` | Your secure master key |
| `NAVY_API_KEY` | Your Navy AI API key |
| `STORE_MODEL_IN_DB` | `True` |
| `LITELLM_LOG` | `INFO` |

### Services

| Service | Purpose |
|---------|---------|
| **LiteLLM Proxy** | API gateway + Admin UI |
| **PostgreSQL** | Spend tracking & key storage |

---

## Local Development (Docker Compose)

```bash
cp .env.example .env
# Fill in API keys in .env
docker-compose up -d
```

| Service | Port | Description |
|---------|------|-------------|
| **LiteLLM Proxy** | `4000` | API gateway + Admin UI |
| **PostgreSQL** | `5432` | Spend tracking & key storage |
| **Redis** | `6379` | Rate limiting & caching |

| URL | Description |
|-----|-------------|
| http://localhost:4000/ui | 🎛️ Admin Dashboard |
| http://localhost:4000/docs | 📖 Swagger API Docs |
| http://localhost:4000/health | ❤️ Health Check |

---

## Key Management (Virtual Keys)

Generate API keys with budgets and rate limits:

```bash
curl http://localhost:4000/key/generate \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "models": ["navy-deepseek"],
    "max_budget": 100,
    "duration": "30d"
  }'
```

Or manage keys through the Admin UI at `/ui`.

---

## Management

```bash
# View logs
docker-compose logs -f litellm

# Restart proxy (after config changes)
docker-compose restart litellm

# Stop everything
docker-compose down

# Rebuild after Dockerfile changes
docker-compose up -d --build
```

---

## References

- [LiteLLM Docs](https://docs.litellm.ai/)
- [LiteLLM Proxy Config](https://docs.litellm.ai/docs/proxy/configs)
- [Cloudflare AI Gateway Docs](https://developers.cloudflare.com/ai-gateway/)
- [Supported Models](https://docs.litellm.ai/docs/providers)
