//
//  GroceryItemsTableViewController.swift
//  AmeeraAbduallah
//


import UIKit
import FirebaseAuth
import FirebaseDatabase

class GroceryItemsTableViewController: UITableViewController {
    
    // MARK: Properties
    var items: [GroceryItem] = []
    var user: User?
    var userCountBarButtonItem: UIBarButtonItem!
    let ref = Database.database().reference(withPath: "grocery-items")
    let usersRef = Database.database().reference(withPath: "online")
    var usersRefObservers: [DatabaseHandle] = []
    var handle: AuthStateDidChangeListenerHandle?
    
    var onlineUserCount: String = "1"
    let email = UserDefaults.standard.value(forKey: "email") as? String
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Groceries to Buy"
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "ImageBackground")!)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add , target: self, action: #selector(addItem))
        tableView.allowsMultipleSelectionDuringEditing = false
        userCountBarButtonItem = UIBarButtonItem(title: "\(onlineUserCount)",
                                                 style: .plain,
                                                 target: self,
                                                 action: #selector(openOnlineUsersView))
        userCountBarButtonItem.tintColor = UIColor.white
        navigationItem.leftBarButtonItem = userCountBarButtonItem
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let itemId = UUID().uuidString
        user = User(uid: itemId, email: email)
    }
    
    // MARK: - Grocery Items Management
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        ref.observe(.value, with: { snapshot in
            var newItems: [GroceryItem] = []
            
            for item in snapshot.children {
                let groceryItem = GroceryItem(snapshot: item as! DataSnapshot)
                newItems.append(groceryItem)
            }
            
            self.items = newItems
            self.tableView.reloadData()
            
        })
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let itemId = UUID().uuidString
        user = User(uid: itemId, email: email)
        
        handle = Auth.auth().addStateDidChangeListener { _, user in
            guard let user = user else { return }
            self.user = User(uid: itemId, email: email)
            
            let currentUserRef = self.usersRef.child(user.uid)
            currentUserRef.setValue(user.email)
            currentUserRef.onDisconnectRemoveValue()
        }
        
        let users = usersRef.observe(.value) { snapshot in
            if snapshot.exists() {
                self.onlineUserCount = snapshot.childrenCount.description
            } else {
                self.onlineUserCount = "0"
            }
        }
        usersRefObservers.append(users)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        usersRefObservers.forEach(ref.removeObserver(withHandle:))
        usersRefObservers = []
        usersRefObservers.forEach(usersRef.removeObserver(withHandle:))
        usersRefObservers = []
        guard let handle = handle else { return }
        Auth.auth().removeStateDidChangeListener(handle)
    }
    
    
    //MARK: - Add Item
    @objc func addItem() {
        let alert = UIAlertController(title: "Grocery Item",
                                      message: "Add an Item",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save",
                                       style: .default) { _ in
            
            guard let textField = alert.textFields?.first,
                  let text = textField.text,
                  let user = self.user else { return }
            
            let groceryItem = GroceryItem(name: text,
                                          addedByUser: user.email,
                                          completed: false)
            
            let groceryItemRef = self.ref.child(text.lowercased())
            groceryItemRef.setValue(groceryItem.toAnyObject())
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .default)
        
        alert.addTextField()
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - UITableView data source
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemCell", for: indexPath)
        let groceryItem = items[indexPath.row]
        
        cell.textLabel?.text = groceryItem.name
        cell.detailTextLabel?.text = groceryItem.addedByUser
        
        toggleCellCheckbox(cell, isCompleted: groceryItem.completed)
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    //MARK: - Delete Item
    override func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .normal, title: "Delete") { (contextAction, view, CompletionHandler) in
            
            let groceryItem = self.items[indexPath.row]
            groceryItem.ref?.removeValue()
            
        }
        //MARK: - Edit Item
        let editAction = UIContextualAction(style: .normal, title: "Edit") { (contextAction, view, CompletionHandler) in
            let grocery = self.items[indexPath.row]
            let alert = UIAlertController(title: "Grocery Item",
                                          message: "Edit an Item",
                                          preferredStyle: .alert)
            
            let saveAction = UIAlertAction(title: "Save",
                                           style: .default) { _ in
                
                guard let textField = alert.textFields?.first,
                      let text = textField.text,
                      let user = self.user else { return }
                
                let groceryItem = GroceryItem(name: text,
                                              addedByUser: user.email,
                                              completed: false)
                
                self.ref.child(grocery.key).setValue(groceryItem.toAnyObject())
                
            }
            
            
            let cancelAction = UIAlertAction(title: "Cancel",
                                             style: .default)
            
            alert.addTextField()
            
            alert.addAction(saveAction)
            alert.addAction(cancelAction)
            
            self.present(alert, animated: true, completion: nil)
        }
        deleteAction.backgroundColor = .red
        editAction.backgroundColor = .systemGreen
        deleteAction.image = UIImage(systemName: "trash")
        editAction.image = UIImage(systemName: "square.and.pencil")
        return UISwipeActionsConfiguration(actions :[deleteAction,editAction])
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        let groceryItem = items[indexPath.row]
        let toggledCompletion = !groceryItem.completed
        toggleCellCheckbox(cell, isCompleted: toggledCompletion)
        groceryItem.ref?.updateChildValues([
            "completed": toggledCompletion
        ])
        ref.queryOrdered(byChild: "completed").observe(.value, with: { snapshot in
            var newItems: [GroceryItem] = []
            
            for item in snapshot.children {
                let groceryItem = GroceryItem(snapshot: item as! DataSnapshot)
                newItems.append(groceryItem)
            }
            
            self.items = newItems
            self.tableView.reloadData()
        })
        
    }
    //MARK: - Completed Item
    
    func toggleCellCheckbox(_ cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = .none
            cell.textLabel?.textColor = UIColor.black
            cell.detailTextLabel?.textColor = UIColor.black
        } else {
            cell.accessoryType = .checkmark
            cell.textLabel?.textColor = UIColor.gray
            cell.detailTextLabel?.textColor = UIColor.gray
        }
    }
    
    @objc func openOnlineUsersView() {
        let OnlineUsersVC =  self.storyboard?.instantiateViewController(withIdentifier: "OnlineUsers") as! OnlineUsersTableViewController
        self.navigationController?.pushViewController(OnlineUsersVC, animated: true)
    }
    
}
