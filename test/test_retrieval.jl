using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage
using PromptingTools: ConversationMemory

@testset "Message Retrieval" begin
    mem = ConversationMemory()

    # Add test messages
    push!(mem, SystemMessage("System prompt"))
    push!(mem, UserMessage("First user"))
    for i in 1:15
        push!(mem, AIMessage("AI message $i"))
        push!(mem, UserMessage("User message $i"))
    end

    # Test get_last without batch_size
    recent = get_last(mem, 5)
    @test length(recent) == 7  # 5 + system + first user
    @test recent[1].content == "System prompt"
    @test recent[2].content == "First user"

    # Test get_last with batch_size=10
    recent = get_last(mem, 20; batch_size=10)
    @test 11 <= length(recent) <= 20  # Should be between 11-20 messages
    @test recent[1].content == "System prompt"
    @test recent[2].content == "First user"

    # Test get_last with explanation
    recent = get_last(mem, 5; explain=true)
    @test contains(recent[3].content, "For efficiency reasons")

    # Test get_last with verbose
    mktemp() do path, io
        redirect_stdout(io) do
            get_last(mem, 5; verbose=true)
        end
        seekstart(io)
        output = read(io, String)
        @test contains(output, "Total messages:")
        @test contains(output, "Keeping:")
    end
end
