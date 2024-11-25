using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage
using PromptingTools: ConversationMemory

@testset "Message Deduplication" begin
    mem = ConversationMemory()

    # Test append! with empty memory
    msgs = [
        SystemMessage("System prompt"),
        UserMessage("User 1"),
        AIMessage("AI 1")
    ]
    append!(mem, msgs)
    @test length(mem) == 2  # excluding system message

    # Test append! with run_id based deduplication
    msgs_with_ids = [
        SystemMessage("System prompt"; run_id=1),
        UserMessage("User 2"; run_id=2),
        AIMessage("AI 2"; run_id=2)
    ]
    append!(mem, msgs_with_ids)
    @test length(mem) == 4  # Should add new messages with higher run_id

    # Test append! with overlapping messages
    msgs_overlap = [
        UserMessage("User 2"; run_id=1),  # Old run_id, should be ignored
        AIMessage("AI 2"; run_id=1),      # Old run_id, should be ignored
        UserMessage("User 3"; run_id=3),  # New run_id, should be added
        AIMessage("AI 3"; run_id=3)       # New run_id, should be added
    ]
    append!(mem, msgs_overlap)
    @test length(mem) == 6  # Should only add the new messages
end
