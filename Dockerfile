FROM --platform=linux/amd64 ruby:2.6.5 AS Build
RUN apt-get update -qq && apt-get install -y build-essential libpq-dev nodejs
RUN mkdir /myapp
WORKDIR /myapp
ADD Gemfile /myapp/Gemfile
ADD Gemfile.lock /myapp/Gemfile.lock
RUN gem install bundler -v 1.17.3
RUN gem install veracode -v 1.1.0
RUN curl -fsS https://tools.veracode.com/veracode-cli/install | sh
RUN ./veracode package -s ./ -a -o .verascan

FROM veracode/api-wrapper-java

COPY --from=Build /myapp/.verascan /myapp/.verascan

ARG VERACODE_API_ID
ARG VERACODE_API_KEY
ARG APP_NAME
ARG VERSION

RUN java -jar /opt/veracode/api-wrapper.jar \
    -vid "${VERACODE_API_ID}" \
    -vkey "${VERACODE_API_KEY}" \
    -action UploadAndScan \
    -appname "${APP_NAME}" \
    -createprofile true \
    -autoscan true \
    -filepath "/myapp/.verascan/" \
    -version "${VERSION}" \
    -policy "Veracode Recommended High" \
    -criticality "High"
