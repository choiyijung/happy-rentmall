$ErrorActionPreference = "Stop"

$root = "D:\happy-rentmall"
$assetDir = Join-Path $root "assets\cars"
$creditsPath = Join-Path $assetDir "image-credits.csv"

New-Item -ItemType Directory -Path $assetDir -Force | Out-Null

# 남은 13개: Wikimedia Commons에서 실제 존재가 확인된 정확한 파일명
$targets = @(
    @{slug="musso-khan"; name="무쏘 칸"; file="SsangYong Rexton Sports Khan Q250 Amazonia Green (1).jpg"},
    @{slug="palisade"; name="팰리세이드"; file="Hyundai Palisade LX3 01 China 2026-04-01.jpg"},
    @{slug="santafe"; name="싼타페"; file="2023 Hyundai Santa Fe (MX5) 1.jpg"},
    @{slug="sonata"; name="쏘나타"; file="Hyundai Sonata DN8 (1).jpg"},
    @{slug="sorento"; name="쏘렌토"; file="Kia Sorento MQ4 black (1).jpg"},
    @{slug="sportage"; name="스포티지"; file="Kia Sportage NQ5 white (1).jpg"},
    @{slug="staria"; name="스타리아"; file="0Hyundai Staria.jpg"},
    @{slug="tesla-model-3"; name="테슬라 모델3"; file="2024 Tesla Model 3.jpg"},
    @{slug="tesla-model-y"; name="테슬라 모델Y"; file="Tesla Model Y (Facelift) – f 05052026.jpg"},
    @{slug="torres"; name="토레스"; file="2024 KGM Torres.jpg"},
    @{slug="torres-evx"; name="토레스 EVX"; file="KG Mobility Torres EVX U100 Iron Metal (1).jpg"},
    @{slug="tucson"; name="투싼"; file="0 Hyundai Tucson (NX4).jpg"},
    @{slug="volvo-xc60"; name="볼보 XC60"; file="Volvo XC60.JPG"}
)

$headers = @{
    "User-Agent" = "HappyRentmallImageCollector/4.0"
}

$credits = @()
if (Test-Path $creditsPath) {
    try {
        $credits = @(Import-Csv $creditsPath)
    } catch {
        $credits = @()
    }
}

$success = 0
$failed = @()

