using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage
using PromptingTools: issystemmessage, isusermessage, isaimessage
using PromptingTools: ConversationMemory

# Include our test files
include("memory_batch.jl")
include("memory_dedup.jl")
include("memory_core.jl")
