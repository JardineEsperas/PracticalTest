//
//  APIService.swift
//  tawk.to
//
//  Created by Marc Jardine Esperas on 12/8/20.
//

import Foundation

typealias APIServiceCompletionHandler = ((Result<[UserData]?>) -> Void)

enum Result<T> {
    case Success(T)
    case Error(String)
}

class APIService {
    private let baseURL: String = "https://api.github.com"
    private let userListUrl: String = "/users?since="
    var isPaginating: Bool = false
    
    func getUsersList(currentUsersCount: Int, completion: @escaping (Result<[UserData]?>) -> Void) {
        isPaginating = true
        
        let urlString = "\(baseURL)\(userListUrl)\(currentUsersCount)"
        
        guard let url = URL(string:urlString ) else {
            return completion(.Error("Invalid URL, we can't update your feed"))
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            guard error == nil else {
                return completion(.Error(error!.localizedDescription))
            }
            
            guard let data = data else {
                return completion(.Error(error?.localizedDescription ?? "There are no new Items to show"))
            }
            
            let articleList = try? JSONDecoder().decode([UserData].self, from: data)
            
            if let articleList = articleList {
                DispatchQueue.main.async {
                    completion(.Success(articleList))
                    self.isPaginating = false
                }
            }
                
        }.resume()
    }
    
    func getUserProfile(with urlString: String, completion: @escaping (Result<ProfileData?>) -> Void) {
        
        guard let url = URL(string:urlString ) else {
            return completion(.Error("Invalid URL, we can't update your feed"))
        }
        
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            
            guard error == nil else {
                return completion(.Error(error!.localizedDescription))
            }
            
            guard let data = data else {
                return completion(.Error(error?.localizedDescription ?? "There are no new Items to show"))
            }
            
            let profile = try? JSONDecoder().decode(ProfileData.self, from: data)
            
            if let profile = profile {
                print(profile)
                DispatchQueue.main.async {
                    completion(.Success(profile))
                    
                }
                
            }
            
        }.resume()
    }
    
}

