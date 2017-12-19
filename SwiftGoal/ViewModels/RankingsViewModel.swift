//
//  RankingsViewModel.swift
//  SwiftGoal
//
//  Created by Martin Richter on 23/07/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa
import Result
import ReactiveSwift

class RankingsViewModel {

    typealias RankingChangeset = Changeset<Ranking>

    // Inputs
    let active = MutableProperty(false)
    let refreshObserver: Signal<Void, NoError>.Observer

    // Outputs
    let title: String
    let contentChangesSignal: Signal<RankingChangeset, NoError>
    let isLoading: MutableProperty<Bool>
    let alertMessageSignal: Signal<String, NoError>

    fileprivate let store: StoreType
    fileprivate let contentChangesObserver: Signal<RankingChangeset, NoError>.Observer
    fileprivate let alertMessageObserver: Signal<String, NoError>.Observer

    fileprivate var rankings: [Ranking]

    // MARK: Lifecycle

    init(store: StoreType) {
        self.title = "Rankings"
        self.store = store
        self.rankings = []

        let (refreshSignal, refreshObserver) = Signal<Void, NoError>.pipe()
        self.refreshObserver = refreshObserver

        let (contentChangesSignal, contentChangesObserver) = Signal<RankingChangeset, NoError>.pipe()
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

        SignalProducer(refreshSignal)
            .on(starting: { _ in isLoading.value = true })
            .flatMap(.latest, { _ in
                return store.fetchRankings()
                    .flatMapError { error in
                        alertMessageObserver.send(value: error.localizedDescription)
                        return SignalProducer(value: [])
                }
            })
            .on(starting: { _ in isLoading.value = false })
            .combinePrevious([]) // Preserve history to calculate changeset
            .startWithValues({ [weak self] (oldRankings, newRankings) in
                self?.rankings = newRankings
                if let observer = self?.contentChangesObserver {
                    let changeset = Changeset(
                        oldItems: oldRankings,
                        newItems: newRankings,
                        contentMatches: Ranking.contentMatches
                    )
                    observer.send(value: changeset)
                }
            })
    }

    // MARK: Data Source

    func numberOfSections() -> Int {
        return 1
    }

    func numberOfRankingsInSection(_ section: Int) -> Int {
        return rankings.count
    }

    func playerNameAtIndexPath(_ indexPath: IndexPath) -> String {
        return rankingAtIndexPath(indexPath).player.name
    }

    func ratingAtIndexPath(_ indexPath: IndexPath) -> String {
        let rating = rankingAtIndexPath(indexPath).rating
        return String(format: "%.2f", rating)
    }

    // MARK: Internal Helpers

    fileprivate func rankingAtIndexPath(_ indexPath: IndexPath) -> Ranking {
        return rankings[indexPath.row]
    }
}
