$ErrorActionPreference = "Continue"

$root = "D:\happy-rentmall"
$assetDir = Join-Path $root "assets\cars"
$creditsPath = Join-Path $assetDir "image-credits.csv"

New-Item -ItemType Directory -Path $assetDir -Force | Out-Null

$targets = @(
    @{
        slug="musso-khan"; name="무쏘 칸";
        url="https://upload.wikimedia.org/wikipedia/commons/d/d2/SsangYong_Rexton_Sports_Khan_Q250_Amazonia_Green_%281%29.jpg";
        source="https://commons.wikimedia.org/wiki/File:SsangYong_Rexton_Sports_Khan_Q250_Amazonia_Green_(1).jpg"
    },
    @{
        slug="palisade"; name="팰리세이드";
        url="https://upload.wikimedia.org/wikipedia/commons/4/46/Hyundai_Palisade_in_White%2C_front_right_%28South_Korea%29.jpg";
        source="https://commons.wikimedia.org/wiki/File:Hyundai_Palisade_in_White,_front_right_(South_Korea).jpg"
    },
    @{
        slug="santafe"; name="싼타페";
        url="https://upload.wikimedia.org/wikipedia/commons/c/c8/2024_Hyundai_Santa_Fe_%28MX5%29_IMG_5295.jpg";
        source="https://commons.wikimedia.org/wiki/File:2024_Hyundai_Santa_Fe_(MX5)_IMG_5295.jpg"
    },
    @{
        slug="sonata"; name="쏘나타";
        url="https://upload.wikimedia.org/wikipedia/commons/c/c6/Hyundai_Sonata_DN8_%281%29.jpg";
        source="https://commons.wikimedia.org/wiki/File:Hyundai_Sonata_DN8_(1).jpg"
    },
    @{
        slug="sorento"; name="쏘렌토";
        url="https://upload.wikimedia.org/wikipedia/commons/b/b2/Kia_Sorento_MQ4_black_%281%29.jpg";
        source="https://commons.wikimedia.org/wiki/File:Kia_Sorento_MQ4_black_(1).jpg"
    },
    @{
        slug="sportage"; name="스포티지";
        url="https://upload.wikimedia.org/wikipedia/commons/3/3a/Kia_Sportage_NQ5_white_%281%29.jpg";
        source="https://commons.wikimedia.org/wiki/File:Kia_Sportage_NQ5_white_(1).jpg"
    },
    @{
        slug="staria"; name="스타리아";
        url="https://upload.wikimedia.org/wikipedia/commons/0/07/Hyundai_Staria_IMG_5633.jpg";
        source="https://commons.wikimedia.org/wiki/File:Hyundai_Staria_IMG_5633.jpg"
    },
    @{
        slug="tesla-model-3"; name="테슬라 모델3";
        url="https://upload.wikimedia.org/wikipedia/commons/8/84/Tesla_Model3.jpg";
        source="https://commons.wikimedia.org/wiki/File:Tesla_Model3.jpg"
    },
    @{
        slug="tesla-model-y"; name="테슬라 모델Y";
        url="https://upload.wikimedia.org/wikipedia/commons/1/14/Tesla_Model_Y_white_%281%29.jpg";
        source="https://commons.wikimedia.org/wiki/File:Tesla_Model_Y_white_(1).jpg"
    },
    @{
        slug="torres"; name="토레스";
        url="https://upload.wikimedia.org/wikipedia/commons/0/0b/SsangYong_Torres_J100_Space_Black_%281%29.jpg";
        source="https://commons.wikimedia.org/wiki/File:SsangYong_Torres_J100_Space_Black_(1).jpg"
    },
    @{
        slug="torres-evx"; name="토레스 EVX";
        url="https://upload.wikimedia.org/wikipedia/commons/0/09/KGM_Torres_EVX_%E2%80%93_f_01092025.jpg";
        source="https://commons.wikimedia.org/wiki/File:KGM_Torres_EVX_–_f_01092025.jpg"
    },
    @{
        slug="tucson"; name="투싼";
        url="https://upload.wikimedia.org/wikipedia/commons/1/1a/0_Hyundai_Tucson_%28NX4%29.jpg";
        source="https://commons.wikimedia.org/wiki/File:0_Hyundai_Tucson_(NX4).jpg"
    },
    @{
        slug="volvo-xc60"; name="볼보 XC60";
        url="https://upload.wikimedia.org/wikipedia/commons/8/83/Volvo_XC60.JPG";
        source="https://commons.wikimedia.org/wiki/File:Volvo_XC60.JPG"
    }
)

$headers = @{
    "User-Agent" = "Mozilla/5.0"
    "Accept" = "image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8"
}

