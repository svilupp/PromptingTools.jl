# Unified Usage Schema Implementation Plan

This document outlines the implementation plan for comprehensive observability metadata in PromptingTools.jl and Logfire.jl.

## Overview

**Goal**: Capture all detailed usage statistics from LLM providers (OpenAI, Anthropic, Ollama) in a unified format that enables rich observability through Logfire.jl.

**Approach**: Two-layer schema
1. **Unified Keys** - Cross-provider normalized keys for OTEL mapping
2. **Raw Provider Dicts** - Original nested structures for debugging

---

## Part 1: PromptingTools.jl Changes

### 1.1 OpenAI Chat Completions (`src/llm_openai_chat.jl`)

Update all three `response_to_message` functions to extract detailed usage.

**Provider Response Structure:**
```json
{
  "model": "gpt-4o-2024-08-06",
  "id": "chatcmpl-abc123",
  "system_fingerprint": "fp_def456",
  "service_tier": "default",
  "usage": {
    "prompt_tokens": 100,
    "completion_tokens": 50,
    "total_tokens": 150,
    "prompt_tokens_details": {
      "cached_tokens": 50,
      "audio_tokens": 0
    },
    "completion_tokens_details": {
      "reasoning_tokens": 0,
      "audio_tokens": 0,
      "accepted_prediction_tokens": 0,
      "rejected_prediction_tokens": 0
    }
  }
}
```

**Extras to populate:**
```julia
extras = Dict{Symbol, Any}()

# Provider metadata
extras[:model] = resp.response[:model]
extras[:response_id] = resp.response[:id]
extras[:system_fingerprint] = resp.response[:system_fingerprint]  # if not nothing
extras[:service_tier] = resp.response[:service_tier]  # if present

# Unified usage keys (flattened for easy access)
if haskey(resp.response, :usage)
    usage = resp.response[:usage]

    # Prompt token details
    if haskey(usage, :prompt_tokens_details)
        details = usage[:prompt_tokens_details]
        haskey(details, :cached_tokens) && (extras[:cache_read_tokens] = details[:cached_tokens])
        haskey(details, :audio_tokens) && (extras[:audio_input_tokens] = details[:audio_tokens])
        # Keep raw dict
        extras[:prompt_tokens_details] = details
    end

    # Completion token details
    if haskey(usage, :completion_tokens_details)
        details = usage[:completion_tokens_details]
        haskey(details, :reasoning_tokens) && (extras[:reasoning_tokens] = details[:reasoning_tokens])
        haskey(details, :audio_tokens) && (extras[:audio_output_tokens] = details[:audio_tokens])
        haskey(details, :accepted_prediction_tokens) && (extras[:accepted_prediction_tokens] = details[:accepted_prediction_tokens])
        haskey(details, :rejected_prediction_tokens) && (extras[:rejected_prediction_tokens] = details[:rejected_prediction_tokens])
        # Keep raw dict
        extras[:completion_tokens_details] = details
    end
end
```

**Files to modify:**
- `src/llm_openai_chat.jl` - Three `response_to_message` functions (lines ~206, ~918, ~1596)

### 1.2 OpenAI Responses API (`src/llm_openai.jl` or dedicated file)

**Provider Response Structure:**
```json
{
  "id": "resp_abc123",
  "model": "gpt-4o-2024-08-06",
  "usage": {
    "input_tokens": 36,
    "output_tokens": 87,
    "total_tokens": 123,
    "input_tokens_details": {
      "cached_tokens": 0
    },
    "output_tokens_details": {
      "reasoning_tokens": 0
    }
  }
}
```

**Extras to populate:**
```julia
extras[:model] = resp.response[:model]
extras[:response_id] = resp.response[:id]

if haskey(resp.response, :usage)
    usage = resp.response[:usage]

    if haskey(usage, :input_tokens_details)
        details = usage[:input_tokens_details]
        haskey(details, :cached_tokens) && (extras[:cache_read_tokens] = details[:cached_tokens])
        extras[:input_tokens_details] = details
    end

    if haskey(usage, :output_tokens_details)
        details = usage[:output_tokens_details]
        haskey(details, :reasoning_tokens) && (extras[:reasoning_tokens] = details[:reasoning_tokens])
        extras[:output_tokens_details] = details
    end
end
```

