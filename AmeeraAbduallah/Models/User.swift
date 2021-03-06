//
//  User.swift
//  AmeeraAbduallah
//

import Foundation
import Firebase

struct User {
  
  let uid: String
  let email: String
  
    init(authData: User) {
    uid = authData.uid
    email = authData.email
        
  }
  
  init(uid: String, email: String) {
    self.uid = uid
    self.email = email
  }
    var safeEmail: String {
        
        var safeEmail = email.replacingOccurrences(of: ".", with: "-")
        safeEmail = safeEmail.replacingOccurrences(of: "@", with: "-")
        return safeEmail
    }
}
