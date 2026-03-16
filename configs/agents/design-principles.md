# Design Principles

These are the principles I care most about when building software. They're not rules — they're a lens. There are always tradeoffs, and the right move isn't always the principled one. But when I deviate, I want to do it consciously and mark it down.

---

## The Core Principle: Mechanism, Not Policy

Inspired by the Linux kernel philosophy. The kernel provides capabilities; it doesn't decide behavior. The center stays still so the edges can move fast.

**Litmus test:** "Could two teams reasonably want different behavior here?"
- If yes → it's policy → push it to the edge
- If no → it's mechanism → it belongs in the core

A stable core means the things built on top of it can be replaced, extended, or discarded without touching anything underneath. That's what makes a system composable.

**Example:** The Linux VFS (Virtual File System) layer provides `open`, `read`, `write`, `close` — the stable mechanism. Whether the underlying storage is ext4, btrfs, NFS, or a RAM disk is policy that lives in filesystem modules. The system call interface has been stable for decades while dozens of filesystems have come and gone underneath it. The kernel doesn't know or care which filesystem you choose; it just provides the mechanism for the policy to attach to.

---

## Stable Elements and Fast Elements

Not all parts of a system change at the same rate. Good architecture aligns boundaries with change rates.

- **Stable elements** — defined by external contracts (file formats, protocols, OS interfaces) or by fundamental facts (a process is either alive or dead). These change slowly and reluctantly. Design them to be small, correct, and boring.
- **Fast elements** — interpretations, labels, UI concerns, business logic, pricing models, heuristics. These change often and should be cheap to replace.

When a fast element gets embedded in a stable one, you pay for it every time the fast element changes. The goal is to keep them cleanly separated.

---

## Simple, Composable, Extendable

In that order.

Start with the minimum that is correct. Add composability so pieces can be combined. Make it extendable so new capabilities attach at the edges without touching the core.

Don't build for hypothetical futures. An abstraction that exists for one use case is a liability. When a second use case arrives, the right shape usually becomes obvious — that's when to abstract.

**"As simple as possible, but no simpler."** Every abstraction must justify its existence. If you can't state clearly what a module is responsible for, it's doing too much.

---

## Interfaces Are the Contract

Each module is self-contained. You should be able to rewrite any module from scratch without touching the others, as long as the interface stays the same. Think of it like plumbing: a pipe segment can be replaced with a better one as long as the fittings at both ends are compatible. Nobody cares what material the pipe is made of — only that it fits.

This means:
- Interfaces are the most important design decision, more important than the implementation
- A module's internal structure is private; only its interface is a promise
- Stable interfaces enable composition; unstable interfaces create coupling

---

## Make the System Transparent

A system you can't inspect is a system you can't trust. Important state changes should be visible, not buried inside function calls. If something happened that a future reader would care about, it should leave a trace.

This is broader than logging. It means: prefer designs where the system's behavior is observable from the outside without needing to know its internals. An append-only record of what happened is often more valuable than a current-state snapshot, because it's replayable and auditable.

Opacity is usually a symptom of the wrong boundary — state that should be external got trapped inside a module.

---

## Conscious Tradeoffs

These principles sometimes conflict. Ruthless simplicity can mean skipping composability for a one-off. Time pressure can mean embedding policy in the kernel temporarily. A standard that changes often might not be stable enough to treat as a fixed contract.

That's fine. The principle isn't to be pure — it's to be deliberate.

**When deviating, mark it down:** a comment, a commit message, a note in the architecture doc. "We embedded this policy here because X — revisit when Y." Future you will thank present you.

---

## What This Is Not

This is not a rulebook. It's a default posture — the way I want to think about problems before I've thought about them specifically. When a specific problem has different constraints, those constraints win. The principles are inputs to the decision, not overrides of it.
