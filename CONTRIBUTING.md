# Contributing

## Running CI Checks Locally

All checks below run in CI on every push and pull request to `main`. Run them locally before pushing.

### ShellCheck (Shell Script Linting)

```bash
shellcheck -S warning setup.sh local-setup.sh vps-setup.sh update-skill.sh
```

Install: `apt install shellcheck` or `brew install shellcheck`

### Hadolint (Dockerfile Linting)

```bash
hadolint Dockerfile
```

Install: `brew install hadolint` or download from [github.com/hadolint/hadolint](https://github.com/hadolint/hadolint)

### Docker Compose Validation

```bash
docker compose config --quiet
```

Requires a `.env` file (copy from `.env.example` if needed).

### JSON Template Validation

```bash
for f in templates/memory/*.json; do
  python3 -c "import json, sys; json.load(open(sys.argv[1]))" "$f" && echo "OK: $f" || echo "FAIL: $f"
done
```

### Env Var Coverage

Checks that every `${VAR}` in `docker-compose.yml` is defined in `.env.example`:

```bash
# Extract vars from docker-compose.yml
compose_vars=$(grep -oP '\$\{(\w+)' docker-compose.yml | sed 's/\${//' | sort -u)
env_vars=$(grep -oP '^\w+(?==)' .env.example | sort -u)

for var in $compose_vars; do
  echo "$env_vars" | grep -qx "$var" && echo "OK: $var" || echo "MISSING: $var"
done
```

### YAML Frontmatter Validation

Validates `skills/*/SKILL.md` files have valid YAML frontmatter with required `name` and `description` fields. Run the CI script directly:

```bash
python3 -c "
import yaml, glob, sys
for path in sorted(glob.glob('skills/*/SKILL.md')):
    with open(path) as f: content = f.read()
    if not content.startswith('---\n'): print(f'FAIL: {path}'); sys.exit(1)
    end = content.index('\n---', 3)
    data = yaml.safe_load(content[4:end])
    missing = [f for f in ['name','description'] if f not in data]
    print(f'FAIL: {path} missing {missing}' if missing else f'OK: {path}')
    if missing: sys.exit(1)
"
```

### Markdown Lint

```bash
npx markdownlint-cli2 "**/*.md" "#node_modules"
```

Configuration is in `.markdownlint.yml`.

### Integration Tests

```bash
bash tests/test-setup-sync.sh
```

Tests heredoc content sync and autonomy preset values across setup scripts.

## Branch Protection Rules

These rules should be configured by a repository admin in **Settings > Branches > Branch protection rules** for the `main` branch.

### Recommended Settings

1. **Require a pull request before merging**
   - Require at least 1 approval
   - Dismiss stale pull request approvals when new commits are pushed

2. **Require status checks to pass before merging**
   - Require branches to be up to date before merging
   - Required status checks:
     - `ShellCheck`
     - `Hadolint Dockerfile Lint`
     - `Docker Compose Config Validation`
     - `JSON Template Validation`
     - `Env Var Coverage Check`
     - `SKILL.md YAML Frontmatter Validation`
     - `Markdown Lint`
     - `Setup Script Integration Tests`

3. **Do not allow bypassing the above settings**
