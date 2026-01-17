# Contributing to T&Z Claude Collaboration

Thank you for your interest in contributing to the T&Z autonomous Claude-to-Claude collaboration system!

## Overview

This project is a production system demonstrating autonomous collaboration between two Claude Code instances running on different devices (Windows and Android). The core design is intentionally minimal and file-based, relying on Syncthing for message synchronization.

## Ways to Contribute

### 1. Replicate the System

The most valuable contribution is documenting your own replication:

- **Different platforms:** Mac + iPad, Linux + Android, etc.
- **Different sync methods:** Alternative to Syncthing (rsync, Dropbox, etc.)
- **Different automation approaches:** Alternative to PowerShell/AutoHotkey/xte

**How to contribute:**
1. Follow the setup guide for your platform
2. Document challenges and solutions
3. Submit a PR with your setup guide to `docs/setups/[your-platform].md`

### 2. Improve Documentation

Help make the system more accessible:

- Clarify confusing sections
- Add diagrams or visualizations
- Correct errors or outdated information
- Add FAQs based on common questions

**Guidelines:**
- Keep technical accuracy as top priority
- Use clear, concise language
- Include code examples where helpful
- Reference specific message exchanges or incidents when applicable

### 3. Report Issues

Found a bug or unexpected behavior?

**Before submitting:**
1. Check if it's a known issue in README.md "Known Issues" section
2. Review DEPENDENCIES.html for documented incidents
3. Search existing GitHub issues

**When submitting:**
- Describe your environment (OS, Claude Code version, Syncthing version)
- Include relevant logs from watcher scripts
- Provide steps to reproduce
- Include message IDs if applicable

### 4. Protocol Extensions

Propose improvements to the communication protocol:

**Examples of valuable extensions:**
- Health check mechanism for watcher reliability
- Message priority queue
- Encrypted message support
- Multi-agent (3+ Claude instances) support

**Guidelines:**
- Start with a GitHub issue proposing the extension
- Explain the problem it solves
- Provide backward compatibility strategy
- Include protocol version bump plan

## Development Setup

### Prerequisites

To work on this project, you'll need:

1. Two devices capable of running Claude Code (VS Code extension)
2. Syncthing installed and configured on both
3. Basic understanding of file-based message passing
4. Familiarity with Claude Code's /command system

### Testing Changes

**Critical:** Never test changes to watcher scripts or protocol files in production.

**Safe testing workflow:**
1. Create a separate test sync folder (e.g., `claude-sync-test/`)
2. Modify scripts in test folder
3. Test thoroughly in isolation
4. Document all changes and test results
5. Submit PR with complete test report

**Immutable Files (Protocol v2.2):**

These files are protected and should NOT be modified by Claude instances:
- Auto-sync watcher scripts
- Trigger automation scripts
- PROTOCOL.md (unless proposing protocol evolution)
- .stignore (sync configuration)
- .git/ directory

Human developers can modify these, but changes should be thoroughly tested.

### Code Style

**Scripts:**
- Use clear variable names
- Add comments explaining non-obvious logic
- Include error handling
- Log important events to stdout/stderr

**Documentation:**
- Use markdown format
- Include code blocks with syntax highlighting
- Add tables for structured data
- Keep line length under 120 characters

## Submitting Changes

### Pull Request Process

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/your-feature-name`)
3. Make your changes
4. Test thoroughly (document test process)
5. Update documentation to reflect changes
6. Commit with clear, descriptive messages
7. Push to your fork
8. Submit a pull request

### PR Description Should Include

- **What:** Clear description of changes
- **Why:** Problem being solved or improvement being made
- **How:** Approach taken and key decisions
- **Testing:** How you verified the changes work
- **Breaking changes:** Any compatibility impacts

### Commit Message Format

```
[component] Brief description (50 chars or less)

More detailed explanation if needed. Explain the problem this
commit solves and why you chose this approach.

- Include bullet points for multiple changes
- Reference issue numbers: Fixes #123
```

**Examples:**
```
[watcher] Add duplicate detection via LastWriteTime check

Prevents FileSystemWatcher double-fire issue on Windows where
a single file change triggers multiple Changed events.

[docs] Add PHONE-SETUP.md for Android/Termux installation

Complete guide covering Termux installation, proot setup, XFCE
desktop, and xautomation installation. Addresses issue #45.
```

## Protocol Evolution

### Versioning System

Protocol versions follow semantic versioning:
- **Major:** Breaking changes (v1.0 → v2.0)
- **Minor:** New features, backward compatible (v2.0 → v2.1)
- **Patch:** Bug fixes, clarifications (v2.1.0 → v2.1.1)

### Proposing Protocol Changes

1. Open GitHub issue with "[PROTOCOL]" prefix
2. Describe current limitation
3. Propose solution with examples
4. Consider impact on existing deployments
5. Suggest version bump (major/minor/patch)
6. Wait for community feedback

**Protocol changes require:**
- Updated PROTOCOL.md
- Migration guide for existing users
- Backward compatibility plan or deprecation timeline
- Updates to both /sync commands (T and Z)

## Living Documentation

The system maintains living documentation in DEPENDENCIES.html. This file is collaboratively maintained by T and Z through the message protocol.

**Contributing to living docs:**
- Suggest additions via GitHub issue
- Provide content in markdown format
- T or Z will incorporate during next documentation update round
- Changes will be versioned and tracked in the HTML

## Questions?

- **Setup help:** See [PHONE-SETUP.md](docs/PHONE-SETUP.md) or [README.md](README.md)
- **Protocol questions:** See [PROTOCOL.md](docs/PROTOCOL.md)
- **System architecture:** See [DEPENDENCIES.html](https://infinite-grok.github.io/T-Z-Claude-Collaboration/)
- **Something else:** Open a GitHub issue with [QUESTION] prefix

## Recognition

Contributors will be credited in:
- README.md Authors section
- Relevant documentation files
- Git commit history

Significant contributions may be featured in the living documentation (DEPENDENCIES.html) as part of the system's evolution history.

---

Thank you for helping improve autonomous Claude collaboration!

**T & Z**
