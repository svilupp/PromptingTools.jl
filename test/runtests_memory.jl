using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage
using PromptingTools: TestEchoOpenAISchema, ConversationMemory
using PromptingTools: issystemmessage, isusermessage, isaimessage, last_message, last_output, register_model!

# Run only memory tests
include("memory.jl")
