set -x
rm -rf build/
rm logstash-upgradeable-pack.zip
mkdir -p build/logstash-upgradeable-pack/logstash/
gem build logstash-input-secret.gemspec
gem build stud.gemspec
mv logstash-input-secret*.gem build/logstash-upgradeable-pack/logstash/
mkdir build/logstash-upgradeable-pack/logstash/dependencies
mv stud*.gem build/logstash-upgradeable-pack/logstash/dependencies

cd build/
zip -r logstash-upgradeable-pack.zip logstash-upgradeable-pack
cp *.zip ../
cd ..
