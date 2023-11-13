using PromptingTools
const PT = PromptingTools
using PromptingTools: AIMessage,
    SystemMessage, UserMessage, DataMessage, MetadataMessage, render
using JSON3

# Create a few templates directly
msg = [
    MetadataMessage(; content = "",
        description = "Basic template for LLM-based classification whether provided statement is true/false/unknown.",
        version = "1"),
    SystemMessage("You are an impartial AI judge evaluting whether the provided statement is \"true\" or \"false\". Answer \"unknown\" if you cannot decide."),
    UserMessage("# Statement\n\n{{it}}"),
]

JSON3.write("templates/test.json", msg)
JSON3.read("templates/test.json", Vector{PT.AbstractChatMessage})

# Standard definition
msg = [
    SystemMessage("You are an impartial AI judge evaluting whether the provided statement is \"true\" or \"false\". Answer \"unknown\" if you cannot decide."),
    UserMessage("# Statement\n\n{{it}}"),
]
PT.save_template(joinpath("templates", "classification", "JudgeIsItTrue.json"),
    msg;
    description = "LLM-based classification whether provided statement is true/false/unknown. Statement is provided via `it` placeholder.")

msg = [
    SystemMessage("You are a world-class AI assistant. Your communication is brief and concise. You're precise and answer only when you're confident in the high quality of your answer."),
    UserMessage("# Question\n\n{{ask}}"),
]
PT.save_template(joinpath("templates", "persona-task", "AssistantAsk.json"),
    msg;
    description = "Helpful assistant for asking generic questions. Placeholders: `ask`")

msg = [
    SystemMessage("You are a world-class Julia language programmer with the knowledge of the latest syntax. Your communication is brief and concise. You're precise and answer only when you're confident in the high quality of your answer."),
    UserMessage("# Question\n\n{{ask}}"),
]
PT.save_template(joinpath("templates", "persona-task", "JuliaExpertAsk.json"),
    msg;
    description = "For asking questions about Julia language. Placeholders: `ask`")

msg = [
    SystemMessage("You are a world-class Julia language programmer with the knowledge of the latest syntax. Your communication is brief and concise. You precisely follow the given task and use the data when provided. First, think through your approach step by step. Only then start with the answer."),
    UserMessage("# Task\n\n{{task}}\n\n\n\n# Data\n\n{{data}}"),
]
PT.save_template(joinpath("templates", "persona-task", "JuliaExpertCoTTask.json"), msg;
    description = "For small code task in Julia language. It will first describe the approach (CoT = Chain of Thought). Placeholders: `task`, `data`")

msg = [
    PT.SystemMessage("You are a world-class AI assistant. You are detail oriented, diligent, and have a great memory. Your communication is brief and concise."),
    PT.UserMessage("# Task\n\n{{task}}\n\n\n\n# Data\n\n{{data}}"),
]
PT.save_template(joinpath("templates", "persona-task", "DetailOrientedTask.json"),
    msg;
    description = "Great template for detail-oriented tasks like string manipulations, data cleaning, etc. Placeholders: `task`, `data`.")

# Load one test
t, m = PT.load_template("templates/test.json")

# Load templates
PT.load_templates!()

# Render templates
template = AITemplate(:JudgeIsItTrue)

render(PT.PROMPT_SCHEMA, template)
render(template)

# Search for templates
tmp = aitemplates("template")

# Hack for a nicer display in vscode
using DataFrames
DataFrame(tmp) |> vscodedisplay