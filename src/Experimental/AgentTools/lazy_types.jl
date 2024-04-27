# The following implements lazy types for all ai* functions (eg, aigenerate -> AIGenerate) and AICodeFixer

abstract type AbstractAIPrompter end
abstract type AICallBlock end

"""
    RetryConfig

Configuration for self-fixing the AI calls. It includes the following fields:

# Fields
- `retries::Int`: The number of retries ("fixing rounds") that have been attempted so far.
- `calls::Int`: The total number of SUCCESSFULLY generated ai* function calls made so far (across all samples/retry rounds).
  Ie, if a call fails, because of an API error, it's not counted, because it didn't reach the LLM.
- `max_retries::Int`: The maximum number of retries ("fixing rounds") allowed for the AI call. Defaults to 10.
- `max_calls::Int`: The maximum number of ai* function calls allowed for the AI call. Defaults to 99.
- `retry_delay::Int`: The delay (in seconds) between retry rounds. Defaults to 0s.
- `n_samples::Int`: The number of samples to generate in each ai* call round (to increase changes of successful pass). Defaults to 1.
- `scoring::AbstractScoringMethod`: The scoring method to use for generating multiple samples. Defaults to `UCT(sqrt(2))`.
- `ordering::Symbol`: The ordering to use for select the best samples. With `:PostOrderDFS` we prioritize leaves, with `:PreOrderDFS` we prioritize the root. Defaults to `:PostOrderDFS`.
- `feedback_inplace::Bool`: Whether to provide feedback in previous UserMessage (and remove the past AIMessage) or to create a new UserMessage. Defaults to `false`.
- `feedback_template::Symbol`: Template to use for feedback in place. Defaults to `:FeedbackFromEvaluator`.
- `temperature::Float64`: The temperature to use for sampling. Relevant only if not defined in `api_kwargs` provided. Defaults to 0.7.
- `catch_errors::Bool`: Whether to catch errors during `run!` of AICall. Saves them in `aicall.error`. Defaults to `false`.
"""
@kwdef mutable struct RetryConfig
    retries::Int = 0
    calls::Int = 0
    max_retries::Int = 10
    max_calls::Int = 99
    retry_delay::Int = 0
    n_samples::Int = 1
    scoring::AbstractScoringMethod = UCT()
    ordering::Symbol = :PostOrderDFS
    feedback_inplace::Bool = false
    feedback_template::Symbol = :FeedbackFromEvaluator # Template to use for feedback
    temperature::Float64 = 0.7
    catch_errors::Bool = false
end
function Base.show(io::IO, config::RetryConfig)
    dump(IOContext(io, :limit => true), config, maxdepth = 1)
end
function Base.copy(config::RetryConfig)
    return deepcopy(config)
end
function Base.var"=="(c1::RetryConfig, c2::RetryConfig)
    all(f -> getfield(c1, f) == getfield(c2, f), fieldnames(typeof(c1)))
end

