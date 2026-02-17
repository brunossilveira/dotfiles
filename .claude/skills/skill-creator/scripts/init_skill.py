#!/usr/bin/env python3
"""
Skill Initializer - Creates a new skill from template

Usage:
    init_skill.py <skill-name> --path <path>

Examples:
    init_skill.py my-new-skill --path ~/.claude/skills
    init_skill.py my-api-helper --path .claude/skills
"""

import sys
import re
from pathlib import Path


SKILL_TEMPLATE = """---
name: {skill_name}
description: [TODO: Complete and informative explanation of what the skill does and when to use it.]
---

# {skill_title}

## Overview

[TODO: 1-2 sentences explaining what this skill enables]

## When to Use

[TODO: Specific scenarios, file types, or tasks that trigger this skill]

## Process

[TODO: Step-by-step instructions for how to use this skill]

## Resources

[TODO: Reference any bundled scripts/, references/, or assets/ files. Delete unused directories.]
"""


def title_case_skill_name(skill_name):
    return ' '.join(word.capitalize() for word in skill_name.split('-'))


def init_skill(skill_name, path):
    skill_dir = Path(path).resolve() / skill_name

    if skill_dir.exists():
        print(f"Error: Skill directory already exists: {skill_dir}")
        return None

    # Validate name
    if not re.match(r'^[a-z0-9-]+$', skill_name):
        print(f"Error: Name '{skill_name}' should be hyphen-case (lowercase letters, digits, and hyphens only)")
        return None

    try:
        skill_dir.mkdir(parents=True, exist_ok=False)
    except Exception as e:
        print(f"Error creating directory: {e}")
        return None

    skill_title = title_case_skill_name(skill_name)
    skill_content = SKILL_TEMPLATE.format(skill_name=skill_name, skill_title=skill_title)

    (skill_dir / 'SKILL.md').write_text(skill_content)

    for subdir in ['scripts', 'references', 'assets']:
        (skill_dir / subdir).mkdir(exist_ok=True)

    print(f"Skill '{skill_name}' initialized at {skill_dir}")
    print("\nNext steps:")
    print("1. Edit SKILL.md to complete the TODO items")
    print("2. Add scripts, references, or assets as needed")
    print("3. Delete unused resource directories")

    return skill_dir


def main():
    if len(sys.argv) < 4 or sys.argv[2] != '--path':
        print("Usage: init_skill.py <skill-name> --path <path>")
        print("\nExamples:")
        print("  init_skill.py my-new-skill --path ~/.claude/skills")
        print("  init_skill.py my-api-helper --path .claude/skills")
        sys.exit(1)

    skill_name = sys.argv[1]
    path = sys.argv[3]

    result = init_skill(skill_name, path)
    sys.exit(0 if result else 1)


if __name__ == "__main__":
    main()
