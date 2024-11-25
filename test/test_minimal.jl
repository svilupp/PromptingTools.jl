using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage
using PromptingTools: ConversationMemory

@testset "ConversationMemory Minimal Tests" begin
    @testset "Message Deduplication" begin
        mem = ConversationMemory()
        msgs = [SystemMessage("System prompt"), UserMessage("User 1"), AIMessage("AI 1")]
        append!(mem, msgs)
        @test length(mem) == 2  # excluding system message

        msgs_with_ids = [
            SystemMessage("System prompt"; run_id=1),
            UserMessage("User 2"; run_id=2),
            AIMessage("AI 2"; run_id=2)
        ]
        append!(mem, msgs_with_ids)
        @test length(mem) == 4
    end

    @testset "Message Retrieval" begin
        mem = ConversationMemory()
        push!(mem, SystemMessage("System prompt"))
        push!(mem, UserMessage("First user"))
        for i in 1:5  # Reduced number of messages
            push!(mem, AIMessage("AI message $i"))
            push!(mem, UserMessage("User message $i"))
        end

        recent = get_last(mem, 5)
        @test length(recent) == 7  # 5 + system + first user
        @test recent[1].content == "System prompt"
        @test recent[2].content == "First user"

        recent = get_last(mem, 5; explain=true)
        @test contains(recent[3].content, "For efficiency reasons")
    end
end
