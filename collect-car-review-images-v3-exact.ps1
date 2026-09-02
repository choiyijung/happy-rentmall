$ErrorActionPreference = "Stop"

$root = "D:\happy-rentmall"
$assetDir = Join-Path $root "assets\cars"
$creditsPath = Join-Path $assetDir "image-credits.csv"

New-Item -ItemType Directory -Path $assetDir -Force | Out-Null

# 2차 수집에서 남은 30개를 Wikimedia Commons의 "정확한 파일명"으로 직접 지정
$targets = @(
    @{slug="g90"; name="G90"; file="Genesis G90 (RS4) DSC 0590.jpg"},
    @{slug="grandeur"; name="그랜저"; file="00 Hyundai Grandeur (GN7).jpg"},
    @{slug="grand-koleos"; name="그랑 콜레오스"; file="Renault Grand Koleos 001.jpg"},
    @{slug="ioniq9"; name="아이오닉9"; file="2026 Hyundai Ioniq 9.jpg"},
    @{slug="k5"; name="K5"; file="KIA K5 (DL3) China (13).jpg"},
    @{slug="k8"; name="K8"; file="Kia K8 GL3 Matte Grey (4).jpg"},
    @{slug="kona"; name="코나"; file="Hyundai Kona.jpg"},
    @{slug="korando"; name="코란도"; file="Ssangyong Korando (4th generation) IMG 3089.jpg"},
    @{slug="lexus-es"; name="렉서스 ES"; file="Lexus-ES-2026.jpg"},
    @{slug="morning"; name="모닝"; file="2023 Kia Picanto.jpg"},
    @{slug="musso-khan"; name="무쏘 칸"; file="SsangYong Musso Grand.jpg"},
    @{slug="musso-sports"; name="무쏘 스포츠"; file="0 SsangYong Musso Sports 1.jpg"},
    @{slug="niro"; name="니로"; file="Kia Niro.jpg"},
    @{slug="palisade"; name="팰리세이드"; file="Hyundai Palisade.jpg"},
    @{slug="qm6"; name="QM6"; file="Renault Samsung QM6 HZG FL Metallic Black Unmarked (1).jpg"},
    @{slug="ray"; name="레이"; file="The New Kia Ray TAM 2025-03-07.jpg"},
    @{slug="rexton"; name="렉스턴"; file="2024 Ssangyong Rexton Auto.jpg"},
    @{slug="santafe"; name="싼타페"; file="Hyundai Santa Fe.jpg"},
    @{slug="scenic-e-tech"; name="세닉 E-Tech"; file="Renault Scénic E-Tech (2025) (54712552219).jpg"},
    @{slug="seltos"; name="셀토스"; file="2026 Kia Seltos.jpg"},
    @{slug="sonata"; name="쏘나타"; file="1 Hyundai Sonata (DN8).jpg"},
    @{slug="sorento"; name="쏘렌토"; file="Kia Sorento (51945585259).jpg"},
    @{slug="sportage"; name="스포티지"; file="Kia Sportage(1).jpg"},
    @{slug="staria"; name="스타리아"; file="0Hyundai Staria.jpg"},
    @{slug="tesla-model-3"; name="테슬라 모델3"; file="Tesla Model3.jpg"},
    @{slug="tesla-model-y"; name="테슬라 모델Y"; file="Tesla Model Y (Facelift) – f 05052026.jpg"},
    @{slug="torres"; name="토레스"; file="SsangYong Torres 1.5 T-GDI J100 Space Black (1).jpg"},
    @{slug="torres-evx"; name="토레스 EVX"; file="KG Mobility Torres EVX Auto Zuerich 2024 DSC 6633.jpg"},
    @{slug="tucson"; name="투싼"; file="Hyundai-Tucson.jpg"},
    @{slug="volvo-xc60"; name="볼보 XC60"; file="Volvo XC60.JPG"}
)

$headers = @{
    "User-Agent" = "HappyRentmallImageCollector/3.0"
}

