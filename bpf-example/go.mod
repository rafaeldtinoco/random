module github.com/rafaeldtinoco/example

go 1.21.3

require github.com/aquasecurity/libbpfgo v0.1.1

require golang.org/x/sys v0.0.0-20210514084401-e8d321eab015 // indirect

replace github.com/aquasecurity/libbpfgo => ./libbpfgo
