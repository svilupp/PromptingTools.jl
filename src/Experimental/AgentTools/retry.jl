"""
    airetry(
        f_cond::Function, aicall::AICallBlock, feedback::Union{AbstractString, Function} = "";
        verbose::Bool = true, throw::Bool = false, evaluate_all::Bool = true, feedback_expensive::Bool = false,
        max_retries::Union{Nothing, Int} = nothing, retry_delay::Union{Nothing, Int} = nothing)

Evalutes the condition `f_cond` (must return Bool) on the `aicall` object (eg, we evaluate `f_cond(aicall) -> Bool`). 
If the condition is not met, it will return the best sample to retry from and provide `feedback`. 
It will retry running the `aicall` `max_retries` times.

If feedback is provided (not empty), it will be append it to the conversation before the retry. 
If a function is provided, it must accept the `aicall` object as the only argument and return a string.

If `throw` is `true`, it will throw an error if the function does not return `true` after `max_retries` retries.

Function `f_cond` is expected to accept the `aicall` object as the only argument. 
You can leverage the `last_message` and `last_output` functions to access the last message and output in the conversation.
It must return a boolean value, which indicates whether the condition is met.

# Gotchas
- If controlling keyword arguments are set to nothing, they will fall back to the default values in `aicall.config`. You can override them by passing the keyword arguments explicitly.
- If there multiple `airetry` checks, they are evaluted sequentially. As long as `throw==false`, they will be all evaluated even if they failed previous checks.
- Only samples which passed previous evaluations are evaluated (`sample.success` is `true`). If there are no successful samples, the function will evaluate only the active sample (`aicall.active_sample_id`) and nothing else.
- We implement a version of Monte Carlo Tree Search (MCTS) to always pick the most promising sample to restart from (you can tweak the options in `RetryConfig` to change the behaviour).

# Arguments
- `f_cond::Function`: A function that accepts the `aicall` object and returns a boolean value. Retry will be attempted if the condition is not met (`f_cond -> false`).
- `aicall::AICallBlock`: The `aicall` object to evaluate the condition on.
- `feedback::Union{AbstractString, Function}`: Feedback to provide if the condition is not met. If a function is provided, it must accept the `aicall` object as the only argument and return a string.
- `verbose::Integer=1`: A verbosity level for logging the retry attempts and warnings. A higher value indicates more detailed logging.
- `throw::Bool=false`: If true, it will throw an error if the function `f_cond` does not return `true` after `max_retries` retries.
- `evaluate_all::Bool=false`: If true, it will evaluate all the "successful" samples in the `aicall` object. Otherwise, it will only evaluate the active sample.
- `feedback_expensive::Bool=false`: If false, it will provide feedback to all samples that fail the condition. 
  If `feedback` function is expensive to call (eg, another ai* function), set this to `true` and feedback will be provided only to the sample we will retry from.
- `max_retries::Union{Nothing, Int}=nothing`: Maximum number of retries. If not provided, it will fall back to the `max_retries` in `aicall.config`.
- `retry_delay::Union{Nothing, Int}=nothing`: Delay between retries in seconds. If not provided, it will fall back to the `retry_delay` in `aicall.config`.

# Returns
- a tuple `(condition_passed, sample)`, where `condition_passed` is a boolean indicating whether the condition was met, and `sample` is the best sample to retry from.

# Example

You can use `airetry` to catch API errors in `run!` and auto-retry the call. 
`RetryConfig` is how you influence all the subsequent retry behaviours - see `?RetryConfig` for more details.
```julia
# API failure because of a non-existent model
out = AIGenerate("say hi!"; config = RetryConfig(; catch_errors = true),
    model = "NOTEXIST")
run!(out) # fails

# we ask to wait 2s between retries and retry 2 times (can be set in `config` in aicall as well)
airetry(isvalid, out; retry_delay = 2, max_retries = 2)
```

If you provide arguments to the aicall, we try to honor them as much as possible in the following calls, 
eg, set low verbosity
```julia
out = AIGenerate("say hi!"; config = RetryConfig(; catch_errors = true),
model = "NOTEXIST", verbose=false)
run!(out)
# No info message, you just see `success = false` in the properties of the AICall
```

Let's show a toy example to demonstrate the runtime checks / guardrails for the model output.
We'll play a color guessing game (I'm thinking "yellow"):

```julia
# Notice that we ask for two samples (`n_samples=2`) at each attempt (to improve our chances). 
# Both guesses are scored at each time step, and the best one is chosen for the next step.
# And with OpenAI, we can set `api_kwargs = (;n=2)` to get both samples simulatenously (cheaper and faster)!
out = AIGenerate(
    "Guess what color I'm thinking. It could be: blue, red, black, white, yellow. Answer with 1 word only";
    verbose = false,
    config = RetryConfig(; n_samples = 2), api_kwargs = (; n = 2))
run!(out)

## Check that the output is 1 word only, third argument is the feedback that will be provided if the condition fails
## Notice: functions operate on `aicall` as the only argument. We can use utilities like `last_output` and `last_message` to access the last message and output in the conversation.
airetry(x -> length(split(last_output(x), r" |\\.")) == 1, out,
    "You must answer with 1 word only.")

## Let's ensure that the output is in lowercase - simple and short
airetry(x -> all(islowercase, last_output(x)), out, "You must answer in lowercase.")
# [ Info: Condition not met. Retrying...

## Let's add final hint - it took us 2 retries
airetry(x -> startswith(last_output(x), "y"), out, "It starts with \"y\"")
# [ Info: Condition not met. Retrying...
# [ Info: Condition not met. Retrying...

## We end up with the correct answer
last_output(out)
# Output: "yellow"
```

Let's explore how we got here. 
We save the various attempts in a "tree" (SampleNode object)
You can access it in `out.samples`, which is the ROOT of the tree (top level).
Currently "active" sample ID is `out.active_sample_id` -> that's the same as `conversation` field in your AICall.

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
        println("ID: \$(sample.id), Answer: \$(msg.content)")
    end
end

# ID: 20493, Answer: yellow
# ID: 50086, Answer: yellow
# ID: 2733, Answer: red
# ID: 30088, Answer: blue
# ID: 44816, Answer: blue
```

Note: `airetry` will attempt to fix the model `max_retries` times. 
If you set `throw=true`, it will throw an ErrorException if the condition is not met after `max_retries` retries.


```julia
# Let's define a mini program to guess the number
\"\"\"
    llm_guesser()

Mini program to guess the number provided by the user (betwee 1-100).
\"\"\"
function llm_guesser(user_number::Int)
    @assert 1 <= user_number <= 100
    prompt = \"\"\"
I’m thinking a number between 1-100. Guess which one it is. 
You must respond only with digits and nothing else. 
Your guess:\"\"\"
    ## 2 samples at a time, max 5 fixing rounds
    out = AIGenerate(prompt; config = RetryConfig(; n_samples = 2, max_retries = 5),
        api_kwargs = (; n = 2)) |> run!
    ## Check the proper output format - must parse to Int, use do-syntax
    ## We can provide feedback via a function!
    airetry(out,
        x -> "Output: \$(last_output(x))\nFeedback: You must respond only with digits!!") do aicall
        !isnothing(tryparse(Int, last_output(aicall)))
    end
    ## Give a hint on bounds
    lower_bound = (user_number ÷ 10) * 10
    upper_bound = lower_bound + 10
    airetry(
        out, "The number is between or equal to \$lower_bound and \$upper_bound.") do aicall
        guess = tryparse(Int, last_output(aicall))
        lower_bound <= guess <= upper_bound
    end
    ## You can make at most 3x guess now -- if there is max_retries in `config.max_retries` left
    max_retries = out.config.retries + 3
    airetry(==(user_number), out,
        x -> "Your guess of \$(last_output(x)) is wrong. Try again"; max_retries)

    ## Evaluate the best guess
    @info "Guess: \$(last_output(out)) vs User: \$user_number (Number of calls made: \$(out.config.calls))"
    return out
end

# Let's play the game
out = llm_guesser(42)
## [ Info: Condition not met. Retrying...
## [ Info: Condition not met. Retrying...
## [ Info: Condition not met. Retrying...
## [ Info: Condition not met, but maximum retry budget was reached (Retries: 3/3, Calls: 8/99).
## [ Info: Guess: 25 vs User: 42 (Number of calls made: 8)
```
Okay, 3 guesses were not enough to guess the number. Try changing the max_retries or hints :)

Now, we could explore different samples (eg, `print_samples(out.samples)`) or see what the model guessed at each step:
```julia
print_samples(out.samples)
## SampleNode(id: 31817, stats: 4/12, score: 0.33, length: 2)
## ├─ SampleNode(id: 11089, stats: 2/7, score: 1.13, length: 4)
## │  ├─ SampleNode(id: 10484, stats: 0/3, score: 1.14, length: 6)
## │  │  ├─ SampleNode(id: 43493, stats: 0/1, score: 1.48, length: 7)
## │  │  └─ SampleNode(id: 11480, stats: 0/1, score: 1.48, length: 7)
## │  └─ SampleNode(id: 43481, stats: 0/1, score: 1.97, length: 5)
## └─ SampleNode(id: 40077, stats: 2/5, score: 1.4, length: 4)
##    ├─ SampleNode(id: 65021, stats: 0/1, score: 1.79, length: 5)
##    └─ SampleNode(id: 40493, stats: 0/1, score: 1.79, length: 5)

# Lastly, let's check all the guesses AI made across all samples. 
# We can clearly see that despite the feedback, the guesses were too repetitive and not close to the user's number.
# We could for example change some feedback to try +2 or -2 from the previous guess.
# Or we could add a condition that tells how far from the user's number the guess was.

for sample in PostOrderDFS(out.samples)
    [println("ID: \$(sample.id), Guess: \$(msg.content)")
     for msg in sample.data if msg isa PT.AIMessage]
end
## ID: 43493, Guess: 50
## ID: 43493, Guess: 25
## ID: 43493, Guess: 75
## ID: 11480, Guess: 50
## ID: 11480, Guess: 25
## ID: 11480, Guess: 75
## ID: 10484, Guess: 50
## ID: 10484, Guess: 25
## ID: 43481, Guess: 50
## ID: 43481, Guess: 25
## ID: 11089, Guess: 50
## ID: 65021, Guess: 50
## ID: 65021, Guess: 25
## ID: 40493, Guess: 50
## ID: 40493, Guess: 25
## ID: 40077, Guess: 50
```

Note that the model always see only the feedback of its own and its ancestors, not other "branches". 
But it can be changed, because feedback function has access to the aicall object.
"""
function airetry(
        f_cond::Function, aicall::AICallBlock, feedback::Union{AbstractString, Function} = "";
        verbose::Integer = 1, throw::Bool = false, evaluate_all::Bool = true, feedback_expensive::Bool = false,
        max_retries::Union{Nothing, Int} = nothing, retry_delay::Union{Nothing, Int} = nothing)
    (; config) = aicall
    (; max_calls, feedback_inplace, feedback_template) = aicall.config

    max_retries = max_retries isa Nothing ? config.max_retries : max_retries
    retry_delay = retry_delay isa Nothing ? config.retry_delay : retry_delay
    verbose = min(verbose, get(aicall.kwargs, :verbose, 99))

    ## Enter the retry loop
    condition_passed = false
    while !condition_passed

        ## Evaluation + feedback (sample is either the "successful" node or the best node to retry from)
        condition_passed, sample = evaluate_condition!(
            f_cond, aicall, feedback; evaluate_all, feedback_expensive)

        ## Update the aicall
        aicall.conversation = sample.data
        aicall.active_sample_id = sample.id
        aicall.success = condition_passed

        if condition_passed
            ## If condition is met, break the loop
            break
        elseif (config.calls >= max_calls) || (config.retries >= max_retries)
            ## condition not met, but no budget
            balance_str = "(Retries: $(config.retries)/$(max_retries), Calls: $(config.calls)/$(max_calls))."
            if throw
                throw(ErrorException("Maximum retry budget reached $balance_str"))
            else
                verbose > 0 &&
                    @info "Condition not met, but maximum retry budget was reached $balance_str"
                break
            end
        end

        ## If the condition is not met and we have budget, retry the aicall
        verbose > 0 && @info "Condition not met. Retrying..."
        ## Note: we already sampled the best node to expand from in aicall in evaluate_condition

        ## Append feedback if provided
        if sample.feedback != ""
            aicall.conversation = add_feedback!(
                aicall.conversation, sample; feedback_inplace, feedback_template)
        end
        sleep(retry_delay)
        aicall.config.retries += 1
        run!(aicall; verbose)
    end

    return aicall
