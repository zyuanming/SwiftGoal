//
//  MatchesViewModel.swift
//  SwiftGoal
//
//  Created by Martin Richter on 10/05/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa
import Result
import ReactiveSwift

class MatchesViewModel {

    typealias MatchChangeset = Changeset<Match>

    // Inputs
    let active = MutableProperty(false)
    let refreshObserver: Signal<Void, NoError>.Observer

    // Outputs
    let title: String
    let contentChangesSignal: Signal<MatchChangeset, NoError>
    let isLoading: MutableProperty<Bool>
    let alertMessageSignal: Signal<String, NoError>

    // Actions
    lazy var deleteAction: Action<IndexPath, Bool, AnyError> = { [unowned self] in
        return Action(execute: { indexPath in
            let match = self.matchAtIndexPath(indexPath)
            return self.store.deleteMatch(match)
        })
    }()

    fileprivate let store: StoreType
    fileprivate let contentChangesObserver: Signal<MatchChangeset, NoError>.Observer
    fileprivate let alertMessageObserver: Signal<String, NoError>.Observer
    fileprivate var matches: [Match]

    // MARK: - Lifecycle

    init(store: StoreType) {
        self.title = "Matches"
        self.store = store
        self.matches = []

        let (refreshSignal, refreshObserver) = Signal<Void, NoError>.pipe()
        self.refreshObserver = refreshObserver

        let (contentChangesSignal, contentChangesObserver) = Signal<MatchChangeset, NoError>.pipe()
        self.contentChangesSignal = contentChangesSignal
        self.contentChangesObserver = contentChangesObserver

        let isLoading = MutableProperty(false)
        self.isLoading = isLoading

        let (alertMessageSignal, alertMessageObserver) = Signal<String, NoError>.pipe()
        self.alertMessageSignal = alertMessageSignal
        self.alertMessageObserver = alertMessageObserver

        // Trigger refresh when view becomes active
        active.producer
            .filter { $0 }
            .map { _ in () }
            .start(refreshObserver)

        // Trigger refresh after deleting a match
        deleteAction.values
            .filter { $0 }
            .map { _ in () }
            .observe(refreshObserver)

        SignalProducer(refreshSignal)
            .on(starting: { isLoading.value = true })
            .flatMap(.latest) { _ in
                return store.fetchMatches()
                    .flatMapError { error in
                        alertMessageObserver.send(value: error.localizedDescription)
                        return SignalProducer(value: [])
                    }
            }
            .on(starting: { isLoading.value = false })
            .combinePrevious([]) // Preserve history to calculate changeset
            .startWithValues({ [weak self] (oldMatches, newMatches) in
                self?.matches = newMatches
                if let observer = self?.contentChangesObserver {
                    let changeset = Changeset(
                        oldItems: oldMatches,
                        newItems: newMatches,
                        contentMatches: Match.contentMatches
                    )
                    observer.send(value: changeset)
                }
            })

        // Feed deletion errors into alert message signal
        deleteAction.errors
            .map { $0.localizedDescription }
            .observe(alertMessageObserver)
    }

    // MARK: - Data Source

    func numberOfSections() -> Int {
        return 1
    }

    func numberOfMatchesInSection(_ section: Int) -> Int {
        return matches.count
    }

    func homePlayersAtIndexPath(_ indexPath: IndexPath) -> String {
        let match = matchAtIndexPath(indexPath)
        return separatedNamesForPlayers(match.homePlayers)
    }

    func awayPlayersAtIndexPath(_ indexPath: IndexPath) -> String {
        let match = matchAtIndexPath(indexPath)
        return separatedNamesForPlayers(match.awayPlayers)
    }

    func resultAtIndexPath(_ indexPath: IndexPath) -> String {
        let match = matchAtIndexPath(indexPath)
        return "\(match.homeGoals) : \(match.awayGoals)"
    }

    // MARK: View Models

    func editViewModelForNewMatch() -> EditMatchViewModel {
        return EditMatchViewModel(store: store)
    }

    func editViewModelForMatchAtIndexPath(_ indexPath: IndexPath) -> EditMatchViewModel {
        let match = matchAtIndexPath(indexPath)
        return EditMatchViewModel(store: store, match: match)
    }

    // MARK: Internal Helpers

    fileprivate func matchAtIndexPath(_ indexPath: IndexPath) -> Match {
        return matches[indexPath.row]
    }

    fileprivate func separatedNamesForPlayers(_ players: [Player]) -> String {
        let playerNames = players.map { player in player.name }
        return playerNames.joined(separator: ", ")
    }
}
