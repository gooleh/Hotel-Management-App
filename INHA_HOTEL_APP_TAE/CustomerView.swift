import SwiftUI

struct CustomerView: View {
    @EnvironmentObject var userSession: UserSession
    @State private var currentImageIndex = 0
    @State private var timer: Timer?
    @State private var offset: CGFloat = 0

    // 배경 이미지 배열
    let backgroundImages = ["image1", "image2", "image3"]

    var body: some View {
        ZStack {
            // 배경 이미지 애니메이션 추가
            Image(backgroundImages[currentImageIndex])
                .resizable()
                .scaledToFill()
                .edgesIgnoringSafeArea(.all)
                .offset(x: offset)
                .transition(.opacity) // 페이드 인/아웃 효과

            // 반투명한 블랙 오버레이
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)

            VStack {
                HStack {
                    // 객실 번호를 작은 글씨로 왼쪽 상단에 표시
                    if let roomNumber = userSession.roomNumber {
                        Text("Room \(roomNumber)")
                            .font(.caption)
                            .foregroundColor(.white)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(5)
                            .padding([.top, .leading], 20)
                    } else {
                        Text("Room number not available")
                            .font(.caption)
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Color.black.opacity(0.5))
                            .cornerRadius(5)
                            .padding([.top, .leading], 20)
                    }
                    Spacer()
                }
                Spacer()

                VStack(spacing: 20) {
                    // Request Supplies 버튼
                    NavigationLink(destination: SupplyRequestView().environmentObject(userSession)) {
                        HStack {
                            Image(systemName: "cart.fill") // 아이콘 추가
                                .foregroundColor(.blue.opacity(0.8))
                                .font(.title2)
                            Text("Request Supplies")
                                .font(.headline)
                                .foregroundColor(.white)
                                .shadow(radius: 5) // 텍스트에 그림자 추가
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)

                    // Request Room Service 버튼
                    NavigationLink(destination: RoomServiceRequestView().environmentObject(userSession)) {
                        HStack {
                            Image(systemName: "bell.fill") // 아이콘 추가
                                .foregroundColor(.green.opacity(0.8))
                                .font(.title2)
                            Text("Request Room Service")
                                .font(.headline)
                                .foregroundColor(.white)
                                .shadow(radius: 5) // 텍스트에 그림자 추가
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(15)
                        .shadow(radius: 5)
                    }
                    .padding(.horizontal, 20)
                }
                Spacer()
            }
            .padding()
        }
        .onAppear {
            // 로그인된 사용자의 전화번호로 roomNumber를 가져옵니다.
            if let phoneNumber = userSession.roomNumber {
                userSession.fetchRoomDetails(roomNumber: phoneNumber) {
                    print("Room details fetched for: \(userSession.roomNumber ?? "nil")")
                    userSession.startListeningForRoomUpdates()
                }
            } else {
                print("No room number available on appear")
            }
            startImageAnimation()
        }
        .onDisappear {
            userSession.stopListeningForRoomUpdates()
            timer?.invalidate()
        }
    }

    private func startImageAnimation() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
            withAnimation(.linear(duration: 0.02)) {
                offset += 1
                if offset >= UIScreen.main.bounds.width {
                    offset = -UIScreen.main.bounds.width
                    currentImageIndex = (currentImageIndex + 1) % backgroundImages.count
                }
            }
        }
    }
}

struct CustomerView_Previews: PreviewProvider {
    static var previews: some View {
        CustomerView().environmentObject(UserSession())
    }
}
