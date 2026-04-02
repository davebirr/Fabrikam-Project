---
name: workflow-fixer
description: >
  Fix Azure-generated GitHub Actions workflow files for the Fabrikam monorepo.
  Azure Portal's Deployment Center creates workflow YAML files that assume a single-project repo —
  they build the entire solution instead of the specific project, use generic names, and lack path filters.
  This skill applies the monorepo-specific corrections: friendly workflow names with emoji prefixes,
  path-scoped triggers so only relevant changes trigger deploys, and explicit .csproj paths in
  dotnet build/publish commands.
  Use this skill whenever the user mentions fixing workflows, updating deployment workflows,
  Azure-generated workflow files, monorepo CI/CD, or when new workflow files appear in .github/workflows/
  that have the generic "Build and deploy ASP.Net Core app" naming pattern.
  Also trigger when the user says things like "Azure created new workflows" or "fix the CI/CD files"
  or "update the deploy workflows for the new instance."
---

# Workflow Fixer

Fix Azure Portal-generated GitHub Actions workflow files for the Fabrikam monorepo structure.

## Why this skill exists

When you set up CI/CD via Azure Portal > App Service > Deployment Center, Azure generates a GitHub Actions
workflow file per App Service. These files assume a flat single-project repo:

- Generic name: `Build and deploy ASP.Net Core app to Azure Web App - fabrikam-api-dev-xyzabc`
- No path filters: every push to the branch triggers ALL workflows, even if only one project changed
- Generic build: `dotnet build --configuration Release` builds the entire solution
- Generic publish: `dotnet publish -c Release` publishes whatever it finds

In a monorepo with 4+ projects sharing a branch, this causes redundant builds, deployment races, and failures.

## Service mapping

This is the canonical mapping for the Fabrikam monorepo. Each Azure App Service maps to exactly one project:

| Service slug | Emoji | Friendly name | .csproj path | Path triggers |
|---|---|---|---|---|
| `api` | 🚀 | API | `FabrikamApi/src/FabrikamApi.csproj` | `FabrikamApi/**`, `FabrikamContracts/**` |
| `mcp` | 🤖 | MCP | `FabrikamMcp/src/FabrikamMcp.csproj` | `FabrikamMcp/**`, `FabrikamContracts/**` |
| `dash` | 📊 | Dashboard | `FabrikamDashboard/FabrikamDashboard.csproj` | `FabrikamDashboard/**` |
| `sim` | 🎲 | Simulator | `FabrikamSimulator/src/FabrikamSimulator.csproj` | `FabrikamSimulator/**` |

**FabrikamContracts** is a shared library containing DTOs and enums. API and MCP depend on it,
so changes to FabrikamContracts must trigger rebuilds of both. Dashboard and Simulator do not depend on it.

## How to identify files that need fixing

Azure-generated workflow filenames follow this pattern:
```
{branch}_{app-name}.yml
```

Where `{branch}` has `/` replaced with `-`. Examples:
- `main_fabrikam-api-dev-efhbcl.yml`
- `feature-a365-integration_fabrikam-api-dev-mxawus.yml`

**Detection signals** — a file needs fixing if ANY of these are true:
1. The `name:` field starts with `Build and deploy ASP.Net Core app`
2. The `on.push` block has no `paths:` key
3. The `dotnet build` step uses bare `dotnet build --configuration Release` without a .csproj path

## Extracting metadata from the filename

Parse the filename to extract:
- **Branch**: everything before the first `_`, with `-` converted back to `/` for non-`main` branches
  - `main_fabrikam-api-dev-efhbcl.yml` → branch: `main`
  - `feature-a365-integration_fabrikam-mcp-dev-mxawus.yml` → branch: `feature/a365-integration`
- **App name**: everything after the first `_`, minus `.yml`
  - `fabrikam-api-dev-mxawus`
- **Service slug**: extract from app name — the segment after `fabrikam-` and before the next `-`
  - `fabrikam-api-dev-mxawus` → `api`
  - `fabrikam-dash-dev-mxawus` → `dash`
- **Suffix**: the last segment of the app name (the deployment instance identifier)
  - `fabrikam-api-dev-mxawus` → `mxawus`

