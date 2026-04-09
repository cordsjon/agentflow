# /pipeline — RETIRED (2026-04-09)

> **Superseded by Idea Forge** — `http://localhost:9104/ideas`
>
> The old pipeline runner (`pipeline_runner.py`) and Decision Panel never migrated from Windows.
> All functionality absorbed into Consigliere Idea Forge:
>
> | Old Pipeline | Idea Forge Equivalent |
> |---|---|
> | `/pipeline start` | `consigliere idea add` or POST `/api/ideas/inbox` |
> | `/pipeline scan` (INBOX scan) | URL resolver auto-detects YT/GitHub at intake |
> | `/pipeline process` (panel chain) | `consigliere idea enrich` (Ollama gemma4) |
> | `/pipeline status` | `consigliere idea status` or `/ideas` web UI |
> | `/pipeline decisions` | Inbox triage in web UI (Accept/Trash/View) |
> | `/pipeline resolve` (score 1-5) | Staleness check + relevance assessment in detail panel |
> | `/pipeline graduate` | `consigliere idea graduate --to <project>` |
> | Decision Panel (:8500) | `/ideas` web UI with inline actions |
> | 5-min polling DAG | ideas-nightly (2am), ideas-clustering (2:30am) |
>
> **6 valuable ideas migrated** from old pipeline to Idea Forge on 2026-04-09.
> **4 ideas archived** (stale or obsolete).

Use `consigliere idea` CLI or visit `http://localhost:9104/ideas` instead.
