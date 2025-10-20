plugins {
    id "com.android.application"
    id "kotlin-android"
    id "dev.flutter.flutter-gradle-plugin"
    // Firebase Google Services plugin
    id "com.google.gms.google-services"
}

android {
    namespace "com.alisapp.staj_proje"
    compileSdkVersion flutter.compileSdkVersion

    defaultConfig {
        applicationId "com.alisapp.staj_proje"
        minSdkVersion flutter.minSdkVersion
        targetSdkVersion flutter.targetSdkVersion
        versionCode flutterVersionCode.toInteger()
        versionName flutterVersionName
    }

    buildTypes {
        release {
            // Release build için ayarlar
            signingConfig signingConfigs.debug
        }
    }
}

flutter {
    source '../..'
}

dependencies {
    implementation platform('com.google.firebase:firebase-bom:33.3.0')
    implementation 'com.google.firebase:firebase-analytics'
    // Firebase kullandığın paketlere göre diğerleri otomatik bom üzerinden eklenecek
}
