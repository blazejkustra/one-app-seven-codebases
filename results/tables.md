| | React Native (Expo) | Swift (SwiftUI) | Flutter | Compose Multiplatform | Angular Native | Lynx |
|---|---|---|---|---|---|---|
| Agent minutes, v1 (first build) | 13.7 | 15.0 | 21.1 | 34.4 | 16.7 | 32.7 |
| Agent minutes, 5 iterations | 12.6 | 15.2 | 18.2 | 33.5 | 20.5 | 14.0 |
| **Agent minutes, total** | **26.2** | **30.2** | **39.3** | **67.9** | **37.2** | **46.7** |
| Agent tool calls, total | 155 | 155 | 268 | 228 | 197 | 246 |
| Tokens processed, total (M, incl. cached context) | 25.4 | 26.4 | 54.5 | 55.4 | 37.7 | 50.5 |
| Fresh input tokens (k, non-cached) | 311 | 333 | 421 | 448 | 390 | 711 |
| Output tokens (k, estimated) | 31 | 38 | 45 | 48 | 36 | 48 |
| Hidden QA checks passed (of 32) | 26 | 32 | 32 | 32 | 31 | 24 |
| → functional bugs after manual review | 0 | 0 | 0 | 0 | 0 | 0 |
| → accessibility defects (VoiceOver can't read / type) | 1 | 0 | 0 | 0 | 0 | 2 |
| Visual fidelity, layout SSIM vs spec (7 screens) | 0.940 | 0.861 | 0.984 | 0.998 | 0.916 | 0.931 |
| Visual fidelity, pixel SSIM vs spec | 0.924 | 0.888 | 0.971 | 0.989 | 0.913 | 0.920 |
| Cold start, median of 10 (ms) | 690 | 760 | 1032\* | 757 | 678 | 670 |
| Crashes in random taps | 0 in 15,000 | 0 in 15,000 | 0 in 15,000 | 0 in 15,000 | 0 in 15,000 | 0 in 15,000 |
| Random taps that left the app (share sheet etc.) | 1 | 2 | 10 | 3 | 3 | 2 |
| App size, device IPA zipped (MB) | 8.1 | 2.1 | 6.8 | 11.8 | 8.9 | 5.7 |
| App size, device .app unzipped (MB) | 28.3 | 7.3 | 16.6 | 39.1 | 30.2 | 19.4 |
| Hand-written source lines | 1586 | 1573 | 2066 | 1863 | 1817 | 2029 |

Per-iteration agent minutes (tool calls) · tokens processed (M) · source lines changed:

| Iteration | React Native (Expo) | Swift (SwiftUI) | Flutter | Compose Multiplatform | Angular Native | Lynx |
|---|---|---|---|---|---|---|
| v1 | 13.7 (59) · 6.5M · ±? | 15.0 (69) · 7.6M · ±? | 21.1 (143) · 19.1M · ±? | 34.4 (117) · 19.3M · ±? | 16.7 (84) · 10.8M · ±? | 32.7 (139) · 22.0M · ±? |
| v2-tags | 2.5 (17) · 2.8M · ±? | 3.9 (19) · 3.6M · ±? | 4.6 (29) · 6.6M · ±? | 6.9 (24) · 6.5M · ±? | 4.6 (22) · 4.8M · ±? | 2.9 (20) · 5.2M · ±? |
| v3-checklists | 2.4 (19) · 3.5M · ±? | 3.2 (17) · 3.4M · ±? | 4.2 (30) · 8.3M · ±? | 9.1 (29) · 8.8M · ±? | 4.4 (23) · 4.2M · ±? | 2.2 (18) · 4.7M · ±? |
| v4-delete-undo | 1.9 (17) · 3.1M · ±? | 2.8 (17) · 3.6M · ±? | 2.6 (17) · 4.9M · ±? | 5.6 (16) · 5.2M · ±? | 4.0 (22) · 5.4M · ±? | 2.4 (23) · 5.8M · ±? |
| v5-dark-mode | 4.8 (31) · 6.7M · ±? | 3.1 (20) · 4.9M · ±? | 4.3 (33) · 9.7M · ±? | 6.8 (28) · 9.9M · ±? | 4.5 (30) · 8.3M · ±? | 4.7 (33) · 8.9M · ±? |
| v6-share | 1.1 (12) · 2.8M · ±? | 2.1 (13) · 3.3M · ±? | 2.5 (16) · 5.8M · ±? | 5.1 (14) · 5.7M · ±? | 3.0 (16) · 4.3M · ±? | 1.9 (13) · 3.9M · ±? |
