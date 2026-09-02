$ErrorActionPreference = "Stop"

$root = "D:\happy-rentmall"
$assetDir = Join-Path $root "assets\cars"
New-Item -ItemType Directory -Path $assetDir -Force | Out-Null

$cars = @(
    @{slug="actyon"; name="액티언"; queries=@("KGM Actyon","KG Mobility Actyon","SsangYong Actyon")},
    @{slug="arkana"; name="아르카나"; queries=@("Renault Arkana")},
    @{slug="audi-a6"; name="아우디 A6"; queries=@("Audi A6")},
    @{slug="avante"; name="아반떼"; queries=@("Hyundai Avante","Hyundai Elantra CN7","Hyundai Elantra")},
    @{slug="benz-e-class"; name="벤츠 E클래스"; queries=@("Mercedes-Benz E-Class","Mercedes E-Class")},
    @{slug="benz-glc"; name="벤츠 GLC"; queries=@("Mercedes-Benz GLC","Mercedes GLC")},
    @{slug="bmw-5-series"; name="BMW 5시리즈"; queries=@("BMW 5 Series")},
    @{slug="bmw-x3"; name="BMW X3"; queries=@("BMW X3")},
    @{slug="carnival"; name="카니발"; queries=@("Kia Carnival")},
    @{slug="casper"; name="캐스퍼"; queries=@("Hyundai Casper")},
    @{slug="ev3"; name="EV3"; queries=@("Kia EV3")},
    @{slug="ev4"; name="EV4"; queries=@("Kia EV4")},
    @{slug="ev5"; name="EV5"; queries=@("Kia EV5")},
    @{slug="ev6"; name="EV6"; queries=@("Kia EV6")},
    @{slug="ev9"; name="EV9"; queries=@("Kia EV9")},
    @{slug="filante"; name="필랑트"; queries=@("Renault Filante")},
    @{slug="g70"; name="G70"; queries=@("Genesis G70")},
    @{slug="g80"; name="G80"; queries=@("Genesis G80","2024 Genesis G80")},
    @{slug="g90"; name="G90"; queries=@("Genesis G90")},
    @{slug="grandeur"; name="그랜저"; queries=@("Hyundai Grandeur","Hyundai Azera")},
    @{slug="grand-koleos"; name="그랑 콜레오스"; queries=@("Renault Grand Koleos","Grand Koleos")},
    @{slug="gv60"; name="GV60"; queries=@("Genesis GV60")},
    @{slug="gv70"; name="GV70"; queries=@("Genesis GV70")},
    @{slug="gv80"; name="GV80"; queries=@("Genesis GV80")},
    @{slug="ioniq5"; name="아이오닉5"; queries=@("Hyundai Ioniq 5")},
    @{slug="ioniq6"; name="아이오닉6"; queries=@("Hyundai Ioniq 6")},
    @{slug="ioniq9"; name="아이오닉9"; queries=@("Hyundai Ioniq 9","2026 Hyundai Ioniq 9")},
    @{slug="k5"; name="K5"; queries=@("Kia K5","Kia Optima DL3")},
    @{slug="k8"; name="K8"; queries=@("Kia K8")},
    @{slug="kona"; name="코나"; queries=@("Hyundai Kona")},
    @{slug="korando"; name="코란도"; queries=@("SsangYong Korando","KGM Korando")},
    @{slug="lexus-es"; name="렉서스 ES"; queries=@("Lexus ES")},
    @{slug="morning"; name="모닝"; queries=@("Kia Morning","Kia Picanto")},
    @{slug="musso-khan"; name="무쏘 칸"; queries=@("SsangYong Musso Khan","KGM Musso Khan","SsangYong Musso")},
    @{slug="musso-sports"; name="무쏘 스포츠"; queries=@("SsangYong Musso Sports","KGM Musso Sports","SsangYong Musso")},
    @{slug="niro"; name="니로"; queries=@("Kia Niro")},
    @{slug="palisade"; name="팰리세이드"; queries=@("Hyundai Palisade")},
    @{slug="qm6"; name="QM6"; queries=@("Renault Samsung QM6","Renault Korea QM6","Renault Koleos QM6")},
    @{slug="ray"; name="레이"; queries=@("Kia Ray")},
    @{slug="rexton"; name="렉스턴"; queries=@("SsangYong Rexton","KGM Rexton")},
    @{slug="santafe"; name="싼타페"; queries=@("Hyundai Santa Fe")},
    @{slug="scenic-e-tech"; name="세닉 E-Tech"; queries=@("Renault Scenic E-Tech","Renault Scenic E Tech")},
    @{slug="seltos"; name="셀토스"; queries=@("Kia Seltos")},
    @{slug="sonata"; name="쏘나타"; queries=@("Hyundai Sonata")},
    @{slug="sorento"; name="쏘렌토"; queries=@("Kia Sorento")},
    @{slug="sportage"; name="스포티지"; queries=@("Kia Sportage")},
    @{slug="staria"; name="스타리아"; queries=@("Hyundai Staria")},
    @{slug="tesla-model-3"; name="테슬라 모델3"; queries=@("Tesla Model 3")},
    @{slug="tesla-model-y"; name="테슬라 모델Y"; queries=@("Tesla Model Y")},
    @{slug="torres"; name="토레스"; queries=@("KGM Torres","SsangYong Torres")},
    @{slug="torres-evx"; name="토레스 EVX"; queries=@("KGM Torres EVX","SsangYong Torres EVX")},
    @{slug="tucson"; name="투싼"; queries=@("Hyundai Tucson")},
    @{slug="volvo-xc60"; name="볼보 XC60"; queries=@("Volvo XC60")}
)

