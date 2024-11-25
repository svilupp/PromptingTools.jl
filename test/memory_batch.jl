using Test
using PromptingTools
using PromptingTools: SystemMessage, UserMessage, AIMessage, AbstractMessage, ConversationMemory
using PromptingTools: issystemmessage, isusermessage, isaimessage
using Test: @capture_out

@testset "ConversationMemory Batch Tests" begin
    mem = ConversationMemory()

    # Add test messages
    push!(mem, SystemMessage("System"))
    push!(mem, UserMessage("First User"))
    for i in 1:5
        push!(mem, UserMessage("User $i"))
        push!(mem, AIMessage("AI $i"))
    end

    # Test basic batch size
    result = get_last(mem, 6; batch_size=2)
    @test length(result) == 6  # system + first_user + 2 complete pairs
    @test issystemmessage(result[1])
    @test isusermessage(result[2])

    # Test explanation
    result_explained = get_last(mem, 6; batch_size=2, explain=true)
    @test length(result_explained) == 6
    @test any(msg -> occursin("truncated", msg.content), result_explained)

    # Test verbose output
    output = @capture_out begin
        get_last(mem, 6; batch_size=2, verbose=true)
    end
    @test contains(output, "Total messages:")
    @test contains(output, "Keeping:")
    @test contains(output, "Required messages:")

    # Test larger batch size
    result_large = get_last(mem, 8; batch_size=4)
    @test length(result_large) == 8
    @test issystemmessage(result_large[1])
    @test isusermessage(result_large[2])

    # Test with no batch size
    result_no_batch = get_last(mem, 4)
    @test length(result_no_batch) == 4
    @test issystemmessage(result_no_batch[1])
end
