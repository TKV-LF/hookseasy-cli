
# Linux
GOOS=linux GOARCH=amd64 go build -o bundles/tunnel-linux-amd64 main.go
GOOS=linux GOARCH=arm64 go build -o bundles/tunnel-linux-arm64 main.go

# macOS
GOOS=darwin GOARCH=amd64 go build -o bundles/tunnel-darwin-amd64 main.go
GOOS=darwin GOARCH=arm64 go build -o bundles/tunnel-darwin-arm64 main.go

# Windows
GOOS=windows GOARCH=amd64 go build -o bundles/tunnel-windows-amd64.exe main.go
GOOS=windows GOARCH=arm64 go build -o bundles/tunnel-windows-arm64.exe main.go