"""
    AICall(func::F, args...; kwargs...) where {F<:Function}

    AIGenerate(args...; kwargs...)
    AIEmbed(args...; kwargs...)
    AIExtract(args...; kwargs...)

A lazy call wrapper for AI functions in the `PromptingTools` module, such as `aigenerate`.

The `AICall` struct is designed to facilitate a deferred execution model (lazy evaluation) for AI functions that interact with a Language Learning Model (LLM). It stores the necessary information for an AI call and executes the underlying AI function only when supplied with a `UserMessage` or when the `run!` method is applied. This approach allows for more flexible and efficient handling of AI function calls, especially in interactive environments.

Seel also: `run!`, `AICodeFixer`

# Fields
- `func::F`: The AI function to be called lazily. This should be a function like `aigenerate` or other `ai*` functions.
- `schema::Union{Nothing, PT.AbstractPromptSchema}`: Optional schema to structure the prompt for the AI function.
- `conversation::Vector{PT.AbstractMessage}`: A vector of messages that forms the conversation context for the AI call.
- `kwargs::NamedTuple`: Keyword arguments to be passed to the AI function.
- `success::Union{Nothing, Bool}`: Indicates whether the last call was successful (true) or not (false). `Nothing` if the call hasn't been made yet.
- `error::Union{Nothing, Exception}`: Stores any exception that occurred during the last call. `Nothing` if no error occurred or if the call hasn't been made yet.

# Example

Initiate an `AICall` like any ai* function, eg, `AIGenerate`:

```julia
aicall = AICall(aigenerate)

# With arguments and kwargs like ai* functions
# from `aigenerate(schema, conversation; model="abc", api_kwargs=(; temperature=0.1))`
# to
aicall = AICall(aigenerate, schema, conversation; model="abc", api_kwargs=(; temperature=0.1)

# Or with a template
aicall = AIGenerate(:JuliaExpertAsk; ask="xyz", model="abc", api_kwargs=(; temperature=0.1))
```

Trigger the AICall with `run!` (it returns the update `AICall` struct back):
```julia
aicall |> run!
````

You can also use `AICall` as a functor to trigger the AI call with a `UserMessage` or simply the text to send:
```julia
aicall(UserMessage("Hello, world!"))  # Triggers the lazy call
result = run!(aicall)  # Explicitly runs the AI call
```
This can be used to "reply" to previous message / continue the stored conversation

# Notes
- The `AICall` struct is a key component in building flexible and efficient Agentic pipelines
- The lazy evaluation model allows for setting up the call parameters in advance and deferring the actual execution until it is explicitly triggered.
- This struct is particularly useful in scenarios where the timing of AI function execution needs to be deferred or where multiple potential calls need to be prepared and selectively executed.
"""
@kwdef mutable struct AICall{F <: Function} <: AICallBlock
    func::F
    schema::Union{Nothing, PT.AbstractPromptSchema} = nothing
    conversation::Vector{<:PT.AbstractMessage} = Vector{PT.AbstractMessage}()
    kwargs::NamedTuple = NamedTuple()
    success::Union{Nothing, Bool} = nothing # success of the last call - in different airetry checks etc
    error::Union{Nothing, Exception} = nothing
    ## by default, we use samples to hold the conversation attempts across different fixing rounds
    samples::SampleNode = SampleNode(; data = Vector{PT.AbstractMessage}())
    active_sample_id::Int = -1
    memory::Dict{Symbol, Any} = Dict{Symbol, Any}()
    config::RetryConfig = RetryConfig()  # Configuration for retries
    prompter::Union{Nothing, AbstractAIPrompter} = nothing
end

function AICall(func::F, args...; kwargs...) where {F <: Function}
    schema, conversation = unwrap_aicall_args(args)
    kwargs, config = extract_config(kwargs, RetryConfig())
    return AICall{F}(; func, schema, conversation, config, kwargs)
end

"""
    AIGenerate(args...; kwargs...)

Creates a lazy instance of `aigenerate`.
It is an instance of `AICall` with `aigenerate` as the function.

Use exactly the same arguments and keyword arguments as `aigenerate` (see `?aigenerate` for details).

"""
function AIGenerate(args...; kwargs...)
    return AICall(aigenerate, args...; kwargs...)
end

"""
    AIExtract(args...; kwargs...)

Creates a lazy instance of `aiextract`.
It is an instance of `AICall` with `aiextract` as the function.

Use exactly the same arguments and keyword arguments as `aiextract` (see `?aiextract` for details).

"""
function AIExtract(args...; kwargs...)
    return AICall(aiextract, args...; kwargs...)
end

"""
    AIEmbed(args...; kwargs...)

Creates a lazy instance of `aiembed`.
It is an instance of `AICall` with `aiembed` as the function.

Use exactly the same arguments and keyword arguments as `aiembed` (see `?aiembed` for details).

"""
function AIEmbed(args...; kwargs...)
    return AICall(aiembed, args...; kwargs...)
end

"""
    AIClassify(args...; kwargs...)

Creates a lazy instance of `aiclassify`.
It is an instance of `AICall` with `aiclassify` as the function.

Use exactly the same arguments and keyword arguments as `aiclassify` (see `?aiclassify` for details).

"""
function AIClassify(args...; kwargs...)
    return AICall(aiclassify, args...; kwargs...)
