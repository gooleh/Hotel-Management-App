import SwiftUI
import Firebase

@main
struct INHA_hotel_app_tae: App {  // App의 이름 확인
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject var userSession = UserSession()
    @StateObject var orderViewModel = OrderViewModel()
    @StateObject var socketManager = MySocketManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(userSession)
                .environmentObject(orderViewModel)
                .environmentObject(socketManager)
        }
    }
}
