# helper to extract handlebar variables (eg, `{{var}}`) from a prompt string
function _extract_handlebar_variables(s::AbstractString)
    Symbol[Symbol(m[1]) for m in eachmatch(r"\{\{([^\}]+)\}\}", s)]
end

# helper to produce summary message of how many tokens were used and for how much
function _report_stats(msg, model::String, model_costs::AbstractDict = Dict())
    token_prices = get(model_costs, model, (0.0, 0.0))
    cost = sum(msg.tokens ./ 1000 .* token_prices)
    cost_str = iszero(cost) ? "" : " @ Cost: \$$(round(cost; digits=4))"

    return "Tokens: $(sum(msg.tokens))$(cost_str) in $(round(msg.elapsed;digits=1)) seconds"
end