## Transformation steps

Apply these four changes to each file. The deploy job (secrets, app-name, slot) stays untouched.

### 1. Replace the workflow name

```yaml
# BEFORE (Azure-generated):
name: Build and deploy ASP.Net Core app to Azure Web App - fabrikam-api-dev-mxawus

# AFTER:
name: 🚀 Deploy API (mxawus)
```

Format: `{emoji} Deploy {friendly_name} ({suffix})`

### 2. Add path filters to the push trigger

```yaml
# BEFORE (Azure-generated):
on:
  push:
    branches:
      - feature/a365-integration
  workflow_dispatch:

# AFTER (example for API):
on:
  push:
    branches:
      - feature/a365-integration
    paths:
      - 'FabrikamApi/**'
      - 'FabrikamContracts/**'
  workflow_dispatch:
```

Insert the `paths:` block immediately after the `branches:` list, before `workflow_dispatch:`.
Use the path triggers from the service mapping table above.

### 3. Fix dotnet build command

```yaml
# BEFORE (Azure-generated):
      - name: Build with dotnet
        run: dotnet build --configuration Release

# AFTER (example for API):
      - name: Build with dotnet
        run: dotnet build FabrikamApi/src/FabrikamApi.csproj --configuration Release
```

Insert the .csproj path between `dotnet build` and `--configuration Release`.
If the step has a `working-directory:` key, remove it and use the full project path instead.

### 4. Fix dotnet publish command

```yaml
# BEFORE (Azure-generated):
      - name: dotnet publish
        run: dotnet publish -c Release -o ${{env.DOTNET_ROOT}}/myapp

# AFTER (example for API):
      - name: dotnet publish
        run: dotnet publish FabrikamApi/src/FabrikamApi.csproj -c Release -o ${{env.DOTNET_ROOT}}/myapp
```

Insert the .csproj path between `dotnet publish` and `-c Release`.
If the step has a `working-directory:` key, remove it and use the full project path instead.

## Workflow

1. List `.github/workflows/` to find candidate files
2. For each file matching the Azure naming pattern, read it and check the detection signals
3. Parse the filename to extract branch, service slug, and suffix
4. Look up the service in the mapping table — if the slug isn't recognized, ask the user
5. Apply all four transformations using file editing tools
6. Report what was changed: filename, old name → new name, paths added, project path set

## Edge cases

- **Unknown service slug**: If the app name contains a service slug not in the mapping table
  (e.g., a new project was added), ask the user for the .csproj path and path triggers.
  Don't guess.
- **Already fixed**: If a file already has path filters and project-specific build commands, skip it.
  Report it as "already correct."
- **Multiple branches**: The same deployment instance might have workflows for different branches.
  Each gets its own file. Fix them all — the only difference is the branch name in `on.push.branches`.
- **Branch name reconstruction**: For `main`, the branch is just `main`. For feature branches,
  Azure replaces `/` with `-` in the filename. The branch in the YAML `on.push.branches` is
  already correct (Azure writes the real branch name there), so use that value rather than
  reconstructing from the filename.

## After fixing workflows — triggering deployment

Fixing the workflow YAML alone does NOT deploy the code. The Azure App Services are non-functional
until code is actually deployed through the workflow. To trigger deployment:

1. Commit the fixed workflow files
2. Also make a trivial change to source code in each project that needs deploying —
   for example, add a blank line or update a comment in `Program.cs`. The path filters
   you just added mean only changes in the matching project folder will trigger that workflow.
3. Push the commit. Each workflow will trigger based on its path filters.

If you only commit the workflow files without touching source code, the path filters won't match
any project folders and no deployment will run.

## Deployment order on small App Service Plans

On F1/B1 plans with limited CPU, deploying all four services simultaneously can cause resource
thrashing. If the user reports issues (deployments timing out, apps crashing on startup), suggest
deploying in this order:

**API → MCP → Simulator → Dashboard**

API first because MCP and Simulator depend on it. Recommend the user temporarily disable the
MCP, Simulator, and Dashboard workflows (or stop those App Services in the Azure Portal) to
free up CPU for the API to compile and start. Once API is healthy, enable the others one at a time.
