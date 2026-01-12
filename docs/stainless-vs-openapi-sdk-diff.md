# SDK Diff: Stainless vs OpenAPI Generator

**Generated:** January 11, 2026
**Stainless SDK Version:** 0.4.0rc2
**OpenAPI Generator SDK Version:** 0.4.0rc2

## Executive Summary

Both SDKs provide a Python client for Llama Stack with hierarchical API access. The key differences are in the underlying HTTP client, configuration approach, and union type handling.

**Recommendation:** The OpenAPI Generator SDK is functionally equivalent for all core use cases.

---

## 1. Package Structure

### Stainless SDK

```
llama_stack_client/
├── __init__.py
├── _client.py              # Main client classes
├── _base_client.py         # HTTP client base
├── _exceptions.py          # Exception hierarchy
├── _streaming.py           # Stream/AsyncStream classes
├── _types.py               # Type definitions
├── _version.py
├── resources/              # API resource classes
│   ├── chat/
│   │   └── completions.py
│   ├── responses/
│   ├── alpha/
│   └── ...
├── types/                  # Request/response types
└── lib/                    # CLI and utilities
```

**Total files:** 351

### OpenAPI Generator SDK

```
llama_stack_client/
├── __init__.py             # All exports
├── llama_stack_client.py   # Main client class
├── api_client.py           # HTTP client
├── configuration.py        # Configuration class
├── exceptions.py           # Exception classes
├── stream.py               # Stream class
├── api/                    # API classes (one per resource)
│   ├── admin_api.py
│   ├── chat_completions_api.py
│   ├── responses_api.py
│   └── ...
├── models/                 # Pydantic models
│   ├── open_ai_chat_completion.py
│   ├── model.py
│   └── ...
└── lib/                    # CLI and utilities
```

**Total files:** 557

---

## 2. Client Initialization

### Stainless SDK

```python
from llama_stack_client import LlamaStackClient

# Constructor-based configuration
client = LlamaStackClient(
    base_url="http://localhost:8321",
    api_key="optional-api-key",      # Optional
    timeout=30.0,                     # Optional
    max_retries=2,                    # Optional
)

# Environment variables supported:
# LLAMA_STACK_BASE_URL
# LLAMA_STACK_API_KEY
```

### OpenAPI Generator SDK

```python
from llama_stack_client import LlamaStackClient, Configuration

# Configuration object pattern
config = Configuration(
    host="http://localhost:8321",
    api_key={"Authorization": "Bearer token"},  # Optional, header-based
)
client = LlamaStackClient(config)

# Or inline:
client = LlamaStackClient(Configuration(host="http://localhost:8321"))

# Or exactly like Stainless
client = LlamaStackClient(base_url="http://localhost:8321")
```

### Migration

None needed, as the new SDK supports the same format

---

## 3. Exception Classes

### Stainless SDK

```python
from llama_stack_client._exceptions import (
    LlamaStackClientError,      # Base exception
    APIError,                   # API error base
    APIStatusError,             # HTTP status error base
    BadRequestError,            # 400
    AuthenticationError,        # 401
    PermissionDeniedError,      # 403
    NotFoundError,              # 404
    ConflictError,              # 409
    UnprocessableEntityError,   # 422
    RateLimitError,             # 429
    InternalServerError,        # 500+
    APIConnectionError,         # Connection failed
    APITimeoutError,            # Request timed out
)

# Exception properties:
# - message: str
# - request: httpx.Request
# - response: httpx.Response (for status errors)
# - body: object | None
# - status_code: int
```

### OpenAPI Generator SDK

```python
from llama_stack_client.exceptions import (
    OpenApiException,           # Base exception
    ApiException,               # API error base
    BadRequestException,        # 400
    UnauthorizedException,      # 401
    ForbiddenException,         # 403
    NotFoundException,          # 404
    ConflictException,          # 409
    UnprocessableEntityException,  # 422
    RateLimitException,         # 429
    ServiceException,           # 500+
    ApiTypeError,               # Type validation error
    ApiValueError,              # Value validation error
)

# Exception properties:
# - status: int
# - reason: str
# - body: str
# - data: Any
# - headers: dict
# - message: str, alias for reason
# - status_code: int, alias for status
```

### Exception Mapping

| HTTP Status | Stainless | OpenAPI Generator |
|-------------|-----------|-------------------|
| 400 | `BadRequestError` | `BadRequestException` |
| 401 | `AuthenticationError` | `UnauthorizedException` |
| 403 | `PermissionDeniedError` | `ForbiddenException` |
| 404 | `NotFoundError` | `NotFoundException` |
| 409 | `ConflictError` | `ConflictException` |
| 422 | `UnprocessableEntityError` | `UnprocessableEntityException` |
| 429 | `RateLimitError` | *Not implemented* |
| 500+ | `InternalServerError` | `ServiceException` |

### Migration

For most use cases, none needed, becasue there's aliasing from *Exception to *Error and key attributes are also aliased.
However if client code tries to access request/response, a change is indeed needed.

---

## 4. API Method Signatures

### Chat Completion

#### Stainless SDK

```python
response = client.chat.completions.create(
    model="ollama/llama3.2:1b",
    messages=[
        {"role": "system", "content": "You are helpful."},
        {"role": "user", "content": "Hello!"}
    ],
    max_tokens=100,
    stream=False,
)

# Response type: OpenAIChatCompletion
print(response.choices[0].message.content)  # Direct string access
```

