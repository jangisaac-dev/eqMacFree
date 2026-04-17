# eqMacFree Baseline Feature Checklist

**Date:** 2026-04-17  
**Source of truth:** `/Volumes/ssd/opencode_workspace/eqMac/README.md`

## Status legend

- `Pass`
- `Partial`
- `Fail`
- `Not Run`

## Features

| Feature | Status | Repro Steps | Evidence | Notes |
| --- | --- | --- | --- | --- |
| System audio processing | Not Run | Open app, enable eqMacFree pipeline, play system audio, confirm audible routed output | `./script/build_and_run.sh --verify` currently stops before app launch | Blocked until HAL driver install succeeds |
| Volume booster | Not Run | Move booster control, confirm louder output without control desync | `./script/build_and_run.sh --verify` currently stops before app launch | Blocked until HAL driver install succeeds |
| HDMI volume support | Not Run | Select HDMI-capable output, confirm output appears and responds | `./script/build_and_run.sh --verify` currently stops before app launch | Blocked until HAL driver install succeeds |
| Volume balance control | Not Run | Move balance left/right and confirm channel shift | `./script/build_and_run.sh --verify` currently stops before app launch | Blocked until HAL driver install succeeds |
| Basic EQ | Not Run | Switch to Basic EQ, apply preset, confirm audio change | `./script/build_and_run.sh --verify` currently stops before app launch | Blocked until HAL driver install succeeds |
| Advanced EQ | Not Run | Switch to Advanced EQ, adjust bands/preset, confirm audio change | `./script/build_and_run.sh --verify` currently stops before app launch | Blocked until HAL driver install succeeds |