end

"""
    evaluate_condition!(f_cond::Function, aicall::AICallBlock,
        feedback::Union{AbstractString, Function} = "";
        evaluate_all::Bool = true, feedback_expensive::Bool = false)

Evalutes the condition `f_cond` (must return Bool) on the `aicall` object. 
If the condition is not met, it will return the best sample to retry from and provide `feedback`.

Mutating as the results are saved in `aicall.samples`

If `evaluate_all` is `true`, it will evaluate all the "successful" samples in the `aicall` object. Otherwise, it will only evaluate the active sample..

For `f_cond` and `feedback` functions, you can use the `last_message` and `last_output` utilities to access the last message and last output in the conversation, respectively.

# Arguments
- `f_cond::Function`: A function that accepts the `aicall` object and returns a boolean value. Retry will be attempted if the condition is not met (`f_cond -> false`).
- `aicall::AICallBlock`: The `aicall` object to evaluate the condition on.
- `feedback::Union{AbstractString, Function}`: Feedback to provide if the condition is not met. If a function is provided, it must accept the `aicall` object as the only argument and return a string.
- `evaluate_all::Bool=false`: If true, it will evaluate all the "successful" samples in the `aicall` object. Otherwise, it will only evaluate the active sample.
- `feedback_expensive::Bool=false`: If false, it will provide feedback to all samples that fail the condition. 
  If `feedback` function is expensive to call (eg, another ai* function), set this to `true` and feedback will be provided only to the sample we will retry from.

# Returns
- a tuple `(condition_passed, sample)`, where `condition_passed` is a boolean indicating whether the condition was met, and `sample` is the best sample to retry from.

# Example
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

With feedback:
```julia
# Mimic AIGenerate run with feedback
aicall = AIGenerate(
    :BlankSystemUser; system = "a", user = "b")
sample = expand!(aicall.samples, aicall.conversation; success = true)
aicall.active_sample_id = sample.id

# Evaluate
cond, node = AT.evaluate_condition!(
    x -> occursin("NOTFOUND", last_output(x)), aicall, "Feedback X")
cond == false # fail
sample == node # same node (no other choice)
node.wins == 0
node.feedback == "\nFeedback X"
"""
function evaluate_condition!(f_cond::Function, aicall::AICallBlock,
        feedback::Union{AbstractString, Function} = "";
        evaluate_all::Bool = true, feedback_expensive::Bool = false)
    (; scoring, ordering) = aicall.config

    ## Memorize the current conversation
    conversation_ = aicall.conversation
    active_id_ = aicall.active_sample_id

    ## Init
    condition_passed = false
    successful_id = nothing

    for sample in AbstractTrees.PreOrderDFS(aicall.samples)
        ## If we want to evaluate only the active sample, skip the rest
        if !evaluate_all && sample.id != active_id_
            continue
        end
        ## Eveluate only if the sample was successful so far, or if it's the active one
        if sample.success == true || sample.id == active_id_
            ## Set the conversation for eval
            aicall.conversation = sample.data
            aicall.active_sample_id = sample.id
            result = f_cond(aicall)
            if result
                ## If successful evaluation
                condition_passed = true
                successful_id = sample.id
            else
                ## Evaluation failed
                sample.success = false
                if !feedback_expensive && feedback != ""
                    ## If feedback is not expensive, get it
                    if feedback isa Function
                        sample.feedback *= "\n" * feedback(aicall)
                    else
                        sample.feedback *= "\n" * feedback
                    end
                end
            end
            ## Backprop the results
            backpropagate!(sample; wins = result, visits = 1)
        end
    end

    ## Finalize
    sample = if condition_passed
        ## Grab a successful sample
        find_node(aicall.samples, successful_id)
    else
        ## We were unsuccessful, pick the best node to retry from
        select_best(aicall.samples, scoring; ordering)
    end
    if !condition_passed && feedback != "" &&
       feedback_expensive
        ## We were unsuccessful and haven't given any feedback yet
        sample.feedback = if feedback isa Function
            "\n" * feedback(sample)
        else
            "\n" * feedback
        end
    end

    ## return to original state
    aicall.conversation = conversation_
    aicall.active_sample_id = active_id_

    return condition_passed, sample
