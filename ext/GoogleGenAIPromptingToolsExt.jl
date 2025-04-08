module GoogleGenAIPromptingToolsExt

using GoogleGenAI
using PromptingTools
using HTTP, JSON3
const PT = PromptingTools
using StreamCallbacks

"Wrapper for GoogleGenAI.generate_content."
function PromptingTools.ggi_generate_content(prompt_schema::PT.AbstractGoogleSchema,
        api_key::AbstractString, model_name::AbstractString,
        conversation; http_kwargs, streamcallback=nothing, api_kwargs=NamedTuple(), verbose=true)
    r = if !isnothing(streamcallback)
        # Configure the callback with Gemini flavor
        if isnothing(streamcallback.flavor)
            streamcallback.flavor = StreamCallbacks.GoogleStream()
        end
        
        # Create a stream from GoogleGenAI
        config = GenerateContentConfig(; api_kwargs...)
        stream = GoogleGenAI.generate_content_stream(api_key, model_name, conversation; config)
        
        # Process each chunk through StreamCallbacks
        full_text = ""
        for chunk in stream
            if haskey(chunk, :error)
                error_msg = "Stream error: $(chunk.error)"
                @warn error_msg
                if streamcallback.throw_on_error
                    throw(ErrorException(error_msg))
                end
                continue
            end
            
            # Convert the Gemini chunk to a StreamChunk
            # Create a JSON representation of the chunk data
            json_data = Dict{Symbol,Any}(
                :candidates => chunk.candidates,
                :safety_ratings => chunk.safety_ratings,
                :usageMetadata => chunk.usage_metadata
            )
            
            # Add finish_reason if present
            if !isnothing(chunk.finish_reason)
                json_data[:finish_reason] = chunk.finish_reason
            end
            
            # Create a StreamChunk from the JSON data
            stream_chunk = StreamCallbacks.StreamChunk(
                event = :data,
                data = JSON3.write(json_data),
                json = json_data
            )
            
            # Accumulate the full text
            full_text *= chunk.text
            
            # Process the chunk through StreamCallbacks
            StreamCallbacks.handle_error_message(stream_chunk; 
                throw_on_error=streamcallback.throw_on_error, 
                verbose=verbose, 
                streamcallback.kwargs...)
            
            # Check if we're done
            StreamCallbacks.is_done(streamcallback.flavor, stream_chunk; 
                verbose=verbose, 
                streamcallback.kwargs...) && (isdone = true)
            
            # Process the chunk through our callback
            StreamCallbacks.callback(streamcallback, stream_chunk; 
                verbose=verbose, 
                streamcallback.kwargs...)
            
            # Save the chunk for later processing
            push!(streamcallback, stream_chunk)
        end
        
        # Build a response similar to what generate_content would return
        (;
            text = full_text,
            response_status = 200,
            candidates = [],
            safety_ratings = Dict(),
            finish_reason = "STOP",
            usage_metadata = Dict()
        )
    else
        # Non-streaming case
        config = GenerateContentConfig(; api_kwargs...)
        GoogleGenAI.generate_content(
            api_key, model_name, conversation; config)
    end
    return r
end

end # end of module
