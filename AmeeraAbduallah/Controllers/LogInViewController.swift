//
//  ViewController.swift
//  AmeeraAbduallah
//


import UIKit
import FirebaseAuth

class LogInViewController: UIViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    @IBOutlet weak var logInButton: UIButton!
    @IBOutlet weak var signUpButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Log In"
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "ImageBackground")!)
        logInButton.layer.cornerRadius = 10.0
        signUpButton.layer.cornerRadius = 10.0
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        emailField.text = ""
        passwordField.text = ""
        
    }
    // MARK: - Firebase Login

    @IBAction func logInButtonTapped(_ sender: UIButton) {
        
        guard let email = emailField.text,
              let password = passwordField.text, !email.isEmpty, !password.isEmpty else {
                  alertUserLoginError()
                  return
              }
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password, completion: { [weak self] authResult, error in
            
            guard let strongSelf = self else {
                return
            }
            guard let result = authResult, error == nil else {
                print("Failed to log in user with email \(email)")
                return
            }
            let user = result.user

            UserDefaults.standard.setValue(email, forKey: "email")
            print("logged in user: \(user)")
            // if this succeeds, dismiss
            let GroceryItemsVC =  strongSelf.storyboard?.instantiateViewController(withIdentifier: "GroceryItems") as! GroceryItemsTableViewController
            strongSelf.navigationController?.pushViewController(GroceryItemsVC, animated: true)
        })
       
    }
    
    @IBAction func signUpButtonTapped(_ sender: UIButton) {
        let signUpVC =  storyboard?.instantiateViewController(withIdentifier: "RegisterViewController") as! RegisterViewController
        navigationController?.pushViewController(signUpVC, animated: true)
        
    }
  
    func alertUserLoginError() {
           let alert = UIAlertController(title: "Warning",
                                         message: "Please enter all information to log in.",
                                         preferredStyle: .alert)
           alert.addAction(UIAlertAction(title:"Dismiss",
                                         style: .cancel, handler: nil))
           present(alert, animated: true)
       }
    
}

