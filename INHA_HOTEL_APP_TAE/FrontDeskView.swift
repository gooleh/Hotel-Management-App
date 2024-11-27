import SwiftUI
import Firebase

struct FrontDeskView: View {
    @ObservedObject var viewModel: RoomViewModel

    var body: some View {
        NavigationView {
            ZStack {
                // 배경 이미지 추가
                Image(uiImage: UIImage(named: "background_image")!)
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 20) {
                        ForEach(Array(viewModel.groupedRooms.keys.sorted()), id: \.self) { key in
                            Section(header: Text(key)
                                        .font(.headline)
                                        .foregroundColor(.themePrimary)
                                        .padding(.horizontal, 20)
                                        .padding(.top, 10)) {
                                ForEach(viewModel.groupedRooms[key] ?? []) { room in
                                    NavigationLink(destination: FrontDeskRoomDetailView(room: room, viewModel: viewModel)) {
                                        FrontDeskRoomCardView(room: room, viewModel: viewModel)
                                            .padding(.horizontal, 20)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.top, 20)
                }
                .navigationBarTitle("Front Desk", displayMode: .inline)
                .navigationBarColor(.clear)
            }
        }
    }
}

// Navigation Bar의 색상을 조정하기 위해 사용하는 확장
extension View {
    func navigationBarColor(_ backgroundColor: UIColor) -> some View {
        self.modifier(NavigationBarModifier(backgroundColor: backgroundColor))
    }
}

// Navigation Bar 색상을 조정하는 모디파이어
struct NavigationBarModifier: ViewModifier {
    let backgroundColor: UIColor

    init(backgroundColor: UIColor) {
        self.backgroundColor = backgroundColor
        let coloredAppearance = UINavigationBarAppearance()
        coloredAppearance.configureWithOpaqueBackground()
        coloredAppearance.backgroundColor = backgroundColor
        coloredAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = coloredAppearance
        UINavigationBar.appearance().compactAppearance = coloredAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = coloredAppearance
    }

    func body(content: Content) -> some View {
        ZStack {
            content
            VStack {
                GeometryReader { geometry in
                    Color(self.backgroundColor) // Use the stored backgroundColor
                        .frame(height: geometry.safeAreaInsets.top)
                        .edgesIgnoringSafeArea(.top)
                    Spacer()
                }
            }
        }
    }
}

struct FrontDeskRoomCardView: View {
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
                Image(systemName: room.isCheckedIn ? "person.fill.checkmark" : "person.fill.xmark")
                    .foregroundColor(room.isCheckedIn ? .green : .red)
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
        .background(
            LinearGradient(gradient: Gradient(colors: [.white, .gray.opacity(0.1)]), startPoint: .top, endPoint: .bottom)
        )
        .cornerRadius(15)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
}

struct FrontDeskRoomDetailView: View {
    @ObservedObject var viewModel: RoomViewModel
    var room: Room
    @State private var notes: String
    @State private var showAlert = false
    @State private var alertMessage = ""

    init(room: Room, viewModel: RoomViewModel) {
        self.viewModel = viewModel
        _notes = State(initialValue: room.notes)  // Initialize notes before setting room
        self.room = room
    }

    var body: some View {
        ZStack {
            // 배경 이미지 추가
            Image(uiImage: UIImage(named: "background_image")!)
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 20) {
                    Text("Room \(room.number) Details")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.themePrimary) // 텍스트 색상 변경
                        .padding(.top, 20)
                    
                    VStack(spacing: 20) {
                        DetailCardView(label: "Status", value: room.status, color: viewModel.statusColor(for: room.status))
                        DetailCardView(label: "Last Cleaned", value: room.lastCleaned.formatted(.dateTime.month().day().hour().minute()), color: .secondary)
                        DetailCardView(label: "Occupied", value: room.occupied ? "Yes" : "No", color: room.occupied ? .red : .green)
                        DetailCardView(label: "Checked In", value: room.isCheckedIn ? "Yes" : "No", color: room.isCheckedIn ? .green : .red)
                    }
                    .padding(.horizontal, 20)

                    VStack(spacing: 10) {
                        ActionButton(iconName: room.isCheckedIn ? "rectangle.badge.xmark" : "rectangle.badge.checkmark", text: room.isCheckedIn ? "Check Out" : "Check In", color: room.isCheckedIn ? .orange : .purple) {
                            viewModel.updateCheckInStatusOnly(room: room, isCheckedIn: !room.isCheckedIn)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Customer Notes")
                            .font(.headline)
                            .foregroundColor(.themePrimary) // 텍스트 색상 변경
                        
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
                        if let roomId = room.id {
                            viewModel.updateRoomNotes(roomId: roomId, notes: notes)
                            alertMessage = "Your notes for Room \(room.number) have been successfully updated."
                            showAlert = true
                        } else {
                            alertMessage = "Room ID not found."
                            showAlert = true
                        }
                    }) {
                        Text("Save Notes")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.themePrimary)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                    .alert(isPresented: $showAlert) {
                        Alert(
                            title: Text("Notes Updated"),
                            message: Text(alertMessage),
                            dismissButton: .default(Text("OK"))
                        )
                    }
                }
                .padding()
                .navigationBarTitle("Room \(room.number) Details", displayMode: .inline)
            }
        }
    }
}


struct FlatPrimaryButtonStyle: ButtonStyle {
    var color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding()
            .background(configuration.isPressed ? color.opacity(0.5) : color)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}
