import SwiftUI

struct HousekeepingView: View {
    @EnvironmentObject var userSession: UserSession
    @ObservedObject var viewModel: RoomViewModel
    @State private var messages: [String] = []
    @State private var navigateToOrders: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                // 배경 그라데이션 추가
                LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.8), Color.purple.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(Array(viewModel.groupedRoomsByStatus.keys.sorted()), id: \.self) { key in
                            roomsSection(key: key)
                        }
                        
                        notificationsSection()
                    }
                    .padding(.top, 20)
                }
                .navigationTitle("Housekeeping")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: OrderView(viewModel: OrderViewModel())) {
                            Text("Orders")
                                .foregroundColor(.white)
                        }
                    }
                }
                .onAppear {
                    userSession.connectSocket()
                    userSession.socketManager.onReceiveRequest(forType: "housekeeping") { message in
                        self.messages.append(message)
                        self.sendNotification(message: message)
                        viewModel.saveNotification(message: message, recipient: "housekeeping")
                    }
                    NotificationCenter.default.addObserver(forName: .newNotification, object: nil, queue: .main) { notification in
                        if let message = notification.userInfo?["message"] as? String {
                            viewModel.saveNotification(message: message, recipient: "housekeeping")
                        }
                    }
                }
                .onDisappear {
                    userSession.socketManager.offReceiveRequest()
                    NotificationCenter.default.removeObserver(self, name: .newNotification, object: nil)
                }
            }
            .navigationDestination(isPresented: $navigateToOrders) {
                OrderView(viewModel: OrderViewModel())
            }
            .navigationDestination(for: Room.self) { room in
                RoomDetailView(viewModel: viewModel, room: room)
                    .environmentObject(userSession)
            }
        }
    }

    private func roomsSection(key: String) -> some View {
        Section(header: Text(key)
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.top, 10)) {
                ForEach(viewModel.groupedRoomsByStatus[key] ?? []) { room in
                    NavigationLink(value: room) {
                        RoomCardView(room: room, viewModel: viewModel)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 10)
                    }
                }
        }
    }
    
    private func notificationsSection() -> some View {
        Section(header: Text("Notifications")
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.top, 10)) {
                ForEach(messages, id: \.self) { message in
                    Text(message)
                        .padding()
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(10)
                        .shadow(radius: 5)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 10)
                        .onTapGesture {
                            navigateToOrders = true
                        }
                }
        }
    }

    private func sendNotification(message: String) {
        let content = UNMutableNotificationContent()
        content.title = "New Request"
        content.body = message
        content.sound = UNNotificationSound.default

        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}

struct RoomCardView: View {
    var room: Room
    var viewModel: RoomViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Room \(room.number)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.themeAccent)
                Spacer()
                Image(systemName: "bed.double.fill")
                    .foregroundColor(viewModel.statusColor(for: room.status))
            }
            
            Text("Status: \(room.status)")
                .font(.subheadline)
                .foregroundColor(viewModel.statusColor(for: room.status))
            
            Text("Last Cleaned: \(room.lastCleaned.formatted(.dateTime.month().day().hour().minute()))")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(room.isCheckedIn ? "Checked In" : "Checked Out")
                .font(.subheadline)
                .foregroundColor(room.isCheckedIn ? .green : .red)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 5)
    }
}

struct HousekeepingView_Previews: PreviewProvider {
    static var previews: some View {
        HousekeepingView(viewModel: RoomViewModel())
            .environmentObject(UserSession())
    }
}
