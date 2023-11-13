# This file contains examples of how to work with AITemplate(s).

using PromptingTools
const PT = PromptingTools

# LLM responses are only as good as the prompts you give them. However, great prompts take long time to write -- AITemplate are a way to re-use great prompts!
#
# AITemplates are just a collection of templated prompts (ie, set of "messages" that have placeholders like {{question}})
# 
# They are saved as JSON files in the `templates` directory.
# They are automatically loaded on package import, but you can always force a re-load with `PT.load_templates!()`
PT.load_templates!();

# You can (create them) and use them for any ai* function instead of a prompt:
# Let's use a template called :JuliaExpertAsk
# alternatively, you can use `AITemplate(:JuliaExpertAsk)` for cleaner dispatch
msg = aigenerate(:JuliaExpertAsk; ask = "How do I add packages?")
# ... some response from GPT3.5
#
# You can see that it had a placeholder for the actual question (`ask`) that we provided as a keyword argument. 
# We did not have to write any system prompt for personas, tone, etc. -- it was all provided by the template!
#
# How to know which templates are available? You can search for them with `aitemplates()`:
# You can search by Symbol (only for partial name match), String (partial match on name or description), or Regex (more fields)
tmps = aitemplates("JuliaExpertAsk")
# Outputs a list of available templates that match the search -- there is just one in this case:
#
# 1-element Vector{AITemplateMetadata}:
# PromptingTools.AITemplateMetadata
#   name: Symbol JuliaExpertAsk
#   description: String "For asking questions about Julia language. Placeholders: `ask`"
#   version: String "1"
#   wordcount: Int64 237
#   variables: Array{Symbol}((1,))
#   system_preview: String "You are a world-class Julia language programmer with the knowledge of the latest syntax. Your commun"
#   user_preview: String "# Question\n\n{{ask}}"
#   source: String ""
#
# You see not just the description, but also a preview of the actual prompts, placeholders available, and the length (to gauge how much it would cost).
#
# If you use VSCode, you can display them in a nice scrollable table with `vscodedisplay`:
using DataFrames
DataFrame(tmp) |> vscodedisplay
#
#
# You can also just `render` the template to see the underlying mesages:
msgs = PT.render(AITemplate(:JuliaExpertAsk))
#
# 2-element Vector{PromptingTools.AbstractChatMessage}:
#  PromptingTools.SystemMessage("You are a world-class Julia language programmer with the knowledge of the latest syntax. Your communication is brief and concise. You're precise and answer only when you're confident in the high quality of your answer.")
#  PromptingTools.UserMessage("# Question\n\n{{ask}}")
#
# Now, you know exactly what's in the template! 
#
# If you want to modify it, simply change it and save it as a new file with `save_template` (see the docs `?save_template` for more details):
#
# !!! If you have some good templates, please consider sharing them with the community by opening a PR to the `templates` directory!