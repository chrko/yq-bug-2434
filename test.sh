#!/usr/bin/env bash

set -euxo pipefail

YQ_VERSION=$(yq --version | awk '{print $(NF)}')

YQ_4_47_1_FLAG=""
if yq --help | grep -q -- --yaml-fix-merge-anchor-to-spec; then
  YQ_4_47_1_FLAG="--yaml-fix-merge-anchor-to-spec"
fi

# working until yq 4.45.4
cp chart-values.yaml test-1-$YQ_VERSION.yaml
yq eval-all \
  "(select(fileIndex == 0) | explode(.)) * (select(fileIndex == 1) | explode(.))" \
  test-1-$YQ_VERSION.yaml \
  stage-values.yaml \
  --inplace

# with new flag
cp chart-values.yaml test-2-$YQ_VERSION.yaml
yq eval-all \
  "(select(fileIndex == 0) | explode(.)) * (select(fileIndex == 1) | explode(.))" \
  test-2-$YQ_VERSION.yaml \
  stage-values.yaml \
  --inplace $YQ_4_47_1_FLAG

# expanded the yq command into dedicated calls corresponding to the parenthesis
cp chart-values.yaml test-3-$YQ_VERSION.yaml
cp stage-values.yaml test-3-stage-tmp-$YQ_VERSION.yaml
yq eval-all --inplace $YQ_4_47_1_FLAG "explode(.)" test-3-$YQ_VERSION.yaml
yq eval-all --inplace $YQ_4_47_1_FLAG "explode(.)" test-3-stage-tmp-$YQ_VERSION.yaml
yq eval-all --inplace $YQ_4_47_1_FLAG "select(fileIndex == 0) * select(fileIndex == 1)" test-3-$YQ_VERSION.yaml test-3-stage-tmp-$YQ_VERSION.yaml

set +x

if [[ $YQ_VERSION != "v4.45.4" ]]; then
  if ! diff -u "test-2-v4.45.4.yaml" "test-2-$YQ_VERSION.yaml"; then
    echo "contents didn't match, bug is not fixed in $YQ_VERSION"
  fi
fi
