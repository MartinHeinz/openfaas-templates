module handler

go 1.12

replace handler/function => ./function

require (
	github.com/openfaas-incubator/go-function-sdk v0.0.0-20191017092257-70701da50a91
	github.com/stretchr/testify v1.4.0
)
