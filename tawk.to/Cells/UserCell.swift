//
//  UserCell.swift
//  tawk.to
//
//  Created by Marc Jardine Esperas on 12/8/20.
//

import UIKit

class UserCell: UITableViewCell {
    
    @IBOutlet weak var avatarImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    @IBOutlet weak var skeletonImageView: UIImageView!
    
    func setCellData(user: UserModel, indexPathRow: Int, note: String) {
        
        let isInverted: Bool = shouldInvert(row: indexPathRow)
        
        DispatchQueue.main.async {
            self.usernameLabel.text = user.login
            self.detailsLabel.text = note.isEmpty ? user.url : note
            
            if let url = user.avatar_url {
                self.avatarImageView.loadImage(url, isInverted: isInverted)
            }
        }
    }
    
    private func shouldInvert (row: Int) -> Bool {
        return (row + 1) % 4 == 0
    }
    
}
