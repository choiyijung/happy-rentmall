$ErrorActionPreference = "Stop"

$root = "D:\happy-rentmall"
$assetDir = Join-Path $root "assets\cars"
New-Item -ItemType Directory -Path $assetDir -Force | Out-Null

$cars = @(
    @{slug="actyon"; name="액티언"; q="KGM Actyon automobile"},
    @{slug="arkana"; name="아르카나"; q="Renault Arkana automobile"},
    @{slug="audi-a6"; name="아우디 A6"; q="Audi A6 automobile"},
    @{slug="avante"; name="아반떼"; q="Hyundai Avante Elantra automobile"},
    @{slug="benz-e-class"; name="벤츠 E클래스"; q="Mercedes-Benz E-Class automobile"},
    @{slug="benz-glc"; name="벤츠 GLC"; q="Mercedes-Benz GLC automobile"},
    @{slug="bmw-5-series"; name="BMW 5시리즈"; q="BMW 5 Series automobile"},
    @{slug="bmw-x3"; name="BMW X3"; q="BMW X3 automobile"},
    @{slug="carnival"; name="카니발"; q="Kia Carnival automobile"},
    @{slug="casper"; name="캐스퍼"; q="Hyundai Casper automobile"},
    @{slug="ev3"; name="EV3"; q="Kia EV3 automobile"},
    @{slug="ev4"; name="EV4"; q="Kia EV4 automobile"},
    @{slug="ev5"; name="EV5"; q="Kia EV5 automobile"},
    @{slug="ev6"; name="EV6"; q="Kia EV6 automobile"},
    @{slug="ev9"; name="EV9"; q="Kia EV9 automobile"},
    @{slug="filante"; name="필랑트"; q="Renault Filante automobile"},
    @{slug="g70"; name="G70"; q="Genesis G70 automobile"},
    @{slug="g80"; name="G80"; q="Genesis G80 automobile"},
    @{slug="g90"; name="G90"; q="Genesis G90 automobile"},
    @{slug="grandeur"; name="그랜저"; q="Hyundai Grandeur Azera automobile"},
    @{slug="grand-koleos"; name="그랑 콜레오스"; q="Renault Grand Koleos automobile"},
    @{slug="gv60"; name="GV60"; q="Genesis GV60 automobile"},
    @{slug="gv70"; name="GV70"; q="Genesis GV70 automobile"},
    @{slug="gv80"; name="GV80"; q="Genesis GV80 automobile"},
    @{slug="ioniq5"; name="아이오닉5"; q="Hyundai Ioniq 5 automobile"},
    @{slug="ioniq6"; name="아이오닉6"; q="Hyundai Ioniq 6 automobile"},
    @{slug="ioniq9"; name="아이오닉9"; q="Hyundai Ioniq 9 automobile"},
    @{slug="k5"; name="K5"; q="Kia K5 automobile"},
    @{slug="k8"; name="K8"; q="Kia K8 automobile"},
    @{slug="kona"; name="코나"; q="Hyundai Kona automobile"},
    @{slug="korando"; name="코란도"; q="SsangYong Korando automobile"},
    @{slug="lexus-es"; name="렉서스 ES"; q="Lexus ES automobile"},
    @{slug="morning"; name="모닝"; q="Kia Picanto Morning automobile"},
    @{slug="musso-khan"; name="무쏘 칸"; q="SsangYong Musso Khan automobile"},
    @{slug="musso-sports"; name="무쏘 스포츠"; q="SsangYong Musso Sports automobile"},
    @{slug="niro"; name="니로"; q="Kia Niro automobile"},
    @{slug="palisade"; name="팰리세이드"; q="Hyundai Palisade automobile"},
    @{slug="qm6"; name="QM6"; q="Renault Samsung QM6 automobile"},
    @{slug="ray"; name="레이"; q="Kia Ray automobile"},
    @{slug="rexton"; name="렉스턴"; q="SsangYong Rexton automobile"},
    @{slug="santafe"; name="싼타페"; q="Hyundai Santa Fe automobile"},
    @{slug="scenic-e-tech"; name="세닉 E-Tech"; q="Renault Scenic E-Tech automobile"},
    @{slug="seltos"; name="셀토스"; q="Kia Seltos automobile"},
    @{slug="sonata"; name="쏘나타"; q="Hyundai Sonata automobile"},
    @{slug="sorento"; name="쏘렌토"; q="Kia Sorento automobile"},
    @{slug="sportage"; name="스포티지"; q="Kia Sportage automobile"},
    @{slug="staria"; name="스타리아"; q="Hyundai Staria automobile"},
    @{slug="tesla-model-3"; name="테슬라 모델3"; q="Tesla Model 3 automobile"},
    @{slug="tesla-model-y"; name="테슬라 모델Y"; q="Tesla Model Y automobile"},
    @{slug="torres"; name="토레스"; q="SsangYong Torres automobile"},
    @{slug="torres-evx"; name="토레스 EVX"; q="KGM Torres EVX automobile"},
    @{slug="tucson"; name="투싼"; q="Hyundai Tucson automobile"},
    @{slug="volvo-xc60"; name="볼보 XC60"; q="Volvo XC60 automobile"}
)

$headers = @{ "User-Agent" = "HappyRentmallImageCollector/1.0" }