function Test-ImageFile {
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        return $false
    }

    $item = Get-Item $Path
    if ($item.Length -lt 10000) {
        return $false
    }

    try {
        $fs = [System.IO.File]::OpenRead($Path)
        $b1 = $fs.ReadByte()
        $b2 = $fs.ReadByte()
        $b3 = $fs.ReadByte()
        $b4 = $fs.ReadByte()
        $fs.Close()

        $jpeg = ($b1 -eq 255 -and $b2 -eq 216)
        $png  = ($b1 -eq 137 -and $b2 -eq 80 -and $b3 -eq 78 -and $b4 -eq 71)

        return ($jpeg -or $png)
    }
    catch {
        return $false
    }
}

$success = 0
$failed = @()

foreach ($t in $targets) {

    $out = Join-Path $assetDir ($t.slug + ".jpg")

    if (Test-ImageFile $out) {
        Write-Host "이미 존재:" $t.name
        continue
    }

    Remove-Item $out -Force -ErrorAction SilentlyContinue

    Write-Host "다운로드:" $t.name

    $downloaded = $false

    try {
        Invoke-WebRequest `
            -Uri $t.url `
            -Headers $headers `
            -OutFile $out `
            -UseBasicParsing `
            -TimeoutSec 90

        if (Test-ImageFile $out) {
            $downloaded = $true
        }
    }
    catch {
        Write-Host "  1차 실패 - BITS 재시도"
    }

    if (-not $downloaded) {
        Remove-Item $out -Force -ErrorAction SilentlyContinue

        try {
            Import-Module BitsTransfer -ErrorAction Stop
            Start-BitsTransfer -Source $t.url -Destination $out -ErrorAction Stop

            if (Test-ImageFile $out) {
                $downloaded = $true
            }
        }
        catch {
        }
    }

    if ($downloaded) {
        $success++
        Write-Host "  → 성공:" (Get-Item $out).Length "bytes"
    }
    else {
        Remove-Item $out -Force -ErrorAction SilentlyContinue
        $failed += $t
        Write-Host "  → 최종 실패"
    }
}

# 출처 CSV 갱신
$credits = @()

if (Test-Path $creditsPath) {
    try {
        $credits = @(Import-Csv $creditsPath)
    }
    catch {
        $credits = @()
    }
}

foreach ($t in $targets) {
    $img = Join-Path $assetDir ($t.slug + ".jpg")

    if (-not (Test-ImageFile $img)) {
        continue
    }

    $credits = @($credits | Where-Object { $_.Slug -ne $t.slug })

    $credits += [pscustomobject]@{
        Car        = $t.name
        Slug       = $t.slug
        SourceFile = Split-Path $t.source -Leaf
        SourcePage = $t.source
        License    = "Wikimedia Commons - 개별 파일 페이지 참조"
        LicenseUrl = $t.source
        Artist     = "개별 파일 페이지 참조"
        Source     = "Wikimedia Commons"
    }
}

$credits |
    Sort-Object Slug |
    Export-Csv $creditsPath -NoTypeInformation -Encoding UTF8

# 13개 차종 후기 이미지 연결
$linked = 0

foreach ($t in $targets) {

    $file = Join-Path $root ("cars\" + $t.slug + "\index.html")
    $img  = Join-Path $assetDir ($t.slug + ".jpg")

    if (-not (Test-Path $file) -or -not (Test-ImageFile $img)) {
        continue
    }

    $html = Get-Content $file -Raw -Encoding UTF8
    $relImg = "../../assets/cars/$($t.slug).jpg"

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

            } else {

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

    if ($verify -match [regex]::Escape($relImg)) {
        $linked++
    }
}

$totalImages = (
    Get-ChildItem $assetDir -File -Filter "*.jpg" -ErrorAction SilentlyContinue |
    Where-Object { Test-ImageFile $_.FullName }
).Count

$allCarDirs = Get-ChildItem (Join-Path $root "cars") -Directory
$missing = @()

foreach ($dir in $allCarDirs) {
    $img = Join-Path $assetDir ($dir.Name + ".jpg")
    if (-not (Test-ImageFile $img)) {
        $missing += $dir.Name
    }
}

Write-Host ""
Write-Host "=============================="
Write-Host "이번 13개 성공:" $success
Write-Host "이번 13개 실패:" $failed.Count
Write-Host "현재 정상 차량사진 총:" $totalImages
Write-Host "이번 13개 페이지 연결:" $linked
Write-Host "전체 이미지 없는 차종:" $missing.Count
Write-Host "출처 파일:" $creditsPath

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "=== 실패 차종 ==="
    $failed | ForEach-Object { Write-Host $_.slug "|" $_.name }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "=== 이미지 없는 slug ==="
    $missing | ForEach-Object { Write-Host $_ }
}
