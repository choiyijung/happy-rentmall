$ErrorActionPreference = "Stop"

$root = "D:\happy-rentmall"
$assetDir = Join-Path $root "assets\cars"
$creditsPath = Join-Path $assetDir "image-credits.csv"

$targets = @(
    @{slug="sportage"; name="스포티지"; file="Kia Sportage (NQ5) 1758033820001.jpg"},
    @{slug="staria"; name="스타리아"; file="Hyundai Staria.jpg"},
    @{slug="tesla-model-3"; name="테슬라 모델3"; file="2024 Tesla Model 3.jpg"},
    @{slug="tesla-model-y"; name="테슬라 모델Y"; file="Tesla Model Y.jpg"},
    @{slug="torres"; name="토레스"; file="2024 KGM Torres.jpg"},
    @{slug="torres-evx"; name="토레스 EVX"; file="KGM Torres EVX – f 01092025.jpg"},
    @{slug="tucson"; name="투싼"; file="0 Hyundai Tucson (NX4).jpg"},
    @{slug="volvo-xc60"; name="볼보 XC60"; file="2017 Volvo XC60.jpg"}
)

$headers = @{
    "User-Agent" = "HappyRentmallImageCollector/6.0"
}

function Get-CommonsExact {
    param([string]$FileName)

    $title = "File:$FileName"
    $encoded = [uri]::EscapeDataString($title)

    $api = "https://commons.wikimedia.org/w/api.php?action=query&titles=$encoded&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=1600&format=json&formatversion=2"

    $data = Invoke-RestMethod -Uri $api -Headers $headers -TimeoutSec 60
    $page = @($data.query.pages)[0]

    if (-not $page -or -not $page.imageinfo) {
        throw "Commons에서 파일을 찾지 못했습니다: $FileName"
    }

    $ii = $page.imageinfo[0]
    $url = $ii.thumburl
    if (-not $url) { $url = $ii.url }
    if (-not $url) { throw "이미지 URL이 없습니다: $FileName" }

    return [pscustomobject]@{
        Url        = $url
        PageUrl    = $ii.descriptionurl
        License    = $ii.extmetadata.LicenseShortName.value
        LicenseUrl = $ii.extmetadata.LicenseUrl.value
        Artist     = ($ii.extmetadata.Artist.value -replace '<[^>]+>',' ')
    }
}

function Test-Image {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return $false }
    if ((Get-Item $Path).Length -lt 10000) { return $false }

    $fs = [System.IO.File]::OpenRead($Path)
    try {
        $b1 = $fs.ReadByte()
        $b2 = $fs.ReadByte()
        $b3 = $fs.ReadByte()
        $b4 = $fs.ReadByte()
    }
    finally {
        $fs.Close()
    }

    $jpg = ($b1 -eq 255 -and $b2 -eq 216)
    $png = ($b1 -eq 137 -and $b2 -eq 80 -and $b3 -eq 78 -and $b4 -eq 71)

    return ($jpg -or $png)
}

$credits = @()
if (Test-Path $creditsPath) {
    try { $credits = @(Import-Csv $creditsPath) } catch { $credits = @() }
}

$success = 0
$failed = @()

foreach ($t in $targets) {

    $out = Join-Path $assetDir ($t.slug + ".jpg")

    Write-Host "수집:" $t.name

    try {
        $info = Get-CommonsExact -FileName $t.file

        Invoke-WebRequest `
            -Uri $info.Url `
            -Headers $headers `
            -OutFile $out `
            -UseBasicParsing `
            -TimeoutSec 90

        if (-not (Test-Image $out)) {
            Remove-Item $out -Force -ErrorAction SilentlyContinue
            throw "다운로드 파일 검증 실패"
        }

        $credits = @($credits | Where-Object { $_.Slug -ne $t.slug })

        $credits += [pscustomobject]@{
            Car        = $t.name
            Slug       = $t.slug
            SourceFile = $t.file
            SourcePage = $info.PageUrl
            License    = $info.License
            LicenseUrl = $info.LicenseUrl
            Artist     = $info.Artist
            Source     = "Wikimedia Commons"
        }

        $success++
        Write-Host "  → 성공:" (Get-Item $out).Length "bytes"
    }
    catch {
        Remove-Item $out -Force -ErrorAction SilentlyContinue
        $failed += $t
        Write-Host "  → 실패:" $_.Exception.Message
    }
}

$credits |
    Sort-Object Slug |
    Export-Csv $creditsPath -NoTypeInformation -Encoding UTF8

# 확보된 이미지들을 후기 3개 카드에 다시 연결
$linked = 0

foreach ($t in $targets) {

    $file = Join-Path $root ("cars\" + $t.slug + "\index.html")
    $img = Join-Path $assetDir ($t.slug + ".jpg")

    if (-not (Test-Path $file) -or -not (Test-Image $img)) {
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

$allDirs = Get-ChildItem (Join-Path $root "cars") -Directory
$missing = @()

foreach ($dir in $allDirs) {
    $img = Join-Path $assetDir ($dir.Name + ".jpg")
    if (-not (Test-Image $img)) {
        $missing += $dir.Name
    }
}

$total = (Get-ChildItem $assetDir -File -Filter "*.jpg" | Where-Object { Test-Image $_.FullName }).Count

Write-Host ""
Write-Host "=============================="
Write-Host "이번 8개 수집 성공:" $success
Write-Host "이번 8개 수집 실패:" $failed.Count
Write-Host "현재 정상 차량사진 총:" $total
Write-Host "이번 8개 페이지 연결:" $linked
Write-Host "전체 이미지 없는 차종:" $missing.Count
Write-Host "출처 파일:" $creditsPath

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "=== 실패 ==="
    $failed | ForEach-Object {
        Write-Host $_.slug "|" $_.name "|" $_.file
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "=== 이미지 없는 slug ==="
    $missing | ForEach-Object { Write-Host $_ }
}