function Get-CommonsImage {
    param([string]$Query)

    $encoded = [uri]::EscapeDataString($Query)
    $api = "https://commons.wikimedia.org/w/api.php?action=query&generator=search&gsrnamespace=6&gsrlimit=8&gsrsearch=$encoded&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=1400&format=json&formatversion=2"
    $data = Invoke-RestMethod -Uri $api -Headers $headers -TimeoutSec 35

    if (-not $data.query.pages) { return $null }

    $candidates = @(
        $data.query.pages |
        Where-Object {
            $_.title -match '\.(jpg|jpeg|png)$' -and
            $_.title -notmatch '(logo|badge|interior|dashboard|engine|wheel|diagram|map)'
        }
    )

    if ($candidates.Count -eq 0) {
        $candidates = @($data.query.pages | Where-Object { $_.title -match '\.(jpg|jpeg|png)$' })
    }

    foreach ($page in $candidates) {
        $ii = $page.imageinfo[0]
        if ($ii.thumburl) {
            return [pscustomobject]@{
                Url        = $ii.thumburl
                PageUrl    = $ii.descriptionurl
                Title      = $page.title
                Artist     = $ii.extmetadata.Artist.value
                License    = $ii.extmetadata.LicenseShortName.value
                LicenseUrl = $ii.extmetadata.LicenseUrl.value
            }
        }
    }

    return $null
}

$ok = 0
$fail = @()
$credits = @()

foreach ($car in $cars) {
    Write-Host "수집:" $car.name

    try {
        $image = Get-CommonsImage -Query $car.q

        if (-not $image) {
            $fail += $car
            Write-Host "  → 검색 실패"
            continue
        }

        $out = Join-Path $assetDir ($car.slug + ".jpg")
        Invoke-WebRequest -Uri $image.Url -Headers $headers -OutFile $out -TimeoutSec 45

        if ((Get-Item $out).Length -lt 10000) {
            Remove-Item $out -Force -ErrorAction SilentlyContinue
            $fail += $car
            Write-Host "  → 이미지 크기 이상"
            continue
        }

        $credits += [pscustomobject]@{
            Car        = $car.name
            Slug       = $car.slug
            SourceFile = $image.Title
            SourcePage = $image.PageUrl
            License    = $image.License
            LicenseUrl = $image.LicenseUrl
            Artist     = ($image.Artist -replace '<[^>]+>',' ')
        }

        $ok++
        Write-Host "  → 완료:" (Split-Path $out -Leaf)
    }
    catch {
        $fail += $car
        Write-Host "  → 실패:" $_.Exception.Message
    }

    Start-Sleep -Milliseconds 250
}

$credits | Export-Csv (Join-Path $assetDir "image-credits.csv") -NoTypeInformation -Encoding UTF8

$changed = 0

foreach ($car in $cars) {
    $file = Join-Path $root ("cars\" + $car.slug + "\index.html")
    $imgFile = Join-Path $assetDir ($car.slug + ".jpg")

    if (-not (Test-Path $file) -or -not (Test-Path $imgFile)) { continue }

    $html = Get-Content $file -Raw -Encoding UTF8
    $before = $html
    $relImg = "../../assets/cars/$($car.slug).jpg"

    $matches = [regex]::Matches(
        $html,
        '(?is)<div class="review-car-image[^"]*"[^>]*>.*?</div>'
    )

    if ($matches.Count -ge 3) {
        for ($i = 2; $i -ge 0; $i--) {
            $m = $matches[$i]
            $n = $i + 1
            $replacement = "<div class=`"review-car-image car-review-photo car-review-photo-$n`" style=`"background-image:url('$relImg')`"></div>"
            $html = $html.Remove($m.Index,$m.Length).Insert($m.Index,$replacement)
        }
    }

    if ($html -ne $before) {
        Set-Content $file $html -Encoding UTF8
        $changed++
    }
}

$cssPath = Join-Path $root "styles.css"
$css = Get-Content $cssPath -Raw -Encoding UTF8

if ($css -notmatch 'CAR REVIEW REAL PHOTOS V1') {
$photoCss = @'

/* ===== CAR REVIEW REAL PHOTOS V1 ===== */
.car-review-photo{
  min-height:190px;
  background-size:cover !important;
  background-repeat:no-repeat !important;
  background-position:center !important;
}
.car-review-photo-1{ background-position:center 52% !important; }
.car-review-photo-2{
  background-position:center 42% !important;
  filter:saturate(.96) contrast(1.03);
}
.car-review-photo-3{
  background-position:center 60% !important;
  filter:brightness(.97);
}
/* ===== END CAR REVIEW REAL PHOTOS V1 ===== */

'@
    Add-Content $cssPath $photoCss -Encoding UTF8
}

Write-Host ""
Write-Host "차량 사진 수집 성공:" $ok
Write-Host "차량 사진 수집 실패:" $fail.Count
Write-Host "차종 페이지 이미지 적용:" $changed
Write-Host "출처 파일:" (Join-Path $assetDir "image-credits.csv")

if ($fail.Count -gt 0) {
    Write-Host ""
    Write-Host "=== 수집 실패 차종 ==="
    $fail | ForEach-Object { Write-Host $_.slug "|" $_.name }
}
