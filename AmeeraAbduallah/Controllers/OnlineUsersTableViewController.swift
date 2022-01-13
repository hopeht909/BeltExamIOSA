//
//  OnlineUsersTableViewController.swift
//  AmeeraAbduallah
//

import UIKit
import FirebaseAuth
import FirebaseDatabase

class OnlineUsersTableViewController: UITableViewController {
    
    // MARK: Properties
    let usersRef = Database.database().reference(withPath: "online")
    var usersRefObservers: [DatabaseHandle] = []
    var currentUsers: [String] = []
    var user: User!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Family (Online)"
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "ImageBackground")!)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Sign out", style: .done, target: self, action: #selector(signOut))
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    // MARK: -  Online Users Management
    override func viewWillAppear(_ animated: Bool) {
        // 1
        let childAdded = usersRef
            .observe(.childAdded) { [weak self] snap in
                // 2
                guard
                    let email = snap.value as? String,
                    let self = self
                else { return }
                self.currentUsers.append(email)
                print (self.currentUsers)
                // 3
                let row = self.currentUsers.count-1
                // 4
                let indexPath = IndexPath(row: row, section: 0)
                print (indexPath)
                // 5
                self.tableView.insertRows(at: [indexPath], with: .top)
            }
        usersRefObservers.append(childAdded)
        let childRemoved = usersRef
            .observe(.childRemoved) {[weak self] snap in
                guard
                    let emailToFind = snap.value as? String,
                    let self = self
                else { return }
                
                for (index, email) in self.currentUsers.enumerated()
                where email == emailToFind {
                    let indexPath = IndexPath(row: index, section: 0)
                    self.currentUsers.remove(at: index)
                    self.tableView.deleteRows(at: [indexPath], with: .fade)
                }
            }
        usersRefObservers.append(childRemoved)
        
        
    }
    override func viewDidDisappear(_ animated: Bool) {
        usersRefObservers.forEach(usersRef.removeObserver(withHandle:))
        usersRefObservers = []
    }
    //MARK: - Sign Out
    @objc func signOut() {
        let actionSheet = UIAlertController(title: "",
                                            message: "Are you sure you want to log out",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Log Out",
                                            style: .destructive,
                                            handler: { [weak self] _ in
            
            guard let strongSelf = self else {
                return
            }
            UserDefaults.standard.setValue(nil, forKey: "email")
            UserDefaults.standard.setValue(nil, forKey: "name")
            do {
                try FirebaseAuth.Auth.auth().signOut()
                
                let logInVC =  strongSelf.storyboard?.instantiateViewController(withIdentifier: "LogInViewController") as! LogInViewController
                logInVC.modalPresentationStyle = .fullScreen
                strongSelf.navigationController?.popToRootViewController(animated: true)
                
            }
            catch {
                print("Failed to log out")
            }
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        present(actionSheet, animated: true)
    }
    
    // MARK: - Table view data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentUsers.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        let onlineUserEmail = currentUsers[indexPath.row]
        cell.textLabel?.text = onlineUserEmail
        return cell
    }
}
