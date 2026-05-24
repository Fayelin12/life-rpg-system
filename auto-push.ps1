$repoPath = "G:\人生开放系统"

Write-Host "=== 人生开放系统 自动推送 ===" -ForegroundColor Cyan

Set-Location $repoPath

# 检查 Git 是否可用
$status = git status --short 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "`nGit 命令执行失败，请确认 Git 已安装。" -ForegroundColor Red
    Read-Host "按 Enter 键退出"
    exit 1
}

# 无变更则跳过
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "没有检测到更改，无需推送。" -ForegroundColor Green
    Read-Host "按 Enter 键退出"
    exit 0
}

Write-Host "`n检测到以下更改：" -ForegroundColor Cyan
Write-Host $status
Write-Host ""

# 检查远程仓库是否配置
$remote = git remote 2>$null
if ([string]::IsNullOrWhiteSpace($remote)) {
    Write-Host "⚠ 未配置远程仓库，请先执行：" -ForegroundColor Yellow
    Write-Host "  git remote add origin <你的仓库地址>" -ForegroundColor Yellow
    Write-Host "提交将保存在本地。" -ForegroundColor Gray
}

# Stage & Commit
git add .
if ($LASTEXITCODE -ne 0) {
    Write-Host "git add 失败" -ForegroundColor Red
    Read-Host "按 Enter 键退出"
    exit 1
}

$dateStr = Get-Date -Format "yyyy-MM-dd HH:mm"
git commit -m "$dateStr 自动更新"
if ($LASTEXITCODE -ne 0) {
    Write-Host "git commit 失败（可能没有实质性变更）" -ForegroundColor Yellow
    Read-Host "按 Enter 键退出"
    exit 1
}

# Push（仅在有远程仓库时）
if (-not [string]::IsNullOrWhiteSpace($remote)) {
    Write-Host "`n正在推送到远程仓库..." -ForegroundColor Cyan
    git push origin master
    if ($LASTEXITCODE -ne 0) {
        Write-Host "git push 失败，请检查远程仓库配置" -ForegroundColor Red
        Read-Host "按 Enter 键退出"
        exit 1
    }
}

Write-Host "`n推送完成！" -ForegroundColor Green
Read-Host "按 Enter 键退出"
