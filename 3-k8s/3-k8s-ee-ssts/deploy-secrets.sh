#!/bin/bash

#    Copyright 2020 AxonIQ B.V.

#    Licensed under the Apache License, Version 2.0 (the "License");
#    you may not use this file except in compliance with the License.
#    You may obtain a copy of the License at

#        http://www.apache.org/licenses/LICENSE-2.0

#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS,
#    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#    See the License for the specific language governing permissions and
#    limitations under the License.

if [[ $# != 2 ]] ; then
    echo "Usage: $0 <firstnode-name> <namespace>"
    exit 1
fi

STS_NAME=$1
NS_NAME=$2

echo "Generating files"
echo ""
for src in axonserver.properties.tmpl ; do
    dst=$(basename ${src} .tmpl)
    echo "Generating ${dst}"
    sed -e s/__STS_NAME__/${STS_NAME}/g -e s/__NS_NAME__/${NS_NAME}/g < ${src} > ${dst}
done

echo ""
echo "Creating Namespace if needed"
echo ""
kubectl create ns ${NS_NAME} --dry-run=client -o yaml | kubectl apply -f -

echo ""
echo "Creating/updating Secrets and ConfigMap"
echo ""
for f in ../../axoniq.license ../../axonserver.token ; do
    secret=$(basename ${f} | tr '.' '-')
    descriptor=${secret}.yml
    kubectl create secret generic ${secret} --from-file=${f} --dry-run=client -o yaml > ${descriptor}
    kubectl apply -f ${descriptor} -n ${NS_NAME} 
done
for f in axonserver.properties ; do
    cfg=$(basename ${f} | tr '.' '-')
    descriptor=${cfg}.yml
    kubectl create configmap ${cfg} --from-file=${f} --dry-run=client -o yaml > ${descriptor}
    kubectl apply -f ${descriptor} -n ${NS_NAME} 
done
