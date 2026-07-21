CLAUDE.md
=========

Guidance for working in this repository.

Commits
-------

Every commit MUST be signed off (DCO) and MUST follow
[Conventional Commits](https://www.conventionalcommits.org/), which are enforced
by commitlint.

### Sign-off (DCO)

Every commit must carry a `Signed-off-by:` trailer, enforced by the DCO check on
every pull request. Add it with `git commit -s`:

```
Signed-off-by: Your Name <your@email>
```

The name and email must match the commit author.

### Format

```
<type>(<scope>): <subject>

[optional body]

[optional footer — BREAKING CHANGE: …]
```

- **Types:** `feat`, `fix`, `docs`, `chore`, `refactor`, `revert`, `test`, `ci`,
  `build`, `perf`, `style`.
- **Scopes:** align with top-level directories (`bin`, `scripts`, `src`) or the
  component being changed.
- **Subject:** imperative mood, lowercase, no trailing period, ≤72 chars.
- **One logical change per commit.** If a refactor landed alongside a fix, split
  it into separate commits.

### Examples

```
feat(src): add new tool to the image
fix(src): pin dependency to a released version
docs(readme): document the installed tool versions
refactor(scripts): extract shared helper
```
