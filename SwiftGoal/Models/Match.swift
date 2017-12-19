//
//  Match.swift
//  SwiftGoal
//
//  Created by Martin Richter on 11/05/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import Argo
import Curry
import Runes

struct Match {
    let identifier: String
    let homePlayers: [Player]
    let awayPlayers: [Player]
    let homeGoals: Int
    let awayGoals: Int

    static fileprivate let identifierKey = "id"
    static fileprivate let homePlayersKey = "home_players"
    static fileprivate let awayPlayersKey = "away_players"
    static fileprivate let homeGoalsKey = "home_goals"
    static fileprivate let awayGoalsKey = "away_goals"

    init(identifier: String, homePlayers: [Player], awayPlayers: [Player], homeGoals: Int, awayGoals: Int) {
        self.identifier = identifier
        self.homePlayers = homePlayers
        self.awayPlayers = awayPlayers
        self.homeGoals = homeGoals
        self.awayGoals = awayGoals
    }

    // TODO: Decide if content matching should include identifier or not
    static func contentMatches(_ lhs: Match, _ rhs: Match) -> Bool {
        return lhs.identifier == rhs.identifier
            && Player.contentMatches(lhs.homePlayers, rhs.homePlayers)
            && Player.contentMatches(lhs.awayPlayers, rhs.awayPlayers)
            && lhs.homeGoals == rhs.homeGoals
            && lhs.awayGoals == rhs.awayGoals
    }
}

// MARK: Equatable

extension Match: Equatable {}

func ==(lhs: Match, rhs: Match) -> Bool {
    return lhs.identifier == rhs.identifier
}

// MARK: Decodable

extension Match: Argo.Decodable {
    static func decode(_ json: JSON) -> Decoded<Match> {
        return curry(Match.init)
            <^> json <| identifierKey
            <*> json <|| homePlayersKey
            <*> json <|| awayPlayersKey
            <*> json <| homeGoalsKey
            <*> json <| awayGoalsKey
    }
}

// MARK: Encodable

extension Match: Encodable {
    func encode() -> [String: AnyObject] {
        return [
            Match.identifierKey: identifier as AnyObject,
            Match.homePlayersKey: homePlayers.map { $0.encode() } as AnyObject,
            Match.awayPlayersKey: awayPlayers.map { $0.encode() }  as AnyObject,
            Match.homeGoalsKey: homeGoals as AnyObject,
            Match.awayGoalsKey: awayGoals as AnyObject
        ]
    }
}
