import Flutter
import UIKit
import GoogleMaps // Import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {

    // Retrieve API key from Info.plist and provide it to GoogleMaps
    guard let googleMapsApiKey = Bundle.main.object(forInfoDictionaryKey: "GoogleMapsApiKey") as? String, !googleMapsApiKey.isEmpty else {
      fatalError("Google Maps API Key for iOS not found in Info.plist or is empty. Please add it.")
    }
    GMSServices.provideAPIKey(googleMapsApiKey)

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}