import FirebaseCore
import FirebaseMessaging
import Flutter
import NetworkExtension
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Configure before APNs registration so Messaging.apnsToken can be set
    // even if the device-token callback arrives before Dart runs.
    if FirebaseApp.app() == nil {
      FirebaseApp.configure()
    }
    let ok = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    // Scene-based lifecycle + disabled AppDelegate proxy means Firebase
    // will not swizzle this; register and forward the APNs token ourselves.
    application.registerForRemoteNotifications()
    return ok
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Messaging.messaging().apnsToken = deviceToken
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("[Push] APNs registration failed: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.yencode.ghostroute/vpn_status",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "activeTunnel":
        Self.queryActiveTunnel(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func queryActiveTunnel(result: @escaping FlutterResult) {
    NETunnelProviderManager.loadAllFromPreferences { managers, error in
      guard error == nil, let managers = managers else {
        result(nil)
        return
      }

      var connectingMatch: [String: String]?

      for manager in managers {
        guard let protocolConfig = manager.protocolConfiguration as? NETunnelProviderProtocol else {
          continue
        }
        let bundleId = protocolConfig.providerBundleIdentifier ?? ""
        let status = manager.connection.status

        switch status {
        case .connected, .reasserting:
          result([
            "bundleId": bundleId,
            "status": "connected",
          ])
          return
        case .connecting, .disconnecting:
          if connectingMatch == nil {
            connectingMatch = [
              "bundleId": bundleId,
              "status": status == .connecting ? "connecting" : "disconnecting",
            ]
          }
        default:
          break
        }
      }

      result(connectingMatch)
    }
  }
}
