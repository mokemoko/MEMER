//
//  FirebaseManager.swift
//  SelfOpenData
//
//  Created by 浅野　宏明 on 2018/05/21.
//  Copyright © 2018年 akylab. All rights reserved.
//

import Firebase
import FirebaseDatabase

final class FirebaseManager {
    enum Category: String {
        case ally
        case health
        case meme
        
        fileprivate func ref() -> DatabaseReference {
            return Database.database().reference(withPath: "public/\(self.rawValue)/\(FirebaseManager.targetUser)")
        }
    }
    static let shared = FirebaseManager()
    
    // TODO: 一旦固定
    static let targetUser = "hiro-asano"
    
    private init() {}
    
    func setup() {
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
    }
    
    func update(type: Category, additionalPath: String, data: [AnyHashable: Any]) {
        type.ref().child(additionalPath).updateChildValues(data)
    }
}