function Get-ExactCommonsFile {
    param([string]$FileName)

    $title = "File:$FileName"
    $encoded = [uri]::EscapeDataString($title)

    $api = "https://commons.wikimedia.org/w/api.php?action=query&titles=$encoded&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=1600&format=json&formatversion=2"

    $data = Invoke-RestMethod -Uri $api -Headers $headers -TimeoutSec 40
    $page = @($data.query.pages)[0]

    if (-not $page.imageinfo) {
        return $null
    }

    $ii = $page.imageinfo[0]
    $url = $ii.thumburl

    if (-not $url) {
        $url = $ii.url
    }

    if (-not $url) {
        return $null
    }

    [pscustomobject]@{
        Url        = $url
        PageUrl    = $ii.descriptionurl
        Artist     = ($ii.extmetadata.Artist.value -replace '<[^>]+>',' ')
        License    = $ii.extmetadata.LicenseShortName.value
        LicenseUrl = $ii.extmetadata.LicenseUrl.value
    }
}

$existingCredits = @()

if (Test-Path $creditsPath) {
    try {
        $existingCredits = @(Import-Csv $creditsPath)
    }
    catch {
        $existingCredits = @()
    }
}

$credits = @($existingCredits)
$downloaded = 0
$failed = @()

foreach ($t in $targets) {

    $out = Join-Path $assetDir ($t.slug + ".jpg")

    if ((Test-Path $out) -and ((Get-Item $out).Length -ge 10000)) {
        Write-Host "이미 존재:" $t.name
        continue
    }

    Write-Host "정확 파일 수집:" $t.name

    try {
        $info = Get-ExactCommonsFile -FileName $t.file

        if (-not $info) {
            $failed += $t
            Write-Host "  → Commons 파일 조회 실패"
            continue
        }

        Invoke-WebRequest `
            -Uri $info.Url `
            -Headers $headers `
            -OutFile $out `
            -TimeoutSec 60

        if ((Get-Item $out).Length -lt 10000) {
            Remove-Item $out -Force -ErrorAction SilentlyContinue
            $failed += $t
            Write-Host "  → 다운로드 파일 크기 이상"
            continue
        }

        $credits = @(
            $credits | Where-Object { $_.Slug -ne $t.slug }
        )

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

        $downloaded++
        Write-Host "  → 완료:" ($t.slug + ".jpg")
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

# 현재 확보된 53개 이미지 전체를 각 차종 후기 3개 카드에 다시 확실하게 연결
$carPages = Get-ChildItem (Join-Path $root "cars") -Directory
$applied = 0
$missing = @()

foreach ($dir in $carPages) {

    $slug = $dir.Name
    $img = Join-Path $assetDir ($slug + ".jpg")
    $file = Join-Path $dir.FullName "index.html"

    if (-not (Test-Path $file)) {
        continue
    }

    if (-not (Test-Path $img)) {
        $missing += $slug
        continue
    }

    $html = Get-Content $file -Raw -Encoding UTF8
    $before = $html
    $relImg = "../../assets/cars/$slug.jpg"

    # review-card-new 3개 각각 내부의 이미지 div만 교체
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

    if ($html -ne $before) {
        Set-Content $file $html -Encoding UTF8
        $applied++
    }
}

# 실제 이미지 개수 및 페이지 연결 검사
$totalImages = (
    Get-ChildItem $assetDir -File -Filter "*.jpg" -ErrorAction SilentlyContinue
).Count

$linked = 0

foreach ($dir in $carPages) {
    $slug = $dir.Name
    $file = Join-Path $dir.FullName "index.html"

    if (-not (Test-Path $file)) {
        continue
    }

    $html = Get-Content $file -Raw -Encoding UTF8

    if ($html -match [regex]::Escape("../../assets/cars/$slug.jpg")) {
        $linked++
    }
}

Write-Host ""
Write-Host "=============================="
Write-Host "이번 정확수집 성공:" $downloaded
Write-Host "이번 정확수집 실패:" $failed.Count
Write-Host "현재 차량사진 총:" $totalImages
Write-Host "차종페이지 이미지 재연결:" $applied
Write-Host "실사진 연결 완료 페이지:" $linked
Write-Host "이미지 없는 차종:" $missing.Count
Write-Host "출처 파일:" $creditsPath

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "=== 정확수집 실패 ==="
    $failed | ForEach-Object {
        Write-Host $_.slug "|" $_.name "|" $_.file
    }
}

if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "=== 아직 이미지 없는 slug ==="
    $missing | ForEach-Object { Write-Host $_ }
}
