# Contributing

The repository is [MIT licensed](https://github.com/swade1987/flux2-kustomize-template/blob/main/LICENSE) and
accepts contributions via GitHub pull requests. This document outlines
some of the conventions on to make it easier to get your contribution
accepted.

We gratefully welcome improvements to issues and documentation as well as to
code.

## Certificate of Origin

By contributing to the repository you agree to the Developer Certificate of
Origin (DCO). This document was created by the Linux Kernel community and is a
simple statement that you, as a contributor, have the legal right to make the
contribution.

We require all commits to be signed. By signing off with your signature, you
certify that you wrote the patch or otherwise have the right to contribute the
material by the rules of the [DCO](DCO):

`Signed-off-by: Jane Doe <jane.doe@example.com>`

The signature must contain your real name
(sorry, no pseudonyms or anonymous contributions)
If your `user.name` and `user.email` are configured in your Git config,
you can sign your commit automatically with `git commit -s`.

## Acceptance policy

These things will make a PR more likely to be accepted:

- a well-described requirement
- sign-off all your commits
- tests for new configuration
- tests for old configuration!

In general, we will merge a PR once one maintainer has endorsed it.
For substantial changes, more people may become involved, and you might
get asked to resubmit the PR or divide the changes into more than one PR.

### Commit Message and Pull Request Requirements:

This repository enforces the `Conventional Commits` specification for both commit messages and pull request titles.

All commits and PR titles must follow this format:
type(optional scope): description

Examples:
- `feat: add new istio validation check`
- `fix(ci): resolve kubeconform pipeline error`
- `docs: update deployment instructions`
- `chore: bump pre-commit hooks version`

The type must be one of: `build, chore, ci, docs, feat, fix, perf, refactor, revert, style, test`

For more details on Conventional Commits, see: https://www.conventionalcommits.org/

Note: This is enforced automatically via GitHub Actions and pre-commit hooks.
