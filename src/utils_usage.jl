## Usage Extraction Functions

# Add schema types to CACHE_DISCOUNTS (now that schemas are defined)
CACHE_DISCOUNTS[OpenAISchema] = (read_discount = 0.5, write_premium = 0.0)
CACHE_DISCOUNTS[OpenAIResponseSchema] = (read_discount = 0.5, write_premium = 0.0)
CACHE_DISCOUNTS[GoogleOpenAISchema] = (read_discount = 0.9, write_premium = 0.0)
CACHE_DISCOUNTS[AnthropicSchema] = (read_discount = 0.9, write_premium = 0.25)
# Note: AbstractOpenAISchema, CustomOpenAISchema, etc. → default 0% (unknown provider)

"""
    _lookup_schema_type(schema::AbstractPromptSchema) -> Union{Nothing, NamedTuple}

Helper to look up cache discounts by schema type.
Checks exact type match and subtype relationships (e.g., TestEchoAnthropicSchema <: AnthropicSchema).
"""
function _lookup_schema_type(schema::AbstractPromptSchema)
    schema_type = typeof(schema)

    # Check exact type match first
    haskey(CACHE_DISCOUNTS, schema_type) && return CACHE_DISCOUNTS[schema_type]

    # Check if schema is subtype of any registered type
    for (key, discount) in CACHE_DISCOUNTS
        if key isa Type && schema isa key
            return discount
        end
    end

    return nothing
end

"""
    get_cache_discounts(model_id::String; schema::Union{Nothing, AbstractPromptSchema}=nothing) -> NamedTuple{(:read_discount, :write_premium), Tuple{Float64, Float64}}

Get cache discount configuration for a model.

Lookup priority:
1. Explicit schema parameter (if provided)
2. Schema from MODEL_REGISTRY (if model_id registered)
3. Model name prefix matching
4. Default (0%, 0%) for unknown models/providers

Returns `(read_discount=0.0, write_premium=0.0)` if no match found.

# Examples
```julia
# Schema-based (most reliable)
get_cache_discounts("any-model"; schema=GoogleOpenAISchema())  # (read_discount = 0.9, write_premium = 0.0)
get_cache_discounts("any-model"; schema=AnthropicSchema())     # (read_discount = 0.9, write_premium = 0.25)

# Model registry lookup (if model registered)
get_cache_discounts("gemini-2.5-flash")  # Looks up schema in registry → 90%

# Model name pattern matching (fallback)
get_cache_discounts("gpt-4o-2024-08-06")     # (read_discount = 0.5, write_premium = 0.0)
get_cache_discounts("claude-sonnet-4")       # (read_discount = 0.9, write_premium = 0.25)
get_cache_discounts("unknown-model")         # (read_discount = 0.0, write_premium = 0.0)
```
"""
function get_cache_discounts(model_id::String; schema::Union{Nothing, AbstractPromptSchema} = nothing)
    # Priority 1: Explicit schema provided
    if !isnothing(schema)
        discount = _lookup_schema_type(schema)
        !isnothing(discount) && return discount
    end

    # Priority 2: Look up schema from MODEL_REGISTRY
    if haskey(MODEL_REGISTRY, model_id)
        model_spec = MODEL_REGISTRY[model_id]
        # Only lookup if schema is not nothing
        if !isnothing(model_spec.schema)
            discount = _lookup_schema_type(model_spec.schema)
            !isnothing(discount) && return discount
        end
    end

    # Priority 3: Model name prefix matching
    for (key, discount) in CACHE_DISCOUNTS
        if key isa String && startswith(model_id, key)
            return discount
        end
    end

    # Priority 4: Default (safe for unknown providers)
    return (read_discount = 0.0, write_premium = 0.0)
end

"""
    extract_usage(schema::AbstractPromptSchema, resp; model_id="", elapsed=0.0) -> TokenUsage

Extract token usage from an API response into a standardized TokenUsage struct.

Each schema type has its own implementation to handle provider-specific response formats.
This is the main dispatch point for usage extraction across all providers.

# Arguments
- `schema`: The prompt schema (determines provider-specific parsing)
- `resp`: The raw API response
- `model_id`: Model identifier for cost calculation
- `elapsed`: Time taken for the API call in seconds

# Returns
A `TokenUsage` struct with normalized token counts and calculated cost.
"""
function extract_usage end

# Fallback for unknown schemas
function extract_usage(::AbstractPromptSchema, resp; model_id::String = "", elapsed::Float64 = 0.0)
    TokenUsage(; model_id, elapsed)
end
