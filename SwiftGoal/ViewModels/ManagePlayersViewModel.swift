//
//  ManagePlayersViewModel.swift
//  SwiftGoal
//
//  Created by Martin Richter on 30/06/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa
import Result
import ReactiveSwift

class ManagePlayersViewModel {

    typealias PlayerChangeset = Changeset<Player>

    // Inputs
    let active = MutableProperty(false)
    let playerName = MutableProperty("")
    let refreshObserver: Signal<Void, NoError>.Observer

    // Outputs
    let title: String
    let contentChangesSignal: Signal<PlayerChangeset, NoError>
    let isLoading: MutableProperty<Bool>
    let alertMessageSignal: Signal<String, NoError>
    let selectedPlayers: MutableProperty<Set<Player>>
    let inputIsValid = MutableProperty(false)

    // Actions
    lazy var saveAction: Action<Void, Bool, AnyError> = { [unowned self] in
        return Action<Void, Bool, AnyError>(enabledIf: self.inputIsValid, execute: { (_) -> SignalProducer<Bool, AnyError> in
            return self.store.createPlayerWithName(self.playerName.value)
        })
//        return Action<Void, Bool, AnyError>(enabledIf: self.inputIsValid, { _ in
//            return self.store.createPlayerWithName(self.playerName.value)
//        })
    }()

    fileprivate let store: StoreType
    fileprivate let contentChangesObserver: Signal<PlayerChangeset, NoError>.Observer
    fileprivate let alertMessageObserver: Signal<String, NoError>.Observer
    fileprivate let disabledPlayers: Set<Player>

    fileprivate var players: [Player]

    // MARK: Lifecycle

    init(store: StoreType, initialPlayers: Set<Player>, disabledPlayers: Set<Player>) {
        self.title = "Players"
        self.store = store
        self.players = []
        self.selectedPlayers = MutableProperty(initialPlayers)
        self.disabledPlayers = disabledPlayers

        let (refreshSignal, refreshObserver) = Signal<Void, NoError>.pipe()
        self.refreshObserver = refreshObserver

        let (contentChangesSignal, contentChangesObserver) = Signal<PlayerChangeset, NoError>.pipe()
        self.contentChangesSignal = contentChangesSignal
        self.contentChangesObserver = contentChangesObserver

        let isLoading = MutableProperty(false)
        self.isLoading = isLoading

        let (alertMessageSignal, alertMessageObserver) = Signal<String, NoError>.pipe()
        self.alertMessageSignal = alertMessageSignal
        self.alertMessageObserver = alertMessageObserver

        active.producer
            .filter { $0 }
            .map { _ in () }
            .start(refreshObserver)

        saveAction.values
            .filter { $0 }
            .map { _ in () }
            .observe(refreshObserver)

        SignalProducer(refreshSignal)
            .on(starting: { isLoading.value = true })
            .flatMap(.latest, { _ in
                return store.fetchPlayers()
                    .flatMapError { error in
                        alertMessageObserver.send(value: error.localizedDescription)
                        return SignalProducer(value: [])
                    }
            })
            .on(starting: { isLoading.value = false })
            .combinePrevious([]) // Preserve history to calculate changeset
            .startWithValues({ [weak self] (oldPlayers, newPlayers) in
                self?.players = newPlayers
                if let observer = self?.contentChangesObserver {
                    let changeset = Changeset(
                        oldItems: oldPlayers,
                        newItems: newPlayers,
                        contentMatches: Player.contentMatches
                    )
                    observer.send(value: changeset)
                }
            })

        // Feed saving errors into alert message signal
        saveAction.errors
            .map { $0.localizedDescription }
            .observe(alertMessageObserver)

        inputIsValid <~ playerName.producer.map { $0.count > 0 }
    }

    // MARK: Data Source

    func numberOfSections() -> Int {
        return 1
    }

    func numberOfPlayersInSection(_ section: Int) -> Int {
        return players.count
    }

    func playerNameAtIndexPath(_ indexPath: IndexPath) -> String {
        return playerAtIndexPath(indexPath).name
    }

    func isPlayerSelectedAtIndexPath(_ indexPath: IndexPath) -> Bool {
        let player = playerAtIndexPath(indexPath)
        return selectedPlayers.value.contains(player)
    }

    func canSelectPlayerAtIndexPath(_ indexPath: IndexPath) -> Bool {
        let player = playerAtIndexPath(indexPath)
        return !disabledPlayers.contains(player)
    }

    // MARK: Player Selection

    func selectPlayerAtIndexPath(_ indexPath: IndexPath) {
        let player = playerAtIndexPath(indexPath)
        selectedPlayers.value.insert(player)
    }

    func deselectPlayerAtIndexPath(_ indexPath: IndexPath) {
        let player = playerAtIndexPath(indexPath)
        selectedPlayers.value.remove(player)
    }

    // MARK: Internal Helpers

    fileprivate func playerAtIndexPath(_ indexPath: IndexPath) -> Player {
        return players[indexPath.row]
    }
}
