#!/bin/sh -e

GEN_TOOL=openapi-generator
if ! [ -x "$(command -v $GEN_TOOL)" ]; then
  echo "Error: '$GEN_TOOL' is not installed. Install it with `brew install openapi-generator`" >&2
  exit 1
fi


cd $(dirname $0)
INPUTDIR=$PWD
# using https://github.com/radixdlt/babylon-gateway/blob/develop/src/RadixDlt.NetworkGateway.GatewayApi/gateway-api-schema.yaml
# commit 0836c93 from 2023-03-17
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

# Remove malformed models
rm ../Generated/FungibleResourcesCollectionItem.swift
rm ../Generated/NonFungibleResourcesCollectionItem.swift
rm ../Generated/StateEntityDetailsResponseItemDetails.swift
rm ../Generated/PublicKey.swift

cd $OUTPUTDIR
find $PROJECT_NAME -type f -not -name 'Configuration.swift' \
-not -name 'FungibleResourcesCollectionItem.swift' \
-not -name 'NonFungibleResourcesCollectionItem.swift' \
-not -name 'StateEntityDetailsResponseItemDetails.swift' \
-not -name 'PublicKey.swift' \
-delete

rm -r docs Cartfile git_push.sh $PROJECT_NAME.podspec Package.swift project.yml README.md .gitignore .openapi-generator-ignore .swiftformat .openapi-generator/FILES  .openapi-generator/VERSION