#### OpenAPI Generator SDK

```python
response = client.chat.completions.create(
    model="ollama/llama3.2:1b",
    messages=[
        {"role": "system", "content": "You are helpful."},
        {"role": "user", "content": "Hello!"}
    ],
    max_tokens=100,
    stream=False,
)

# Response type: OpenAIChatCompletion
content = response.choices[0].message.content
# Content may be wrapped in union type
actual = content.actual_instance if hasattr(content, 'actual_instance') else content
print(actual)
# But direct access, just like Stainless, works too!
print(response.choices[0].message.content)  # Direct string access
```

### Migration

No migration needed

---

## 5. Hierarchical API Access

Both SDKs support identical hierarchical patterns

```python
# Stable APIs (v1)
client.chat.completions.create(...)
client.responses.create(...)
client.embeddings.create(...)
client.models.list()
client.files.list()
client.vector_stores.create(...)
client.vector_stores.files.list(...)

# Beta APIs (v1beta)
client.beta.datasets.list()

# Alpha APIs (v1alpha)
client.alpha.inference.rerank(...)
client.alpha.post_training.supervised_fine_tune(...)
client.alpha.benchmarks.list()
client.alpha.admin.health()
```

---

## 6. Type System

### Stainless SDK

- Uses Pydantic v2 models
- TypedDict for request parameters
- Strong IDE support with type stubs
- Union types are transparent

```python
from llama_stack_client.types import ChatCompletionCreateParams

params: ChatCompletionCreateParams = {
    "model": "llama3.2",
    "messages": [{"role": "user", "content": "Hi"}],
}
```

### OpenAPI Generator SDK

- Uses Pydantic v2 models
- Generated dataclasses with validation
- Supports also dict parameters
- Union types wrapped in discriminator classes

```python
from llama_stack_client.models import OpenAIChatCompletionRequest

request = OpenAIChatCompletionRequest(
    model="llama3.2",
    messages=[{"role": "user", "content": "Hi"}],
)
# But can also accept dict
request = OpenAIChatCompletionRequest(
    {
        "model": "llama3.2",
        "messages": [{"role": "user", "content": "Hi"}],
    }
)
```

---

## 7. HTTP Client

| Feature | Stainless (httpx) | OpenAPI Generator (urllib3) |
|---------|-------------------|----------------------------|
| Async support | Native `AsyncLlamaStackClient` | Native `AsyncLlamaStackClient` |
| Connection pooling | Built-in | Built-in |
| Retry logic | Built-in with backoff | Manual |
| Timeout handling | Per-request | Via Configuration |
| Proxy support | Native | Via Configuration |
| HTTP/2 | Supported | Not supported |

---

## 8. Features Comparison

| Feature | Stainless | OpenAPI Generator |
|---------|-----------|-------------------|
| Hierarchical API | Yes | Yes |
| Streaming (SSE) | Yes | Yes |
| Async client | Yes (`AsyncLlamaStackClient`) |  Yes (`AsyncLlamaStackClient`) 
| CLI tools | Yes | Yes (same lib/) |
| Pagination helpers | Yes | No |
| Retry with backoff | Yes | No |
| Environment variables | Yes | No |
| Type stubs (.pyi) | Yes | No |
| Union type transparency | Yes | No (wrapped) |

---

## 9. Wire Protocol

**Both SDKs produce identical HTTP requests.**

Example request for chat completion:

```http
POST /v1/chat/completions HTTP/1.1
Host: localhost:8321
Content-Type: application/json
X-LlamaStack-Client-Version: 0.4.0.dev0

{
  "model": "ollama/llama3.2:1b",
  "messages": [
    {"role": "user", "content": "Hello!"}
  ],
  "max_tokens": 100
}
```

---

## 10. Migration Checklist

### Optional Changes

- [ ] Remove environment variable reliance
- [ ] Add manual retry logic if needed

### Code Changes

```python
# Imports
# Before
from llama_stack_client import LlamaStackClient
from llama_stack_client._exceptions import NotFoundError

# After
from llama_stack_client import LlamaStackClient, Configuration
from llama_stack_client.exceptions import NotFoundException

# Initialization
# Before
client = LlamaStackClient(base_url="http://localhost:8321")

# After
client = LlamaStackClient(Configuration(host="http://localhost:8321"))

# Exception handling
# Before
except NotFoundError as e:
    print(e.message)

# After
except NotFoundException as e:
    print(e.reason)
```

---

## 11. Known Issues

### OpenAPI Generator SDK

2. **No RateLimitError (429)** - Falls through to generic `ApiException`

3. **No automatic retry** - Must implement manually

4. **No environment variable support** - Must pass config explicitly

### Stainless SDK

1. **Closed-source generator** - Cannot customize or debug generation
2. **Version coupling** - Tied to Stainless release cycle

---

## 12. Conclusion

The OpenAPI Generator SDK is a viable replacement for the Stainless SDK with the following trade-offs:

**Advantages:**
- Open-source generator (customizable templates)
- Community-maintained
- Multi-language support potential
- No vendor lock-in

**Disadvantages:**
- No built-in retry logic
- No environment variable support

**Recommendation:** Proceed with OpenAPI Generator SDK for production use after addressing the union type unwrapping in templates.
