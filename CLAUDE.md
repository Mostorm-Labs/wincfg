# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Project: Windows Config Automation Tool
Windows configuration setup scripts for updates, power management, password management, and other system configuration tasks. Hosted under the Mostorm-Labs GitHub organization.

## Goal
Implement a Windows configuration script similar to Zoom Rooms setup.

## Features
- Disable screen lock
- Disable sleep
- Disable Windows Update
- Disable Cortana
- Set high performance power plan
- Disable notifications
- Install background service

## Tech Stack
- PowerShell (primary)
- C++ (optional service)
- Windows Registry API

## Coding Rules
- Prefer idempotent scripts
- All changes must be reversible
- Log every operation
- Support dry-run mode

## Output Format
- Scripts in /scripts
- Service in /service
- Docs in /docs

## Repository State

This repository is in early stages — no scripts have been implemented yet. As scripts are added, update this file with relevant run/test instructions.