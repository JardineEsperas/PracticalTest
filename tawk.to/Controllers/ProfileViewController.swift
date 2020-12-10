//
//  ProfileViewController.swift
//  tawk.to
//
//  Created by Marc Jardine Esperas on 12/8/20.
//

import UIKit
import CoreData

class ProfileViewController: BaseViewController {
    
    // MARK: - Properties
    
    let service = APIService()
    private let context = CoreDataStack.sharedInstance.persistentContainer.viewContext
    private let userFetchRequest: NSFetchRequest<UserModel> = UserModel.fetchRequest()
    private let noteFetchRequest: NSFetchRequest<NoteModel> = NoteModel.fetchRequest()
    
    var user = UserModel()
    var note: String = ""

    // MARK: - Outlet Properties
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var repoLabel: UILabel!
    @IBOutlet weak var repoPlaceholderLabel: UILabel!
    @IBOutlet weak var followersLabel: UILabel!
    @IBOutlet weak var followersPlaceholderLabel: UILabel!
    @IBOutlet weak var followingLabel: UILabel!
    @IBOutlet weak var followingPlaceholderLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var blogLabel: UILabel!
    @IBOutlet weak var notesTextView: UITextView!
    @IBOutlet weak var saveButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        getUserProfile(with: user.url ?? "")
    }
    
    // Fetch API
    private func getUserProfile(with urlString: String) {
        self.showSpinner()
        
        service.getUserProfile(with: urlString) { [weak self] result in

            switch result {
            case .Success(let data):
                self?.updateUser(with: data!)
                
            case .Error(let message):
                DispatchQueue.main.async {
                    self?.updateUI()
                    self?.showAlert(title: "Error", message: message)
                }
            }
            
            DispatchQueue.main.async {
                self?.removeSpinner()
            }
        }
        
    }
    
    override func hasInternetConnection() {
        super.hasInternetConnection()
        
        getUserProfile(with: user.url ?? "")
    }
    
    private func getImage(urlString: String) {
        if let cachedImage = imageCache.object(forKey: NSString(string: urlString)) {
            profileImageView.image = cachedImage
        } else {
            profileImageView.loadImage(urlString, isInverted: false)
        }
    }
    
    private func updateUI() {
        title = (user.name != nil) ? user.name : user.login
        
        if let urlString = user.avatar_url {
            getImage(urlString: urlString)
        }
        
        followersLabel.text = String(user.followers)
        followingLabel.text = String(user.following)
        
        if let name = user.name {
            nameLabel.text = !(name).isEmpty ? "Name:  \(name)" : ""
        }
        
        if let company = user.company {
            companyLabel.text = !(company).isEmpty ? "Company:  \(company)" : ""
        }
        
        if let blog = user.blog {
            blogLabel.text = !(blog).isEmpty ? "Blog:  \(blog)" : ""
        }

        notesTextView.text = !(note).isEmpty ? note : "What's on your mind?"
        notesTextView.textColor = !(note).isEmpty ? UIColor(named: "TextFontColor") : UIColor.lightGray
        
    }

    
    // MARK: - UIButton Pressed
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        
        let text = notesTextView.text!
        
        var messageText = ""
        
        guard !text.isEmpty && text != "What's on your mind?" else {
            self.showAlert(title: "", message: "Please input a note")
            return
        }
        
        if note.isEmpty {
            
            addNote { message in
                messageText = message.isEmpty ? "Note Saved" : message
            }
            
        } else {
            
            updateNote(note: text) { (message) in
                messageText = message.isEmpty ? "Note Updated" : message
            }
            
        }
        
        updateUI()
        
        self.showAlert(title: "", message: messageText)
        
        notesTextView.resignFirstResponder()
    }
    
}

extension ProfileViewController: UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = ""
            textView.textColor = UIColor(named: "TextFontColor")
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "What's on your mind"
            textView.textColor = UIColor.lightGray
        }
    }
    
}

// MARK: - Core Data Methods
extension ProfileViewController {

    // Save Data
    private func saveData(completion: (String) -> Void) {
        
        do {
            try context.save()
            completion("")
        } catch {
            completion("Error saving context ")
        }
        
    }
    
    // Update User
    private func updateUser(with profileData: ProfileData) {
        
        userFetchRequest.predicate = NSPredicate(format: "id MATCHES %@", String(user.id))
        
        var userArray = [UserModel]()
        
        do {
            userArray = try context.fetch(userFetchRequest)
        } catch {
            print("Error fetching data from context")
        }
        
        userArray[0].setValue(profileData.login, forKey: "login")
        userArray[0].setValue(profileData.avatar_url, forKey: "avatar_url")
        userArray[0].setValue(profileData.followers, forKey: "followers")
        userArray[0].setValue(profileData.following, forKey: "following")
        userArray[0].setValue(profileData.blog, forKey: "blog")
        userArray[0].setValue(profileData.company, forKey: "company")
        userArray[0].setValue(profileData.name, forKey: "name")
        
        user = userArray[0]
        
        saveData { (message) in
            if !message.isEmpty {
                self.showAlert(title: "Error", message: message)
            }
        }
        
        self.updateUI()
        
    }
    
    // Add Note
    private func addNote(completion: (String) -> Void) {
        
        let newNote = NoteModel(context: self.context)
        
        newNote.id = user.id
        newNote.note = notesTextView.text
        
        saveData { (message) in
            self.note = notesTextView.text
            completion(message)
        }

    }
    
    // Update Note
    private func updateNote(note: String, completion: (String) -> Void) {
        
        noteFetchRequest.predicate = NSPredicate(format: "id MATCHES %@", String(user.id))
        
        var noteArray = [NoteModel]()
        
        do {
            noteArray = try context.fetch(noteFetchRequest)
        } catch {
            completion("Error fetching data from context")
        }
        
        noteArray[0].setValue(note, forKey: "note")
        
        saveData { (message) in
        
            completion(message)
            self.note = note
            
        }

    }
    
}