end

"""
    AIScan(args...; kwargs...)

Creates a lazy instance of `aiscan`.
It is an instance of `AICall` with `aiscan` as the function.

Use exactly the same arguments and keyword arguments as `aiscan` (see `?aiscan` for details).

"""
function AIScan(args...; kwargs...)
    return AICall(aiscan, args...; kwargs...)
end

"""
    run!(aicall::AICallBlock; verbose::Int = 1, catch_errors::Bool = false, return_all::Bool = true, kwargs...)

Executes the AI call wrapped by an `AICallBlock` instance. This method triggers the actual communication with the AI model and processes the response based on the provided conversation context and parameters.

Note: Currently `return_all` must always be set to true.

# Arguments
- `aicall::AICallBlock`: An instance of `AICallBlock` which encapsulates the AI function call along with its context and parameters (eg, `AICall`, `AIGenerate`)
- `verbose::Integer=1`: A verbosity level for logging. A higher value indicates more detailed logging.
- `catch_errors::Union{Nothing, Bool}=nothing`: A flag to indicate whether errors should be caught and saved to `aicall.error`. If `nothing`, it defaults to `aicall.config.catch_errors`.
- `return_all::Bool=true`: A flag to indicate whether the whole conversation from the AI call should be returned. It should always be true.
- `kwargs...`: Additional keyword arguments that are passed to the AI function.

# Returns
- `AICallBlock`: The same `AICallBlock` instance, updated with the results of the AI call. This includes updated conversation, success status, and potential error information.

# Example
```julia
aicall = AICall(aigenerate)
run!(aicall)
```

Alternatively, you can trigger the `run!` call by using the AICall as a functor and calling it with a string or a UserMessage:
```julia
aicall = AICall(aigenerate)
aicall("Say hi!")
```

# Notes
- The `run!` method is a key component of the lazy evaluation model in `AICall`. It allows for the deferred execution of AI function calls, providing flexibility in how and when AI interactions are conducted.
- The method updates the `AICallBlock` instance with the outcome of the AI call, including any generated responses, success or failure status, and error information if an error occurred.
- This method is essential for scenarios where AI interactions are based on dynamic or evolving contexts, as it allows for real-time updates and responses based on the latest information.
"""
function run!(aicall::AICallBlock;
        verbose::Integer = 1,
        catch_errors::Union{Nothing, Bool} = nothing,
        return_all::Bool = true,
        kwargs...)
    @assert return_all "`return_all` must be true (provided: $return_all)"
    (; schema, conversation, config) = aicall
    (; max_calls, n_samples) = aicall.config

    catch_errors = isnothing(catch_errors) ? config.catch_errors : catch_errors
    verbose = min(verbose, get(aicall.kwargs, :verbose, 99))

    ## Locate the parent node in samples node, if it's the first call, we'll fall back to `aicall.samples` itself
    parent_node = find_node(aicall.samples, aicall.active_sample_id) |>
                  x -> isnothing(x) ? aicall.samples : x
    ## Obtain the new API kwargs (if we need to tweak parameters)
    new_api_kwargs = merge(get(aicall.kwargs, :api_kwargs, NamedTuple()),
        get(kwargs, :api_kwargs, NamedTuple()),
        (; temperature = aicall.config.temperature))
    ## Collect n_samples in a loop
    ## if API supports it, you can speed it up via `api_kwargs=(; n= n_samples)` to generate them at once
    samples_collected = 0
    for i in 1:n_samples
        ## Check if we don't need to collect more samples
        samples_collected >= n_samples && break
        ## Check if we have budget left
        if aicall.config.calls >= max_calls
            verbose > 0 &&
                @info "Max calls limit reached (calls: $(aicall.config.calls)). Generation interrupted."
            break
        end
        ## We need to set explicit temperature to ensure our calls are not cached 
        ## (small perturbations in temperature of each request, unless user requested temp=0)
        if !iszero(new_api_kwargs.temperature)
            new_api_kwargs = merge(new_api_kwargs,
                (; temperature = new_api_kwargs.temperature + 1e-3))
        end
        ## Call the API with try-catch (eg, catch API errors, bad user inputs, etc.)
        try
            ## Note: always return all conversation (including prompt)
            result = if isnothing(schema)
                aicall.func(conversation; aicall.kwargs..., kwargs...,
                    new_api_kwargs..., return_all = true)
            else
                aicall.func(schema, conversation; aicall.kwargs..., kwargs...,
                    new_api_kwargs..., return_all = true)
            end
            # unpack multiple samples (if present; if not, it will be a single sample in a vector)
            conv_list = split_multi_samples(result)
            for conv in conv_list
                ## save the sample into our sample tree
                node = expand!(parent_node, conv; success = true)
                aicall.active_sample_id = node.id
                aicall.config.calls += 1
                samples_collected += 1
            end
            aicall.success = true
        catch e
            verbose > 0 && @info "Error detected and caught in AICall"
            aicall.success = false
            aicall.error = e
            !catch_errors && rethrow(aicall.error)
        end
        ## Break the loop - no point in sampling if we get errors
        aicall.success == false && break
    end
    ## Finalize the generaion
    if aicall.success == true
        ## overwrite the active conversation
        current_node = find_node(aicall.samples, aicall.active_sample_id)
        aicall.conversation = current_node.data
        # Remove used kwargs (for placeholders)
        aicall.kwargs = remove_used_kwargs(aicall.kwargs, aicall.conversation)
        ## If first sample (parent == root node), 
        ## make sure that root node sample has a conversation to retry from
        if current_node.parent.id == aicall.samples.id && isempty(aicall.samples.data)
            aicall.samples.data = copy(aicall.conversation)
            pop!(aicall.samples.data)  # remove the last AI message
        end
    end
    return aicall
