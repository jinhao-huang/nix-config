---
name: grilling
description: Grill the user relentlessly about a plan, decision, or idea. Use when the user wants to stress-test their thinking, or uses any 'grill' trigger phrases.
---

Interview the user relentlessly until you reach a shared understanding. Map this as a **design tree**: every decision branches into the decisions that hang off it.

Treat decisions and authorization already established in the conversation as settled prerequisites. Ask about unresolved choices that materially affect the outcome; investigate discoverable facts yourself.

Work the tree in **rounds**. The **frontier** is every decision whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you haven't heard yet. Ask the whole frontier in one round: number each question and give your recommended answer. Then wait for the user's answers before the next round.

Use the client's question interface when available, respecting its question limits. Otherwise, format a round like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>

---

❓ **Q2** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

Each round the user answers reshapes the tree: settled decisions push the frontier outward and unblock questions that depended on them. Recompute the frontier and ask the next round. A question whose answer depends on another question still open in this round belongs to a _later_ round, not this one.

Finding _facts_ is your job, never the user's. When a frontier question needs a fact from the environment (filesystem, tools, etc.), dispatch a sub-agent when available, or inspect it directly. A running exploration is an unsettled prerequisite, so only the questions downstream of it wait; ask the rest of the frontier now. Put unresolved material _decisions_ to the user and wait for their answers.

The session is done when the frontier is empty: every material branch of the design tree settled, with assumptions made explicit. Summarize the agreed direction. Continue implementation when the user has already authorized it; otherwise finish with the decision or plan they requested.
