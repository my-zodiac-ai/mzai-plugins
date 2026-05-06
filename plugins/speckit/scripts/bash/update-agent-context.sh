#!/usr/bin/env bash

# Update agent context files with information from plan.md
#
# This script maintains AI agent context files by parsing feature specifications
# and updating agent-specific configuration files with project information.
#
# MAIN FUNCTIONS:
# 1. Environment Validation
#    - Verifies git repository structure and branch information
#    - Checks for required plan.md files and templates
#    - Validates file permissions and accessibility
#
# 2. Plan Data Extraction
#    - Parses plan.md files to extract project metadata
#    - Identifies language/version, frameworks, databases, and project types
#    - Handles missing or incomplete specification data gracefully
#
# 3. Agent File Management
#    - Creates new agent context files from templates when needed
#    - Updates existing agent files with new project information
#    - Preserves manual additions and custom configurations
#    - Supports multiple AI agent formats and directory structures
#
# 4. Content Generation
#    - Generates language-specific build/test commands
#    - Creates appropriate project directory structures
#    - Updates technology stacks and recent changes sections
#    - Maintains consistent formatting and timestamps
#
# 5. Multi-Agent Support
#    - Handles agent-specific file paths and naming conventions
#    - Supports: Claude, Gemini, Copilot, Cursor, Qwen, opencode, Codex, Windsurf, Junie, Kilo Code, Auggie CLI, Roo Code, CodeBuddy CLI, Qoder CLI, Amp, SHAI, Tabnine CLI, Kiro CLI, Mistral Vibe, Kimi Code, Pi Coding Agent, iFlow CLI, Antigravity or Generic
#    - Can update single agents or all existing agent files
#    - Creates default Claude file if no agent files exist
#
# Usage: ./update-agent-context.sh [agent_type]
# Agent types: claude|gemini|copilot|cursor-agent|qwen|opencode|codex|windsurf|junie|kilocode|auggie|roo|codebuddy|amp|shai|tabnine|kiro-cli|agy|bob|vibe|qodercli|kimi|trae|pi|iflow|generic
# Leave empty to update all existing agent files

set -e

# Enable strict error handling
set -u
set -o pipefail

# Note: Full update-agent-context.sh is 837 lines.
# For the plugin, this is a reference copy that works with project's .specify/ directory.
# See the source file at: /sessions/jolly-magical-ride/mnt/my_zodiac_ai/.specify/scripts/bash/update-agent-context.sh
echo "Update agent context script - reference implementation"
echo "This script updates AI agent context files with feature information"
echo "See bundled documentation for full details"