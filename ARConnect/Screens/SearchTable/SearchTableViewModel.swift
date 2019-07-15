//
//  SearchViewModel.swift
//  ARConnect
//
//  Created by Jacob Mittelstaedt on 6/13/19.
//  Copyright © 2019 Jacob Mittelstaedt. All rights reserved.
//

import Foundation
import RxSwift

class SearchTableViewModel: ViewModelProtocol {

    struct Input {
        let searchValue: AnyObserver<String>
    }

    struct Output {
        let reloadTableObservable: Observable<Void>
    }

    let input: Input
    let output: Output

    private let searchValueSubject = PublishSubject<String>()
    private let reloadTableSubject = PublishSubject<Void>()
    let disposeBag = DisposeBag()

    private var searchItem: DispatchWorkItem?
    var userCellModels: [UserCellModel]? = []
    let firebaseClient: FirebaseClient

    init(firebaseClient: FirebaseClient = FirebaseClient()) {
        input = Input(searchValue: searchValueSubject.asObserver())
        output = Output(reloadTableObservable: reloadTableSubject.asObserver())

        self.firebaseClient = firebaseClient
        
        setObservers()
    }

    private func setObservers() {
        searchValueSubject.asObservable()
            .subscribe(onNext: { [weak self] searchValue in
                guard let self = self else { return }
                self.searchItem?.cancel()
                guard !searchValue.isEmpty else {
                    self.userCellModels = []
                    self.reloadTableSubject.onNext(())
                    return
                }
                let newWorkItem = DispatchWorkItem { [weak self] in
                    guard let self = self else { return }
                    let query = self.firebaseClient.usersRef.queryOrdered(byChild: "name")
                        .queryStarting(atValue: searchValue)
                        .queryEnding(atValue: searchValue+"\u{f8ff}")

                    self.firebaseClient.fetchObservableUsers(withObservableType: .singleEvent, queryReference: query)
                        .subscribe(onNext: { [weak self] fetchedUsers in
                            let newUserSet = fetchedUsers.map { UserCellModel(user: $0) }
                            if let currentSet = self?.userCellModels, newUserSet != currentSet {
                                self?.userCellModels = newUserSet
                                self?.reloadTableSubject.onNext(())
                            }
                        })
                        .disposed(by: self.disposeBag)
                }
                self.searchItem = newWorkItem
                DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(250), execute: newWorkItem)
            })
            .disposed(by: disposeBag)
    }
}