end

function Base.show(io::IO, aicall::AICallBlock; max_length::Int = 100)
    print(io,
        "$(typeof(aicall))(Messages: $(length(aicall.conversation)), Success: $(aicall.success))")
    ## If AIMessage, show the first 100 characters of the content
    if !isempty(aicall.conversation) && last(aicall.conversation) isa PT.AIMessage
        str = last(aicall.conversation).content
        print(io,
            "\n- Preview of the Latest AIMessage (see property `:conversation`):\n $(first(str,max_length))")
    end
end

function (aicall::AICall)(str::AbstractString; kwargs...)
    return aicall(PT.UserMessage(str); kwargs...)
end
function (aicall::AICall)(msg::PT.UserMessage; kwargs...)
    push!(aicall.conversation, msg)
    return run!(aicall; kwargs...)
end

"Helpful accessor for AICall blocks. Returns the last message in the conversation."
function PT.last_message(aicall::AICallBlock)
    length(aicall.conversation) == 0 ? nothing : aicall.conversation[end]
end

"Helpful accessor for AICall blocks. Returns the last output in the conversation (eg, the string/data in the last message)."
function PT.last_output(aicall::AICallBlock)
    msg = PT.last_message(aicall)
    return isnothing(msg) ? nothing : msg.content
end

function Base.isvalid(aicall::AICallBlock)
    aicall.success == true
end

function Base.copy(aicall::AICallBlock)
    return AICall{typeof(aicall.func)}(aicall.func,
        aicall.schema,
        copy(aicall.conversation),
        aicall.kwargs,
        aicall.success,
        aicall.error,
        copy(aicall.samples),
        aicall.active_sample_id,
        copy(aicall.memory),
        copy(aicall.config),
        aicall.prompter)
end
function Base.var"=="(c1::AICallBlock, c2::AICallBlock)
    all(f -> getfield(c1, f) == getfield(c2, f), fieldnames(typeof(c1)))
end

function aicodefixer_feedback(aicall::AICall; kwargs...)
    aicodefixer_feedback(aicall.conversation; kwargs...)
end

