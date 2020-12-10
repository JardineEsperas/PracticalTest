//
//  UserViewController.swift
//  tawk.to
//
//  Created by Marc Jardine Esperas on 12/9/20.
//

import UIKit
import CoreData

protocol UserViewControllerRouterType {
    func goToProfileViewController(with user: UserModel, note: String?)
}

class UserViewController: BaseViewController {

    private let service = APIService()
    private let context = CoreDataStack.sharedInstance.persistentContainer.viewContext

    private var usersListArray = [UserModel]()
    private var noteArray = [NoteModel]()
    
    private var sinceUserID: Int = 0
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        print(FileManager.default.urls(for: .documentDirectory, in: .userDomainMask))
        
        setUpUI()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    
        loadNote()
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

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
        print("SINCE USER ID: \(sinceUserID)")
        service.getUsersList(currentUsersCount: sinceUserID) { [weak self] result in

            switch result {
            case .Success(let data):
                self?.clearData()
                self?.addData(with: data!)
                
            case .Error(let message):
                DispatchQueue.main.async {
                    self?.loadUserData()
                    self?.showAlert(title: "", message: message)
                }
            }
            DispatchQueue.main.async {
                self?.removeSpinner()
            }
        }
    }
    
    override func hasInternetConnection() {
        super.hasInternetConnection()
        
        showSpinner()
        loadNote()
        getUsersList()
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
        
        self.tableView.reloadData()

    }
}

// MARK: - UITableView Data Source

extension UserViewController: UITableViewDataSource {
    
    func getIdentifier(with note: String) -> String {
        return note.isEmpty ? "UserCell" : "UserCellNote"
    }

    func hasNote(note: String) -> Bool {
        return  note.isEmpty ? false : true
    }
    
    func getNote(userId: Int) -> String {
        guard let note = noteArray.first(where: { $0.id == userId }) else {
           return ""
        }
        
        return note.note ?? ""
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let note = getNote(userId: Int(usersListArray[indexPath.row].id))
        
        let cellIdentifier = getIdentifier(with: note)
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as? UserCell else {
            fatalError("TableViewCell not found")
        }
        
        cell.setCellData(user: usersListArray[indexPath.row], indexPathRow: indexPath.row, note: note)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return usersListArray.count
    }

}

// MARK: - UITableView Delegate
extension UserViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        goToProfileViewController(with: usersListArray[indexPath.row], note: getNote(userId: Int(usersListArray[indexPath.row].id)))
    }

}

// MARK: - UIScrollView Delegate

extension UserViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let position = scrollView.contentOffset.y
        let tableViewHeight = tableView.contentSize.height
        let buttomHeightLeft: CGFloat = 20
        let scrollViewHeight = scrollView.frame.size.height
        
        if position > tableViewHeight - buttomHeightLeft - scrollViewHeight {

            guard !service.isPaginating else {
                return
            }
            
            tableView.tableFooterView = self.createSpinnerFooter()
            
            getUsersList()
        }
    }
    
}

// MARK: - UISearchBarDelegate Methods

extension UserViewController: UISearchBarDelegate {
    
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
        
        searchBar.resignFirstResponder()
        
        let text = searchBar.text!
        
        guard !text.isEmpty else {
            return
        }
        
        filterData(with: searchBar.text!)
        
    }
    
    // MARK: - UISearchBar Methods
    // Filter Array using Predicate
    private func filterData(with text: String) {
        
        let request: NSFetchRequest<UserModel> = UserModel.fetchRequest()
        
        request.predicate = NSPredicate(format: "login CONTAINS[c] %@", text)
        
        request.sortDescriptors = [NSSortDescriptor(key: "login", ascending: true, selector: #selector(NSString.caseInsensitiveCompare))]
        
        loadUserData(with: request)
        
    }
}

// MARK: - UserViewController Router

extension UserViewController: UserViewControllerRouterType {
    
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
