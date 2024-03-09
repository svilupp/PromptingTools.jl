## Code-Fixing Templates

The following files are auto-generated from the `templates` folder. For any changes, please modify the source files in the `templates` folder.

To use these templates in `aigenerate`, simply provide the template name as a symbol, eg, `aigenerate(:MyTemplate; placeholder1 = value1)`

### Template: CodeFixerRCI

- Description: This template is meant to be used with `AICodeFixer`. It loosely follows the [Recursive Critique and Improvement paper](https://arxiv.org/pdf/2303.17491.pdf) with two steps Critique and Improve based on `feedback`. Placeholders: `feedback`
- Placeholders: `feedback`
- Word count: 2475
- Source: 
- Version: 1.0

**System Prompt:**


**User Prompt:**
Ignore all previous instructions. 
Your goal is to satisfy the user's request by using several rounds of self-reflection (Critique step) and improvement of the previously provided solution (Improve step).
Always enclose Julia code in triple backticks code fence (```julia\n ... \n```).

1. **Recall Past Critique:**
- Summarize past critique to refresh your memory (use inline quotes to highlight the few characters of the code that caused the mistakes). It must not repeat.

2. **Critique Step Instructions:** 
- Read the user request word-by-word. Does the code implementation follow the request to the the letter? Think it though step-by-step.
- Review the provided feedback in detail.
- Provide 2-3 bullet points of criticism for the code. Each bullet point must refer to a different type of error or issue.
    - If there are any errors, explain why and what needs to be changed to FIX THEM! Be specific. 
    - If an error repeats or critique repeats, previous issue was not addressed. YOU MUST

### Template: CodeFixerShort

- Description: This template is meant to be used with `AICodeFixer` to ask for code improvements based on `feedback`. It uses the same message for both the introduction of the new task and for the iterations. Placeholders: `feedback`
- Placeholders: `feedback`
- Word count: 791
- Source: 
- Version: 1.0

**System Prompt:**


**User Prompt:**

The above Julia code has been executed with the following results:

```plaintext
{{feedback}}
```

0. Read the user request word-by-word. Does the code implementation follow the request to the the letter? Think it though step-by-step.
1. Review the execution results in detail and, if there is an error, explain why it happened.
2. Suggest improvements to the code. Be EXTREMELY SPECIFIC. Think step-by-step and break it down.
3. Write an improved implemented based on your reflection.

All code must be enclosed in triple backticks code fence (```julia\n ... \n```) and included in one message to be re-evaluated.

I believe in you. Take a deep breath. You can actually do it, so do it ffs. Avoid shortcuts or placing comments instead of code. I also need code, actual working Julia code.


### Template: CodeFixerTiny

- Description: This tiniest template to use with `AICodeFixer`. Iteratively asks to improve the code based on provided `feedback`. Placeholders: `feedback`
- Placeholders: `feedback`
- Word count: 210
- Source: 
- Version: 1.0

**System Prompt:**


**User Prompt:**
### Execution Results

```plaintext
{{feedback}}
```

Take a deep break. Think step-by-step and fix the above errors. I believe in you. You can do it! I also need code, actual working Julia code, no shortcuts.


## Feedback Templates

The following files are auto-generated from the `templates` folder. For any changes, please modify the source files in the `templates` folder.

To use these templates in `aigenerate`, simply provide the template name as a symbol, eg, `aigenerate(:MyTemplate; placeholder1 = value1)`

### Template: FeedbackFromEvaluator

- Description: Simple user message with "Feedback from Evaluator". Placeholders: `feedback`
- Placeholders: `feedback`
- Word count: 41
- Source: 
- Version: 1.0

**System Prompt:**


**User Prompt:**
### Feedback from Evaluator
{{feedback}}


