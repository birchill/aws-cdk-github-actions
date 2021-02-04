FROM alpine:3

RUN apk --update --no-cache add nodejs nodejs-npm jq curl bash git docker && \
	npm install -g yarn && \
	yarn global add esbuild

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
