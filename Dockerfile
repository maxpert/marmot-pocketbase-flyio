FROM debian:bookworm-slim

ARG PB_VERSION=0.16.6
ARG MARMOT_VERSION=v0.8.4-beta.3

RUN apt update && apt install unzip dnsutils sqlite3 curl wget -y
    

# download and unzip PocketBase
COPY run.sh /pb/run.sh
COPY pb_data.tar.gz /pb/pb_data.tar.gz
ADD https://github.com/pocketbase/pocketbase/releases/download/v${PB_VERSION}/pocketbase_${PB_VERSION}_linux_amd64.zip /tmp/pb.zip
ADD https://github.com/maxpert/marmot/releases/download/${MARMOT_VERSION}/marmot-${MARMOT_VERSION}-linux-amd64.tar.gz /tmp/marmot.tar.gz
RUN unzip /tmp/pb.zip -d /pb/ && \
    mkdir -p /tmp/marmot && \
    cd /tmp/marmot && \
    tar vxzf /tmp/marmot.tar.gz && \
    mv /tmp/marmot/marmot /pb/marmot && \
    cd /pb && \
    rm -rf /tmp/marmot

RUN chmod +x /pb/run.sh

EXPOSE 8080

# start PocketBase
CMD ["/pb/run.sh"]
