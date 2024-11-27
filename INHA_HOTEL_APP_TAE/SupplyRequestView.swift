import SwiftUI
import FirebaseFirestore

struct SupplyRequestView: View {
    @EnvironmentObject var userSession: UserSession
    @State private var supplies: [Supply] = [
        Supply(name: "Face Towel", imageName: "face_towel"),
        Supply(name: "Bath Towel", imageName: "bath_towel"),
        Supply(name: "Bathroom Amenities", imageName: "bathroom_amenities"),
        Supply(name: "Toothbrush", imageName: "toothbrush"),
        Supply(name: "Extra Pillow", imageName: "extra_pillow"),
        Supply(name: "Extra Bed", imageName: "extra_bed"),
        Supply(name: "Capsule Coffee", imageName: "capsule_coffee"),
        Supply(name: "Water", imageName: "water"),
        Supply(name: "Edible Ice", imageName: "edible_ice")
    ]
    @State private var isLoading: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        ZStack {
            // 배경 그라디언트 추가
            LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .topLeading, endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)

            VStack(alignment: .leading) {
                Text("Request Supplies")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.bottom, 10)
                    .padding(.leading, 20)

                Text("Select the supplies you need:")
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.leading, 20)
                    .padding(.bottom, 20)

                ScrollView(.vertical, showsIndicators: false) {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        ForEach(supplies.indices, id: \.self) { index in
                            SupplyItemView(supply: $supplies[index])
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 20)

                Button(action: {
                    requestSupplies()
                }) {
                    Text("Submit Request")
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

                Spacer()
            }
            .padding(.top, 20)
        }
        .overlay(
            Group {
                if isLoading {
                    Color.black.opacity(0.4)
                        .edgesIgnoringSafeArea(.all)
                    ProgressView("Submitting...")
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(10)
                }
            }
        )
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Request Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    func requestSupplies() {
        let selectedItems = supplies.filter { $0.isSelected }
        guard !selectedItems.isEmpty else {
            alertMessage = "Please select at least one supply."
            showAlert = true
            return
        }

        isLoading = true
        let db = Firestore.firestore()
        guard let roomNumber = userSession.roomNumber else {
            alertMessage = "Room number not found."
            showAlert = true
            isLoading = false
            return
        }

        let group = DispatchGroup()
        for item in selectedItems {
            let request = Request(type: "Supply", item: item.name, timestamp: Timestamp(), roomNumber: roomNumber)
            group.enter()
            do {
                try db.collection("Requests").addDocument(from: request) { error in
                    if let error = error {
                        print("Error adding document: \(error.localizedDescription)")
                    } else {
                        MySocketManager.shared.sendRequest(message: "Supply request for \(item.name) from room \(roomNumber)", requestType: "housekeeping", recipient: "housekeeping") // 소켓으로 메시지 전송
                        print("Document successfully added!")
                    }
                    group.leave()
                }
            } catch {
                print("Error creating request: \(error.localizedDescription)")
                group.leave()
            }
        }

        group.notify(queue: .main) {
            isLoading = false
            alertMessage = "Supply request successful!"
            showAlert = true
        }
    }
}

struct SupplyItemView: View {
    @Binding var supply: Supply

    var body: some View {
        VStack {
            Image(supply.imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(supply.isSelected ? Color.blue : Color.gray, lineWidth: 3)
                )
                .shadow(radius: 5)
            Text(supply.name)
                .font(.caption)
                .fontWeight(.bold)
                .padding(.top, 5)
                .foregroundColor(.black) // 텍스트 색상을 검정으로 조정
        }
        .frame(width: 130, height: 150) // 일정한 크기 설정
        .background(Color.white) // 배경을 흰색으로 조정
        .cornerRadius(10)
        .shadow(radius: 5)
        .onTapGesture {
            supply.isSelected.toggle()
        }
    }
}
