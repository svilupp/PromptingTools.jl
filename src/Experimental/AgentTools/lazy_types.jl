abstract type AICallBlock end

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
    success::Union{Nothing, Bool} = nothing
    error::Union{Nothing, Exception} = nothing
end

function AICall(func::F, args...; kwargs...) where {F <: Function}
    @assert length(args)<=2 "AICall takes at most 2 positional arguments (provided: $(length(args)))"
    schema = nothing
    conversation = Vector{PT.AbstractMessage}()
    for arg in args
        if isa(arg, PT.AbstractPromptSchema)
            schema = arg
        elseif isa(arg, Vector{<:PT.AbstractMessage})
            conversation = arg
        elseif isa(arg, AbstractString) && isempty(conversation)
            ## User Prompt -- create a UserMessage
            push!(conversation, PT.UserMessage(arg))
        elseif isa(arg, Symbol) && isempty(conversation)
            conversation = PT.render(schema, AITemplate(arg))
        elseif isa(arg, AITemplate) && isempty(conversation)
            conversation = PT.render(schema, arg)
        else
            error("Invalid argument type: $(typeof(arg))")
        end
    end

    return AICall{F}(; func, schema, conversation, kwargs = NamedTuple(kwargs))
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

# Arguments
- `aicall::AICallBlock`: An instance of `AICallBlock` which encapsulates the AI function call along with its context and parameters (eg, `AICall`, `AIGenerate`)
- `verbose::Int=1`: A verbosity level for logging. A higher value indicates more detailed logging.
- `catch_errors::Bool=false`: If set to `true`, the method will catch and handle errors internally. Otherwise, errors are propagated.
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
        verbose::Int = 1,
        catch_errors::Bool = false,
        return_all::Bool = true,
        kwargs...)
    @assert return_all "`return_all` must be true (provided: $return_all)"
    (; schema, conversation) = aicall
    try
        result = if isnothing(schema)
            aicall.func(conversation; aicall.kwargs..., kwargs..., return_all)
        else
            aicall.func(schema, conversation; aicall.kwargs..., kwargs..., return_all)
        end
        # Remove used kwargs (for placeholders)
        aicall.kwargs = remove_used_kwargs(aicall.kwargs, conversation)
        aicall.conversation = result
        aicall.success = true
    catch e
        verbose > 0 && @info "Error detected and caught in AICall"
        aicall.success = false
        aicall.error = e
        !catch_errors && rethrow(aicall.error)
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