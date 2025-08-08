using PromptingTools

# Demonstrates GPT-5-specific kwargs for controlling verbosity and reasoning effort

# Lower the verbosity of the text response
msg_low = aigenerate("Explain the theory of relativity in two sentences";
    model = "gpt-5-mini",
    api_kwargs = (; verbosity = "low"))
println(msg_low.content)

# Minimize reasoning effort
msg_reason = aigenerate("What is 2 + 2?";
    model = "gpt-5-mini",
    api_kwargs = (; reasoning_effort = "minimal"))
println(msg_reason.content)
