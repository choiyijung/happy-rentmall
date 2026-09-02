$ErrorActionPreference = "Stop"

$root = "D:\happy-rentmall"
$dataFile = Join-Path $root "data\legal-dong\법정동코드 전체자료.txt"

$legal = Get-Content $dataFile -Encoding Default |
    ConvertFrom-Csv -Delimiter "`t" |
    Where-Object { $_.폐지여부 -eq "존재" }

$regionOfficial = [ordered]@{
    "seoul"     = "서울특별시"
    "busan"     = "부산광역시"
    "daegu"     = "대구광역시"
    "incheon"   = "인천광역시"
    "gwangju"   = "광주광역시"
    "daejeon"   = "대전광역시"
    "ulsan"     = "울산광역시"
    "sejong"    = "세종특별자치시"
    "gyeonggi"  = "경기도"
    "gangwon"   = "강원특별자치도"
    "chungbuk"  = "충청북도"
    "chungnam"  = "충청남도"
    "jeonbuk"   = "전북특별자치도"
    "jeonnam"   = "전라남도"
    "gyeongbuk" = "경상북도"
    "gyeongnam" = "경상남도"
    "jeju"      = "제주특별자치도"
}

$regionDisplay = @{
    "seoul"="서울"; "busan"="부산"; "daegu"="대구"
    "incheon"="인천"; "gwangju"="광주"; "daejeon"="대전"
    "ulsan"="울산"; "sejong"="세종"; "gyeonggi"="경기"
    "gangwon"="강원"; "chungbuk"="충북"; "chungnam"="충남"
    "jeonbuk"="전북"; "jeonnam"="전남"; "gyeongbuk"="경북"
    "gyeongnam"="경남"; "jeju"="제주"
}

function Get-DirectChildren {
    param([string]$Prefix)

    $depth = ($Prefix -split '\s+').Count

    @(
        $legal |
        Where-Object {
            $_.법정동명 -like "$Prefix *" -and
            (($_.법정동명 -split '\s+').Count -eq ($depth + 1))
        }
    )
}

function Get-LastName {
    param([string]$FullName)

    return ($FullName -split '\s+')[-1]
}

function Set-RootPrefix {
    param(
        [string]$Html,
        [string]$Prefix
    )

    $Html = [regex]::Replace(
        $Html,
        'href="(?:\.\./)+styles\.css"',
        'href="' + $Prefix + 'styles.css"'
    )

    $Html = [regex]::Replace(
        $Html,
        'src="(?:\.\./)+script\.js"',
        'src="' + $Prefix + 'script.js"'
    )

    $Html = [regex]::Replace(
        $Html,
        'href="(?:\.\./)+privacy\.html"',
        'href="' + $Prefix + 'privacy.html"'
    )

    $Html = [regex]::Replace(
        $Html,
        'href="(?:\.\./)+terms\.html"',
        'href="' + $Prefix + 'terms.html"'
    )

    $Html = [regex]::Replace(
        $Html,
        'href="(?:\.\./)+reviews/index\.html"',
        'href="' + $Prefix + 'reviews/index.html"'
    )

    $Html = [regex]::Replace(
        $Html,
        'href="(?:\.\./)+index\.html(?<frag>#[^"]*)?"',
        {
            param($m)

            'href="' +
            $Prefix +
            'index.html' +
            $m.Groups['frag'].Value +
            '"'
        }
    )

    return $Html
}

function Set-PageMeta {
    param(
        [string]$Html,
        [string]$Location
    )

    $title = "$Location 장기렌트·자동차리스 가격비교 | 행복한렌트몰"

    $desc = "$Location 장기렌트와 자동차리스 이용조건을 행복한렌트몰에서 비교하고 차량별 견적과 지역별 상담 정보를 확인해보세요."

    $Html = [regex]::Replace(
        $Html,
        '<title>.*?</title>',
        "<title>$title</title>",
        1
    )

    $Html = [regex]::Replace(
        $Html,
        '<meta name="description" content="[^"]*">',
        "<meta name=`"description`" content=`"$desc`">",
        1
    )

    $Html = [regex]::Replace(
        $Html,
        '<meta property="og:title" content="[^"]*">',
        "<meta property=`"og:title`" content=`"$title`">",
        1
    )

    $Html = [regex]::Replace(
        $Html,
        '<meta property="og:description" content="[^"]*">',
        "<meta property=`"og:description`" content=`"$desc`">",
        1
    )

    return $Html
}

function New-RegionGrid {
    param(
        [array]$Items
    )

    $grid = '<div class="bottom-region-grid">' + "`r`n"

    foreach ($item in $Items) {

        $grid +=
            '  <a href="' +
            $item.Href +
            '">' +
            $item.Name +
            ' 바로상담</a>' +
            "`r`n"
    }

    $grid += '</div>'

    return $grid
}