### 1.3 Anthropic (`src/llm_anthropic.jl`)

**Provider Response Structure:**
```json
{
  "id": "msg_abc123",
  "model": "claude-sonnet-4-20250514",
  "usage": {
    "input_tokens": 2095,
    "output_tokens": 503,
    "cache_creation_input_tokens": 2051,
    "cache_read_input_tokens": 2051,
    "cache_creation": {
      "ephemeral_1h_input_tokens": 0,
      "ephemeral_5m_input_tokens": 0
    },
    "server_tool_use": {
      "web_search_requests": 0
    },
    "service_tier": "standard"
  }
}
```

**Extras to populate:**
```julia
extras = Dict{Symbol, Any}()

# Provider metadata
extras[:model] = resp.response[:model]
extras[:response_id] = resp.response[:id]

if haskey(resp.response, :usage)
    usage = resp.response[:usage]

    # Cache tokens (unified keys)
    haskey(usage, :cache_read_input_tokens) && (extras[:cache_read_tokens] = usage[:cache_read_input_tokens])
    haskey(usage, :cache_creation_input_tokens) && (extras[:cache_write_tokens] = usage[:cache_creation_input_tokens])

    # Keep original Anthropic keys for backwards compatibility
    haskey(usage, :cache_read_input_tokens) && (extras[:cache_read_input_tokens] = usage[:cache_read_input_tokens])
    haskey(usage, :cache_creation_input_tokens) && (extras[:cache_creation_input_tokens] = usage[:cache_creation_input_tokens])

    # Ephemeral cache details
    if haskey(usage, :cache_creation)
        details = usage[:cache_creation]
        haskey(details, :ephemeral_1h_input_tokens) && (extras[:cache_write_1h_tokens] = details[:ephemeral_1h_input_tokens])
        haskey(details, :ephemeral_5m_input_tokens) && (extras[:cache_write_5m_tokens] = details[:ephemeral_5m_input_tokens])
        extras[:cache_creation] = details
    end

    # Server tool use
    if haskey(usage, :server_tool_use)
        details = usage[:server_tool_use]
        haskey(details, :web_search_requests) && (extras[:web_search_requests] = details[:web_search_requests])
        extras[:server_tool_use] = details
    end

    # Service tier
    haskey(usage, :service_tier) && (extras[:service_tier] = usage[:service_tier])
end
```

**Files to modify:**
- `src/llm_anthropic.jl` - `aigenerate`, `aiextract`, `aitools` functions

### 1.4 Ollama (`src/llm_ollama.jl`, `src/llm_ollama_managed.jl`)

Ollama has simpler usage - just add `:model` (already done in current PR).

No additional changes needed beyond current PR.

---

## Part 2: Logfire.jl Changes (Separate Implementation)

### 2.1 Add `_record_detailed_usage!` Function

**File:** `src/logfire_schema.jl`

