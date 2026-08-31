---
name: feedback_script_path
description: Correct path for the gather_prior_level_words.py script
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ce81b07b-405c-438c-b21b-56841866eb74
---

Script is at the project root, not under `app/`:

```
tools/gather_prior_level_words.py
```

Run from project root:
```bash
python3 tools/gather_prior_level_words.py {level-id} --format json
```

**Why:** It was mistakenly called as `app/tools/...` which fails.
**How to apply:** Always use `tools/gather_prior_level_words.py` (no `app/` prefix) when running from the project root.