function Replace-RegionGrid {
    param(
        [string]$Html,
        [string]$Grid
    )

    return [regex]::Replace(
        $Html,
        '(?s)<div class="bottom-region-grid">.*?</div>',
        $Grid,
        1
    )
}

$generalGuCreated = 0
$leafCreated = 0

foreach ($regionSlug in $regionOfficial.Keys) {

    $regionPage = Join-Path $root "$regionSlug\index.html"

    if (-not (Test-Path $regionPage)) {
        continue
    }

    $regionHtml = Get-Content $regionPage -Raw -Encoding UTF8

    # 광역페이지에 연결된 253개 시·군·구/세종 지역 추출
    $parentLinks = [regex]::Matches(
        $regionHtml,
        '<a href="\./([^/]+)/index\.html">([^<]+) 바로상담</a>'
    )

    # 세종처럼 최하위 자체 페이지인 경우를 위한 형제 목록
    $allParentItems = @()

    foreach ($parentLink in $parentLinks) {

        $allParentItems += [pscustomobject]@{
            Name = $parentLink.Groups[2].Value
            Slug = $parentLink.Groups[1].Value
        }
    }

    foreach ($parentLink in $parentLinks) {

        $parentSlug = $parentLink.Groups[1].Value
        $parentName = $parentLink.Groups[2].Value

        $parentFolder = Join-Path $root "$regionSlug\$parentSlug"
        $parentPage   = Join-Path $parentFolder "index.html"

        if (-not (Test-Path $parentPage)) {
            continue
        }

        $parentHtml = Get-Content $parentPage -Raw -Encoding UTF8

        $officialPrefix =
            "$($regionOfficial[$regionSlug]) $parentName"

        $children = @(Get-DirectChildren $officialPrefix)

        # 시 아래 일반구 여부 확인
        $generalGus = @(
            $children |
            Where-Object {
                (Get-LastName $_.법정동명) -match '구$'
            }
        )

        if ($generalGus.Count -gt 0) {

            # ---------------------------------------
            # 예: 경기 → 수원시 → 장안구 → 파장동
            # ---------------------------------------

            $guParentItems = @()

            foreach ($gu in $generalGus) {

                $guName = Get-LastName $gu.법정동명
                $guFolder = Join-Path $parentFolder $guName
                $guPage = Join-Path $guFolder "index.html"

                New-Item -ItemType Directory -Force $guFolder | Out-Null

                $guParentItems += [pscustomobject]@{
                    Name = $guName
                    Href = "./$guName/index.html"
                }

                $leafs = @(
                    Get-DirectChildren $gu.법정동명 |
                    Where-Object {
                        (Get-LastName $_.법정동명) -match '(동|읍|면)$'
                    }
                )

                # 일반구 페이지의 동 버튼
                $guLeafItems = @()

                foreach ($leaf in $leafs) {

                    $leafName = Get-LastName $leaf.법정동명

                    $guLeafItems += [pscustomobject]@{
                        Name = $leafName
                        Href = "./$leafName/index.html"
                    }
                }

                # 수원시 페이지를 그대로 복제 → 장안구 페이지
                $guHtml = Set-RootPrefix `
                    -Html $parentHtml `
                    -Prefix "../../../"

                $guHtml = Set-PageMeta `
                    -Html $guHtml `
                    -Location "$($regionDisplay[$regionSlug]) $parentName $guName"

                $guGrid = New-RegionGrid $guLeafItems

                $guHtml = Replace-RegionGrid `
                    -Html $guHtml `
                    -Grid $guGrid

                Set-Content $guPage $guHtml -Encoding UTF8

                $generalGuCreated++

                # 최하위 동 페이지에서는 같은 구의 동 목록을 계속 표시
                $leafSiblingItems = @()

                foreach ($sibling in $leafs) {

                    $siblingName = Get-LastName $sibling.법정동명

                    $leafSiblingItems += [pscustomobject]@{
                        Name = $siblingName
                        Href = "../$siblingName/index.html"
                    }
                }

                $leafSiblingGrid = New-RegionGrid $leafSiblingItems

                foreach ($leaf in $leafs) {

                    $leafName = Get-LastName $leaf.법정동명

                    $leafFolder = Join-Path $guFolder $leafName
                    $leafPage = Join-Path $leafFolder "index.html"

                    New-Item -ItemType Directory -Force $leafFolder | Out-Null

                    $leafHtml = Set-RootPrefix `
                        -Html $guHtml `
                        -Prefix "../../../../"

                    $leafHtml = Set-PageMeta `
                        -Html $leafHtml `
                        -Location "$($regionDisplay[$regionSlug]) $parentName $guName $leafName"

                    $leafHtml = Replace-RegionGrid `
                        -Html $leafHtml `
                        -Grid $leafSiblingGrid

                    Set-Content $leafPage $leafHtml -Encoding UTF8

                    $leafCreated++
                }
            }

            # 수원시 페이지 하단은 4개 일반구로 변경
            $parentGrid = New-RegionGrid $guParentItems

            $parentHtml = Replace-RegionGrid `
                -Html $parentHtml `
                -Grid $parentGrid

            Set-Content $parentPage $parentHtml -Encoding UTF8
        }
        else {

            # ---------------------------------------
            # 예: 서울 → 강남구 → 역삼동
            #     경기 → 김포시 → 구래동
            #     강원 → 홍천군 → 홍천읍
            # ---------------------------------------

            $leafs = @(
                $children |
                Where-Object {
                    (Get-LastName $_.법정동명) -match '(동|읍|면)$'
                }
            )

            if ($leafs.Count -gt 0) {

                # 상위 페이지 하단 링크
                $parentLeafItems = @()

                foreach ($leaf in $leafs) {

                    $leafName = Get-LastName $leaf.법정동명

                    $parentLeafItems += [pscustomobject]@{
                        Name = $leafName
                        Href = "./$leafName/index.html"
                    }
                }

                $parentGrid = New-RegionGrid $parentLeafItems

                $parentHtml = Replace-RegionGrid `
                    -Html $parentHtml `
                    -Grid $parentGrid

                Set-Content $parentPage $parentHtml -Encoding UTF8

                # 최하위 페이지에서는 같은 상위지역의 형제 동·읍·면 표시
                $leafSiblingItems = @()

                foreach ($leaf in $leafs) {

                    $leafName = Get-LastName $leaf.법정동명

                    $leafSiblingItems += [pscustomobject]@{
                        Name = $leafName
                        Href = "../$leafName/index.html"
                    }
                }

                $leafSiblingGrid = New-RegionGrid $leafSiblingItems

                foreach ($leaf in $leafs) {

                    $leafName = Get-LastName $leaf.법정동명

                    $leafFolder = Join-Path $parentFolder $leafName
                    $leafPage = Join-Path $leafFolder "index.html"

                    New-Item -ItemType Directory -Force $leafFolder | Out-Null

                    $leafHtml = Set-RootPrefix `
                        -Html $parentHtml `
                        -Prefix "../../../"

                    $leafHtml = Set-PageMeta `
                        -Html $leafHtml `
                        -Location "$($regionDisplay[$regionSlug]) $parentName $leafName"

                    $leafHtml = Replace-RegionGrid `
                        -Html $leafHtml `
                        -Grid $leafSiblingGrid

                    Set-Content $leafPage $leafHtml -Encoding UTF8

                    $leafCreated++
                }
            }
            else {

                # 세종의 읍·면·동처럼 현재 페이지 자체가 최하위인 경우
                # 죽은 '세부지역' 버튼 대신 같은 세종 지역 형제 버튼 표시
                $siblingItems = @()

                foreach ($sibling in $allParentItems) {

                    $siblingItems += [pscustomobject]@{
                        Name = $sibling.Name
                        Href = "../$($sibling.Slug)/index.html"
                    }
                }

                if ($siblingItems.Count -gt 0) {

                    $siblingGrid = New-RegionGrid $siblingItems

                    $parentHtml = Replace-RegionGrid `
                        -Html $parentHtml `
                        -Grid $siblingGrid

                    Set-Content $parentPage $parentHtml -Encoding UTF8
                }
            }
        }
    }
}