$headers = @{
    "User-Agent" = "HappyRentmallImageCollector/2.0"
}

function Get-ImageInfoFromCommonsTitle {
    param([string]$Title)

    $encodedTitle = [uri]::EscapeDataString($Title)
    $api = "https://commons.wikimedia.org/w/api.php?action=query&titles=$encodedTitle&prop=imageinfo&iiprop=url|extmetadata&iiurlwidth=1400&format=json&formatversion=2"

    try {
        $data = Invoke-RestMethod -Uri $api -Headers $headers -TimeoutSec 30
        $page = @($data.query.pages)[0]

        if (-not $page.imageinfo) {
            return $null
        }

        $ii = $page.imageinfo[0]
        $downloadUrl = $ii.thumburl

        if (-not $downloadUrl) {
            $downloadUrl = $ii.url
        }

        if (-not $downloadUrl) {
            return $null
        }

        return [pscustomobject]@{
            Url        = $downloadUrl
            PageUrl    = $ii.descriptionurl
            Title      = $Title
            Artist     = $ii.extmetadata.Artist.value
            License    = $ii.extmetadata.LicenseShortName.value
            LicenseUrl = $ii.extmetadata.LicenseUrl.value
            Source     = "Wikimedia Commons"
        }
    }
    catch {
        return $null
    }
}

function Find-CommonsImage {
    param([string]$Query)

    $encoded = [uri]::EscapeDataString($Query)
    $api = "https://commons.wikimedia.org/w/api.php?action=query&list=search&srnamespace=6&srlimit=30&srsearch=$encoded&format=json&formatversion=2"

    try {
        $data = Invoke-RestMethod -Uri $api -Headers $headers -TimeoutSec 30
    }
    catch {
        return $null
    }

    $hits = @($data.query.search)

    # 먼저 실제 차량 외관 사진으로 보이는 제목 우선
    $preferred = @(
        $hits | Where-Object {
            $_.title -match '\.(jpg|jpeg|png|webp)$' -and
            $_.title -notmatch '(logo|badge|emblem|interior|dashboard|engine|wheel|rim|diagram|map|brochure|advert|render)'
        }
    )

    $fallback = @(
        $hits | Where-Object {
            $_.title -match '\.(jpg|jpeg|png|webp)$'
        }
    )

    foreach ($hit in @($preferred + $fallback)) {
        $info = Get-ImageInfoFromCommonsTitle -Title $hit.title
        if ($info) {
            return $info
        }
    }

    return $null
}

function Find-WikipediaLeadImage {
    param(
        [string]$Query,
        [string]$WikiHost
    )

    $encoded = [uri]::EscapeDataString($Query)
    $searchApi = "https://$WikiHost/w/api.php?action=query&list=search&srnamespace=0&srlimit=6&srsearch=$encoded&format=json&formatversion=2"

    try {
        $search = Invoke-RestMethod -Uri $searchApi -Headers $headers -TimeoutSec 30
    }
    catch {
        return $null
    }

    foreach ($hit in @($search.query.search)) {
        $pageId = $hit.pageid
        $imgApi = "https://$WikiHost/w/api.php?action=query&pageids=$pageId&prop=pageimages&piprop=name|thumbnail|original&pithumbsize=1400&format=json&formatversion=2"

        try {
            $pageData = Invoke-RestMethod -Uri $imgApi -Headers $headers -TimeoutSec 30
            $page = @($pageData.query.pages)[0]

            if ($page.pageimage) {
                $commonsTitle = "File:" + $page.pageimage
                $info = Get-ImageInfoFromCommonsTitle -Title $commonsTitle

                if ($info) {
                    return $info
                }
            }
        }
        catch {
        }
    }

    return $null
}

