FROM registry.access.redhat.com/ubi8/python-38
  
ADD startup.sh /opt/app-root/src

RUN pip install --upgrade pip; pip install gdbgui

EXPOSE 8082

ENTRYPOINT [ "/opt/app-root/src/startup.sh" ]
