<!-- codex-review-kiss-yagni:start -->
## Code Review Rules

- Prioritize concrete, reachable regressions in current functional flows and security trust boundaries. Do not report hypothetical future requirements.
- Apply KISS and YAGNI: do not request abstractions, generalized compatibility, configurability, or defensive branches without a current caller, accepted input, existing data, explicit contract, observed incident, or exposed trust boundary.
- Report P1 only for a blocking issue with severe impact and demonstrated reachability or exploitability. Prefer a few well-evidenced findings over an open-ended architecture audit.
<!-- codex-review-kiss-yagni:end -->
