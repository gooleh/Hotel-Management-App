import SwiftUI

struct DepartmentView: View {
    @EnvironmentObject var userSession: UserSession
    @EnvironmentObject var orderViewModel: OrderViewModel

    var body: some View {
        VStack {
            if let department = userSession.department {
                switch department {
                case "Customer":
                    CustomerView()
                        .environmentObject(userSession)
                case "Kitchen":
                    KitchenView()
                        .environmentObject(userSession)
                case "Facility":
                    FacilityView()
                        .environmentObject(userSession)
                case "Housekeeping":
                    HousekeepingView(viewModel: userSession.roomViewModel)
                        .environmentObject(userSession)
                case "FrontDesk":
                    FrontDeskView(viewModel: userSession.roomViewModel)
                        .environmentObject(userSession)
                case "Admin":
                    AdminView()
                        .environmentObject(userSession)
                default:
                    Text("Unknown Department")
                }
            } else {
                Text("No department available.")
            }
        }
    }
}

struct DepartmentView_Previews: PreviewProvider {
    static var previews: some View {
        DepartmentView()
            .environmentObject(UserSession())
            .environmentObject(OrderViewModel())
    }
}
