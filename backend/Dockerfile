FROM alpine:latest
RUN apk --no-cache add ca-certificates tzdata
WORKDIR /root/

# 复制本地构建的二进制文件
COPY bin/server .
COPY configs ./configs

EXPOSE 8080
CMD ["./server"]
