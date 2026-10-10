PROJECT_PATH="$(git rev-parse --show-toplevel)/commet/"
PATH="$PROJECT_PATH/../.fvm/flutter_sdk/bin/:$PATH"
PATH="$HOME/.cargo/bin:$PATH"


cd $PROJECT_PATH
dart run scripts/codegen.dart

rustup component add rust-src --toolchain nightly-x86_64-unknown-linux-gnu

eval $PROJECT_PATH/scripts/prepare-web.sh

cd $PROJECT_PATH
dart run scripts/build_release.dart --platform web --version_tag 'v0.0.0-artifact'

cd $PROJECT_PATH/build
tar -czf commet-web.tar.gz web

cd $PROJECT_PATH
mkdir -p $PROJECT_PATH/build/output
cp $PROJECT_PATH/build/commet-web.tar.gz $PROJECT_PATH/build/output/commet-web.tar.gz
cd $PROJECT_PATH/build/output/
echo "Output file is present in now ${PROJECT_PATH}build/output directory"
ls
