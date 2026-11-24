<#
.SYNOPSIS
  Global git config + SSH key + GitHub login.
  Name and email are asked at run time and saved only in ~/.gitconfig.
  The private key never leaves ~/.ssh; only the public key is sent to GitHub.
#>
# Not 'Stop': git, gh and `ssh -T` write normal messages to stderr, which 5.1 would treat as fatal.
$ErrorActionPreference = 'Continue'

foreach ($tool in 'git', 'gh', 'ssh-keygen') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        Write-Host "x $tool nao encontrado. Rode .\install.ps1 -Categoria Dev antes." -ForegroundColor Red
        exit 1
    }
}

Write-Host '==> Identidade' -ForegroundColor Cyan
$name = git config --global user.name
$email = git config --global user.email
if (-not $name) { $name = Read-Host '  Nome para os commits' }
if (-not $email) {
    Write-Host '  Dica: use o email noreply do GitHub (Settings > Emails) para nao expor o seu.' -ForegroundColor DarkGray
    $email = Read-Host '  Email para os commits'
}
git config --global user.name $name
git config --global user.email $email
Write-Host "  = $name <$email>"

Write-Host '==> Configuracoes' -ForegroundColor Cyan
$settings = [ordered]@{
    'init.defaultBranch'     = 'main'
    'pull.rebase'            = 'true'
    'push.autoSetupRemote'   = 'true'
    'fetch.prune'            = 'true'
    'rebase.autoStash'       = 'true'
    'core.autocrlf'          = 'true'
    'core.editor'            = 'code --wait'
    'core.sshCommand'        = 'C:/Windows/System32/OpenSSH/ssh.exe'  # same ssh as ssh-agent service
}
foreach ($key in $settings.Keys) {
    git config --global $key $settings[$key]
    Write-Host "  $key = $($settings[$key])"
}

Write-Host '==> Chave SSH' -ForegroundColor Cyan
$key = "$HOME\.ssh\id_ed25519"
if (Test-Path $key) {
    Write-Host "  = $key ja existe" -ForegroundColor DarkGray
} else {
    New-Item -ItemType Directory -Force "$HOME\.ssh" | Out-Null
    Write-Host '  Defina uma senha para a chave (recomendado).'
    ssh-keygen -t ed25519 -C $email -f $key
}
# ssh-agent keeps the unlocked key for the session (service setup needs admin).
try {
    Set-Service ssh-agent -StartupType Automatic
    Start-Service ssh-agent
    ssh-add $key
} catch {
    Write-Host "  ssh-agent nao configurado (rode como admin): $_" -ForegroundColor Yellow
}

Write-Host '==> GitHub' -ForegroundColor Cyan
gh auth status *> $null
if ($LASTEXITCODE -ne 0) { gh auth login --hostname github.com --git-protocol ssh --web --skip-ssh-key }
# Uploading keys needs the admin:public_key scope.
gh auth refresh --hostname github.com --scopes admin:public_key
$pub = (Get-Content "$key.pub" -Raw).Trim()
$already = gh ssh-key list --json key --jq '.[].key' 2>$null
if ($already -match [regex]::Escape(($pub -split ' ')[1])) {
    Write-Host '  = chave publica ja cadastrada' -ForegroundColor DarkGray
} else {
    gh ssh-key add "$key.pub" --title $env:COMPUTERNAME
}
ssh -T git@github.com 2>&1 | Select-Object -First 1

Write-Host "`nPronto." -ForegroundColor Green
exit 0
