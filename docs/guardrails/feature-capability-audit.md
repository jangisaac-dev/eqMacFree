# eqMacFree Feature Capability Audit

Run `yarn audit:boundary` whenever a change touches launch-critical docs, UI copy, native launch identity, or public support/update routing.

## Human checklist

- Did this change reintroduce a legacy eqMac URL or old GitHub repo reference?
- Does `Lock` still mean planned or unavailable, not purchasable or secretly unlockable?
- Do README and roadmap files still use the same feature buckets?
- Do support and update links still point to public GitHub surfaces or intentionally neutralized endpoints?

## Result types

- Hard fail: fix before merging
- Warning: review wording drift and either fix it or document why it is intentional
- Allowed exception: historical context in approved files such as README or design docs
