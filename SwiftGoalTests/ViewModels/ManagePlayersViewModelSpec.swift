//
//  ManagePlayersViewModelSpec.swift
//  SwiftGoal
//
//  Created by Martin Richter on 04/01/16.
//  Copyright © 2016 Martin Richter. All rights reserved.
//

import Quick
import Nimble
import ReactiveCocoa
@testable import SwiftGoal
import ReactiveSwift

class ManagePlayersViewModelSpec: QuickSpec {
    override func spec() {
        describe("ManagePlayersViewModel") {
            var mockStore: MockStore!
            var managePlayersViewModel: ManagePlayersViewModel!

            beforeEach {
                mockStore = MockStore()
                managePlayersViewModel = ManagePlayersViewModel(store: mockStore, initialPlayers: [], disabledPlayers: [])
            }

            it("has the correct title") {
                expect(managePlayersViewModel.title).to(equal("Players"))
            }

            it("initially has a only single, empty section") {
                expect(managePlayersViewModel.numberOfSections()).to(equal(1))
                expect(managePlayersViewModel.numberOfPlayersInSection(0)).to(equal(0))
            }

            context("when initialized with a set of initial players") {
                beforeEach {
                    let p1 = Player(identifier: "a", name: "A")
                    let p2 = Player(identifier: "b", name: "B")
                    let p3 = Player(identifier: "c", name: "C")
                    mockStore.players = [p1, p2, p3]
                    managePlayersViewModel = ManagePlayersViewModel(store: mockStore, initialPlayers: [p1, p2], disabledPlayers: [])
                }

                it("has the right players selected") {
                    managePlayersViewModel.active.value = true

                    let indexPath1 = IndexPath(row: 0, section: 0)
                    let indexPath2 = IndexPath(row: 1, section: 0)
                    let indexPath3 = IndexPath(row: 2, section: 0)

                    expect(managePlayersViewModel.isPlayerSelectedAtIndexPath(indexPath1)).to(beTrue())
                    expect(managePlayersViewModel.isPlayerSelectedAtIndexPath(indexPath2)).to(beTrue())
                    expect(managePlayersViewModel.isPlayerSelectedAtIndexPath(indexPath3)).to(beFalse())
                }
            }

            context("when initialized with a set of disabled players") {
                beforeEach {
                    let p1 = Player(identifier: "a", name: "A")
                    let p2 = Player(identifier: "b", name: "B")
                    let p3 = Player(identifier: "c", name: "C")
                    mockStore.players = [p1, p2, p3]
                    managePlayersViewModel = ManagePlayersViewModel(store: mockStore, initialPlayers: [], disabledPlayers: [p1, p2])
                }

                it("allows the right players to be selected") {
                    managePlayersViewModel.active.value = true

                    let indexPath1 = IndexPath(row: 0, section: 0)
                    let indexPath2 = IndexPath(row: 1, section: 0)
                    let indexPath3 = IndexPath(row: 2, section: 0)

                    expect(managePlayersViewModel.canSelectPlayerAtIndexPath(indexPath1)).to(beFalse())
                    expect(managePlayersViewModel.canSelectPlayerAtIndexPath(indexPath2)).to(beFalse())
                    expect(managePlayersViewModel.canSelectPlayerAtIndexPath(indexPath3)).to(beTrue())
                }
            }

            context("after becoming active") {
                beforeEach {
                    managePlayersViewModel.active.value = true
                }

                it("fetches a list of players") {
                    expect(mockStore.didFetchPlayers).to(beTrue())
                }

                it("has only a single section") {
                    expect(managePlayersViewModel.numberOfSections()).to(equal(1))
                }

                it("has the right number of players") {
                    expect(managePlayersViewModel.numberOfPlayersInSection(0)).to(equal(4))
                }

                it("displays the right player names") {
                    let indexPath1 = IndexPath(row: 0, section: 0)
                    let indexPath2 = IndexPath(row: 1, section: 0)
                    let indexPath3 = IndexPath(row: 2, section: 0)
                    let indexPath4 = IndexPath(row: 3, section: 0)
                    expect(managePlayersViewModel.playerNameAtIndexPath(indexPath1)).to(equal("C"))
                    expect(managePlayersViewModel.playerNameAtIndexPath(indexPath2)).to(equal("A"))
                    expect(managePlayersViewModel.playerNameAtIndexPath(indexPath3)).to(equal("D"))
                    expect(managePlayersViewModel.playerNameAtIndexPath(indexPath4)).to(equal("B"))
                }

                it("allows selecting and deselecting a player") {
                    let indexPath = IndexPath(row: 0, section: 0)
                    managePlayersViewModel.selectPlayerAtIndexPath(indexPath)
                    expect(managePlayersViewModel.isPlayerSelectedAtIndexPath(indexPath)).to(beTrue())

                    managePlayersViewModel.deselectPlayerAtIndexPath(indexPath)
                    expect(managePlayersViewModel.isPlayerSelectedAtIndexPath(indexPath)).to(beFalse())
                }
            }

            context("when asked to refresh") {
                it("fetches a list of players") {
                    managePlayersViewModel.refreshObserver.send(value: ())
                    expect(mockStore.didFetchPlayers).to(beTrue())
                }
            }

            context("when becoming active and upon refresh") {
                it("indicates its loading state") {
                    // Aggregate loading states into an array
                    var loadingStates: [Bool] = []
                    managePlayersViewModel.isLoading.producer
                        .take(first: 5)
                        .collect()
                        .startWithValues({ values in
                            loadingStates = values
                        })

                    managePlayersViewModel.active.value = true
                    managePlayersViewModel.refreshObserver.send(value: ())

                    expect(loadingStates).to(equal([false, true, false, true, false]))
                }

                it("notifies subscribers about content changes") {
                    var changeset: Changeset<Player>?
                    managePlayersViewModel.contentChangesSignal.observeValues { contentChanges in
                        changeset = contentChanges
                    }

                    let expectedInsertions = [
                        IndexPath(row: 0, section: 0),
                        IndexPath(row: 1, section: 0),
                        IndexPath(row: 2, section: 0),
                        IndexPath(row: 3, section: 0)
                    ]

                    managePlayersViewModel.active.value = true
                    expect(changeset?.deletions).to(beEmpty())
                    expect(changeset?.insertions).to(equal(expectedInsertions))

                    managePlayersViewModel.refreshObserver.send(value: ())
                    expect(changeset?.deletions).to(beEmpty())
                    expect(changeset?.insertions).to(beEmpty())
                }
            }

            it("raises an alert when players cannot be fetched") {
                mockStore.players = nil // will cause fetch error

                var didRaiseAlert = false
                managePlayersViewModel.alertMessageSignal.observeValues({ alertMessage in
                    didRaiseAlert = true
                })

                managePlayersViewModel.active.value = true

                expect(didRaiseAlert).to(beTrue())
            }
        }
    }
}