Write-Host ""
Write-Host "일반구 페이지 생성:" $generalGuCreated
Write-Host "동·읍·면 페이지 생성:" $leafCreated
Write-Host "추가 페이지 합계:" ($generalGuCreated + $leafCreated)

Write-Host ""
Write-Host "강남구 역삼동 존재:" `
    (Test-Path ".\seoul\gangnam-gu\역삼동\index.html")

Write-Host "수원 장안구 존재:" `
    (Test-Path ".\gyeonggi\suwon-si\장안구\index.html")

Write-Host "수원 장안구 파장동 존재:" `
    (Test-Path ".\gyeonggi\suwon-si\장안구\파장동\index.html")

Write-Host "김포 구래동 존재:" `
    (Test-Path ".\gyeonggi\gimpo-si\구래동\index.html")

Write-Host "홍천 홍천읍 존재:" `
    (Test-Path ".\gangwon\hongcheon-gun\홍천읍\index.html")

Write-Host ""
Write-Host "수원→장안구 연결:" `
    ((Select-String `
        -Path ".\gyeonggi\suwon-si\index.html" `
        -Pattern './장안구/index.html' `
        -SimpleMatch).Count)

Write-Host "장안구→파장동 연결:" `
    ((Select-String `
        -Path ".\gyeonggi\suwon-si\장안구\index.html" `
        -Pattern './파장동/index.html' `
        -SimpleMatch).Count)
