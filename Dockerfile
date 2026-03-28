# =============================================================================
# LiteLLM Proxy - Dockerfile
# =============================================================================
# Uses the official LiteLLM Docker image with custom config overlay.
# Docs: https://docs.litellm.ai/docs/proxy/deploy
# =============================================================================

FROM ghcr.io/berriai/litellm:main-latest

# Set working directory
WORKDIR /app

# Copy the proxy configuration
COPY litellm_config.yaml /app/litellm_config.yaml

# Expose the proxy port
EXPOSE 4000

# The base image entrypoint already calls `litellm`.
# We only pass arguments here.
CMD ["--config", "/app/litellm_config.yaml", "--port", "4000", "--host", "0.0.0.0"]
