PROJECT_PATH="$(git rev-parse --show-toplevel)/commet/"
PATH="$PROJECT_PATH/../.fvm/flutter_sdk/bin/:$PATH"

cd $PROJECT_PATH
dart run scripts/codegen.dart

cd $PROJECT_PATH
git checkout linux/flatpak

cd $PROJECT_PATH
dart run scripts/build_release.dart --platform linux --version_tag 'v0.0.0-artifact' --build_detail flatpak


flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
flatpak install -y flathub org.gnome.Platform//51 org.gnome.Sdk//51
mkdir -p linux/flatpak/commet
cp -r $PROJECT_PATH/build/linux/x64/release/bundle $PROJECT_PATH/linux/flatpak/commet/bundle
version=0.0.0
echo $version
cd $PROJECT_PATH/linux/flatpak
sed -i "s/{{VERSION_TAG}}/$version/g" ./chat.commet.commetapp.desktop
sed -i "s/{{VERSION_TAG}}/$version/g" ./chat.commet.commetapp.metainfo.xml
flatpak-builder --force-clean build-dir chat.commet.commetapp.local.yaml --repo=repo
flatpak build-bundle repo chat.commet.commetapp.flatpak chat.commet.commetapp

cd $PROJECT_PATH
mkdir -p $PROJECT_PATH/build/output
cp $PROJECT_PATH/linux/flatpak/chat.commet.commetapp.flatpak $PROJECT_PATH/build/output/chat.commet.commetapp.flatpak
cd $PROJECT_PATH/build/output/
echo "Output file is present in now ${PROJECT_PATH}build/output directory"
ls