"""
    AICodeFixer(aicall::AICall, templates::Vector{<:PT.UserMessage}; num_rounds::Int = 3, feedback_func::Function = aicodefixer_feedback; kwargs...)
    AICodeFixer(aicall::AICall, template::Union{AITemplate, Symbol} = :CodeFixerRCI; kwargs...)

An AIAgent that iteratively evaluates any received Julia code and provides feedback back to the AI model if `num_rounds>0`.
`AICodeFixer` manages the lifecycle of a code fixing session, including tracking conversation history, rounds of interaction, and applying user feedback through a specialized feedback function.

It integrates with lazy AI call structures like `AIGenerate`. 

The operation is "lazy", ie, the agent is only executed when needed, eg, when `run!` is called.

# Fields
- `call::AICall`: The AI call that is being used for code generation or processing, eg, AIGenerate (same as `aigenerate` but "lazy", ie, called only when needed
- `templates::Union{Symbol, AITemplate, Vector{PT.UserMessage}}`: A set of user messages or templates that guide the AI's code fixing process. 
  The first UserMessage is used in the first round of code fixing, the second UserMessage is used for every subsequent iteration.
- `num_rounds::Int`: The number of rounds for the code fixing session. Defaults to 3.
- `round_counter::Int`: Counter to track the current round of interaction.
- `feedback_func::Function`: Function to generate feedback based on the AI's proposed code, defaults to `aicodefixer_feedback` 
  (modular thanks to type dispatch on `AbstractOutcomes`)
- `kwargs::NamedTuple`: Additional keyword arguments for customizing the AI call.

Note: Any kwargs provided to `run!()` will be passed to the underlying AICall.

# Example

Let's create an AIGenerate call and then pipe it to AICodeFixer to run a few rounds of the coding fixing:

```julia
# Create an AIGenerate call
lazy_call = AIGenerate("Write a function to do XYZ...")

# the action starts only when `run!` is called
result = lazy_call |> AICodeFixer |> run!

# Access the result of the code fixing session
# result.call refers to the AIGenerate lazy call above
conversation = result.call.conversation
fixed_code = last(conversation) # usually in the last message

# Preview the conversation history
preview(conversation)
```

You can change the template used to provide user feedback and number of counds via arguments:

```julia
# Setup an AIGenerate call
lazy_call = AIGenerate(aigenerate, "Write code to do XYZ...")

# Custom template and 2 fixing rounds
result = AICodeFixer(lazy_call, [PT.UserMessage("Please fix the code.\n\nFeedback: {{feedback}}")]; num_rounds = 2) |> run!

# The result now contains the AI's attempts to fix the code
preview(result.call.conversation)
```

# Notes
- `AICodeFixer` is particularly useful when code is hard to get right in one shot (eg, smaller models, complex syntax)
- The structure leverages the lazy evaluation model of `AICall` (/AIGenerate) to efficiently manage AI interactions and be able to repeatedly call it.
- The `run!` function executes the AI call and applies the feedback loop for the specified number of rounds, enabling an interactive code fixing process.
"""
@kwdef mutable struct AICodeFixer
    call::AICall
    templates::Vector{PT.UserMessage} = Vector{PT.UserMessage}()
    num_rounds::Int
    round_counter::Int = 0
    feedback_func::Function
    kwargs::NamedTuple = NamedTuple()

    function AICodeFixer(aicall::AICall, templates::Vector{<:PT.UserMessage},
            num_rounds::Int,
            round_counter::Int,
            feedback_func::Function,
            kwargs::NamedTuple)
        @assert num_rounds>=0 "`num_rounds` must be non-negative (provided: $num_rounds))"
        @assert !isempty(templates) "Must provide a template / user message (provided: $(length(templates)))"
        new(aicall, templates, num_rounds, round_counter, feedback_func, kwargs)
    end
end
function AICodeFixer(aicall::AICall, templates::Vector{<:PT.UserMessage};
        round_counter::Int = 0,
        num_rounds::Int = 3,
        feedback_func::Function = aicodefixer_feedback,
        kwargs...)
    AICodeFixer(aicall,
        templates,
        num_rounds,
        round_counter,
        feedback_func,
        NamedTuple(kwargs))