foreach ($t in $targets) {

    $out = Join-Path $assetDir ($t.slug + ".jpg")

    if ((Test-Path $out) -and ((Get-Item $out).Length -ge 10000)) {
        Write-Host "이미 존재:" $t.name
        continue
    }

    Write-Host "직접 다운로드:" $t.name

    try {
        $encoded = [uri]::EscapeDataString($t.file)

        # Wikimedia Commons가 정확한 파일로 직접 리다이렉트
        $downloadUrl = "https://commons.wikimedia.org/wiki/Special:Redirect/file/$encoded?width=1600"

        Invoke-WebRequest `
            -Uri $downloadUrl `
            -Headers $headers `
            -OutFile $out `
            -MaximumRedirection 10 `
            -TimeoutSec 60

        $size = (Get-Item $out).Length

        if ($size -lt 10000) {
            Remove-Item $out -Force -ErrorAction SilentlyContinue
            throw "다운로드 파일이 너무 작습니다: $size bytes"
        }

        # HTML 오류 페이지가 저장된 경우 방지
        $head = [System.IO.File]::ReadAllBytes($out)
        if ($head.Length -ge 4) {
            $isJpeg = ($head[0] -eq 0xFF -and $head[1] -eq 0xD8)
            $isPng  = ($head[0] -eq 0x89 -and $head[1] -eq 0x50 -and $head[2] -eq 0x4E -and $head[3] -eq 0x47)

            if (-not ($isJpeg -or $isPng)) {
                Remove-Item $out -Force -ErrorAction SilentlyContinue
                throw "이미지 파일 형식이 아닙니다."
            }
        }

        $sourceTitle = "File:" + $t.file
        $sourceUrl = "https://commons.wikimedia.org/wiki/" + [uri]::EscapeDataString($sourceTitle)

        $credits = @(
            $credits | Where-Object { $_.Slug -ne $t.slug }
        )

        $credits += [pscustomobject]@{
            Car        = $t.name
            Slug       = $t.slug
            SourceFile = $t.file
            SourcePage = $sourceUrl
            License    = "Wikimedia Commons - source page 확인"
            LicenseUrl = $sourceUrl
            Artist     = "source page 확인"
            Source     = "Wikimedia Commons"
        }

        $success++
        Write-Host "  → 완료:" ($t.slug + ".jpg") "|" $size "bytes"
    }
    catch {
        Remove-Item $out -Force -ErrorAction SilentlyContinue
        $failed += $t
        Write-Host "  → 실패:" $_.Exception.Message
    }

    Start-Sleep -Milliseconds 200
}

$credits |
    Sort-Object Slug |
    Export-Csv $creditsPath -NoTypeInformation -Encoding UTF8

# 현재 확보된 이미지 전부를 차종 페이지 후기 3개에 다시 연결
$carPages = Get-ChildItem (Join-Path $root "cars") -Directory
$linkedPages = 0

foreach ($dir in $carPages) {

    $slug = $dir.Name
    $file = Join-Path $dir.FullName "index.html"
    $img  = Join-Path $assetDir ($slug + ".jpg")

    if (-not (Test-Path $file) -or -not (Test-Path $img)) {
        continue
    }

    $html = Get-Content $file -Raw -Encoding UTF8
    $relImg = "../../assets/cars/$slug.jpg"

    $cards = [regex]::Matches(
        $html,
        '(?is)<article class="review-card-new">.*?</article>'
    )

    if ($cards.Count -ge 3) {
        for ($i = 2; $i -ge 0; $i--) {

            $cardMatch = $cards[$i]
            $card = $cardMatch.Value
            $n = $i + 1

            $replacement = "<div class=`"review-car-image car-review-photo car-review-photo-$n`" style=`"background-image:url('$relImg')`"></div>"

            if ($card -match '(?is)<div class="review-car-image[^"]*"[^>]*>.*?</div>') {
                $newCard = [regex]::Replace(
                    $card,
                    '(?is)<div class="review-car-image[^"]*"[^>]*>.*?</div>',
                    $replacement,
                    1
                )
            }
            else {
                $newCard = [regex]::Replace(
                    $card,
                    '(?is)(<article class="review-card-new">)',
                    ('$1' + "`r`n  " + $replacement),
                    1
                )
            }

            $html = $html.Remove(
                $cardMatch.Index,
                $cardMatch.Length
            ).Insert(
                $cardMatch.Index,
                $newCard
            )
        }
    }

    Set-Content $file $html -Encoding UTF8

    $verify = Get-Content $file -Raw -Encoding UTF8
    if ($verify -match [regex]::Escape("../../assets/cars/$slug.jpg")) {
        $linkedPages++
    }
}

$totalImages = (
    Get-ChildItem $assetDir -File -Filter "*.jpg" -ErrorAction SilentlyContinue
).Count

$missing = @()

foreach ($dir in $carPages) {
    $slug = $dir.Name
    if (-not (Test-Path (Join-Path $assetDir ($slug + ".jpg")))) {
        $missing += $slug
    }
}

Write-Host ""
Write-Host "=============================="
Write-Host "이번 13개 직접수집 성공:" $success
Write-Host "이번 13개 직접수집 실패:" $failed.Count
Write-Host "현재 차량사진 총:" $totalImages
Write-Host "실사진 연결 완료 페이지:" $linkedPages
Write-Host "이미지 없는 차종:" $missing.Count
Write-Host "출처 파일:" $creditsPath

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "=== 아직 실패 ==="
    $failed | ForEach-Object {
        Write-Host $_.slug "|" $_.name "|" $_.file
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "=== 이미지 없는 slug ==="
    $missing | ForEach-Object { Write-Host $_ }
}
