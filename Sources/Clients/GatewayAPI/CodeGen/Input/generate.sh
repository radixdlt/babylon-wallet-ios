#!/bin/sh -e

GEN_TOOL=openapi-generator
if ! [ -x "$(command -v $GEN_TOOL)" ]; then
  echo "Error: '$GEN_TOOL' is not installed. Install it with `brew install openapi-generator`" >&2
  exit 1
fi


cd $(dirname $0)
INPUTDIR=$PWD
# using https://github.com/radixdlt/babylon-gateway/blob/93a023bffc8516ba92338f17725edb2a131c5ed5/src/RadixDlt.NetworkGateway.GatewayApi/gateway-api-spec.yaml
# commit 93a023b from 2022-10-20
PROJECT_NAME=Gateway
SWAGGER_TEMPLATE="$INPUTDIR/gateway-api-spec.yml"
OUTPUTDIR="$INPUTDIR/.."
DESTINATION="$OUTPUTDIR/Generated"

echo "🔮 Generating Gateway API models using '$GEN_TOOL' based on '$SWAGGER_TEMPLATE'"
echo "🎯 Destination for generated files: '$DESTINATION'"

$GEN_TOOL generate -i $SWAGGER_TEMPLATE \
-g swift5 \
-o $OUTPUTDIR \
--additional-properties=useJsonEncodable=false,readonlyProperties=true,swiftUseApiNamespace=true,projectName=Gateway # CONFIG OPTIONS

echo "✨ Generation of models done, Removing some files we dont need."
cd $INPUTDIR
cd ..
rm -rf Generated
mv $PROJECT_NAME/Classes/OpenAPIs/Models Generated
cd Generated
mkdir AUXILARY
mv ../$PROJECT_NAME/Classes/OpenAPIs/Models.swift ../Generated/AUXILARY
mv ../$PROJECT_NAME/Classes/OpenAPIs/Extensions.swift ../Generated/AUXILARY
mv ../$PROJECT_NAME/Classes/OpenAPIs/CodableHelper.swift ../Generated/AUXILARY
mv ../$PROJECT_NAME/Classes/OpenAPIs/OpenISO8601DateFormatter.swift ../Generated/AUXILARY
cd $OUTPUTDIR
rm -r docs Cartfile git_push.sh $PROJECT_NAME.podspec Package.swift project.yml README.md .gitignore .openapi-generator-ignore .swiftformat .openapi-generator/FILES  .openapi-generator/VERSION
