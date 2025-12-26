## Usage Extraction Functions

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
