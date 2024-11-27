import SwiftUI
import UserNotifications
import FirebaseFirestore

struct FacilityRoomDetailView: View {
    @ObservedObject var viewModel: RoomViewModel
    var roomIndex: Int

    @State private var showingSuccessAlert = false
    @State private var maintenanceNotes: String

    init(viewModel: RoomViewModel, roomIndex: Int) {
        self.viewModel = viewModel
        self.roomIndex = roomIndex
        _maintenanceNotes = State(initialValue: viewModel.rooms[roomIndex].maintenanceNotes)
    }

    var body: some View {
        ZStack {
            // 배경 그라데이션 추가
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Room \(viewModel.rooms[roomIndex].number) Details")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 10) // 텍스트에 그림자 추가
                        .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        DetailCardView2(label: "Status", value: viewModel.rooms[roomIndex].status, color: viewModel.statusColor(for: viewModel.rooms[roomIndex].status))
                        DetailCardView2(label: "Last Cleaned", value: viewModel.rooms[roomIndex].lastCleaned.formatted(.dateTime.month().day().hour().minute()), color: .white)
                        DetailCardView2(label: "Occupied", value: viewModel.rooms[roomIndex].occupied ? "Yes" : "No", color: viewModel.rooms[roomIndex].occupied ? .red : .green)
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Maintenance Notes")
                            .font(.headline)
                            .foregroundColor(.white)
                            .shadow(radius: 5) // 텍스트에 그림자 추가
                        
                        TextEditor(text: $maintenanceNotes)
                            .frame(minHeight: 100)
                            .padding()
                            .background(Color.white.opacity(0.8))
                            .cornerRadius(15)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                    HStack {
                        Button(action: {
                            viewModel.updateRoomNotes(roomId: viewModel.rooms[roomIndex].id, notes: maintenanceNotes)
                            showingSuccessAlert = true
                        }) {
                            Text("Save Changes")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)

                        Button(action: {
                            viewModel.updateRoomOccupied(room: viewModel.rooms[roomIndex], occupied: !viewModel.rooms[roomIndex].occupied) {
                                viewModel.rooms[roomIndex].occupied.toggle()
                                showingSuccessAlert = true
                                sendNotification(message: "Room \(viewModel.rooms[roomIndex].number) occupancy changed to \(viewModel.rooms[roomIndex].occupied ? "Occupied" : "Available").")
                            }
                        }) {
                            Text(viewModel.rooms[roomIndex].occupied ? "Set Available" : "Set Occupied")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(viewModel.rooms[roomIndex].occupied ? Color.red : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(15)
                                .shadow(radius: 5)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .alert(isPresented: $showingSuccessAlert) {
                        Alert(
                            title: Text("Success"),
                            message: Text("Changes have been saved successfully."),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                .padding()
                .navigationBarTitle("Room Details", displayMode: .inline)
            }
        }
    }

    private func sendNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "Room Update"
        content.body = message
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

struct DetailCardView2: View {
    let label: String
    let value: String
    var color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label.uppercased()).font(.headline).foregroundColor(.white).shadow(radius: 5)
            Text(value).font(.title2).bold().foregroundColor(color).shadow(radius: 5)
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}

struct FacilityRoomDetailView_Previews: PreviewProvider {
    static var previews: some View {
        FacilityRoomDetailView(viewModel: RoomViewModel(), roomIndex: 0)
    }
}
struct FacilityNotificationsView: View {
    @ObservedObject var viewModel: RoomViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Notifications")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.top, 20)

            List(viewModel.notifications) { notification in
                Text(notification.message)
                    .padding()
                    .background(Color.white.opacity(0.6))
                    .cornerRadius(8)
                    .shadow(radius: 5)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 10)
            }
            .onAppear {
                print("Notifications view appeared with \(viewModel.notifications.count) notifications") // 디버깅용 로그
            }
        }
        .background(
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
        )
        .onAppear {
            viewModel.fetchNotifications()
            MySocketManager.shared.connect()
        }
        .onDisappear {
            MySocketManager.shared.disconnect()
        }
    }
}



struct FacilityView: View {
    @ObservedObject var viewModel = RoomViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // 배경 그라데이션 추가
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                VStack(alignment: .leading) {
                    Text("Facility Management")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 10) // 텍스트에 그림자 추가
                        .padding(.bottom, 10)
                        .padding(.leading, 20)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            ForEach(viewModel.groupedRooms2.keys.sorted(), id: \.self) { key in
                                Section(header: Text(key).font(.headline).foregroundColor(.white).shadow(radius: 10)) { // 텍스트에 그림자 추가
                                    ForEach(viewModel.groupedRooms2[key] ?? []) { room in
                                        NavigationLink(destination: FacilityRoomDetailView(viewModel: viewModel, roomIndex: viewModel.rooms.firstIndex(where: { $0.id == room.id })!)) {
                                            FacilityRoomCardView(room: room, viewModel: viewModel)
                                                .padding(.horizontal, 20)
                                                .padding(.bottom, 10)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: FacilityNotificationsView(viewModel: viewModel)) {
                        Text("Notifications")
                            .foregroundColor(.white)
                    }
                }
            }
            .onAppear {
                MySocketManager.shared.connect()
                MySocketManager.shared.onReceiveRequest(forType: "facility") { message in
                    print("Received message: \(message)") // 디버깅 로그 추가
                    viewModel.saveNotification(message: message, recipient: "facility")
                    viewModel.fetchNotifications() // 수신된 후 알림 새로고침 추가
                }
                NotificationCenter.default.addObserver(forName: .newNotification, object: nil, queue: .main) { notification in
                    if let message = notification.userInfo?["message"] as? String {
                        print("NotificationCenter received message: \(message)") // 디버깅 로그 추가
                        viewModel.saveNotification(message: message, recipient: "facility")
                        viewModel.fetchNotifications() // 수신된 후 알림 새로고침 추가
                    }
                }
            }

            .onDisappear {
                MySocketManager.shared.offReceiveRequest()
                NotificationCenter.default.removeObserver(self, name: .newNotification, object: nil)
                MySocketManager.shared.disconnect()
            }
        }
    }
}

struct FacilityRoomCardView: View {
    var room: Room
    var viewModel: RoomViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Room \(room.number)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .shadow(radius: 5) // 텍스트에 그림자 추가
                
                Spacer()
                
                Image(systemName: room.isCheckedIn ? "person.fill.checkmark" : "person.fill.xmark")
                    .foregroundColor(room.isCheckedIn ? .green : .red)
            }
            
            Text("Status: \(room.status)")
                .font(.subheadline)
                .foregroundColor(viewModel.statusColor(for: room.status))
                .shadow(radius: 5) // 텍스트에 그림자 추가
            
            Text("Last Cleaned: \(room.lastCleaned.formatted(.dateTime.month().day().hour().minute()))")
                .font(.subheadline)
                .foregroundColor(.white)
                .shadow(radius: 5) // 텍스트에 그림자 추가
            
            Text(room.occupied ? "Occupied" : "Available")
                .font(.subheadline)
                .foregroundColor(room.occupied ? .red : .green)
                .shadow(radius: 5) // 텍스트에 그림자 추가
        }
        .padding()
        .background(Color.black.opacity(0.6))
        .cornerRadius(15)
        .shadow(radius: 5)
    }
}
