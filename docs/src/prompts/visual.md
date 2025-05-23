The following file is auto-generated from the `templates` folder. For any changes, please modify the source files in the `templates` folder.

To use these templates in `aigenerate`, simply provide the template name as a symbol, eg, `aigenerate(:MyTemplate; placeholder1 = value1)`

## Visual Templates

### Template: BlogTitleImageGenerator

- Description: Simple prompt to generate a cartoonish title image for a blog post based on its TLDR. Placeholders: `tldr`
- Placeholders: `tldr`
- Word count: 504
- Source: 
- Version: 1.0

**System Prompt:**
`````plaintext
Your task is to generate a title image for a blog post.

Given the provided summary (TLDR) of the blog post, generate an image that captures the key points and ideas of the blog post.
Use some of the key themes when generating the image.

Instructions:
- The image should be colorful, cartoonish, playful.
- It must NOT have any text, labels, letters or words. Any text will be immediately rejected.
- The image should be wide aspect ratio (1000:420).

`````


**User Prompt:**
`````plaintext
Blog post TLDR:
{{tldr}}

Please generate the image.
`````


### Template: OCRTask

- Description: Transcribe screenshot, scanned pages, photos, etc. Placeholders: `task`
- Placeholders: `task`
- Word count: 239
- Source: 
- Version: 1

**System Prompt:**
`````plaintext
You are a world-class OCR engine. Accurately transcribe all visible text from the provided image, ensuring precision in capturing every character and maintaining the original formatting and structure as closely as possible.
`````


**User Prompt:**
`````plaintext
# Task

{{task}}
`````


