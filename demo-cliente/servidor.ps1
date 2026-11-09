# Servidor local minimo para mostrar la maqueta de Comercial Sedyjo.
# No instala nada y no necesita internet: sirve la carpeta "maqueta" en http://localhost:PUERTO
param(
    [int]$Puerto = 8099,
    [string]$Pagina = "?cliente=1",
    [switch]$SinNavegador
)

$raiz = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot "maqueta"))
if (-not (Test-Path (Join-Path $raiz "index.html"))) {
    Write-Host "No encuentro la carpeta 'maqueta'. Deja este archivo junto a ella." -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}

$tipos = @{
    ".html" = "text/html; charset=utf-8"; ".js" = "text/javascript; charset=utf-8"; ".mjs" = "text/javascript; charset=utf-8"
    ".json" = "application/json; charset=utf-8"; ".wasm" = "application/wasm"; ".css" = "text/css; charset=utf-8"
    ".webp" = "image/webp"; ".png" = "image/png"; ".jpg" = "image/jpeg"; ".jpeg" = "image/jpeg"; ".ico" = "image/x-icon"
    ".svg" = "image/svg+xml"; ".ttf" = "font/ttf"; ".otf" = "font/otf"; ".woff2" = "font/woff2"
    ".txt" = "text/plain; charset=utf-8"; ".symbols" = "text/plain; charset=utf-8"
}

$escucha = New-Object System.Net.HttpListener
$escucha.Prefixes.Add("http://localhost:$Puerto/")
try {
    $escucha.Start()
} catch {
    Write-Host "No se pudo usar el puerto $Puerto. Cierra otra ventana de la maqueta y vuelve a intentar." -ForegroundColor Red
    Read-Host "Presiona Enter para salir"
    exit 1
}

$direccion = "http://localhost:$Puerto/$Pagina"
Write-Host ""
Write-Host "  Maqueta de Comercial Sedyjo lista" -ForegroundColor Green
Write-Host "  Direccion: $direccion"
Write-Host "  Para terminar, cierra esta ventana."
Write-Host ""
if (-not $SinNavegador) { Start-Process $direccion }

while ($escucha.IsListening) {
    $ctx = $escucha.GetContext()
    try {
        $ruta = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath.TrimStart('/'))
        if ([string]::IsNullOrEmpty($ruta)) { $ruta = "index.html" }
        $archivo = [System.IO.Path]::GetFullPath((Join-Path $raiz $ruta))
        if (-not $archivo.StartsWith($raiz) -or -not (Test-Path $archivo -PathType Leaf)) {
            $ctx.Response.StatusCode = 404
        } else {
            $ext = [System.IO.Path]::GetExtension($archivo).ToLower()
            $tipo = $tipos[$ext]
            if (-not $tipo) { $tipo = "application/octet-stream" }
            $ctx.Response.ContentType = $tipo
            $ctx.Response.Headers.Add("Cache-Control", "no-cache")
            $bytes = [System.IO.File]::ReadAllBytes($archivo)
            $ctx.Response.ContentLength64 = $bytes.Length
            $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
        }
    } catch {
        # El navegador cancelo la descarga: no pasa nada.
    } finally {
        $ctx.Response.Close()
    }
}