$creditsPath = Join-Path $assetDir "image-credits.csv"
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
$okExisting = 0
$okNew = 0
$fail = @()

foreach ($car in $cars) {
    $out = Join-Path $assetDir ($car.slug + ".jpg")

    if ((Test-Path $out) -and ((Get-Item $out).Length -ge 10000)) {
        $okExisting++
        Write-Host "기존 유지:" $car.name
        continue
    }

    Write-Host "수집:" $car.name
    $found = $null

    foreach ($q in $car.queries) {
        if (-not $found) {
            $found = Find-CommonsImage -Query $q
        }
    }

    if (-not $found) {
        foreach ($q in $car.queries) {
            if (-not $found) {
                $found = Find-WikipediaLeadImage -Query $q -Host "en.wikipedia.org"
            }
        }
    }

    if (-not $found) {
        foreach ($q in $car.queries) {
            if (-not $found) {
                $found = Find-WikipediaLeadImage -Query $q -Host "ko.wikipedia.org"
            }
        }
    }

    if (-not $found) {
        $fail += $car
        Write-Host "  → 최종 실패"
        continue
    }

    try {
        Invoke-WebRequest -Uri $found.Url -Headers $headers -OutFile $out -TimeoutSec 45

        if ((Get-Item $out).Length -lt 10000) {
            Remove-Item $out -Force -ErrorAction SilentlyContinue
            $fail += $car
            Write-Host "  → 다운로드 파일 이상"
            continue
        }

        $credits = @(
            $credits | Where-Object { $_.Slug -ne $car.slug }
        )

        $credits += [pscustomobject]@{
            Car        = $car.name
            Slug       = $car.slug
            SourceFile = $found.Title
            SourcePage = $found.PageUrl
            License    = $found.License
            LicenseUrl = $found.LicenseUrl
            Artist     = ($found.Artist -replace '<[^>]+>',' ')
            Source     = $found.Source
        }

        $okNew++
        Write-Host "  → 완료:" ($car.slug + ".jpg")
    }
    catch {
        Remove-Item $out -Force -ErrorAction SilentlyContinue
        $fail += $car
        Write-Host "  → 다운로드 실패:" $_.Exception.Message
    }

    Start-Sleep -Milliseconds 180
}

$credits |
    Sort-Object Slug |
    Export-Csv $creditsPath -NoTypeInformation -Encoding UTF8

# 후기 문구 + 후기 이미지까지 차종별로 변경
$reviewOpen = @(
    "{0} 장기렌트 조건을 비교하면서 계약기간과 초기비용을 함께 확인했습니다.",
    "{0} 신차 이용을 준비하며 월 납입 조건과 계약기간을 나누어 살펴봤습니다.",
    "{0} 견적을 알아보면서 보증금과 선납금 방식에 따른 차이를 비교했습니다.",
    "{0}을 장기간 이용할 계획이라 계약조건과 월 이용금액을 함께 확인했습니다.",
    "{0} 신차장기렌트 견적을 여러 조건으로 비교해봤습니다."
)

$reviewMiddle = @(
    "연간 주행거리까지 같은 기준으로 맞춰보니 조건별 차이를 파악하기 쉬웠습니다.",
    "초기 부담과 월 비용을 따로 확인할 수 있어 계약 방향을 정리하기 편했습니다.",
    "월 이용료만 보는 것보다 전체 조건을 함께 살펴보는 데 도움이 됐습니다.",
    "렌트와 리스의 조건을 한 화면에서 비교할 수 있어 선택 기준을 잡기 수월했습니다.",
    "계약기간에 따라 달라지는 비용 구성을 확인하면서 필요한 조건을 정리할 수 있었습니다."
)

$reviewClose = @(
    "{0} 이용 계획에 맞는 견적 범위를 확인할 수 있었습니다.",
    "{0} 계약 전에 필요한 항목을 순서대로 살펴볼 수 있었습니다.",
    "{0}을 이용할 때 어떤 계약조건을 봐야 하는지 정리하기 쉬웠습니다.",
    "{0} 신차 견적의 주요 항목을 비교해서 확인할 수 있었습니다.",
    "{0} 렌트·리스 조건을 비교하는 데 참고하기 좋았습니다."
)

$pagesChanged = 0
$imagePages = 0

