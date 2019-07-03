//
//  UserCellModel.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/14/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import RxSwift

class UserCellModel {
    var user: LocalUser
    let uid: String
    let name: String
    let username: String
    let isOnline: PublishSubject<Bool> = PublishSubject()
    let profileImageData = ReplaySubject<Data>.create(bufferSize: 1)
    let firebaseClient: FirebaseClient

    let disposeBag = DisposeBag()

    init(user: LocalUser, firebaseClient: FirebaseClient = FirebaseClient()) {
        self.user = user
        uid = user.uid
        name = user.name
        username = user.email
        self.firebaseClient = firebaseClient
        if let data = user.profileImageData {
            profileImageData.onNext(data)
            profileImageData.onCompleted()
            return
        }
        guard let url = user.profileUrl else {
            return
        }
        firebaseClient.createUserOnlineObservable(forUid: user.uid)
            .subscribe(onNext: { [weak self] online in
                self?.isOnline.onNext(online)
            })
            .disposed(by: disposeBag)

        NetworkRequests.profilePictureNetworkRequest(withUrl: url) { result in
            switch result {
            case .success(let data):
                self.user.profileImageData = data
                self.profileImageData.onNext(data)
                self.profileImageData.onCompleted()
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

extension UserCellModel: Equatable {
    static func == (lhs: UserCellModel, rhs: UserCellModel) -> Bool {
        return lhs.uid == rhs.uid
    }
}