end
# Dispatch on template/symbol
function AICodeFixer(aicall::AICall,
        template::Union{AITemplate, Symbol} = :CodeFixerRCI;
        kwargs...)
    # Prepare template -- we expect two messages: the first is the intro, the second is the iteration steps
    template_rendered = if template isa AITemplate
        PT.render(aicall.schema, template)
    else
        @assert haskey(PT.TEMPLATE_STORE, template) "Template $(template) not found in TEMPLATE_STORE"
        PT.render(aicall.schema, AITemplate(template))
    end
    user_messages = filter(msg -> isa(msg, PT.UserMessage), template_rendered)
    @assert length(user_messages)>0 "Template $(template) must have at least 1 user message (provided: $(length(user_messages)))"
    AICodeFixer(aicall, convert(Vector{PT.UserMessage}, user_messages); kwargs...)
end

function Base.show(io::IO, fixer::AICodeFixer)
    print(io,
        "$(typeof(fixer))(Rounds: $(fixer.round_counter)/$(fixer.num_rounds))")
end

"""
    run!(codefixer::AICodeFixer; verbose::Int = 1, max_conversation_length::Int = 32000, run_kwargs...)

Executes the code fixing process encapsulated by the `AICodeFixer` instance. 
This method iteratively refines and fixes code by running the AI call in a loop for a specified number of rounds, using feedback from the code evaluation (`aicodefixer_feedback`) to improve the outcome in each iteration.

# Arguments
- `codefixer::AICodeFixer`: An instance of `AICodeFixer` containing the AI call, templates, and settings for the code fixing session.
- `verbose::Int=1`: Verbosity level for logging. A higher value indicates more detailed logging.
- `max_conversation_length::Int=32000`: Maximum length in characters for the conversation history to keep it within manageable limits, especially for large code fixing sessions.
- `num_rounds::Union{Nothing, Int}=nothing`: Number of additional rounds for the code fixing session. If `nothing`, the value from the `AICodeFixer` instance is used.
- `run_kwargs...`: Additional keyword arguments that are passed to the AI function.

# Returns
- `AICodeFixer`: The updated `AICodeFixer` instance with the results of the code fixing session.

# Usage
```julia
aicall = AICall(aigenerate, schema=mySchema, conversation=myConversation)
codefixer = AICodeFixer(aicall, myTemplates; num_rounds=5)
result = run!(codefixer, verbose=2)
```

# Notes
- The `run!` method drives the core logic of the `AICodeFixer`, iterating through rounds of AI interactions to refine and fix code.
- In each round, it applies feedback based on the current state of the conversation, allowing the AI to respond more effectively.
- The conversation history is managed to ensure it stays within the specified `max_conversation_length`, keeping the AI's focus on relevant parts of the conversation.
- This iterative process is essential for complex code fixing tasks where multiple interactions and refinements are required to achieve the desired outcome.
"""
function run!(codefixer::AICodeFixer;
        verbose::Int = 1,
        max_conversation_length::Int = 32000,
        num_rounds::Union{Nothing, Int} = nothing,
        run_kwargs...)
    (; call, templates, round_counter, feedback_func) = codefixer
    ## Select main num_rounds
    num_rounds_ = !isnothing(num_rounds) ? (codefixer.round_counter + num_rounds) :
                  codefixer.num_rounds

    # Call the aicall for the first time
    isnothing(call.success) && (run!(call; verbose, run_kwargs...))

    # Early exit
    num_rounds_ == 0 && return codefixer

    # Run the fixing loop `num_rounds` times
    while round_counter < num_rounds_
        round_counter += 1
        verbose > 0 && @info "CodeFixing Round: $(round_counter)/$(num_rounds_)"
        kwargs_new = feedback_func(call.conversation) # will update the feedback kwarg
        call.kwargs = (; call.kwargs..., kwargs_new...)
        # In the first round, add the intro message (first template)
        msg = round_counter == 1 ? first(templates) : last(templates)
        push!(call.conversation, msg)
        call.conversation = truncate_conversation(call.conversation;
            max_conversation_length)
        ## Call LLM again for the fix
        call = run!(call; verbose, run_kwargs...)
    end
    codefixer.round_counter = round_counter
    codefixer.call = call

    return codefixer
end

### Prompt Generators
# Placeholder for future
@kwdef mutable struct AIPrompter
end
