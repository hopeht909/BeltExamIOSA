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
        super.viewWillAppear(true)
        
        let childAdded = usersRef
            .observe(.childAdded) { [weak self] snap in
                guard
                    let email = snap.value as? String,
                    let self = self
                else { return }
                self.currentUsers.append(email)
                print (self.currentUsers)
                let row = self.currentUsers.count-1
                let indexPath = IndexPath(row: row, section: 0)
                print (indexPath)
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
        super.viewDidDisappear(true)
        usersRefObservers.forEach(usersRef.removeObserver(withHandle:))
        usersRefObservers = []
    }
    
    //MARK: - Sign Out
    @objc func signOut() {
        guard let user = Auth.auth().currentUser else { return }
        
        let onlineRef = Database.database().reference(withPath: "online/\(user.uid)")
        onlineRef.removeValue { error, _ in
            if let error = error {
                print("Removing online failed: \(error)")
                return
            }
            do {
                try Auth.auth().signOut()
                self.navigationController?.popToRootViewController(animated: true)
            } catch let error {
                print("Auth sign out failed: \(error)")
            }
        }
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