foreach ($car in $cars) {
    $file = Join-Path $root ("cars\" + $car.slug + "\index.html")

    if (-not (Test-Path $file)) {
        continue
    }

    $html = Get-Content $file -Raw -Encoding UTF8
    $before = $html

    $carName = $car.name
    $seed = [Math]::Abs($car.slug.GetHashCode())

    $p1 = ($reviewOpen[$seed % $reviewOpen.Count] -f $carName) + " " +
          $reviewMiddle[($seed + 1) % $reviewMiddle.Count]

    $p2 = ($reviewOpen[($seed + 2) % $reviewOpen.Count] -f $carName) + " " +
          ($reviewClose[($seed + 3) % $reviewClose.Count] -f $carName)

    $p3 = $reviewMiddle[($seed + 4) % $reviewMiddle.Count] + " " +
          ($reviewClose[($seed + 1) % $reviewClose.Count] -f $carName)

    $imgFile = Join-Path $assetDir ($car.slug + ".jpg")
    $img1 = '<div class="review-car-image review-car-1"></div>'
    $img2 = '<div class="review-car-image review-car-2"></div>'
    $img3 = '<div class="review-car-image review-car-3"></div>'

    if (Test-Path $imgFile) {
        $relImg = "../../assets/cars/$($car.slug).jpg"
        $img1 = "<div class=`"review-car-image car-review-photo car-review-photo-1`" style=`"background-image:url('$relImg')`"></div>"
        $img2 = "<div class=`"review-car-image car-review-photo car-review-photo-2`" style=`"background-image:url('$relImg')`"></div>"
        $img3 = "<div class=`"review-car-image car-review-photo car-review-photo-3`" style=`"background-image:url('$relImg')`"></div>"
        $imagePages++
    }

    $cards = @(
@"
<article class="review-card-new">
  $img1
  <div class="review-card-body">
    <div class="review-stars-new">★★★★★</div>
    <h3>$carName 장기렌트 상담</h3>
    <p>$p1</p>
    <div class="review-bottom">
      <span>장기렌트 비교</span>
      <span>이용후기 예시</span>
    </div>
  </div>
</article>
"@,
@"
<article class="review-card-new">
  $img2
  <div class="review-card-body">
    <div class="review-stars-new">★★★★★</div>
    <h3>$carName 신차리스 비교</h3>
    <p>$p2</p>
    <div class="review-bottom">
      <span>리스 조건 확인</span>
      <span>이용후기 예시</span>
    </div>
  </div>
</article>
"@,
@"
<article class="review-card-new">
  $img3
  <div class="review-card-body">
    <div class="review-stars-new">★★★★★</div>
    <h3>$carName 견적 조건 확인</h3>
    <p>$p3</p>
    <div class="review-bottom">
      <span>견적 비교</span>
      <span>이용후기 예시</span>
    </div>
  </div>
</article>
"@
    )

    $matches = [regex]::Matches(
        $html,
        '(?is)<article class="review-card-new">.*?</article>'
    )

    if ($matches.Count -ge 3) {
        for ($i = 2; $i -ge 0; $i--) {
            $m = $matches[$i]
            $html = $html.Remove($m.Index,$m.Length).Insert($m.Index,$cards[$i])
        }
    }

    # 차종 페이지 견적폼 예시도 현재 차종으로 표시
    $html = [regex]::Replace(
        $html,
        '(<input\s+name="car"\s+type="text"\s+placeholder=")[^"]*(")',
        ('$1예: ' + $carName + '$2'),
        1
    )

    if ($html -ne $before) {
        Set-Content $file $html -Encoding UTF8
        $pagesChanged++
    }
}

$cssPath = Join-Path $root "styles.css"
$css = Get-Content $cssPath -Raw -Encoding UTF8

if ($css -notmatch 'CAR REVIEW REAL PHOTOS V2') {
$photoCss = @'

/* ===== CAR REVIEW REAL PHOTOS V2 ===== */
.car-review-photo{
  min-height:190px;
  background-size:cover !important;
  background-repeat:no-repeat !important;
  background-position:center !important;
}
.car-review-photo-1{ background-position:center 52% !important; }
.car-review-photo-2{ background-position:center 43% !important; }
.car-review-photo-3{ background-position:center 60% !important; }
/* ===== END CAR REVIEW REAL PHOTOS V2 ===== */

'@
    Add-Content $cssPath $photoCss -Encoding UTF8
}

$totalImages = (
    Get-ChildItem $assetDir -File -Filter "*.jpg" -ErrorAction SilentlyContinue
).Count

Write-Host ""
Write-Host "=============================="
Write-Host "기존 차량 사진:" $okExisting
Write-Host "이번 추가 수집:" $okNew
Write-Host "현재 차량 사진 총:" $totalImages
Write-Host "최종 수집 실패:" $fail.Count
Write-Host "차종별 후기 수정 페이지:" $pagesChanged
Write-Host "실사진 적용 차종 페이지:" $imagePages
Write-Host "출처 파일:" $creditsPath

if ($fail.Count -gt 0) {
    Write-Host ""
    Write-Host "=== 최종 실패 차종 ==="
    $fail | ForEach-Object { Write-Host $_.slug "|" $_.name }
}

