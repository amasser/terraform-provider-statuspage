#!/usr/bin/make

TFPLAN ?= plan.tfplan
TEST?=$$(go list ./... |grep -v 'vendor')
GOIMAGE ?= golang:1.14

export CGO_ENABLED = 0
export GOFLAGS = -mod=vendor
export GO111MODULE = on
export GOOS = linux
export GOARCH = amd64

all: plan

vet:
	go vet $(TEST)

test: vet
	go test -v $(TEST)

docker-test:
	docker run -t -v $$PWD:/go/src/github.com/yannh/terraform-provider-statuspage -w /go/src/github.com/yannh/terraform-provider-statuspage $(GOIMAGE) make test

build-static:
	go build -tags netgo -ldflags '-extldflags "-static"' -a -o bin/terraform-provider-statuspage

docker-build-static:
	docker run -t -v $$PWD:/go/src/github.com/yannh/terraform-provider-statuspage -w /go/src/github.com/yannh/terraform-provider-statuspage $(GOIMAGE) make build-static

init: test build-static
	terraform init -plugin-dir ./bin

plan: init
	terraform plan -out ${TFPLAN}

acc:
	TF_ACC=1 go test $(TEST) -v -timeout 120m

docker-acc:
	docker run -e DATADOG_API_KEY -e DATADOG_APPLICATION_KEY -e STATUSPAGE_PAGE -e STATUSPAGE_TOKEN -t -v $$PWD:/go/src/github.com/yannh/terraform-provider-statuspage -w /go/src/github.com/yannh/terraform-provider-statuspage $(GOIMAGE) make acc

apply:
	terraform apply ${TFPLAN}

update-sdk:
	GOFLAGS=  go get -u github.com/yannh/statuspage-go-sdk
	go mod vendor
