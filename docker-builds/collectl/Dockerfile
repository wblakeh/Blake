FROM registry.access.redhat.com/ubi8

COPY collectl.rpm /

RUN dnf update -y && dnf install /collectl.rpm -y && dnf clean all && rm /collectl.rpm

ENTRYPOINT ["/usr/bin/collectl"]
CMD ["--nohup", "--all", "-f /collectl/host"]