```julia
"""
Record detailed usage statistics from extras to OTEL GenAI attributes.

Reads unified keys first, falls back to raw provider dicts.
"""
function _record_detailed_usage!(span, ai_msg)
    ai_msg === nothing && return
    extras = _getextras(ai_msg)
    isempty(extras) && return

    # === Unified Keys (preferred) ===

    # Cache tokens
    _set_if_some(span, "gen_ai.usage.cache_read_tokens", get(extras, :cache_read_tokens, nothing))
    _set_if_some(span, "gen_ai.usage.cache_write_tokens", get(extras, :cache_write_tokens, nothing))
    _set_if_some(span, "gen_ai.usage.cache_write_1h_tokens", get(extras, :cache_write_1h_tokens, nothing))
    _set_if_some(span, "gen_ai.usage.cache_write_5m_tokens", get(extras, :cache_write_5m_tokens, nothing))

    # Reasoning/audio tokens
    _set_if_some(span, "gen_ai.usage.reasoning_tokens", get(extras, :reasoning_tokens, nothing))
    _set_if_some(span, "gen_ai.usage.audio_input_tokens", get(extras, :audio_input_tokens, nothing))
    _set_if_some(span, "gen_ai.usage.audio_output_tokens", get(extras, :audio_output_tokens, nothing))

    # Prediction tokens
    _set_if_some(span, "gen_ai.usage.accepted_prediction_tokens", get(extras, :accepted_prediction_tokens, nothing))
    _set_if_some(span, "gen_ai.usage.rejected_prediction_tokens", get(extras, :rejected_prediction_tokens, nothing))

    # Service tier
    _set_if_some(span, "gen_ai.service_tier", get(extras, :service_tier, nothing))

    # Anthropic server tools
    _set_if_some(span, "gen_ai.usage.web_search_requests", get(extras, :web_search_requests, nothing))

    # === Fallback to Raw Dicts (for older PromptingTools versions) ===

    # OpenAI prompt_tokens_details fallback
    if !haskey(extras, :cache_read_tokens) && haskey(extras, :prompt_tokens_details)
        details = extras[:prompt_tokens_details]
        if details isa AbstractDict
            _set_if_some(span, "gen_ai.usage.cache_read_tokens", get(details, :cached_tokens, nothing))
            _set_if_some(span, "gen_ai.usage.audio_input_tokens", get(details, :audio_tokens, nothing))
        end
    end

    # OpenAI completion_tokens_details fallback
    if !haskey(extras, :reasoning_tokens) && haskey(extras, :completion_tokens_details)
        details = extras[:completion_tokens_details]
        if details isa AbstractDict
            _set_if_some(span, "gen_ai.usage.reasoning_tokens", get(details, :reasoning_tokens, nothing))
            _set_if_some(span, "gen_ai.usage.audio_output_tokens", get(details, :audio_tokens, nothing))
            _set_if_some(span, "gen_ai.usage.accepted_prediction_tokens", get(details, :accepted_prediction_tokens, nothing))
            _set_if_some(span, "gen_ai.usage.rejected_prediction_tokens", get(details, :rejected_prediction_tokens, nothing))
        end
    end

    # Anthropic cache fallback (original keys)
    if !haskey(extras, :cache_read_tokens)
        _set_if_some(span, "gen_ai.usage.cache_read_tokens", get(extras, :cache_read_input_tokens, nothing))
    end
    if !haskey(extras, :cache_write_tokens)
        _set_if_some(span, "gen_ai.usage.cache_write_tokens", get(extras, :cache_creation_input_tokens, nothing))
    end
end
```

### 2.2 Update `_record_response_attrs!` to Call New Function

```julia
function _record_response_attrs!(span, ai_msg, requested_model::AbstractString)
    ai_msg === nothing && return
    extras = _getextras(ai_msg)

    _set_if_some(span, "gen_ai.response.model", get(extras, :model, requested_model))
    _set_if_some(span, "gen_ai.response.finish_reasons", _getfield_or(ai_msg, :finish_reason, nothing))
    latency = _getfield_or(ai_msg, :elapsed, nothing)
    latency !== nothing && _set_if_some(span, "gen_ai.latency_ms", latency * 1000)
    _set_if_some(span, "gen_ai.cost", _getfield_or(ai_msg, :cost, nothing))
    _set_if_some(span, "gen_ai.response.id", get(extras, :response_id, get(extras, :id, nothing)))
    _set_if_some(span, "gen_ai.system.fingerprint", get(extras, :system_fingerprint, nothing))
    _set_if_some(span, "gen_ai.response.status",
        _getfield_or(ai_msg, :status, get(extras, :status, nothing)))
    _set_if_some(span, "gen_ai.response.run_id",
        _getfield_or(ai_msg, :run_id, get(extras, :run_id, nothing)))

    # NEW: Record detailed usage
    _record_detailed_usage!(span, ai_msg)
end
```

