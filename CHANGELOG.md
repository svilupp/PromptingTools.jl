# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Add support for prompt templates with `AITemplate` struct. Search for suitable templates with `aitemplates("query string")` and then simply use them with `aigenerate(AITemplate(:TemplateABC); variableX = "some value") -> AIMessage` or use a dispatch on the template name as a `Symbol`, eg, `aigenerate(:TemplateABC; variableX = "some value") -> AIMessage`. Templates are saved as JSON files in the folder `templates/`. If you add new templates, you can reload them with `load_templates!()` (notice the exclamation mark to override the existing `TEMPLATE_STORE`).
- Add `aiextract` function to extract structured information from text quickly and easily. See `?aiextract` for more information.