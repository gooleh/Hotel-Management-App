import SwiftUI

extension Color {
    static let themePrimary = Color.blue
    static let themeSecondary = Color.gray
    static let themeBackground = Color.white
    static let themeAccent = Color.gray // 이 줄을 추가하여 themeAccent를 정의합니다.
}


struct RoomDetailView: View {
    @EnvironmentObject var userSession: UserSession
    @ObservedObject var viewModel: RoomViewModel
    var room: Room
    @State private var showingReportView = false
    @State private var notes: String

    init(viewModel: RoomViewModel, room: Room) {
        self.viewModel = viewModel
        self.room = room
        _notes = State(initialValue: room.notes)
    }

    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    Text("Room \(room.number) Details")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        DetailCardView(label: "Status", value: room.status, color: viewModel.statusColor(for: room.status))
                        DetailCardView(label: "Last Cleaned", value: room.lastCleaned.formatted(.dateTime.month().day().hour().minute()), color: .secondary)
                        DetailCardView(label: "Occupied", value: room.occupied ? "Yes" : "No", color: room.occupied ? .red : .green)
                        DetailCardView(label: "Checked In", value: room.isCheckedIn ? "Yes" : "No", color: room.isCheckedIn ? .green : .red)
                    }
                    .padding(.horizontal, 20)

                    HStack(spacing: 10) {
                        VStack(spacing: 10) {
                            ActionButton(iconName: "checkmark.circle.fill", text: "Set Clean", color: .green) {
                                viewModel.updateRoomStatus(room: room, newStatus: "Clean", newLastCleaned: Date())
                                updateLocalRoomStatus(newStatus: "Clean")
                            }
                            
                            ActionButton(iconName: "xmark.circle.fill", text: "Set Dirty", color: .red) {
                                viewModel.updateRoomStatus(room: room, newStatus: "Dirty")
                                updateLocalRoomStatus(newStatus: "Dirty")
                            }
                        }

                        VStack(spacing: 10) {
                            ActionButton(iconName: "exclamationmark.circle.fill", text: "Inspected", color: .blue) {
                                viewModel.updateRoomStatus(room: room, newStatus: "Inspected")
                                updateLocalRoomStatus(newStatus: "Inspected")
                            }
                            
                            ActionButton(iconName: room.isCheckedIn ? "rectangle.badge.xmark" : "rectangle.badge.checkmark", text: room.isCheckedIn ? "Check Out" : "Check In", color: room.isCheckedIn ? .orange : .purple) {
                                viewModel.updateCheckInStatusOnly(room: room, isCheckedIn: !room.isCheckedIn)
                                updateLocalCheckInStatus(isCheckedIn: !room.isCheckedIn)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Notes")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        TextEditor(text: $notes)
                            .frame(minHeight: 100)
                            .padding()
                            .background(Color.themeBackground)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    Button(action: {
                        viewModel.updateRoomNotes(roomId: room.id, notes: notes)
                        showingReportView = true
                    }) {
                        Text("Save Notes")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .alert(isPresented: $showingReportView) {
                        Alert(
                            title: Text("Notes Updated"),
                            message: Text("Your notes for Room \(room.number) have been successfully updated."),
                            dismissButton: .default(Text("OK"))
                        )
                    }

                    NavigationLink(destination: ReportIssueView(viewModel: viewModel, room: room)) {
                        Text("Report Issue")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                .padding()
                .navigationBarTitle("Room \(room.number) Details", displayMode: .inline)
            }
        }
    }
    
    private func updateLocalRoomStatus(newStatus: String) {
        if let index = viewModel.rooms.firstIndex(where: { $0.id == room.id }) {
            viewModel.rooms[index].status = newStatus
        }
    }
    
    private func updateLocalCheckInStatus(isCheckedIn: Bool) {
        if let index = viewModel.rooms.firstIndex(where: { $0.id == room.id }) {
            viewModel.rooms[index].isCheckedIn = isCheckedIn
        }
    }
}

struct ActionButton: View {
    var iconName: String
    var text: String
    var color: Color
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: iconName)
                    .font(.headline)
                Text(text)
                    .font(.headline)
                    .padding(.leading, 5)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(10)
            .shadow(radius: 5)
        }
    }
}

struct DetailCardView: View {
    let label: String
    let value: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased()).font(.headline).foregroundColor(.themeSecondary)
            Text(value).font(.title2).bold().foregroundColor(color)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct RoomDetailView_Previews: PreviewProvider {
    static var previews: some View {
        RoomDetailView(viewModel: RoomViewModel(), room: Room(id: "1", isCheckedIn: false, lastCleaned: Date(), maintenanceNotes: "", notes: "", number: "101", occupied: false, status: "Clean", supplies: [], roomServices: []))
            .environmentObject(UserSession())
    }
}

