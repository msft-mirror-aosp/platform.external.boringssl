#!/bin/sh

set -e

# If a branch name is passed on the command line then sync
# to that instead of HEAD.
branch="$1"

old_revision=$(cat BORINGSSL_REVISION)
rm -Rf src
git clone https://boringssl.googlesource.com/boringssl src
cd src
if [ "$branch" ]; then
  git checkout "$branch"
fi
new_revision=$(git show -s --pretty=%H)
if [ "$branch" ]; then
  target="branch $branch"
else
  target="$new_revision"
fi
msgfile=$(mktemp)

echo "external/boringssl: Sync to ${target}.

This includes the following changes:

https://boringssl.googlesource.com/boringssl/+log/${old_revision}..${new_revision}
" > $msgfile

# Just pull out commit titles and any Update-Note paragraphs for AOSP commit summary
git log --format='format:* %s%n%n%b' ${old_revision}..${new_revision} \
  | awk -v RS='' -v ORS='\n' '/^Update-Note/ {print} /^\*/ {print}' \
  >> $msgfile


cd ..
echo "
Test: treehugger" >> $msgfile
if [ ! "$branch" ]; then
  echo ${new_revision} > BORINGSSL_REVISION
fi

rm -Rf src/.git
rm -Rf src/fuzz
rm -Rf src/third_party/googletest

python3 src/util/generate_build_files.py android cmake
cp src/LICENSE NOTICE

# TODO(b/503870633): Remove this line after BoringSSL is updated to no longer
# generate sources.mk as part of generating sources.bp.
rm sources.mk

git add .
git commit --no-verify -F $msgfile
rm -f $msgfile
