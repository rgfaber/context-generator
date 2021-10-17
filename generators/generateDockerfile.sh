#! /bin/bash -x

# set -eu

# SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"/generators
# echo $SCRIPT_DIR


###################################################################
### FUNCTIONS
###################################################################


generateBuildSh() {
cat >build.sh<<EOF
#! /bin/bash

set -eu

shopt -s expand_aliases
 
cp ~/.kube/config .

dotnet publish ${1}.csproj --runtime centos.8-x64 --self-contained -c Release -o ./app

echo 'Building ${1} Service'
docker build . -f local.Dockerfile -t local/${2}

rm -rf config
rm -rf ./app

echo 'finished!'
echo 'You may now run the container using: ./run.sh'
EOF
chmod +x *.sh
}


generateRunSh() {
cat >run.sh<<EOF
#! /bin/bash

set -eu

shopt -s expand_aliases

docker run --rm -it --network host local/${1}
EOF
chmod +x *.sh
}


generateDockerfile() {
  cat >Dockerfile<<EOF
# syntax=docker/dockerfile:1.0.0-experimental
FROM mcr.microsoft.com/dotnet/aspnet:5.0 AS base
WORKDIR /app
EXPOSE 80
EXPOSE 443
ARG sdk_nugets_url
ARG logatron_nugets_url
ARG cid_usr
ARG cid_pwd
ENV DOCKER_BUILDKIT=1
RUN --mount=type=secret,id=cid_pwd                   cid_pwd=/run/secrets/cid_pwd

# syntax=docker/dockerfile:1.0.0-experimental
FROM mcr.microsoft.com/dotnet/sdk:5.0 AS publish
ENV DOCKER_BUILDKIT=1
ARG sdk_nugets_url
ARG logatron_nugets_url
ARG cid_usr
ARG cid_pwd
RUN --mount=type=secret,id=cid_pwd                   cat /run/secrets/cid_pwd
WORKDIR /src
COPY . .
RUN dotnet nuget add source ${sdk_nugets_url} -n "M5x SDK Nugets" -u ${cid_usr} -p ${cid_pwd} --store-password-in-clear-text
RUN dotnet nuget add source ${logatron_nugets_url} -n "Logatron Nugets" -u ${cid_usr} -p ${cid_pwd} --store-password-in-clear-text
WORKDIR "/src/$1/$2.$3"
RUN dotnet publish "$2.$3.csproj" -c Release -o /app/publish --runtime alpine-x64 --self-contained 
 
FROM base AS final
WORKDIR /app
COPY --from=publish /app/publish .
ENTRYPOINT ["dotnet", "$2.$3.dll"]
EOF
echo 'done'
}

generateLocalDockerfile() {
    cat >local.Dockerfile<<EOF
FROM mcr.microsoft.com/dotnet/runtime AS base
COPY ./app /app
COPY config /root/.kube/config
WORKDIR /app
ENV ASPNETCORE_URLS http://+:5197
EXPOSE 5197
ENTRYPOINT ["dotnet", "$1.dll"]
EOF
echo 'done'
}