# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

# Project Context - What does this app does
This is a portrait-orientation mobile app developed for both Android and iOS. It is a language learning quiz application that presents users with multiple-choice questions across three main categories:

**Image Quiz:** Displays an image and asks the user to identify what it represents by selecting the correct answer.

**Vocabulary Quiz:** Presents a step-by-step conversation with blanks in one or both parts of the dialogue, challenging the user to fill in the missing vocabulary.

**Grammar Quiz:** Similar to the vocabulary quiz, but focuses on selecting the correct grammatical structure rather than vocabulary.

As users progress through levels, they earn rewards such as stars and diamonds upon completing each level. The app also includes features like user profiles, avatar selection, achievements, and settings.

During gameplay, narrative-driven achievements are unlocked—similar to the storytelling style in games like Gardenscapes—but with a focus on helping others and solving problems.

Currently, the app stores both configuration and state data in JSON files. It is designed to support multiple device types with varying screen resolutions, including mobile phones and tablets.


## Context Management Workflow

Development progress is tracked through files in `.claude/context/`:

- `active-progress-context.md` — the **single** currently active issue (one at a time); developer adds issues here directly
- `progress-context-archive.md` — **summarized** completed items (most recent first)
- `full-project-issue-archive.md` — **verbatim** copy of each completed issue as it appeared in active-progress-context.md (most recent first)
- `architecture-technical-context.md` — tech stack, resolution strategy, asset layout decisions
- `coding-standards-context.md` — coding conventions (to be filled)
- `domain-glossary-context.md` — entity definitions (to be filled)

When an issue is completed and accepted, it is archived in both files above. When a major architectural decision is made, record it in `.claude/decisions/`.

## Key Rules
For rules refer to `.claude/rules/rules.md`