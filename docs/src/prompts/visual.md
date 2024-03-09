The following file is auto-generated from the `templates` folder. For any changes, please modify the source files in the `templates` folder.

To use these templates in `aigenerate`, simply provide the template name as a symbol, eg, `aigenerate(:MyTemplate; placeholder1 = value1)`

## Visual Templates

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


