deep-clean-ios:
	@echo "Cleaning ios"
	fvm flutter clean
	cd ios && rm -rf Podfile.lock
	cd ios && rm -rf Pods
	fvm flutter pub get
	cd ios && pod install --repo-update

clean-ios:
	@echo "Cleaning ios"
	fvm flutter clean
	cd ios && rm -rf Podfile.lock
	cd ios && rm -rf Pods
	fvm flutter pub get
	cd ios && pod install

clean:
	@echo "Cleaning the repo"
	rm -rf build
	fvm flutter clean

build-adb:
	@echo "Building App bundle"
	fvm flutter pub get
	fvm flutter build appbundle

build-apk:
	@echo "Building APK"
	fvm flutter pub get
	fvm flutter build apk


