FROM ubuntu as fetch

WORKDIR /jars
RUN apt-get update -y
RUN apt-get install -y curl
RUN curl -LO https://repo1.maven.org/maven2/org/postgresql/postgresql/42.7.5/postgresql-42.7.5.jar

FROM apache/james
COPY --from=fetch /jars/postgresql-42.7.5.jar /root/libs/
#https://jdbc.postgresql.org/download