end

"""
    add_feedback!(
        conversation::AbstractVector{<:PT.AbstractMessage}, sample::SampleNode; feedback_inplace::Bool = false,
        feedback_template::Symbol = :FeedbackFromEvaluator)

Adds formatted feedback to the `conversation` based on the `sample` node feedback (and its ancestors).

# Arguments
- `conversation::AbstractVector{<:PT.AbstractMessage}`: The conversation to add the feedback to.
- `sample::SampleNode`: The sample node to extract the feedback from.
- `feedback_inplace::Bool=false`: If true, it will add the feedback to the last user message inplace (and pop the last AIMessage). Otherwise, it will append the feedback as a new message.
- `feedback_template::Symbol=:FeedbackFromEvaluator`: The template to use for the feedback message. It must be a valid `AITemplate` name.

# Example

```julia
sample = SampleNode(; data = nothing, feedback = "Feedback X")
conversation = [PT.UserMessage("I say hi!"), PT.AIMessage(; content = "I say hi!")]
conversation = AT.add_feedback!(conversation, sample)
conversation[end].content == "### Feedback from Evaluator\nFeedback X\n"

Inplace feedback:
```julia
conversation = [PT.UserMessage("I say hi!"), PT.AIMessage(; content = "I say hi!")]
conversation = AT.add_feedback!(conversation, sample; feedback_inplace = true)
conversation[end].content == "I say hi!\n\n### Feedback from Evaluator\nFeedback X\n"
```

Sample with ancestors with feedback:
```julia
sample_p = SampleNode(; data = nothing, feedback = "\nFeedback X")
sample = expand!(sample_p, nothing)
sample.feedback = "\nFeedback Y"
conversation = [PT.UserMessage("I say hi!"), PT.AIMessage(; content = "I say hi!")]
conversation = AT.add_feedback!(conversation, sample)

conversation[end].content ==
"### Feedback from Evaluator\n\nFeedback X\n----------\n\nFeedback Y\n"
```
"""
function add_feedback!(
        conversation::AbstractVector{<:PT.AbstractMessage}, sample::SampleNode; feedback_inplace::Bool = false,
        feedback_template::Symbol = :FeedbackFromEvaluator)

    ## Prepare feedback as a UserMessage
    feedback_message = let schema = PT.NoSchema()
        # feedback from all ancestors, newline separated
        all_feedback = collect_all_feedback(sample)
        template = PT.AITemplate(feedback_template)
        output = PT.render(schema, template) # render the feedback template
        output = PT.render(schema, output; feedback = all_feedback) # replace the placeholder
        output[end] # UserMessage with the feedback
    end
    if feedback_inplace
        ## Remove AI Message and extract he user message
        user_msg = pop!(conversation) ## pop the last AI message
        while !PT.isusermessage(user_msg)
            ## keep popping until we find the user message
            user_msg = pop!(conversation)
            length(conversation) == 0 &&
                throw("Something went wrong, no user messages detected to add feedback into.")
        end
        ## Concatenate the feedback message with the user message
        user_msg = PT.UserMessage(;
            content = user_msg.content * "\n\n" * feedback_message.content)
        push!(conversation, user_msg)
    else
        ## append the feedback message to the conversation
        push!(conversation, feedback_message)
    end
    return conversation
end