import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Config {
    static let adminPassword = "1221"
}

// Admin Panel
struct AdminView: View {
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                NavigationLink(destination: ApprovedNumbersView()) {
                    HStack {
                        Image(systemName: "person.badge.plus")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 10)
                        Text("Manage Approved Numbers")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)

                NavigationLink(destination: RequestListView()) {
                    HStack {
                        Image(systemName: "list.bullet")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding(.trailing, 10)
                        Text("View Requests")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.green)
                            .cornerRadius(10)
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.top, 40)
            .background(Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)) // 배경색 설정
            .navigationTitle("Admin Mode")
        }
    }
}

// ApprovedNumbersViewModel
class ApprovedNumbersViewModel: ObservableObject {
    @Published var approvedNumbers = [ApprovedNumber]()

    private var db = Firestore.firestore()

    func fetchApprovedNumbers() {
        db.collection("ApprovedNumbers").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No documents found")
                return
            }
            self.approvedNumbers = documents.compactMap { doc in
                try? doc.data(as: ApprovedNumber.self)
            }
        }
    }

    func addApprovedNumber(id: String, name: String, dept: String) {
        let approvedNumber = ApprovedNumber(id: id, name: name, dept: dept)
        do {
            try db.collection("ApprovedNumbers").document(id).setData(from: approvedNumber)
        } catch {
            print("Error adding approved number: \(error.localizedDescription)")
        }
    }

    func deleteApprovedNumber(_ number: ApprovedNumber, password: String, completion: @escaping (Bool) -> Void) {
        if password == Config.adminPassword {
            db.collection("ApprovedNumbers").document(number.id!).delete { error in
                if let error = error {
                    print("Error deleting approved number: \(error.localizedDescription)")
                    completion(false)
                } else {
                    completion(true)
                }
            }
        } else {
            completion(false)
        }
    }
}

// ApprovedNumber Model
struct ApprovedNumber: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var dept: String
}

// ApprovedNumbersView
struct ApprovedNumbersView: View {
    @State private var newNumber = ""
    @State private var newName = ""
    @State private var newDept = ""
    @State private var showPasswordSheet = false
    @State private var password = ""
    @State private var selectedNumber: ApprovedNumber?
    @State private var showIncorrectPasswordAlert = false
    @ObservedObject private var viewModel = ApprovedNumbersViewModel()

    var body: some View {
        VStack {
            List {
                ForEach(viewModel.approvedNumbers, id: \.id) { number in
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Number: \(number.id ?? "")")
                            Text("Name: \(number.name)")
                            Text("Department: \(number.dept)")
                        }
                        Spacer()
                        Button(action: {
                            selectedNumber = number
                            showPasswordSheet = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(10)
                }
            }
            .onAppear {
                viewModel.fetchApprovedNumbers()
            }
            .listStyle(InsetGroupedListStyle()) // 리스트 스타일 설정

            VStack(spacing: 10) {
                TextField("New Number", text: $newNumber)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Name", text: $newName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                TextField("Department", text: $newDept)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)

                Button(action: {
                    viewModel.addApprovedNumber(id: newNumber, name: newName, dept: newDept)
                    newNumber = ""
                    newName = ""
                    newDept = ""
                }) {
                    Text("Add Approved Number")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .sheet(isPresented: $showPasswordSheet) {
            PasswordEntrySheet(isPresented: $showPasswordSheet, password: $password, onConfirm: {
                if let selectedNumber = selectedNumber {
                    viewModel.deleteApprovedNumber(selectedNumber, password: password) { success in
                        if !success {
                            showIncorrectPasswordAlert = true
                        }
                    }
                }
            })
        }
        .alert(isPresented: $showIncorrectPasswordAlert) {
            Alert(
                title: Text("Incorrect Password"),
                message: Text("The password you entered is incorrect."),
                dismissButton: .default(Text("OK"))
            )
        }
        .background(Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)) // 배경색 설정
        .navigationTitle("Approved Numbers")
    }
}

// PasswordEntrySheet
struct PasswordEntrySheet: View {
    @Binding var isPresented: Bool
    @Binding var password: String
    var onConfirm: () -> Void

    var body: some View {
        VStack {
            Text("Enter Password")
                .font(.headline)
                .padding()

            SecureField("Password", text: $password)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()

            HStack {
                Button(action: {
                    isPresented = false
                }) {
                    Text("Cancel")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()

                Button(action: {
                    onConfirm()
                    isPresented = false
                }) {
                    Text("Confirm")
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                }
                .padding()
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)) // 배경색 설정
    }
}

// RequestListViewModel
class RequestListViewModel: ObservableObject {
    @Published var requests = [Request]()

    private var db = Firestore.firestore()

    func fetchRequests() {
        db.collection("CompletedOrders")
            .order(by: "timestamp", descending: true)  // 타임스탬프 필드를 기준으로 내림차순 정렬
            .addSnapshotListener { querySnapshot, error in
                guard let documents = querySnapshot?.documents else {
                    print("No documents found")
                    return
                }
                self.requests = documents.compactMap { doc in
                    try? doc.data(as: Request.self)
                }
            }
    }
}

// RequestListView
struct RequestListView: View {
    @ObservedObject private var viewModel = RequestListViewModel()

    var body: some View {
        VStack {
            List(viewModel.requests) { request in
                VStack(alignment: .leading) {
                    Text("Type: \(request.type)")
                    Text("Item: \(request.item)")
                    Text("Room Number: \(request.roomNumber)")
                    Text("Timestamp: \(request.timestamp.dateValue().formatted(.dateTime.month().day().hour().minute()))")
                }
                .padding()
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)
            }
            .onAppear {
                viewModel.fetchRequests()
            }
            .listStyle(InsetGroupedListStyle()) // 리스트 스타일 설정
        }
        .background(Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all)) // 배경색 설정
        .navigationTitle("Completed Requests")
    }
}
