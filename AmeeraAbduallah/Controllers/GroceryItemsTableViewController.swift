//
//  GroceryItemsTableViewController.swift
//  AmeeraAbduallah
//


import UIKit
import FirebaseAuth
import FirebaseDatabase

class GroceryItemsTableViewController: UITableViewController {
    
    // MARK: Constants
    let listToUsers = "ListToUsers"
    
    // MARK: Properties
    var items: [GroceryItem] = []
    var user: User!
    var userCountBarButtonItem: UIBarButtonItem!
    let ref = Database.database().reference(withPath: "grocery-items")
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Groceries to Buy"
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add , target: self, action: #selector(addItem))
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Sign out", style: .done, target: self, action: #selector(signOut))
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                   return 
               }
        let itemId = UUID().uuidString
        user = User(uid: itemId, email: email)
        
        ref.observe(.value, with: { snapshot in
            var newItems: [GroceryItem] = []
            
            for item in snapshot.children {
                let groceryItem = GroceryItem(snapshot: item as! DataSnapshot)
                newItems.append(groceryItem)
            }
            
            self.items = newItems
            self.tableView.reloadData()
            
        })
    }
    
    
    //MARK: - Add Item
    @objc func addItem() {
        let alert = UIAlertController(title: "Grocery Item",
                                      message: "Add an Item",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save",
                                       style: .default) { _ in
        
            guard let textField = alert.textFields?.first,
                  let text = textField.text else { return }
            
            let groceryItem = GroceryItem(name: text,
                                          addedByUser: self.user.email,
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
                
                //strongSelf.present(logInVC, animated: false)
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
    //MARK: - Edit Item
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        let grocery = items[indexPath.row]
        let alert = UIAlertController(title: "Grocery Item",
                                      message: "Edit an Item",
                                      preferredStyle: .alert)
        
        let saveAction = UIAlertAction(title: "Save",
                                       style: .default) { _ in
            
            guard let textField = alert.textFields?.first,
                  let text = textField.text else { return }

            let groceryItem = GroceryItem(name: text,
                                          addedByUser: self.user.email,
                                          completed: false)
            
            self.ref.child(grocery.key).setValue(groceryItem.toAnyObject())
        
        }
        
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .default)
        
        alert.addTextField()
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
        
    }
    //MARK: - Delete Item
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let groceryItem = items[indexPath.row]
            groceryItem.ref?.removeValue()
        }
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
    
}
