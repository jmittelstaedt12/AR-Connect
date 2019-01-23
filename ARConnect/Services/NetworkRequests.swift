//
//  NetworkRequests.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 1/18/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa

struct NetworkRequests {

    enum Result {
        case success(Data)
        case failure(Error?)
    }

    static func profilePictureNetworkRequest(withUrl url: URL, completion: @escaping (Data) -> Void) {
        URLSession.shared.dataTask(with: url) { (data, _, error) in
            guard let data = data else {
                if let error = error { print(error.localizedDescription) }
                return
            }
            completion(data)
        }.resume()
    }

}
