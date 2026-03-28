# 🚀 LiteLLM Proxy — Unified LLM Gateway

A Docker-based deployment of [LiteLLM Proxy](https://docs.litellm.ai/) providing a single OpenAI-compatible API gateway to 100+ LLM providers.

## Features

- **Unified API** — OpenAI-compatible `/chat/completions`, `/completions`, `/embeddings` endpoints
- **Multi-Provider** — Azure OpenAI, Anthropic Claude, Huggingface, AWS Bedrock, OpenAI, Ollama, TogetherAI, Cohere
- **Admin UI** — Web dashboard at `/ui` for model management, key management, spend tracking
- **Cost Tracking** — Per-key and per-team spend tracking via PostgreSQL
- **Load Balancing** — Route between multiple deployments of the same model
- **Virtual Keys** — Create API keys with budgets, rate limits, and model access controls
- **Rate Limiting** — Distributed rate limiting via Redis

---

## Quick Start

### 1. Configure Environment

```bash
cp .env.example .env
```

Edit `.env` and fill in your API keys for the providers you want to use. At minimum you need:
- `LITELLM_MASTER_KEY` — set a secure master key
- `UI_USERNAME` / `UI_PASSWORD` — admin dashboard credentials
- API keys for your LLM providers (Azure, Anthropic, etc.)

### 2. Start with Docker Compose

```bash
docker-compose up -d
```

This starts:
| Service | Port | Description |
|---------|------|-------------|
| **LiteLLM Proxy** | `4000` | API gateway + Admin UI |
| **PostgreSQL** | `5432` | Spend tracking & key storage |
| **Redis** | `6379` | Rate limiting & caching |

### 3. Access the Services

| URL | Description |
|-----|-------------|
| http://localhost:4000/ui | 🎛️ Admin Dashboard (login with `UI_USERNAME`/`UI_PASSWORD`) |
| http://localhost:4000/docs | 📖 Swagger API Docs |
| http://localhost:4000/health | ❤️ Health Check |

---

## Usage

### Curl

```bash
curl http://localhost:4000/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

### OpenAI Python SDK

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:4000",
    api_key="your-litellm-master-key"
)

response = client.chat.completions.create(
    model="claude-sonnet",  # routes to Anthropic Claude
    messages=[{"role": "user", "content": "Hello!"}]
)
print(response.choices[0].message.content)
```

### Langchain

```python
from langchain_openai import ChatOpenAI

llm = ChatOpenAI(
    openai_api_base="http://localhost:4000",
    openai_api_key="your-litellm-master-key",
    model="gpt-4"
)

response = llm.invoke("Hello!")
```

---

## Available Model Aliases

| Alias | Provider | Model |
|-------|----------|-------|
| `gpt-4` | Azure OpenAI | gpt-4 |
| `gpt-4o` | Azure OpenAI | gpt-4o |
| `gpt-3.5-turbo` | Azure OpenAI | gpt-35-turbo |
| `claude-sonnet` | Anthropic | claude-sonnet-4-20250514 |
| `claude-haiku` | Anthropic | claude-3-5-haiku |
| `claude-opus` | Anthropic | claude-3-opus |
| `hf-starcoder` | Huggingface | bigcode/starcoder |
| `hf-mistral` | Huggingface | Mistral-7B-Instruct |
| `bedrock-claude` | AWS Bedrock | claude-3-sonnet |
| `bedrock-titan` | AWS Bedrock | titan-text-express |
| `openai-gpt-4` | OpenAI | gpt-4 |
| `openai-gpt-4o` | OpenAI | gpt-4o |
| `ollama-llama3` | Ollama (local) | llama3 |
| `ollama-mistral` | Ollama (local) | mistral |
| `together-mixtral` | Together AI | Mixtral-8x7B |
| `cohere-command` | Cohere | command-r-plus |

> **Tip:** You can also add models via the Admin UI at `/ui` without restarting the proxy.

---

## Adding New Models

Edit `litellm_config.yaml` and add an entry under `model_list`:

```yaml
- model_name: my-new-model          # alias your apps will use
  litellm_params:
    model: provider/actual-model-id  # e.g. anthropic/claude-3-opus-20240229
    api_key: os.environ/MY_API_KEY
```

Then restart:

```bash
docker-compose restart litellm
```

Or add models dynamically via the Admin UI at `http://localhost:4000/ui`.

---

## Management

```bash
# View logs
docker-compose logs -f litellm

# Restart proxy (after config changes)
docker-compose restart litellm

# Stop everything
docker-compose down

# Stop and remove data volumes
docker-compose down -v

# Rebuild after Dockerfile changes
docker-compose up -d --build
```

---

## Debugging

```bash
# Set in .env for verbose logging
LITELLM_LOG=DEBUG

# Or check health
curl http://localhost:4000/health/liveliness
curl http://localhost:4000/health/readiness
```

---

## Key Management (Virtual Keys)

Generate API keys with budgets and rate limits:

```bash
curl http://localhost:4000/key/generate \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "models": ["gpt-4", "claude-sonnet"],
    "max_budget": 100,
    "duration": "30d"
  }'
```

Or manage keys through the Admin UI at `/ui`.

---

## References

- [LiteLLM Docs](https://docs.litellm.ai/)
- [LiteLLM Proxy Config](https://docs.litellm.ai/docs/proxy/configs)
- [Supported Models](https://docs.litellm.ai/docs/providers)
- [LiteLLM GitHub](https://github.com/BerriAI/litellm)
