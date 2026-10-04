#!/usr/bin/env bash
# log-iteration.sh <framework-dir> <iteration> — commits the snapshot after an agent finishes an iteration
# (timings come from the agent transcripts, see agent_stats.py)
cd "$(dirname "$0")/.."
git add "$1" && git commit -qm "$1: $2" && git log --oneline -1
git diff --shortstat HEAD~1 HEAD -- "$1"
