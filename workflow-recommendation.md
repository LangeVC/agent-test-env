# Workflow Recommendation — agent-test-env Gap Closure

**Date:** 2026-05-09
**Complexity Score:** 55/100
**Recommended Mode:** ralph-loop-attended (standard)

## Decision Rationale

### Why ralph_attended (not rex)

- **19 tasks** exceeds the 1-3 task threshold for REX mode
- **5 dependency phases** with a depth of 5 — too deep for simple Plan→Implement→Review
- Each phase produces a checkpoint-worthy milestone (containers buildable → fixtures complete → test infra → CI validation)
- Human should verify Dockerfile builds succeed before committing the full set

### Why ralph_attended (not ralph_overnight)

- **Single agent** handles all work — no multi-agent coordination overhead
- **180 minutes** fits within attended session (<4 hours)
- **42% independent tasks** — Phase 1 alone runs 8 tasks in parallel, making attended execution fast
- No production deployment gates needed — this is infrastructure improvement, not customer-facing code
- Overnight is overkill for file manipulation in one repo

### Phase Checkpoints

| Phase Gate | What to Verify | Human Checkpoint |
|------------|---------------|-----------------|
| After Phase 1 | 8 parallel tasks complete, Docker builds pass | Yes — verify `docker compose build` |
| After Phase 2 | HEALTHCHECK works, fixtures.json valid | Yes — verify `docker compose up -d && docker compose wait` |
| After Phase 3 | Scripts available, docker compose improved | Light — verify `docker compose config` |
| After Phase 4 | CI entrypoint + smoke tests | Light — verify `bats tests/smoke/` |
| After Phase 5 | Full test suite passes | Yes — verify `bash tests/run_tests.sh all` |

## Execution Strategy

1. **Phase 1**: Launch 8 parallel subagents for independent foundation work
2. **Phase 2**: Launch 2 parallel subagents for Docker healthcheck + fixture registry
3. **Phase 3**: Launch 5 parallel subagents for scripts, helpers, docs, compose
4. **Phase 4**: Launch 3 parallel subagents for CI + tests
5. **Phase 5**: Single agent runs final integration validation

**Parallel target:** Use Task tool with subagent_type="general" for each task in each phase, launching all simultaneously.
