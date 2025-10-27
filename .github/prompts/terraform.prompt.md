---
mode: agent
---
## Terraform Module development best practices

- Purpose
    - Each Terraform module should be small, focused, and reusable. One module = one responsibility.

- Repository layout (per-module)
    - A module directory must contain:
        - README.md (purpose, inputs, outputs, examples, compatibility)
        - main.tf, variables.tf, outputs.tf (keep files focused)
        - versions.tf (required_version, provider constraints)
        - examples/ (required — see "Examples" below)
        - Optional: tests/ (unit/integration), docs/

- Versioning and compatibility
    - Use semantic versioning for published modules.
    - Pin provider versions in versions.tf and document compatibility in README.
    - Avoid breaking changes in patch/minor versions. Provide upgrade notes.

- Input variables
    - Give every variable a clear description and sensible default where appropriate.
    - Validate inputs with validation blocks where possible.
    - Don't accept secrets via plain variables — document secret handling (use external secret manager or TF Cloud variable sets).

- Outputs
    - Only expose values consumers need.
    - Document output units/types and example usage.
    - Avoid returning large complex objects unless necessary.

- Idempotency and lifecycle
    - Ensure create/update/destroy produce consistent results.
    - Avoid implicit random or timestamped names unless user can override with input.

- Naming and tags
    - Make resource names configurable via a single naming pattern (prefix/name/suffix).
    - Provide `tags` or `labels` input and merge with module-internal tags without overwriting user-provided values.

- Sensitive data
    - Mark outputs and variables as sensitive where appropriate.
    - Do not log secrets or write them to files.

- Security and least privilege
    - Create IAM roles/policies with least privilege.
    - Allow consumers to pass in IAM role ARNs when they own policies.

- Testing
    - Provide example usage in examples/ and, when possible, include automated tests (terratest, kitchen-terraform, or tflint/terraform validate).
    - Run `terraform validate`, `tflint`, and `terraform fmt` in CI.

- Documentation
    - README should include:
        - Short description
        - Requirements (Terraform, providers)
        - Inputs table
        - Outputs table
        - Examples with commands to run
        - Upgrade notes

- CI/CD
    - Enforce formatting (`terraform fmt`), validation (`terraform validate`), linting, and unit/integration tests.
    - Run plan-only checks for PRs to detect unexpected changes.

- Reusability and composition
    - Keep modules composable — accept ARNs, IDs, and configuration blocks rather than creating everything unconditionally.
    - Document assumptions and default behaviors.

- Backwards compatibility policy
    - Document how long older versions are supported and the migration path for breaking changes.

Examples (required)
- Each module MUST include an examples/ directory at the module root. The examples directory should contain at least:
    - simple/ — minimal example showing required inputs
    - complete/ — a fuller example demonstrating common optional settings
    - README.md inside examples/ explaining how to run the examples

Example module call (to place in examples/<example>/main.tf):