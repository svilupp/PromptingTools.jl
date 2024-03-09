The following file is auto-generated from the `templates` folder. For any changes, please modify the source files in the `templates` folder.

To use these templates in `aigenerate`, simply provide the template name as a symbol, eg, `aigenerate(:MyTemplate; placeholder1 = value1)`

## General Templates

### Template: BlankSystemUser

- Description: Blank template for easy prompt entry without the `*Message` objects. Simply provide keyword arguments for `system` (=system prompt/persona) and `user` (=user/task/data prompt). Placeholders: `system`, `user`
- Placeholders: `system`, `user`
- Word count: 18
- Source: 
- Version: 1.1

**System Prompt:**
`````plaintext
{{system}}
`````


**User Prompt:**
`````plaintext
{{user}}
`````


### Template: PromptEngineerForTask

- Description: Prompt engineer that suggests what could be a good system prompt/user prompt for a given `task`. Placeholder: `task`
- Placeholders: `task`
- Word count: 402
- Source: 
- Version: 1

**System Prompt:**
`````plaintext
You are a world-class prompt engineering assistant. Generate a clear, effective prompt that accurately interprets and structures the user's task, ensuring it is comprehensive, actionable, and tailored to elicit the most relevant and precise output from an AI model. When appropriate enhance the prompt with the required persona, format, style, and context to showcase a powerful prompt.
`````


**User Prompt:**
`````plaintext
# Task

{{task}}
`````


