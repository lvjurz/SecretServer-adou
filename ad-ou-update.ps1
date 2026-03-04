#set some ground variables
$site      = "https://<hostname>/SecretServer" # hostname (ie. https://pam.mydomain.com/SecretServer)
$secretIds = 15, 20       # secret ids to update
$apiusr    = "myapiuser"  # api username
$apipw     = "apiuserpw"  # api password

# optional: keep same field names as before
$ouFieldName     = "OUname"
$targetFieldSlug = "notes"

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.SecurityProtocolType]::Tls12

# ---- get token (same as before) ----
$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$headers.Add("Content-Type", "application/x-www-form-urlencoded")
$body = "username="+$apiusr+"&password="+$apipw+"&grant_type=password"

$response = Invoke-RestMethod "$site/oauth2/token" -Method 'POST' -Headers $headers -Body $body -SessionVariable $xx

$hdr = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$brb = "Bearer "+ $response.access_token
$hdr.Add("Authorization", $brb)

# ---- process each secret ----
foreach ($secretId in $secretIds) {
  try {
    Write-Host "Processing secretId=$secretId ..." -ForegroundColor Cyan

    # read secret
    $rsp = Invoke-RestMethod "$site/api/v2/secrets/$secretId" -Method 'GET' -Headers $hdr -SessionVariable $xx

    # find OU value in the secret (same logic as before)
    $ouValue = $null
    foreach ($z in $rsp.items) {
      if ($z.fieldName -eq $ouFieldName) {
        $ouValue = $z.itemValue
        break
      }
    }

    if ([string]::IsNullOrWhiteSpace($ouValue)) {
      Write-Warning "SecretId: field '$ouFieldName' not found or empty. Skipping."
      continue
    }

    # query AD computers
    $computers = Get-ADComputer -Filter * -SearchBase $ouValue | Select-Object -ExpandProperty Name

    # build comma-separated host list (no trailing comma issues)
    $hostlist = ($computers | Where-Object { $_ } | Sort-Object -Unique) -join ","

    # write hosts to 'Notes' field
    $bd = @{ value = $hostlist } | ConvertTo-Json
    Invoke-RestMethod -Method Put `
      -Uri "$site/api/v1/secrets/$secretId/fields/$targetFieldSlug" `
      -Headers $hdr `
      -ContentType "application/json" `
      -Body $bd | Out-Null

    Write-Host "SecretId=$secretId updated ($($computers.Count) host(s))." -ForegroundColor Green
  }
  catch {
    Write-Error "SecretId=$secretId failed: $($_.Exception.Message)"
  }
}