# # Using AITemplates

# This file contains examples of how to work with AITemplate(s).
#
# First, let's import the package and define a helper link for calling un-exported functions:
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
# Let's use a template called `:JuliaExpertAsk`
# alternatively, you can use `AITemplate(:JuliaExpertAsk)` for cleaner dispatch
msg = aigenerate(:JuliaExpertAsk; ask = "How do I add packages?")

# You can see that it had a placeholder for the actual question (`ask`) that we provided as a keyword argument. 
# We did not have to write any system prompt for personas, tone, etc. -- it was all provided by the template!
#
# How to know which templates are available? You can search for them with `aitemplates()`:
# You can search by Symbol (only for partial name match), String (partial match on name or description), or Regex (more fields)
tmps = aitemplates("JuliaExpertAsk")

# You can see that it outputs a list of available templates that match the search - there is just one in this case.
#
# Moreover, it shows not just the description, but also a preview of the actual prompts, placeholders available, and the length (to gauge how much it would cost).
#
# If you use VSCode, you can display them in a nice scrollable table with `vscodedisplay`:
# ```plaintext
# using DataFrames
# DataFrame(tmp) |> vscodedisplay
# ```
#
# You can also just `render` the template to see the underlying mesages:
msgs = PT.render(AITemplate(:JuliaExpertAsk))

#
# Now, you know exactly what's in the template! 
#
# If you want to modify it, simply change it and save it as a new file with `save_template` (see the docs `?save_template` for more details).
# 
# Let's adjust the previous template to be more specific to a data analysis question:
tpl = [PT.SystemMessage("You are a world-class Julia language programmer with the knowledge of the latest syntax. You're also a senior Data Scientist and proficient in data analysis in Julia. Your communication is brief and concise. You're precise and answer only when you're confident in the high quality of your answer.")
       PT.UserMessage("# Question\n\n{{ask}}")]
# Templates are saved in the `templates` directory of the package. Name of the file will become the template name (eg, call `:JuliaDataExpertAsk`)
filename = joinpath(pkgdir(PromptingTools),
    "templates",
    "persona-task",
    "JuliaDataExpertAsk_123.json")
PT.save_template(filename,
    tpl;
    description = "For asking data analysis questions in Julia language. Placeholders: `ask`")
rm(filename) # cleanup if we don't like it
# 
# When you create a new template, remember to re-load the templates with `load_templates!()` so that it's available for use.
PT.load_templates!();
#
# !!! If you have some good templates (or suggestions for the existing ones), please consider sharing them with the community by opening a PR to the `templates` directory!
