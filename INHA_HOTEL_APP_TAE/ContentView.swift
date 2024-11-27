import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var orderViewModel: OrderViewModel
    @EnvironmentObject var socketManager: MySocketManager

    var body: some View {
        NavigationView {
            if userSession.isLoggedIn {
                DepartmentView()
                    .onAppear {
                        print("Navigating to DepartmentView")
                    }
            } else {
                PhoneNumberLoginView()
                    .onAppear {
                        print("Navigating to PhoneNumberLoginView")
                    }
            }
        }
        .onAppear {
            print("ContentView appeared")
            print("User is logged in: \(userSession.isLoggedIn)")
            if userSession.isLoggedIn {
                userSession.connectSocket()
            }
        }
        .onDisappear {
            if userSession.isLoggedIn {
                userSession.disconnectSocket()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(UserSession())
            .environmentObject(OrderViewModel())
            .environmentObject(MySocketManager.shared)
    }
}
