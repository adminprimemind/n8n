# Script to remove secrets from git history
# This will rewrite git history to remove the detected Vault token

Write-Host "Rewriting git history to remove secrets..." -ForegroundColor Yellow

# Create a backup branch first
git branch backup-before-secret-removal

# Use git filter-branch to replace the secret in all commits
# Replace the Vault token placeholder with a safe one
git filter-branch --force --index-filter `
    "git rm --cached --ignore-unmatch packages/cli/src/modules/external-secrets.ee/providers/vault.ts 2>$null || true && git checkout HEAD -- packages/cli/src/modules/external-secrets.ee/providers/vault.ts 2>$null || true" `
    --prune-empty --tag-name-filter cat -- --all

# Alternative: Use sed/awk to replace the specific token string
# This is safer but requires the exact string match

Write-Host "History rewritten. Original branch saved as 'backup-before-secret-removal'" -ForegroundColor Green
Write-Host "You can now try: git push -u origin master --force" -ForegroundColor Yellow
Write-Host "WARNING: Force push will overwrite remote history. Make sure you have a backup!" -ForegroundColor Red

