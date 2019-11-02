package function

import (
	"github.com/openfaas-incubator/go-function-sdk"
	"github.com/stretchr/testify/assert"
	"net/http"
	"testing"
)

func TestHandleReturnsCorrectResponse(t *testing.T) {
	expected := handler.Response{Body: []byte("Hello world, input was: John"), StatusCode: http.StatusOK}
	response, err := Handle(handler.Request{Body: []byte("John"), Method: "GET"})

	assert.Nil(t, err)
	assert.Equal(t, response.StatusCode, expected.StatusCode)
	assert.Equal(t, response.Body, expected.Body)
}
