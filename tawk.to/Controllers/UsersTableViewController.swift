//
//  UsersTableViewController.swift
//  tawk.to
//
//  Created by Marc Jardine Esperas on 12/5/20.
//

import UIKit
import CoreData

protocol UsersTableViewControllerRouterType {
    func goToProfileViewController(with user: UserModel, note: String?)
}

class UsersTableViewController: UITableViewController {

    private let service = APIService()
    private let context = CoreDataStack.sharedInstance.persistentContainer.viewContext

    private var usersListArray = [UserModel]()
    private var noteArray = [NoteModel]()
    
    private var sinceUserID: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
        setUpUI()
        loadNote()
        getUsersList()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        loadNote()
    }
    
    func setUpUI() {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(self.refresh), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    // Pull to refresh
    @objc func refresh() {
        getUsersList()
    }
    
    // Fetch API
    private func getUsersList() {

        service.getUsersList(currentUsersCount: sinceUserID) { [weak self] result in

            switch result {
            case .Success(let data):
                self?.clearData()
                self?.addData(with: data!)
                
            case .Error(let message):
                self?.loadUserData()
                self?.showAlert(title: "", message: message)
            }
            
        }
    }
    
    private func showAlert(title: String, message: String, style: UIAlertController.Style = .alert) {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: style)
        
        let action = UIAlertAction(title: "Close", style: .default) { (action) in
            self.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(action)
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    private func createSpinnerFooter() -> UIView {
        let footerView = UIView(frame: CGRect(x: 0, y: 0, width: view.frame.size.width, height: 20))
        
        let spinner = UIActivityIndicatorView()
        
        spinner.center = footerView.center
        
        footerView.addSubview(spinner)
        
        spinner.startAnimating()
        
        return footerView
    }
    
// MARK: - Data Manipulation Methods
    
    // Get User Data
    private func loadUserData(with request: NSFetchRequest<UserModel> = UserModel.fetchRequest()) {
        
        request.sortDescriptors = [NSSortDescriptor(key: "id", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))]
        
        do {
            usersListArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }
        
        self.tableView.reloadData()
        self.tableView.refreshControl?.endRefreshing()
    }
    
    // Save Data
    private func saveData() {
        
        do {
            try context.save()
        } catch {
            print("Error saving context \(error)")
        }
        
        self.tableView.reloadData()
        tableView.refreshControl?.endRefreshing()
        tableView.tableFooterView = nil
    }
    
    // Clear Data
    private func clearData() {
        
        guard sinceUserID == 0 else {
            return
        }
        
        do {
            
            let fetchRequest: NSFetchRequest<UserModel> = UserModel.fetchRequest()
            
            do {
                
                let array  = try context.fetch(fetchRequest)
                _ = array.map{
                    context.delete($0)
                    usersListArray.removeAll()
                }
                
                CoreDataStack.sharedInstance.saveContext()
                
            } catch let error {
                print("ERROR DELETING : \(error)")
            }
            
        }
    }
    
    // Add Data
    private func addData(with array: [UserData]) {
        
        _ = array.map {

            let newUser = UserModel(context: self.context)
            
            newUser.login = $0.login
            newUser.id = Int32($0.id)
            newUser.avatar_url = $0.avatar_url
            newUser.url = $0.url
            
            self.usersListArray.append(newUser)
            self.sinceUserID = $0.id
        }
        
        saveData()
        
    }
    
    // Get Data
    private func loadNote(with request: NSFetchRequest<NoteModel> = NoteModel.fetchRequest()) {

        do {
            noteArray = try context.fetch(request)
        } catch {
            print("Error fetching data from context \(error)")
        }

    }
}

// MARK: - UITableView Data Source

extension UsersTableViewController {
    
    func getIdentifier(with note: String) -> String {
        return note.isEmpty ? "UserCell" : "UserCellNote"
    }
    
    func hasNote(note: String) -> Bool {
        return  note.isEmpty ? false : true
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let note = getNote(userId: Int(usersListArray[indexPath.row].id))
        
        let cellIdentifier = getIdentifier(with: note)
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? UserCell else {
            fatalError("TableViewCell not found")
        }
        
        cell.setCellData(user: usersListArray[indexPath.row], indexPathRow: indexPath.row, note: note)
        cell.detailsLabel.text = note
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersListArray.count
    }
    
    func getNote(userId: Int) -> String {
        guard let note = noteArray.first(where: { $0.id == userId }) else {
           return ""
        }
        
        return note.note ?? ""
    }
}

// MARK: - UITableView Delegate
extension UsersTableViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        goToProfileViewController(with: usersListArray[indexPath.row], note: getNote(userId: Int(usersListArray[indexPath.row].id)))
    }

}

// MARK: - UIScrollView Delegate

extension UsersTableViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let position = scrollView.contentOffset.y
        let tableViewHeight = tableView.contentSize.height
        let buttomHeightLeft: CGFloat = 20
        let scrollViewHeight = scrollView.frame.size.height
        
        if position > tableViewHeight - buttomHeightLeft - scrollViewHeight {

            guard !service.isPaginating else {
                return
            }
            
            tableView.tableFooterView = createSpinnerFooter()
            
            getUsersList()
        }
    }
}

// MARK: - UISearchBarDelegate Delegate

extension UsersTableViewController: UISearchBarDelegate {
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        
        if searchBar.text?.count == 0 {
            loadUserData()
            
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        } else {
            filterData(with: searchBar.text!)
        }

    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        filterData(with: searchBar.text!)
        
    }
    
    // Filter Array using Predicate
    private func filterData(with text: String) {
        
        let request: NSFetchRequest<UserModel> = UserModel.fetchRequest()
        
        request.predicate = NSPredicate(format: "login CONTAINS[c] %@", text)
        
        request.sortDescriptors = [NSSortDescriptor(key: "login", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))]
        
        loadUserData(with: request)
        
    }
}

// MARK: - UsersTableViewController Router

extension UsersTableViewController: UsersTableViewControllerRouterType {
    
    func goToProfileViewController(with user: UserModel, note: String?) {
        
        if let viewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ProfileViewController") as? ProfileViewController {
            
            viewController.user = user
            viewController.note = note ?? ""
            
            if let navigator = navigationController {
                navigator.pushViewController(viewController, animated: true)
            }
        }
        
    }
    
}
