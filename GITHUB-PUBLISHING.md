# Publishing on GitHub

This directory is the prepared repository. The existing v2.4.7 installer is unchanged.

1. Sign in at https://github.com/new and create a **public** repository named `5217`.
   Leave the automatic README, license and .gitignore options unchecked because these
   files are already present here.
2. In Terminal, open this directory and run the commands below. Replace
   YOUR-USERNAME with your actual GitHub username before running the remote command.

```sh
git init -b main
git add .
git diff --cached --stat
git commit -m "Open source 5217 v2.4.7 under MIT"
git remote add origin https://github.com/YOUR-USERNAME/5217.git
git push -u origin main
```

Authenticate using GitHub’s supported credential flow, not your account password.
If a remote repository already contains files, clone it first and copy this source
into that checkout instead of forcing a push.

3. Open **Releases → Draft a new release**, choose the main branch, and create the tag
   `v2.4.7`. Use `5217 v2.4.7 — Apple silicon` as the title. State the macOS 13 minimum
   and that this build is ad-hoc signed and not notarized.
4. Attach the existing `5217-v2.4.7-Apple-Silicon.dmg`,
   `5217-v2.4.7-SHA256.txt`, `5217-v2.4.7-Source.zip`, and installation notes from
   the release export folder. The existing source ZIP is the original binary-release
   source snapshot; GitHub’s automatically generated source archive includes the
   additional open-source documentation. The app source is identical.
5. Review the repository and release assets, then publish the release.

For future releases, update version/build metadata and changelog, verify the build,
and publish a corresponding tag and release. Never commit signing credentials or
personal session data. Developer ID signing and notarization require your own Apple
Developer credentials and a separate distribution setup.

Reference: [GitHub’s release instructions](https://docs.github.com/en/repositories/releasing-projects-on-github/managing-releases-in-a-repository).
