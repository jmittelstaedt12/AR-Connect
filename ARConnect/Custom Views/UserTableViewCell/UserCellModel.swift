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
    let uid: String
    let name: String
    let username: String
    let isOnline: PublishSubject<Bool> = PublishSubject()
    let profileImageData: PublishSubject<Data> = PublishSubject()

    let disposeBag = DisposeBag()

    init(user: LocalUser) {
        uid = user.uid
        name = user.name
        username = user.email
        if let data = user.profileImageData {
            profileImageData.onNext(data)
            profileImageData.onCompleted()
            return
        }
        guard let url = user.profileUrl else {
            return
        }
        FirebaseClient.createUserOnlineObservable(forUid: user.uid)
            .subscribe(onNext: { [weak self] online in
                self?.isOnline.onNext(online)
            })
            .disposed(by: disposeBag)

        NetworkRequests.profilePictureNetworkRequest(withUrl: url) { data in
            DispatchQueue.main.async {
                #warning("need to fix this to cancel when cell is removed")
                self.profileImageData.onNext(data)
                self.profileImageData.onCompleted()
            }
        }
    }
}

extension UserCellModel: Equatable {
    static func == (lhs: UserCellModel, rhs: UserCellModel) -> Bool {
        return lhs.uid == rhs.uid
    }
}
