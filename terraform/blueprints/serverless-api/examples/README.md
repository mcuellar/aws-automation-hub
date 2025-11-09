# Examples

This directory contains runnable examples that demonstrate how to consume the serverless API blueprint module.

1. `simple/` – minimal configuration providing only required inputs.
2. `complete/` – fully configured example showcasing optional settings such as Secrets Manager access and AWS WAF.

To execute an example:

```bash
cd examples/<example>
terraform init
terraform apply
```

Destroy resources when finished:

```bash
terraform destroy
```
