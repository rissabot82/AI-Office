param()
Write-Host @'
Set-Location "E:\AI\AI-Office"

git status

git add README.md PROJECT-STATUS.md ROADMAP.md VISION.md
git add config\project-status.json config\identity\version.json config\intelligence
git add scripts\intelligence scripts\conversational-office
git add dashboard\public\data\intelligence.json
git add docs\AI-Office-v2.5*.md
git add Installers\AI-Office-v2.5*.ps1

git commit -m "Release AI Office v2.5 Intelligence Upgrade"
git tag -a v2.5.0 -m "AI Office v2.5 Intelligence Upgrade"
git push origin main
git push origin v2.5.0

git status
git log -1 --oneline
'@