### 2.3 Update Documentation

**File:** `docs/src/otel-genai.md`

Add new section for detailed usage attributes:

```markdown
### Detailed Usage Attributes

| Attribute | Type | Description |
|-----------|------|-------------|
| `gen_ai.usage.input_tokens` | int | Total input tokens |
| `gen_ai.usage.output_tokens` | int | Total output tokens |
| `gen_ai.usage.total_tokens` | int | Sum of input + output |
| `gen_ai.usage.cache_read_tokens` | int | Tokens read from cache |
| `gen_ai.usage.cache_write_tokens` | int | Tokens written to cache |
| `gen_ai.usage.cache_write_1h_tokens` | int | Anthropic 1h ephemeral cache |
| `gen_ai.usage.cache_write_5m_tokens` | int | Anthropic 5m ephemeral cache |
| `gen_ai.usage.reasoning_tokens` | int | Chain-of-thought tokens |
| `gen_ai.usage.audio_input_tokens` | int | Audio tokens in input |
| `gen_ai.usage.audio_output_tokens` | int | Audio tokens in output |
| `gen_ai.usage.accepted_prediction_tokens` | int | Predicted tokens accepted |
| `gen_ai.usage.rejected_prediction_tokens` | int | Predicted tokens rejected |
| `gen_ai.usage.web_search_requests` | int | Anthropic web searches |
| `gen_ai.service_tier` | string | Service tier used |
```

---

## Part 3: Complete Unified Key Reference

### Provider → Unified Key → OTEL Attribute

| Provider | Provider Field | Unified Key | OTEL Attribute |
|----------|---------------|-------------|----------------|
| **All** | `response.model` | `:model` | `gen_ai.response.model` |
| **All** | `response.id` | `:response_id` | `gen_ai.response.id` |
| **OpenAI** | `system_fingerprint` | `:system_fingerprint` | `gen_ai.system.fingerprint` |
| **Both** | `service_tier` | `:service_tier` | `gen_ai.service_tier` |
| **OpenAI** | `prompt_tokens_details.cached_tokens` | `:cache_read_tokens` | `gen_ai.usage.cache_read_tokens` |
| **OpenAI** | `prompt_tokens_details.audio_tokens` | `:audio_input_tokens` | `gen_ai.usage.audio_input_tokens` |
| **OpenAI** | `completion_tokens_details.reasoning_tokens` | `:reasoning_tokens` | `gen_ai.usage.reasoning_tokens` |
| **OpenAI** | `completion_tokens_details.audio_tokens` | `:audio_output_tokens` | `gen_ai.usage.audio_output_tokens` |
| **OpenAI** | `completion_tokens_details.accepted_prediction_tokens` | `:accepted_prediction_tokens` | `gen_ai.usage.accepted_prediction_tokens` |
| **OpenAI** | `completion_tokens_details.rejected_prediction_tokens` | `:rejected_prediction_tokens` | `gen_ai.usage.rejected_prediction_tokens` |
| **Anthropic** | `cache_read_input_tokens` | `:cache_read_tokens` | `gen_ai.usage.cache_read_tokens` |
| **Anthropic** | `cache_creation_input_tokens` | `:cache_write_tokens` | `gen_ai.usage.cache_write_tokens` |
| **Anthropic** | `cache_creation.ephemeral_1h_input_tokens` | `:cache_write_1h_tokens` | `gen_ai.usage.cache_write_1h_tokens` |
| **Anthropic** | `cache_creation.ephemeral_5m_input_tokens` | `:cache_write_5m_tokens` | `gen_ai.usage.cache_write_5m_tokens` |
| **Anthropic** | `server_tool_use.web_search_requests` | `:web_search_requests` | `gen_ai.usage.web_search_requests` |

### Backwards Compatibility Keys (Anthropic)

