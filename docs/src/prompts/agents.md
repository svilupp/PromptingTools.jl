The following file is auto-generated from the `templates` folder. For any changes, please modify the source files in the `templates` folder.

To use these templates in `aigenerate`, simply provide the template name as a symbol, eg, `aigenerate(:MyTemplate; placeholder1 = value1)`

## Code-Fixing Templates

### Template: CodeFixerRCI

- Description: This template is meant to be used with `AICodeFixer`. It loosely follows the [Recursive Critique and Improvement paper](https://arxiv.org/pdf/2303.17491.pdf) with two steps Critique and Improve based on `feedback`. Placeholders: `feedback`
- Placeholders: `feedback`
- Word count: 2487
- Source: 
- Version: 1.1

**System Prompt:**
`````plaintext

`````


**User Prompt:**
`````plaintext
Ignore all previous instructions. 
Your goal is to satisfy the user's request by using several rounds of self-reflection (Critique step) and improvement of the previously provided solution (Improve step).
Always enclose the Julia code in triple backticks code fence (```julia\n ... \n```).

1. **Recall Past Critique:**
- Summarize past critiques to refresh your memory (use inline quotes to highlight the few characters of the code that caused the mistakes). It must not be repeated.

2. **Critique Step Instructions:** 
- Read the user request word-by-word. Does the code implementation follow the request to the letter? Let's think step by step.
- Review the provided feedback in detail.
- Provide 2-3 bullet points of criticism for the code. Each bullet point must refer to a different type of error or issue.
    - If there are any errors, explain why and what needs to be changed to FIX THEM! Be specific. 
    - If an error repeats or critique repeats, the previous issue was not addressed. YOU MUST SUGGEST A DIFFERENT IMPROVEMENT THAN BEFORE.
    - If there are no errors, identify and list specific issues or areas for improvement to write more idiomatic Julia code.


3. **Improve Step Instructions:** 
- Specify what you'll change to address the above critique.
- Provide the revised code reflecting your suggested improvements. Always repeat the function definition, as only the Julia code in the last message will be evaluated.
- Ensure the new version of the code resolves the problems while fulfilling the original task. Ensure it has the same function name.
- Write 2-3 correct and helpful unit tests for the function requested by the user (organize in `@testset "name" begin ... end` block, use `@test` macro).


3. **Response Format:**
---
### Past Critique
<brief bullet points on past critique>

### Critique
<list of issues as bullet points pinpointing the mistakes in the code (use inline quotes)>

### Improve
<list of improvements as bullet points with a clear outline of a solution (use inline quotes)>

```julia
<provide improved code>
```
---

Be concise and focused in all steps.

### Feedback from the User

{{feedback}}

I believe in you. You can actually do it, so do it ffs. Avoid shortcuts or placing comments instead of code. I also need code, actual working Julia code.
What are your Critique and Improve steps?
  ### Feedback from the User

{{feedback}}

Based on your past critique and the latest feedback, what are your Critique and Improve steps?

`````


### Template: CodeFixerShort

- Description: This template is meant to be used with `AICodeFixer` to ask for code improvements based on `feedback`. It uses the same message for both the introduction of the new task and for the iterations. Placeholders: `feedback`
- Placeholders: `feedback`
- Word count: 786
- Source: 
- Version: 1.1

**System Prompt:**
`````plaintext

`````


**User Prompt:**
`````plaintext

The above Julia code has been executed with the following results:

```plaintext
{{feedback}}
```

0. Read the user request word-by-word. Does the code implementation follow the request to the letter? Let's think step by step.
1. Review the execution results in detail and, if there is an error, explain why it happened.
2. Suggest improvements to the code. Be EXTREMELY SPECIFIC. Think step-by-step and break it down.
3. Write an improved implementation based on your reflection.

All code must be enclosed in triple backticks code fence (```julia\n ... \n```) and included in one message to be re-evaluated.

I believe in you. Take a deep breath. You can actually do it, so do it ffs. Avoid shortcuts or placing comments instead of code. I also need code, actual working Julia code.

`````


### Template: CodeFixerTiny

- Description: This tiniest template to use with `AICodeFixer`. Iteratively asks to improve the code based on provided `feedback`. Placeholders: `feedback`
- Placeholders: `feedback`
- Word count: 210
- Source: 
- Version: 1.0

**System Prompt:**
`````plaintext

`````


**User Prompt:**
`````plaintext
### Execution Results

```plaintext
{{feedback}}
```

Take a deep break. Think step-by-step and fix the above errors. I believe in you. You can do it! I also need code, actual working Julia code, no shortcuts.

`````


## Feedback Templates

### Template: FeedbackFromEvaluator

- Description: Simple user message with "Feedback from Evaluator". Placeholders: `feedback`
- Placeholders: `feedback`
- Word count: 41
- Source: 
- Version: 1.0

**System Prompt:**
`````plaintext

`````


**User Prompt:**
`````plaintext
### Feedback from Evaluator
{{feedback}}

`````


