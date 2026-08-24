# GRPO Smoke Run Results — pod3 (RTX 2000 Ada 16GB), 2026-08-24

First completed GRPO training run on native-verify-seq.

## Run facts

- Trainer: prime-rl (harnesses branch) + three local patches
  (single-GPU colocate, optional ring_flash_attn imports)
- Model: Qwen/Qwen2.5-1.5B-Instruct, LoRA
- Algorithm: GRPO, batch_size=16 tasks x group_size=8 = 128 rollouts/step
- Steps: 24 (~24 minutes wall clock, ~3072 episodes total)
- Verification: every episode scored by native_decide against env-held
  train + holdout cases; binary lean_pass reward
- Final checkpoint: step_24 (FSDP sharded, 6.9GB)

## Reward per trainer step (train/agg/all/agent/reward/mean)

```
1: 0.94   2: 0.62   3: 0.62   4: 0.75   5: 0.69   6: 0.69
7: 0.69   8: 0.31   9: 0.38  10: 0.10  11: 0.06  12: 0.94
13: 0.25  14: 0.13  15: 0.16  16: 0.50  17: 0.59  18: 0.80
19: 0.13  20: 0.13  21: 0.44  22: 0.13  23: 0.25  24: 0.03
```

## Honest interpretation

1. **The pipeline works end-to-end.** Rollouts -> Lean execution ->
   binary verified rewards -> GRPO updates -> policy version publishing ->
   weight sync back to vLLM -> checkpointing. Zero infrastructure errors
   during the entire 24-minute run.
2. **No learning claim is possible from 24 steps.** Per-step reward variance
   is dominated by task-family mix per batch (linear ~90% base rate vs
   digit_sum near zero; dataset ordered linear-first explains the high early
   steps). Meaningful signal requires hundreds of steps plus family-balanced
   sampling or difficulty filtering.
3. **Trainable fraction was 100% on every step** — every batch contained a
   reward mix that produced usable advantages. No degenerate groups.
4. Error rate 0.0%, truncation ~0-6%, sanitizer rejections visible in early
   batches then absent from summaries (to be quantified from traces).

## Next-run checklist

- Family-balanced sampling or curriculum so per-batch mix is constant
- Longer run (300+ steps) before reading trend
- Log nv_stage_rank distribution from traces to quantify where failures
  concentrate (sanitize vs compile vs holdout)
- Export HF weights from checkpoint (`--ckpt.weights-only` resume path)
