
# Reference for AgentTools {#Reference-for-AgentTools}
- [`PromptingTools.Experimental.AgentTools.AICall`](#PromptingTools.Experimental.AgentTools.AICall)
- [`PromptingTools.Experimental.AgentTools.AICodeFixer`](#PromptingTools.Experimental.AgentTools.AICodeFixer)
- [`PromptingTools.Experimental.AgentTools.RetryConfig`](#PromptingTools.Experimental.AgentTools.RetryConfig)
- [`PromptingTools.Experimental.AgentTools.SampleNode`](#PromptingTools.Experimental.AgentTools.SampleNode)
- [`PromptingTools.Experimental.AgentTools.ThompsonSampling`](#PromptingTools.Experimental.AgentTools.ThompsonSampling)
- [`PromptingTools.Experimental.AgentTools.UCT`](#PromptingTools.Experimental.AgentTools.UCT)
- [`PromptingTools.Experimental.AgentTools.AIClassify`](#PromptingTools.Experimental.AgentTools.AIClassify-Tuple)
- [`PromptingTools.Experimental.AgentTools.AIEmbed`](#PromptingTools.Experimental.AgentTools.AIEmbed-Tuple)
- [`PromptingTools.Experimental.AgentTools.AIExtract`](#PromptingTools.Experimental.AgentTools.AIExtract-Tuple)
- [`PromptingTools.Experimental.AgentTools.AIGenerate`](#PromptingTools.Experimental.AgentTools.AIGenerate-Tuple)
- [`PromptingTools.Experimental.AgentTools.AIScan`](#PromptingTools.Experimental.AgentTools.AIScan-Tuple)
- [`PromptingTools.Experimental.AgentTools.add_feedback!`](#PromptingTools.Experimental.AgentTools.add_feedback!-Tuple{AbstractVector{<:PromptingTools.AbstractMessage},%20PromptingTools.Experimental.AgentTools.SampleNode})
- [`PromptingTools.Experimental.AgentTools.aicodefixer_feedback`](#PromptingTools.Experimental.AgentTools.aicodefixer_feedback-Tuple{AbstractVector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.Experimental.AgentTools.airetry!`](#PromptingTools.Experimental.AgentTools.airetry!)
- [`PromptingTools.Experimental.AgentTools.backpropagate!`](#PromptingTools.Experimental.AgentTools.backpropagate!-Tuple{PromptingTools.Experimental.AgentTools.SampleNode})
- [`PromptingTools.Experimental.AgentTools.beta_sample`](#PromptingTools.Experimental.AgentTools.beta_sample-Tuple{Real,%20Real})
- [`PromptingTools.Experimental.AgentTools.collect_all_feedback`](#PromptingTools.Experimental.AgentTools.collect_all_feedback-Tuple{PromptingTools.Experimental.AgentTools.SampleNode})
- [`PromptingTools.Experimental.AgentTools.evaluate_condition!`](#PromptingTools.Experimental.AgentTools.evaluate_condition!)
- [`PromptingTools.Experimental.AgentTools.expand!`](#PromptingTools.Experimental.AgentTools.expand!-Tuple{PromptingTools.Experimental.AgentTools.SampleNode,%20Any})
- [`PromptingTools.Experimental.AgentTools.extract_config`](#PromptingTools.Experimental.AgentTools.extract_config-Union{Tuple{T},%20Tuple{Any,%20T}}%20where%20T)
- [`PromptingTools.Experimental.AgentTools.find_node`](#PromptingTools.Experimental.AgentTools.find_node-Tuple{PromptingTools.Experimental.AgentTools.SampleNode,%20Integer})
- [`PromptingTools.Experimental.AgentTools.gamma_sample`](#PromptingTools.Experimental.AgentTools.gamma_sample-Tuple{Real,%20Real})
- [`PromptingTools.Experimental.AgentTools.last_message`](#PromptingTools.Experimental.AgentTools.last_message-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock})
- [`PromptingTools.Experimental.AgentTools.last_output`](#PromptingTools.Experimental.AgentTools.last_output-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock})
- [`PromptingTools.Experimental.AgentTools.print_samples`](#PromptingTools.Experimental.AgentTools.print_samples-Tuple{PromptingTools.Experimental.AgentTools.SampleNode})
- [`PromptingTools.Experimental.AgentTools.remove_used_kwargs`](#PromptingTools.Experimental.AgentTools.remove_used_kwargs-Tuple{NamedTuple,%20AbstractVector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.Experimental.AgentTools.reset_success!`](#PromptingTools.Experimental.AgentTools.reset_success!)
- [`PromptingTools.Experimental.AgentTools.run!`](#PromptingTools.Experimental.AgentTools.run!-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock})
- [`PromptingTools.Experimental.AgentTools.run!`](#PromptingTools.Experimental.AgentTools.run!-Tuple{AICodeFixer})
- [`PromptingTools.Experimental.AgentTools.score`](#PromptingTools.Experimental.AgentTools.score-Tuple{PromptingTools.Experimental.AgentTools.SampleNode,%20PromptingTools.Experimental.AgentTools.ThompsonSampling})
- [`PromptingTools.Experimental.AgentTools.score`](#PromptingTools.Experimental.AgentTools.score-Tuple{PromptingTools.Experimental.AgentTools.SampleNode,%20PromptingTools.Experimental.AgentTools.UCT})
- [`PromptingTools.Experimental.AgentTools.select_best`](#PromptingTools.Experimental.AgentTools.select_best)
- [`PromptingTools.Experimental.AgentTools.split_multi_samples`](#PromptingTools.Experimental.AgentTools.split_multi_samples-Tuple{Any})
- [`PromptingTools.Experimental.AgentTools.truncate_conversation`](#PromptingTools.Experimental.AgentTools.truncate_conversation-Tuple{AbstractVector{<:PromptingTools.AbstractMessage}})
- [`PromptingTools.Experimental.AgentTools.unwrap_aicall_args`](#PromptingTools.Experimental.AgentTools.unwrap_aicall_args-Tuple{Any})

<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools' href='#PromptingTools.Experimental.AgentTools'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools</u></b> &mdash; <i>Module</i>.




```julia
AgentTools
```


Provides Agentic functionality providing lazy calls for building pipelines (eg, `AIGenerate`) and `AICodeFixer`.

This module is experimental and may change at any time. It is intended to be moved to a separate package in the future.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/AgentTools.jl#L1-L7)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.AICall' href='#PromptingTools.Experimental.AgentTools.AICall'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.AICall</u></b> &mdash; <i>Type</i>.




```julia
AICall(func::F, args...; kwargs...) where {F<:Function}

AIGenerate(args...; kwargs...)
AIEmbed(args...; kwargs...)
AIExtract(args...; kwargs...)
```


A lazy call wrapper for AI functions in the `PromptingTools` module, such as `aigenerate`.

The `AICall` struct is designed to facilitate a deferred execution model (lazy evaluation) for AI functions that interact with a Language Learning Model (LLM). It stores the necessary information for an AI call and executes the underlying AI function only when supplied with a `UserMessage` or when the `run!` method is applied. This approach allows for more flexible and efficient handling of AI function calls, especially in interactive environments.

Seel also: `run!`, `AICodeFixer`

**Fields**
- `func::F`: The AI function to be called lazily. This should be a function like `aigenerate` or other `ai*` functions.
  
- `schema::Union{Nothing, PT.AbstractPromptSchema}`: Optional schema to structure the prompt for the AI function.
  
- `conversation::Vector{PT.AbstractMessage}`: A vector of messages that forms the conversation context for the AI call.
  
- `kwargs::NamedTuple`: Keyword arguments to be passed to the AI function.
  
- `success::Union{Nothing, Bool}`: Indicates whether the last call was successful (true) or not (false). `Nothing` if the call hasn't been made yet.
  
- `error::Union{Nothing, Exception}`: Stores any exception that occurred during the last call. `Nothing` if no error occurred or if the call hasn't been made yet.
  

**Example**

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

`````julia
aicall |> run!
````

You can also use `AICall` as a functor to trigger the AI call with a `UserMessage` or simply the text to send:
`````


julia aicall(UserMessage("Hello, world!"))  # Triggers the lazy call result = run!(aicall)  # Explicitly runs the AI call ``` This can be used to "reply" to previous message / continue the stored conversation

**Notes**
- The `AICall` struct is a key component in building flexible and efficient Agentic pipelines
  
- The lazy evaluation model allows for setting up the call parameters in advance and deferring the actual execution until it is explicitly triggered.
  
- This struct is particularly useful in scenarios where the timing of AI function execution needs to be deferred or where multiple potential calls need to be prepared and selectively executed.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L50-L103)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.AICodeFixer' href='#PromptingTools.Experimental.AgentTools.AICodeFixer'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.AICodeFixer</u></b> &mdash; <i>Type</i>.




```julia
AICodeFixer(aicall::AICall, templates::Vector{<:PT.UserMessage}; num_rounds::Int = 3, feedback_func::Function = aicodefixer_feedback; kwargs...)
AICodeFixer(aicall::AICall, template::Union{AITemplate, Symbol} = :CodeFixerRCI; kwargs...)
```


An AIAgent that iteratively evaluates any received Julia code and provides feedback back to the AI model if `num_rounds>0`. `AICodeFixer` manages the lifecycle of a code fixing session, including tracking conversation history, rounds of interaction, and applying user feedback through a specialized feedback function.

It integrates with lazy AI call structures like `AIGenerate`. 

The operation is "lazy", ie, the agent is only executed when needed, eg, when `run!` is called.

**Fields**
- `call::AICall`: The AI call that is being used for code generation or processing, eg, AIGenerate (same as `aigenerate` but "lazy", ie, called only when needed
  
- `templates::Union{Symbol, AITemplate, Vector{PT.UserMessage}}`: A set of user messages or templates that guide the AI's code fixing process.  The first UserMessage is used in the first round of code fixing, the second UserMessage is used for every subsequent iteration.
  
- `num_rounds::Int`: The number of rounds for the code fixing session. Defaults to 3.
  
- `round_counter::Int`: Counter to track the current round of interaction.
  
- `feedback_func::Function`: Function to generate feedback based on the AI's proposed code, defaults to `aicodefixer_feedback`  (modular thanks to type dispatch on `AbstractOutcomes`)
  
- `kwargs::NamedTuple`: Additional keyword arguments for customizing the AI call.
  

Note: Any kwargs provided to `run!()` will be passed to the underlying AICall.

**Example**

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
result = AICodeFixer(lazy_call, [PT.UserMessage("Please fix the code.

Feedback: {{feedback}}")]; num_rounds = 2) |> run!

# The result now contains the AI's attempts to fix the code
preview(result.call.conversation)
```


**Notes**
- `AICodeFixer` is particularly useful when code is hard to get right in one shot (eg, smaller models, complex syntax)
  
- The structure leverages the lazy evaluation model of `AICall` (/AIGenerate) to efficiently manage AI interactions and be able to repeatedly call it.
  
- The `run!` function executes the AI call and applies the feedback loop for the specified number of rounds, enabling an interactive code fixing process.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L358-L420)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.RetryConfig' href='#PromptingTools.Experimental.AgentTools.RetryConfig'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.RetryConfig</u></b> &mdash; <i>Type</i>.




```julia
RetryConfig
```


Configuration for self-fixing the AI calls. It includes the following fields:

**Fields**
- `retries::Int`: The number of retries ("fixing rounds") that have been attempted so far.
  
- `calls::Int`: The total number of SUCCESSFULLY generated ai* function calls made so far (across all samples/retry rounds). Ie, if a call fails, because of an API error, it's not counted, because it didn't reach the LLM.
  
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
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L6-L25)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.SampleNode' href='#PromptingTools.Experimental.AgentTools.SampleNode'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.SampleNode</u></b> &mdash; <i>Type</i>.




```julia
SampleNode{T}
```


A node in the Monte Carlo Tree Search tree. 

It's used to hold the `data` we're trying to optimize/discover (eg, a conversation), the scores from evaluation (`wins`, `visits`) and the results of the evaluations upon failure (`feedback`).

**Fields**
- `id::UInt16`: Unique identifier for the node
  
- `parent::Union{SampleNode, Nothing}`: Parent node that current node was built on
  
- `children::Vector{SampleNode}`: Children nodes
  
- `wins::Int`: Number of successful outcomes
  
- `visits::Int`: Number of condition checks done (eg, losses are `checks - wins`)
  
- `data::T`: eg, the conversation or some parameter to be optimized
  
- `feedback::String`: Feedback from the evaluation, always a string! Defaults to empty string.
  
- `success::Union{Nothing, Bool}`: Success of the generation and subsequent evaluations, proxy for whether it should be further evaluated. Defaults to nothing.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L31-L47)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.ThompsonSampling' href='#PromptingTools.Experimental.AgentTools.ThompsonSampling'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.ThompsonSampling</u></b> &mdash; <i>Type</i>.




```julia
ThompsonSampling <: AbstractScoringMethod
```


Implements scoring and selection for Thompson Sampling method. See https://en.wikipedia.org/wiki/Thompson_sampling for more details.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L12-L16)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.UCT' href='#PromptingTools.Experimental.AgentTools.UCT'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.UCT</u></b> &mdash; <i>Type</i>.




```julia
UCT <: AbstractScoringMethod
```


Implements scoring and selection for UCT (Upper Confidence Bound for Trees) sampling method. See https://en.wikipedia.org/wiki/Monte_Carlo_tree_search#Exploration_and_exploitation for more details.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L22-L26)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.AIClassify-Tuple' href='#PromptingTools.Experimental.AgentTools.AIClassify-Tuple'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.AIClassify</u></b> &mdash; <i>Method</i>.




```julia
AIClassify(args...; kwargs...)
```


Creates a lazy instance of `aiclassify`. It is an instance of `AICall` with `aiclassify` as the function.

Use exactly the same arguments and keyword arguments as `aiclassify` (see `?aiclassify` for details).


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L164-L172)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.AIEmbed-Tuple' href='#PromptingTools.Experimental.AgentTools.AIEmbed-Tuple'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.AIEmbed</u></b> &mdash; <i>Method</i>.




```julia
AIEmbed(args...; kwargs...)
```


Creates a lazy instance of `aiembed`. It is an instance of `AICall` with `aiembed` as the function.

Use exactly the same arguments and keyword arguments as `aiembed` (see `?aiembed` for details).


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L151-L159)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.AIExtract-Tuple' href='#PromptingTools.Experimental.AgentTools.AIExtract-Tuple'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.AIExtract</u></b> &mdash; <i>Method</i>.




```julia
AIExtract(args...; kwargs...)
```


Creates a lazy instance of `aiextract`. It is an instance of `AICall` with `aiextract` as the function.

Use exactly the same arguments and keyword arguments as `aiextract` (see `?aiextract` for details).


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L138-L146)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.AIGenerate-Tuple' href='#PromptingTools.Experimental.AgentTools.AIGenerate-Tuple'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.AIGenerate</u></b> &mdash; <i>Method</i>.




```julia
AIGenerate(args...; kwargs...)
```


Creates a lazy instance of `aigenerate`. It is an instance of `AICall` with `aigenerate` as the function.

Use exactly the same arguments and keyword arguments as `aigenerate` (see `?aigenerate` for details).


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L125-L133)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.AIScan-Tuple' href='#PromptingTools.Experimental.AgentTools.AIScan-Tuple'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.AIScan</u></b> &mdash; <i>Method</i>.




```julia
AIScan(args...; kwargs...)
```


Creates a lazy instance of `aiscan`. It is an instance of `AICall` with `aiscan` as the function.

Use exactly the same arguments and keyword arguments as `aiscan` (see `?aiscan` for details).


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L177-L185)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.add_feedback!-Tuple{AbstractVector{<:PromptingTools.AbstractMessage}, PromptingTools.Experimental.AgentTools.SampleNode}' href='#PromptingTools.Experimental.AgentTools.add_feedback!-Tuple{AbstractVector{<:PromptingTools.AbstractMessage}, PromptingTools.Experimental.AgentTools.SampleNode}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.add_feedback!</u></b> &mdash; <i>Method</i>.




```julia
add_feedback!(
    conversation::AbstractVector{<:PT.AbstractMessage}, sample::SampleNode; feedback_inplace::Bool = false,
    feedback_template::Symbol = :FeedbackFromEvaluator)
```


Adds formatted feedback to the `conversation` based on the `sample` node feedback (and its ancestors).

**Arguments**
- `conversation::AbstractVector{<:PT.AbstractMessage}`: The conversation to add the feedback to.
  
- `sample::SampleNode`: The sample node to extract the feedback from.
  
- `feedback_inplace::Bool=false`: If true, it will add the feedback to the last user message inplace (and pop the last AIMessage). Otherwise, it will append the feedback as a new message.
  
- `feedback_template::Symbol=:FeedbackFromEvaluator`: The template to use for the feedback message. It must be a valid `AITemplate` name.
  

**Example**

```julia
sample = SampleNode(; data = nothing, feedback = "Feedback X")
conversation = [PT.UserMessage("I say hi!"), PT.AIMessage(; content = "I say hi!")]
conversation = AT.add_feedback!(conversation, sample)
conversation[end].content == "### Feedback from Evaluator\nFeedback X\n"

Inplace feedback:
```


julia conversation = [PT.UserMessage("I say hi!"), PT.AIMessage(; content = "I say hi!")] conversation = AT.add_feedback!(conversation, sample; feedback_inplace = true) conversation[end].content == "I say hi!\n\n### Feedback from Evaluator\nFeedback X\n"

```

Sample with ancestors with feedback:
```


julia sample_p = SampleNode(; data = nothing, feedback = "\nFeedback X") sample = expand!(sample_p, nothing) sample.feedback = "\nFeedback Y" conversation = [PT.UserMessage("I say hi!"), PT.AIMessage(; content = "I say hi!")] conversation = AT.add_feedback!(conversation, sample)

conversation[end].content == "### Feedback from Evaluator\n\nFeedback X\n–––––\n\nFeedback Y\n" ```


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/retry.jl#L465-L504)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.aicodefixer_feedback-Tuple{AbstractVector{<:PromptingTools.AbstractMessage}}' href='#PromptingTools.Experimental.AgentTools.aicodefixer_feedback-Tuple{AbstractVector{<:PromptingTools.AbstractMessage}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.aicodefixer_feedback</u></b> &mdash; <i>Method</i>.




```julia
aicodefixer_feedback(conversation::AbstractVector{<:PT.AbstractMessage}; max_length::Int = 512) -> NamedTuple(; feedback::String)
```


Generate feedback for an AI code fixing session based on the conversation history. Function is designed to be extensible for different types of feedback and code evaluation outcomes. 

The highlevel wrapper accepts a conversation and returns new kwargs for the AICall.

Individual feedback functions are dispatched on different subtypes of `AbstractCodeOutcome` and can be extended/overwritten to provide more detailed feedback.

See also: `AIGenerate`, `AICodeFixer`

**Arguments**
- `conversation::AbstractVector{<:PT.AbstractMessage}`: A vector of messages representing the conversation history, where the last message is expected to contain the code to be analyzed.
  
- `max_length::Int=512`: An optional argument that specifies the maximum length of the feedback message.
  

**Returns**
- `NamedTuple`: A feedback message as a kwarg in NamedTuple based on the analysis of the code provided in the conversation.
  

**Example**

```julia
new_kwargs = aicodefixer_feedback(conversation)
```


**Notes**

This function is part of the AI code fixing system, intended to interact with code in AIMessage and provide feedback on improving it.

The highlevel wrapper accepts a conversation and returns new kwargs for the AICall.

It dispatches for the code feedback based on the subtypes of `AbstractCodeOutcome` below:
- `CodeEmpty`: No code found in the message.
  
- `CodeFailedParse`: Code parsing error.
  
- `CodeFailedEval`: Runtime evaluation error.
  
- `CodeFailedTimeout`: Code execution timed out.
  
- `CodeSuccess`: Successful code execution.
  

You can override the individual methods to customize the feedback.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/code_feedback.jl#L10-L47)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.airetry!' href='#PromptingTools.Experimental.AgentTools.airetry!'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.airetry!</u></b> &mdash; <i>Function</i>.




```julia
airetry!(
    f_cond::Function, aicall::AICallBlock, feedback::Union{AbstractString, Function} = "";
    verbose::Bool = true, throw::Bool = false, evaluate_all::Bool = true, feedback_expensive::Bool = false,
    max_retries::Union{Nothing, Int} = nothing, retry_delay::Union{Nothing, Int} = nothing)
```


Evaluates the condition `f_cond` on the `aicall` object.  If the condition is not met, it will return the best sample to retry from and provide `feedback` (string or function) to `aicall`. That's why it's mutating. It will retry maximum `max_retries` times, with `throw=true`, an error will be thrown if the condition is not met after `max_retries` retries.

Function signatures
- `f_cond(aicall::AICallBlock) -> Bool`, ie, it must accept the aicall object and return a boolean value.
  
- `feedback` can be a string or `feedback(aicall::AICallBlock) -> String`, ie, it must accept the aicall object and return a string.
  

You can leverage the `last_message`, `last_output`, and `AICode` functions to access the last message, last output and execute code blocks in the conversation, respectively. See examples below.

**Good Use Cases**
- Retry with API failures/drops (add `retry_delay=2` to wait 2s between retries)
  
- Check the output format / type / length / etc
  
- Check the output with `aiclassify` call (LLM Judge) to catch unsafe/NSFW/out-of-scope content
  
- Provide hints to the model to guide it to the correct answer
  

**Gotchas**
- If controlling keyword arguments are set to nothing, they will fall back to the default values in `aicall.config`. You can override them by passing the keyword arguments explicitly.
  
- If there multiple `airetry!` checks, they are evaluted sequentially. As long as `throw==false`, they will be all evaluated even if they failed previous checks.
  
- Only samples which passed previous evaluations are evaluated (`sample.success` is `true`). If there are no successful samples, the function will evaluate only the active sample (`aicall.active_sample_id`) and nothing else.
  
- Feedback from all "ancestor" evaluations is added upon retry, not feedback from the "sibblings" or other branches. To have only ONE long BRANCH (no sibblings), make sure to keep `RetryConfig(; n_samples=1)`.  That way the model will always see ALL previous feedback.
  
- We implement a version of Monte Carlo Tree Search (MCTS) to always pick the most promising sample to restart from (you can tweak the options in `RetryConfig` to change the behaviour).
  
- For large number of parallel branches (ie, "shallow and wide trees"), you might benefit from switching scoring to `scoring=ThompsonSampling()` (similar to how Bandit algorithms work).
  
- Open-source/local models can struggle with too long conversation, you might want to experiment with `in-place feedback` (set `RetryConfig(; feedback_inplace=true)`).
  

**Arguments**
- `f_cond::Function`: A function that accepts the `aicall` object and returns a boolean value. Retry will be attempted if the condition is not met (`f_cond -> false`).
  
- `aicall::AICallBlock`: The `aicall` object to evaluate the condition on.
  
- `feedback::Union{AbstractString, Function}`: Feedback to provide if the condition is not met. If a function is provided, it must accept the `aicall` object as the only argument and return a string.
  
- `verbose::Integer=1`: A verbosity level for logging the retry attempts and warnings. A higher value indicates more detailed logging.
  
- `throw::Bool=false`: If true, it will throw an error if the function `f_cond` does not return `true` after `max_retries` retries.
  
- `evaluate_all::Bool=false`: If true, it will evaluate all the "successful" samples in the `aicall` object. Otherwise, it will only evaluate the active sample.
  
- `feedback_expensive::Bool=false`: If false, it will provide feedback to all samples that fail the condition.  If `feedback` function is expensive to call (eg, another ai* function), set this to `true` and feedback will be provided only to the sample we will retry from.
  
- `max_retries::Union{Nothing, Int}=nothing`: Maximum number of retries. If not provided, it will fall back to the `max_retries` in `aicall.config`.
  
- `retry_delay::Union{Nothing, Int}=nothing`: Delay between retries in seconds. If not provided, it will fall back to the `retry_delay` in `aicall.config`.
  

**Returns**
- The `aicall` object with the updated `conversation`, and `samples` (saves the evaluations and their scores/feedback).
  

**Example**

You can use `airetry!` to catch API errors in `run!` and auto-retry the call.  `RetryConfig` is how you influence all the subsequent retry behaviours - see `?RetryConfig` for more details.

```julia
# API failure because of a non-existent model
out = AIGenerate("say hi!"; config = RetryConfig(; catch_errors = true),
    model = "NOTEXIST")
run!(out) # fails

# we ask to wait 2s between retries and retry 2 times (can be set in `config` in aicall as well)
airetry!(isvalid, out; retry_delay = 2, max_retries = 2)
```


If you provide arguments to the aicall, we try to honor them as much as possible in the following calls,  eg, set low verbosity

```julia
out = AIGenerate("say hi!"; config = RetryConfig(; catch_errors = true),
model = "NOTEXIST", verbose=false)
run!(out)
# No info message, you just see `success = false` in the properties of the AICall
```


Let's show a toy example to demonstrate the runtime checks / guardrails for the model output. We'll play a color guessing game (I'm thinking "yellow"):

```julia
# Notice that we ask for two samples (`n_samples=2`) at each attempt (to improve our chances). 
# Both guesses are scored at each time step, and the best one is chosen for the next step.
# And with OpenAI, we can set `api_kwargs = (;n=2)` to get both samples simultaneously (cheaper and faster)!
out = AIGenerate(
    "Guess what color I'm thinking. It could be: blue, red, black, white, yellow. Answer with 1 word only";
    verbose = false,
    config = RetryConfig(; n_samples = 2), api_kwargs = (; n = 2))
run!(out)


## Check that the output is 1 word only, third argument is the feedback that will be provided if the condition fails
## Notice: functions operate on `aicall` as the only argument. We can use utilities like `last_output` and `last_message` to access the last message and output in the conversation.
airetry!(x -> length(split(last_output(x), r" |\.")) == 1, out,
    "You must answer with 1 word only.")


## Let's ensure that the output is in lowercase - simple and short
airetry!(x -> all(islowercase, last_output(x)), out, "You must answer in lowercase.")
# [ Info: Condition not met. Retrying...


## Let's add final hint - it took us 2 retries
airetry!(x -> startswith(last_output(x), "y"), out, "It starts with "y"")
# [ Info: Condition not met. Retrying...
# [ Info: Condition not met. Retrying...


## We end up with the correct answer
last_output(out)
# Output: "yellow"
```


Let's explore how we got here.  We save the various attempts in a "tree" (SampleNode object) You can access it in `out.samples`, which is the ROOT of the tree (top level). Currently "active" sample ID is `out.active_sample_id` -> that's the same as `conversation` field in your AICall.

```julia
# Root node:
out.samples
# Output: SampleNode(id: 46839, stats: 6/12, length: 2)

# Active sample (our correct answer):
out.active_sample_id 
# Output: 50086

# Let's obtain the active sample node with this ID  - use getindex notation or function find_node
out.samples[out.active_sample_id]
# Output: SampleNode(id: 50086, stats: 1/1, length: 7)

# The SampleNode has two key fields: data and feedback. Data is where the conversation is stored:
active_sample = out.samples[out.active_sample_id]
active_sample.data == out.conversation # Output: true -> This is the winning guess!
```


We also get a clear view of the tree structure of all samples with `print_samples`:

```julia
julia> print_samples(out.samples)
SampleNode(id: 46839, stats: 6/12, score: 0.5, length: 2)
├─ SampleNode(id: 12940, stats: 5/8, score: 1.41, length: 4)
│  ├─ SampleNode(id: 34315, stats: 3/4, score: 1.77, length: 6)
│  │  ├─ SampleNode(id: 20493, stats: 1/1, score: 2.67, length: 7)
│  │  └─ SampleNode(id: 50086, stats: 1/1, score: 2.67, length: 7)
│  └─ SampleNode(id: 2733, stats: 1/2, score: 1.94, length: 5)
└─ SampleNode(id: 48343, stats: 1/4, score: 1.36, length: 4)
   ├─ SampleNode(id: 30088, stats: 0/1, score: 1.67, length: 5)
   └─ SampleNode(id: 44816, stats: 0/1, score: 1.67, length: 5)
```


You can use the `id` to grab and inspect any of these nodes, eg,

```julia
out.samples[2733]
# Output: SampleNode(id: 2733, stats: 1/2, length: 5)
```


We can also iterate through all samples and extract whatever information we want with `PostOrderDFS` or `PreOrderDFS` (exported from AbstractTrees.jl)

```julia
for sample in PostOrderDFS(out.samples)
    # Data is the universal field for samples, we put `conversation` in there
    # Last item in data is the last message in coversation
    msg = sample.data[end]
    if msg isa PT.AIMessage # skip feedback
        # get only the message content, ie, the guess
        println("ID: $(sample.id), Answer: $(msg.content)")
    end
end

# ID: 20493, Answer: yellow
# ID: 50086, Answer: yellow
# ID: 2733, Answer: red
# ID: 30088, Answer: blue
# ID: 44816, Answer: blue
```


Note: `airetry!` will attempt to fix the model `max_retries` times.  If you set `throw=true`, it will throw an ErrorException if the condition is not met after `max_retries` retries.

Let's define a mini program to guess the number and use `airetry!` to guide the model to the correct answer:

```julia
"""
    llm_guesser()

Mini program to guess the number provided by the user (betwee 1-100).
"""
function llm_guesser(user_number::Int)
    @assert 1 <= user_number <= 100
    prompt = """
I'm thinking a number between 1-100. Guess which one it is. 
You must respond only with digits and nothing else. 
Your guess:"""
    ## 2 samples at a time, max 5 fixing rounds
    out = AIGenerate(prompt; config = RetryConfig(; n_samples = 2, max_retries = 5),
        api_kwargs = (; n = 2)) |> run!
    ## Check the proper output format - must parse to Int, use do-syntax
    ## We can provide feedback via a function!
    function feedback_f(aicall)
        "Output: $(last_output(aicall))
Feedback: You must respond only with digits!!"
    end
    airetry!(out, feedback_f) do aicall
        !isnothing(tryparse(Int, last_output(aicall)))
    end
    ## Give a hint on bounds
    lower_bound = (user_number ÷ 10) * 10
    upper_bound = lower_bound + 10
    airetry!(
        out, "The number is between or equal to $lower_bound to $upper_bound.") do aicall
        guess = tryparse(Int, last_output(aicall))
        lower_bound <= guess <= upper_bound
    end
    ## You can make at most 3x guess now -- if there is max_retries in `config.max_retries` left
    max_retries = out.config.retries + 3
    function feedback_f2(aicall)
        guess = tryparse(Int, last_output(aicall))
        "Your guess of $(guess) is wrong, it's $(abs(guess-user_number)) numbers away."
    end
    airetry!(out, feedback_f2; max_retries) do aicall
        tryparse(Int, last_output(aicall)) == user_number
    end

    ## Evaluate the best guess
    @info "Results: Guess: $(last_output(out)) vs User: $user_number (Number of calls made: $(out.config.calls))"
    return out
end

# Let's play the game
out = llm_guesser(33)
[ Info: Condition not met. Retrying...
[ Info: Condition not met. Retrying...
[ Info: Condition not met. Retrying...
[ Info: Condition not met. Retrying...
[ Info: Results: Guess: 33 vs User: 33 (Number of calls made: 10)
```


Yay! We got it :)

Now, we could explore different samples (eg, `print_samples(out.samples)`) or see what the model guessed at each step:

```julia
print_samples(out.samples)
## SampleNode(id: 57694, stats: 6/14, score: 0.43, length: 2)
## ├─ SampleNode(id: 35603, stats: 5/10, score: 1.23, length: 4)
## │  ├─ SampleNode(id: 55394, stats: 1/4, score: 1.32, length: 6)
## │  │  ├─ SampleNode(id: 20737, stats: 0/1, score: 1.67, length: 7)
## │  │  └─ SampleNode(id: 52910, stats: 0/1, score: 1.67, length: 7)
## │  └─ SampleNode(id: 43094, stats: 3/4, score: 1.82, length: 6)
## │     ├─ SampleNode(id: 14966, stats: 1/1, score: 2.67, length: 7)
## │     └─ SampleNode(id: 32991, stats: 1/1, score: 2.67, length: 7)
## └─ SampleNode(id: 20506, stats: 1/4, score: 1.4, length: 4)
##    ├─ SampleNode(id: 37581, stats: 0/1, score: 1.67, length: 5)
##    └─ SampleNode(id: 46632, stats: 0/1, score: 1.67, length: 5)

# Lastly, let's check all the guesses AI made across all samples. 
# Our winning guess was ID 32991 (`out.active_sample_id`)

for sample in PostOrderDFS(out.samples)
    [println("ID: $(sample.id), Guess: $(msg.content)")
     for msg in sample.data if msg isa PT.AIMessage]
end
## ID: 20737, Guess: 50
## ID: 20737, Guess: 35
## ID: 20737, Guess: 37
## ID: 52910, Guess: 50
## ID: 52910, Guess: 35
## ID: 52910, Guess: 32
## ID: 14966, Guess: 50
## ID: 14966, Guess: 35
## ID: 14966, Guess: 33
## ID: 32991, Guess: 50
## ID: 32991, Guess: 35
## ID: 32991, Guess: 33
## etc...
```


Note that if there are multiple "branches" the model will see only the feedback of its own and its ancestors not the other "branches".  If you wanted to provide ALL feedback, set `RetryConfig(; n_samples=1)` to remove any "branching". It fixing will be done sequentially in one conversation and the model will see all feedback (less powerful if the model falls into a bad state). Alternatively, you can tweak the feedback function.

**See Also**

References: `airetry` is inspired by the [Language Agent Tree Search paper](https://arxiv.org/abs/2310.04406) and by [DSPy Assertions paper](https://arxiv.org/abs/2312.13382).


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/retry.jl#L1-L281)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.backpropagate!-Tuple{PromptingTools.Experimental.AgentTools.SampleNode}' href='#PromptingTools.Experimental.AgentTools.backpropagate!-Tuple{PromptingTools.Experimental.AgentTools.SampleNode}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.backpropagate!</u></b> &mdash; <i>Method</i>.




Provides scores for a given node (and all its ancestors) based on the evaluation (`wins`, `visits`).


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L105)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.beta_sample-Tuple{Real, Real}' href='#PromptingTools.Experimental.AgentTools.beta_sample-Tuple{Real, Real}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.beta_sample</u></b> &mdash; <i>Method</i>.




```julia
beta_sample(α::Real, β::Real)
```


Approximates a sample from the Beta distribution by generating two independent Gamma distributed samples and using their ratio.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/utils.jl#L136-L140)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.collect_all_feedback-Tuple{PromptingTools.Experimental.AgentTools.SampleNode}' href='#PromptingTools.Experimental.AgentTools.collect_all_feedback-Tuple{PromptingTools.Experimental.AgentTools.SampleNode}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.collect_all_feedback</u></b> &mdash; <i>Method</i>.




Collects all feedback from the node and its ancestors (parents). Returns a string separated by `separator`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L231)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.evaluate_condition!' href='#PromptingTools.Experimental.AgentTools.evaluate_condition!'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.evaluate_condition!</u></b> &mdash; <i>Function</i>.




```julia
evaluate_condition!(f_cond::Function, aicall::AICallBlock,
    feedback::Union{AbstractString, Function} = "";
    evaluate_all::Bool = true, feedback_expensive::Bool = false)
```


Evalutes the condition `f_cond` (must return Bool) on the `aicall` object.  If the condition is not met, it will return the best sample to retry from and provide `feedback`.

Mutating as the results are saved in `aicall.samples`

If `evaluate_all` is `true`, it will evaluate all the "successful" samples in the `aicall` object. Otherwise, it will only evaluate the active sample..

For `f_cond` and `feedback` functions, you can use the `last_message` and `last_output` utilities to access the last message and last output in the conversation, respectively.

**Arguments**
- `f_cond::Function`: A function that accepts the `aicall` object and returns a boolean value. Retry will be attempted if the condition is not met (`f_cond -> false`).
  
- `aicall::AICallBlock`: The `aicall` object to evaluate the condition on.
  
- `feedback::Union{AbstractString, Function}`: Feedback to provide if the condition is not met. If a function is provided, it must accept the `aicall` object as the only argument and return a string.
  
- `evaluate_all::Bool=false`: If true, it will evaluate all the "successful" samples in the `aicall` object. Otherwise, it will only evaluate the active sample.
  
- `feedback_expensive::Bool=false`: If false, it will provide feedback to all samples that fail the condition.  If `feedback` function is expensive to call (eg, another ai* function), set this to `true` and feedback will be provided only to the sample we will retry from.
  

**Returns**
- a tuple `(condition_passed, sample)`, where `condition_passed` is a boolean indicating whether the condition was met, and `sample` is the best sample to retry from.
  

**Example**

```julia
# Mimic AIGenerate run!
aicall = AIGenerate("Say hi!"; config = RetryConfig(; n_samples = 2))
sample = expand!(aicall.samples, aicall.conversation; success = true)
aicall.active_sample_id = sample.id

# Return whether it passed and node to take the next action from
cond, node = AT.evaluate_condition!(x -> occursin("hi", last_output(x)), aicall)

# Checks:
cond == true
node == sample
node.wins == 1
```


With feedback: ```julia

**Mimic AIGenerate run with feedback**

aicall = AIGenerate(     :BlankSystemUser; system = "a", user = "b") sample = expand!(aicall.samples, aicall.conversation; success = true) aicall.active_sample_id = sample.id

**Evaluate**

cond, node = AT.evaluate_condition!(     x -> occursin("NOTFOUND", last_output(x)), aicall, "Feedback X") cond == false # fail sample == node # same node (no other choice) node.wins == 0 node.feedback == " Feedback X"


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/retry.jl#L338-L395)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.expand!-Tuple{PromptingTools.Experimental.AgentTools.SampleNode, Any}' href='#PromptingTools.Experimental.AgentTools.expand!-Tuple{PromptingTools.Experimental.AgentTools.SampleNode, Any}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.expand!</u></b> &mdash; <i>Method</i>.




Expands the tree with a new node from `parent` using the given `data` and `success`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L97)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.extract_config-Union{Tuple{T}, Tuple{Any, T}} where T' href='#PromptingTools.Experimental.AgentTools.extract_config-Union{Tuple{T}, Tuple{Any, T}} where T'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.extract_config</u></b> &mdash; <i>Method</i>.




Extracts `config::RetryConfig` from kwargs and returns the rest of the kwargs.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/utils.jl#L37)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.find_node-Tuple{PromptingTools.Experimental.AgentTools.SampleNode, Integer}' href='#PromptingTools.Experimental.AgentTools.find_node-Tuple{PromptingTools.Experimental.AgentTools.SampleNode, Integer}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.find_node</u></b> &mdash; <i>Method</i>.




Finds a node with a given `id` in the tree starting from `node`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L205)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.gamma_sample-Tuple{Real, Real}' href='#PromptingTools.Experimental.AgentTools.gamma_sample-Tuple{Real, Real}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.gamma_sample</u></b> &mdash; <i>Method</i>.




```julia
gamma_sample(α::Real, θ::Real)
```


Approximates a sample from the Gamma distribution using the Marsaglia and Tsang method.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/utils.jl#L110-L114)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.last_message-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock}' href='#PromptingTools.Experimental.AgentTools.last_message-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.last_message</u></b> &mdash; <i>Method</i>.




Helpful accessor for AICall blocks. Returns the last message in the conversation.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L326)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.last_output-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock}' href='#PromptingTools.Experimental.AgentTools.last_output-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.last_output</u></b> &mdash; <i>Method</i>.




Helpful accessor for AICall blocks. Returns the last output in the conversation (eg, the string/data in the last message).


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L331)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.print_samples-Tuple{PromptingTools.Experimental.AgentTools.SampleNode}' href='#PromptingTools.Experimental.AgentTools.print_samples-Tuple{PromptingTools.Experimental.AgentTools.SampleNode}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.print_samples</u></b> &mdash; <i>Method</i>.




Pretty prints the samples tree starting from `node`. Usually, `node` is the root of the tree. Example: `print_samples(aicall.samples)`.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L215)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.remove_used_kwargs-Tuple{NamedTuple, AbstractVector{<:PromptingTools.AbstractMessage}}' href='#PromptingTools.Experimental.AgentTools.remove_used_kwargs-Tuple{NamedTuple, AbstractVector{<:PromptingTools.AbstractMessage}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.remove_used_kwargs</u></b> &mdash; <i>Method</i>.




Removes the kwargs that have already been used in the conversation. Returns NamedTuple.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/utils.jl#L1)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.reset_success!' href='#PromptingTools.Experimental.AgentTools.reset_success!'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.reset_success!</u></b> &mdash; <i>Function</i>.




Sets the `success` field of all nodes in the tree to `success` value.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L223)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.run!-Tuple{AICodeFixer}' href='#PromptingTools.Experimental.AgentTools.run!-Tuple{AICodeFixer}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.run!</u></b> &mdash; <i>Method</i>.




```julia
run!(codefixer::AICodeFixer; verbose::Int = 1, max_conversation_length::Int = 32000, run_kwargs...)
```


Executes the code fixing process encapsulated by the `AICodeFixer` instance.  This method iteratively refines and fixes code by running the AI call in a loop for a specified number of rounds, using feedback from the code evaluation (`aicodefixer_feedback`) to improve the outcome in each iteration.

**Arguments**
- `codefixer::AICodeFixer`: An instance of `AICodeFixer` containing the AI call, templates, and settings for the code fixing session.
  
- `verbose::Int=1`: Verbosity level for logging. A higher value indicates more detailed logging.
  
- `max_conversation_length::Int=32000`: Maximum length in characters for the conversation history to keep it within manageable limits, especially for large code fixing sessions.
  
- `num_rounds::Union{Nothing, Int}=nothing`: Number of additional rounds for the code fixing session. If `nothing`, the value from the `AICodeFixer` instance is used.
  
- `run_kwargs...`: Additional keyword arguments that are passed to the AI function.
  

**Returns**
- `AICodeFixer`: The updated `AICodeFixer` instance with the results of the code fixing session.
  

**Usage**

```julia
aicall = AICall(aigenerate, schema=mySchema, conversation=myConversation)
codefixer = AICodeFixer(aicall, myTemplates; num_rounds=5)
result = run!(codefixer, verbose=2)
```


**Notes**
- The `run!` method drives the core logic of the `AICodeFixer`, iterating through rounds of AI interactions to refine and fix code.
  
- In each round, it applies feedback based on the current state of the conversation, allowing the AI to respond more effectively.
  
- The conversation history is managed to ensure it stays within the specified `max_conversation_length`, keeping the AI's focus on relevant parts of the conversation.
  
- This iterative process is essential for complex code fixing tasks where multiple interactions and refinements are required to achieve the desired outcome.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L470-L498)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.run!-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock}' href='#PromptingTools.Experimental.AgentTools.run!-Tuple{PromptingTools.Experimental.AgentTools.AICallBlock}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.run!</u></b> &mdash; <i>Method</i>.




```julia
run!(aicall::AICallBlock; verbose::Int = 1, catch_errors::Bool = false, return_all::Bool = true, kwargs...)
```


Executes the AI call wrapped by an `AICallBlock` instance. This method triggers the actual communication with the AI model and processes the response based on the provided conversation context and parameters.

Note: Currently `return_all` must always be set to true.

**Arguments**
- `aicall::AICallBlock`: An instance of `AICallBlock` which encapsulates the AI function call along with its context and parameters (eg, `AICall`, `AIGenerate`)
  
- `verbose::Integer=1`: A verbosity level for logging. A higher value indicates more detailed logging.
  
- `catch_errors::Union{Nothing, Bool}=nothing`: A flag to indicate whether errors should be caught and saved to `aicall.error`. If `nothing`, it defaults to `aicall.config.catch_errors`.
  
- `return_all::Bool=true`: A flag to indicate whether the whole conversation from the AI call should be returned. It should always be true.
  
- `kwargs...`: Additional keyword arguments that are passed to the AI function.
  

**Returns**
- `AICallBlock`: The same `AICallBlock` instance, updated with the results of the AI call. This includes updated conversation, success status, and potential error information.
  

**Example**

```julia
aicall = AICall(aigenerate)
run!(aicall)
```


Alternatively, you can trigger the `run!` call by using the AICall as a functor and calling it with a string or a UserMessage:

```julia
aicall = AICall(aigenerate)
aicall("Say hi!")
```


**Notes**
- The `run!` method is a key component of the lazy evaluation model in `AICall`. It allows for the deferred execution of AI function calls, providing flexibility in how and when AI interactions are conducted.
  
- The method updates the `AICallBlock` instance with the outcome of the AI call, including any generated responses, success or failure status, and error information if an error occurred.
  
- This method is essential for scenarios where AI interactions are based on dynamic or evolving contexts, as it allows for real-time updates and responses based on the latest information.
  


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/lazy_types.jl#L190-L223)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.score-Tuple{PromptingTools.Experimental.AgentTools.SampleNode, PromptingTools.Experimental.AgentTools.ThompsonSampling}' href='#PromptingTools.Experimental.AgentTools.score-Tuple{PromptingTools.Experimental.AgentTools.SampleNode, PromptingTools.Experimental.AgentTools.ThompsonSampling}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.score</u></b> &mdash; <i>Method</i>.




Scores a node using the ThomsonSampling method, similar to Bandit algorithms.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L128)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.score-Tuple{PromptingTools.Experimental.AgentTools.SampleNode, PromptingTools.Experimental.AgentTools.UCT}' href='#PromptingTools.Experimental.AgentTools.score-Tuple{PromptingTools.Experimental.AgentTools.SampleNode, PromptingTools.Experimental.AgentTools.UCT}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.score</u></b> &mdash; <i>Method</i>.




Scores a node using the UCT (Upper Confidence Bound for Trees) method.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L120)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.select_best' href='#PromptingTools.Experimental.AgentTools.select_best'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.select_best</u></b> &mdash; <i>Function</i>.




```julia
select_best(node::SampleNode, scoring::AbstractScoringMethod = UCT();
    ordering::Symbol = :PostOrderDFS)
```


Selects the best node from the tree using the given `scoring` (`UCT` or `ThompsonSampling`). Defaults to UCT. Thompson Sampling is more random with small samples, while UCT stabilizes much quicker thanks to looking at parent nodes as well.

Ordering can be either `:PreOrderDFS` or `:PostOrderDFS`. Defaults to `:PostOrderDFS`, which favors the leaves (end points of the tree).

**Example**

Compare the different scoring methods:

```julia
# Set up mock samples and scores
data = PT.AbstractMessage[]
root = SampleNode(; data)
child1 = expand!(root, data)
backpropagate!(child1; wins = 1, visits = 1)
child2 = expand!(root, data)
backpropagate!(child2; wins = 0, visits = 1)
child11 = expand!(child1, data)
backpropagate!(child11; wins = 1, visits = 1)

# Select with UCT
n = select_best(root, UCT())
SampleNode(id: 29826, stats: 1/1, length: 0)

# Show the tree:
print_samples(root; scoring = UCT())
## SampleNode(id: 13184, stats: 2/3, score: 0.67, length: 0)
## ├─ SampleNode(id: 26078, stats: 2/2, score: 2.05, length: 0)
## │  └─ SampleNode(id: 29826, stats: 1/1, score: 2.18, length: 0)
## └─ SampleNode(id: 39931, stats: 0/1, score: 1.48, length: 0)

# Select with ThompsonSampling - much more random with small samples
n = select_best(root, ThompsonSampling())
SampleNode(id: 26078, stats: 2/2, length: 0)

# Show the tree (run it a few times and see how the scores jump around):
print_samples(root; scoring = ThompsonSampling())
## SampleNode(id: 13184, stats: 2/3, score: 0.6, length: 0)
## ├─ SampleNode(id: 26078, stats: 2/2, score: 0.93, length: 0)
## │  └─ SampleNode(id: 29826, stats: 1/1, score: 0.22, length: 0)
## └─ SampleNode(id: 39931, stats: 0/1, score: 0.84, length: 0)

```



[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/mcts.jl#L134-L179)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.split_multi_samples-Tuple{Any}' href='#PromptingTools.Experimental.AgentTools.split_multi_samples-Tuple{Any}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.split_multi_samples</u></b> &mdash; <i>Method</i>.




If the conversation has multiple AIMessage samples, split them into separate conversations with the common past.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/utils.jl#L51)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.truncate_conversation-Tuple{AbstractVector{<:PromptingTools.AbstractMessage}}' href='#PromptingTools.Experimental.AgentTools.truncate_conversation-Tuple{AbstractVector{<:PromptingTools.AbstractMessage}}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.truncate_conversation</u></b> &mdash; <i>Method</i>.




```julia
truncate_conversation(conversation::AbstractVector{<:PT.AbstractMessage};
    max_conversation_length::Int = 32000)
```


Truncates a given conversation to a `max_conversation_length` characters by removing messages "in the middle". It tries to retain the original system+user message and also the most recent messages.

Practically, if a conversation is too long, it will start by removing the most recent message EXCEPT for the last two (assumed to be the last AIMessage with the code and UserMessage with the feedback

**Arguments**

`max_conversation_length` is in characters; assume c. 2-3 characters per LLM token, so 32000 should correspond to 16K context window.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/utils.jl#L71-L82)

</div>
<br>
<div style='border-width:1px; border-style:solid; border-color:black; padding: 1em; border-radius: 25px;'>
<a id='PromptingTools.Experimental.AgentTools.unwrap_aicall_args-Tuple{Any}' href='#PromptingTools.Experimental.AgentTools.unwrap_aicall_args-Tuple{Any}'>#</a>&nbsp;<b><u>PromptingTools.Experimental.AgentTools.unwrap_aicall_args</u></b> &mdash; <i>Method</i>.




Unwraps the arguments for AICall and returns the schema and conversation (if provided). Expands any provided AITemplate.


[source](https://github.com/svilupp/PromptingTools.jl/blob/dc30ccf7a2e2f3066de2cfa3deff86fe3c2ca481/src/Experimental/AgentTools/utils.jl#L13)

</div>
<br>
