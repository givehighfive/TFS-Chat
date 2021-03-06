//
//  FirestoreManager.swift
//  TFS Chat
//
//  Created by dmitry on 17.10.2020.
//  Copyright © 2020 dmitry. All rights reserved.
//

import FirebaseFirestore

protocol ApiClientProtocol {
    
    func addSnapshotListener<T>(for collection: CollectionReference,
                                mapper: @escaping (QueryDocumentSnapshot) -> T?,
                                completion: @escaping ([T]) -> Void) -> ListenerRegistration
    
    func addDocument(to collection: CollectionReference, document: [String: Any], completion: @escaping () -> Void)
    
    func deleteDocument(_ document: DocumentReference)
    
    func getMessagesPath(channelId: String) -> CollectionReference
    
    func getChannelsRootPath() -> CollectionReference
    
    func getChannelPath(channelId: String) -> DocumentReference 
}

class FirestoreClient: ApiClientProtocol {
    
    private let root = Firestore.firestore().collection("channels")
    
    func addSnapshotListener<T>(for collection: CollectionReference,
                                mapper: @escaping (QueryDocumentSnapshot) -> T?,
                                completion: @escaping ([T]) -> Void) -> ListenerRegistration {
        let listener = collection.addSnapshotListener { snapshot, error in
            if let error = error {
                print("Load data error: " + error.localizedDescription)
            } else {
                guard let snapshot = snapshot else { return }
                let documents = snapshot.documents.compactMap { mapper($0) }
                LoggingUtil.debugPrint(documents.count, " documents loaded from firestore")
                completion(documents)
            }
        }
        return listener
    }
    
    func addDocument(to collection: CollectionReference, document: [String: Any], completion: @escaping () -> Void) {
        collection.addDocument(data: document) { error in
            if let error = error {
                print("Add document error: " + error.localizedDescription)
            } else {
                completion()
                LoggingUtil.debugPrint("Document successfully added")
            }
        }
    }
    
    func deleteDocument(_ document: DocumentReference) {
        document.delete { error in
            if let error = error {
                print("Error deleting document: \(error)")
            } else {
                LoggingUtil.debugPrint("Document successfully deleted")
            }
        }
    }
    
    func getMessagesPath(channelId: String) -> CollectionReference {
        return root.document(channelId).collection("messages")
    }
    
    func getChannelsRootPath() -> CollectionReference {
        return root
    }
    
    func getChannelPath(channelId: String) -> DocumentReference {
        return root.document(channelId)
    }
    
}
