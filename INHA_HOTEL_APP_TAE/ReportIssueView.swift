import SwiftUI

struct ReportIssueView: View {
    @ObservedObject var viewModel: RoomViewModel
    var room: Room
    @State private var reportText = ""
    @State private var showingSuccessAlert = false

    var body: some View {
        Form {
            TextField("Enter your report", text: $reportText)
            Button("Submit Report") {
                viewModel.updateRoomOccupied(room: room, occupied: true, report: reportText) {
                    let notificationMessage = "New maintenance report for room \(room.number): \(reportText)"
                    MySocketManager.shared.sendRequest(message: notificationMessage, requestType: "facility", recipient: "facility")
                    showingSuccessAlert = true
                }
            }
            .alert(isPresented: $showingSuccessAlert) {
                Alert(
                    title: Text("Success"),
                    message: Text("Your report has been submitted successfully."),
                    dismissButton: .default(Text("OK"))
                )
            }
            .navigationBarTitle("Report Issue", displayMode: .inline)
        }
        .onAppear {
            self.reportText = room.maintenanceNotes
        }
    }
}
