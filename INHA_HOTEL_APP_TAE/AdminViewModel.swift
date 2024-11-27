import SwiftUI
import FirebaseFirestore
import FirebaseFirestoreSwift

class AdminViewModel: ObservableObject {
    @Published var approvedNumbers: [ApprovedNumber] = []
    @Published var requests: [Request] = []
    @Published var newNumber: String = ""
    @Published var newName: String = ""
    @Published var newDept: String = ""

    private var db = Firestore.firestore()

    init() {
        fetchApprovedNumbers()
        fetchRequests()
    }

    func fetchApprovedNumbers() {
        db.collection("ApprovedNumbers").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No approved numbers found")
                return
            }
            self.approvedNumbers = documents.compactMap { doc -> ApprovedNumber? in
                try? doc.data(as: ApprovedNumber.self)
            }
        }
    }

    func addApprovedNumber() {
        let data: [String: Any] = ["name": newName, "dept": newDept]
        db.collection("ApprovedNumbers").document(newNumber).setData(data) { error in
            if let error = error {
                print("Error adding approved number: \(error.localizedDescription)")
            } else {
                self.newNumber = ""
                self.newName = ""
                self.newDept = ""
            }
        }
    }

    func fetchRequests() {
        db.collection("Requests").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("No requests found")
                return
            }
            self.requests = documents.compactMap { doc -> Request? in
                try? doc.data(as: Request.self)
            }
        }
    }
}



