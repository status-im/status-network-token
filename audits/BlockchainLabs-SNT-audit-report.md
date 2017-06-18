# Status Network Token Audit

## Preamble
This audit report was undertaken by BlockchainLabs.nz for the  purpose of providing feedback to Status Research & Development Gmbh. It has subsequently been shared publicly without any express or implied warranty.

Solidity contracts were sourced from the public Github repo [status-im/status-network-token](https://github.com/status-im/status-network-token) as at commit [a1aa79b34c9e99a81a59b3cd8103c4f2a41cfc3b](https://github.com/status-im/status-network-token/tree/a1aa79b34c9e99a81a59b3cd8103c4f2a41cfc3b) - we would encourage all community members and token holders to make their own assessment of the contracts.

## Scope
All Solidity code contained in [/contracts](https://github.com/status-im/status-network-token/tree/master/contracts) was considered in scope along with the tests contained in [/test](https://github.com/status-im/status-network-token/tree/master/test) as a basis for static and dynamic analysis.

## Focus Areas
The audit report is focused on the following key areas - though this is *not an exhaustive list*.

#### Correctness
* No correctness defects uncovered during static analysis?
* No implemented contract violations uncovered during execution?
* No other generic incorrect behavior detected during execution?
* Adherence to adopted standards such as ERC20?

#### Testability
* Test coverage across all functions and events?
* Test cases for both expected behaviour and failure modes?
* Settings for easy testing of a range of parameters?
* No reliance on nested callback functions or console logs?
* Avoidance of test scenarios calling other test scenarios?

#### Security
* No presence of known security weaknesses?
* No funds at risk of malicious attempts to withdraw/transfer?
* No funds at risk of control fraud?
* Prevention of Integer Overflow or Underflow?

#### Best Practice
* Explicit labeling for the visibility of functions and state variables?
* Proper management of gas limits and nested execution?
* Latest version of the Solidity compiler?

## Classification

#### Defect Severity
* **Minor** - A defect that does not have a material impact on the contract execution and is likely to be subjective.
* **Moderate** - A defect that could impact the desired outcome of the contract execution in a specific scenario.
* **Major** - A defect that impacts the desired outcome of the contract execution or introduces a weakness that may be exploited.
* **Critical** - A defect that presents a significant security vulnerability or failure of the contract across a range of scenarios.

## Findings
#### Minor

#### Moderate

#### Major

#### Critical


## Conclusion
_Conclusions will be drafted upon completion of the audit & testing required for this report_
