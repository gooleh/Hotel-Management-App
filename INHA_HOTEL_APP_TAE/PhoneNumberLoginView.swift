import SwiftUI
import FirebaseFirestore

struct PhoneNumberLoginView: View {
    @EnvironmentObject var userSession: UserSession
    @State private var phoneNumber: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 배경 이미지 추가
                Image("backgroundimage03") // 여기에 배경 이미지 이름을 넣으세요
                    .resizable()
                    .scaledToFill()
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 20) {
                    Spacer() // 상단에 여백 추가

                    Text("Welcome to INHA Hotel Management")
                        .font(.title)
                        .foregroundColor(Color.white)
                        .shadow(radius: 10) // 텍스트에 그림자 추가
                        .padding(.bottom, 20) // 텍스트 하단에 여백 추가

                    TextField("Enter Phone Number", text: $phoneNumber)
                        .padding()
                        .background(Color(.systemGray6).opacity(0.8)) // 투명도 추가
                        .cornerRadius(5.0)
                        .padding(.horizontal, geometry.size.width * 0.1) // 좌우 여백을 화면 크기에 따라 조정
                        .frame(height: geometry.size.height * 0.05) // 입력 필드 높이를 화면 크기에 따라 조정

                    if isLoading {
                        ProgressView()
                            .padding(.top, 20) // 상단 여백 추가
                    } else {
                        Button("Login") {
                            loginUserWithPhoneNumber()
                        }
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity, minHeight: geometry.size.height * 0.05) // 버튼 높이를 화면 크기에 따라 조정
                        .background(Color.blue)
                        .cornerRadius(10)
                        .padding(.horizontal, geometry.size.width * 0.1) // 좌우 여백을 화면 크기에 따라 조정
                        .padding(.top, 20) // 상단 여백 추가
                    }

                    Spacer() // 하단에 여백 추가
                }
                .padding(.vertical, 40) // 상하 여백 조정
                .navigationTitle("Login")
                .navigationBarTitleDisplayMode(.inline)
                .alert(isPresented: .constant(errorMessage != nil), content: {
                    Alert(title: Text("Login Error"), message: Text(errorMessage ?? "Unknown error occurred"), dismissButton: .default(Text("OK")))
                })
            }
        }
    }

    private func loginUserWithPhoneNumber() {
        guard !phoneNumber.isEmpty else {
            errorMessage = "Please enter a phone number."
            return
        }

        isLoading = true
        userSession.login(phoneNumber: phoneNumber) { success, error in
            DispatchQueue.main.async {
                isLoading = false
                if success {
                    userSession.startListeningForRoomUpdates()
                    userSession.connectSocket() // 소켓 연결 시작
                } else {
                    errorMessage = error
                }
            }
        }
    }
}

struct PhoneNumberLoginView_Previews: PreviewProvider {
    static var previews: some View {
        PhoneNumberLoginView().environmentObject(UserSession())
    }
}
