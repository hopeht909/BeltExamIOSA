//
//  RegisterViewController.swift
//  AmeeraAbduallah
//


import UIKit
import FirebaseAuth
class RegisterViewController: UIViewController {
    
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwirdField: UITextField!
    @IBOutlet weak var signUpButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Create Account"
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "ImageBackground")!)
        signUpButton.layer.cornerRadius = 10.0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        nameField.text = ""
        emailField.text = ""
        passwirdField.text = ""
    }
    // MARK: - Firebase SignUp
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        
        guard let password = passwirdField.text, let email = emailField.text,
              let name = nameField.text, !email.isEmpty, !password.isEmpty,
              !name.isEmpty else {
                  alertUserLoginError()
                  return
              }
          
            // try to create an account
            FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password, completion: { authResult , error  in
                guard authResult != nil, error == nil else {
                    print("Error creating user")
                    return
                }
                UserDefaults.standard.setValue(email, forKey: "email")
                UserDefaults.standard.setValue(name, forKey: "name")
                let itemId = UUID().uuidString
                let _ = User(uid: itemId, email: email)
                // if this succeeds, dismiss
                let GroceryItemsVC =  self.storyboard?.instantiateViewController(withIdentifier: "GroceryItems") as! GroceryItemsTableViewController
                self.navigationController?.pushViewController(GroceryItemsVC, animated: true)
            })
    }
    func alertUserLoginError(message: String = "Please enter all information to log in.") {
        let alert = UIAlertController(title: "Warning",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title:"Dismiss",
                                      style: .cancel, handler: nil))
        present(alert, animated: true)
    }
}