These original Anthropic keys are kept for backwards compatibility:
- `:cache_creation_input_tokens` (in addition to `:cache_write_tokens`)
- `:cache_read_input_tokens` (in addition to `:cache_read_tokens`)

---

## Part 4: Implementation Checklist

### PromptingTools.jl (This PR)

- [ ] **OpenAI Chat** (`src/llm_openai_chat.jl`)
  - [ ] Update `response_to_message` for `aigenerate` (~line 206)
  - [ ] Update `response_to_message` for `aiextract` (~line 918)
  - [ ] Update `response_to_message` for `aitools` (~line 1596)
  - [ ] Add unified keys: `:cache_read_tokens`, `:reasoning_tokens`, `:audio_input_tokens`, `:audio_output_tokens`, `:accepted_prediction_tokens`, `:rejected_prediction_tokens`, `:service_tier`
  - [ ] Keep raw dicts: `:prompt_tokens_details`, `:completion_tokens_details`

- [ ] **Anthropic** (`src/llm_anthropic.jl`)
  - [ ] Update `aigenerate` function
  - [ ] Update `aiextract` function
  - [ ] Update `aitools` function
  - [ ] Add unified keys: `:cache_read_tokens`, `:cache_write_tokens`, `:cached_write_1h_tokens`, `:cached_write_5m_tokens`, `:web_search_requests`, `:service_tier`
  - [ ] Add `:response_id` from `response.id`
  - [ ] Keep raw dicts: `:cache_creation`, `:server_tool_use`
  - [ ] Keep backwards compat: `:cache_creation_input_tokens`, `:cache_read_input_tokens`

- [ ] **Tests**
  - [ ] Update `test/llm_openai_chat.jl` with new unified keys
  - [ ] Update `test/llm_anthropic.jl` with new unified keys
  - [ ] Test backwards compatibility

- [ ] **Documentation**
  - [ ] Update CHANGELOG.md
  - [ ] Update README.md Logfire section if needed

### Logfire.jl (Separate PR)

- [ ] Add `_record_detailed_usage!(span, ai_msg)` function in `src/logfire_schema.jl`
- [ ] Call `_record_detailed_usage!` from `_record_response_attrs!`
- [ ] Update `docs/src/otel-genai.md` with new attributes
- [ ] Add tests for new usage recording
- [ ] Test fallback to raw dicts

---

## Part 5: Example Result

After implementation, an OpenAI response will populate `extras` like:

```julia
extras = Dict{Symbol, Any}(
    # Provider metadata
    :model => "gpt-4o-2024-08-06",
    :response_id => "chatcmpl-abc123xyz",
    :system_fingerprint => "fp_def456",
    :service_tier => "default",

    # Unified usage keys
    :cache_read_tokens => 50,
    :reasoning_tokens => 0,
    :audio_input_tokens => 0,
    :audio_output_tokens => 0,
    :accepted_prediction_tokens => 0,
    :rejected_prediction_tokens => 0,

    # Raw dicts (for debugging)
    :prompt_tokens_details => Dict(:cached_tokens => 50, :audio_tokens => 0),
    :completion_tokens_details => Dict(:reasoning_tokens => 0, :audio_tokens => 0, ...),
)
```

And Logfire.jl will record OTEL attributes:
```
gen_ai.response.model = "gpt-4o-2024-08-06"
gen_ai.response.id = "chatcmpl-abc123xyz"
gen_ai.system.fingerprint = "fp_def456"
gen_ai.service_tier = "default"
gen_ai.usage.input_tokens = 100
gen_ai.usage.output_tokens = 50
gen_ai.usage.total_tokens = 150
gen_ai.usage.cache_read_tokens = 50
gen_ai.usage.reasoning_tokens = 0
gen_ai.usage.audio_input_tokens = 0
gen_ai.usage.audio_output_tokens = 0
gen_ai.usage.accepted_prediction_tokens = 0
gen_ai.usage.rejected_prediction_tokens = 0
```

---

*Last updated: 2024-11-28*
