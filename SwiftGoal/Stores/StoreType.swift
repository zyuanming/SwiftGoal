//
//  StoreType.swift
//  SwiftGoal
//
//  Created by Martin Richter on 30/12/15.
//  Copyright © 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa
import ReactiveSwift
import Result

struct MatchParameters {
    let homePlayers: Set<Player>
    let awayPlayers: Set<Player>
    let homeGoals: Int
    let awayGoals: Int
}

protocol StoreType {
    // Matches
    func fetchMatches() -> SignalProducer<[Match], AnyError>
    func createMatch(_ parameters: MatchParameters) -> SignalProducer<Bool, AnyError>
    func updateMatch(_ match: Match, parameters: MatchParameters) -> SignalProducer<Bool, AnyError>
    func deleteMatch(_ match: Match) -> SignalProducer<Bool, AnyError>

    // Players
    func fetchPlayers() -> SignalProducer<[Player], AnyError>
    func createPlayerWithName(_ name: String) -> SignalProducer<Bool, AnyError>

    // Rankings
    func fetchRankings() -> SignalProducer<[Ranking], AnyError>
}
