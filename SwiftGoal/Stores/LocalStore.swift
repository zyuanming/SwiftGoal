//
//  LocalStore.swift
//  SwiftGoal
//
//  Created by Martin Richter on 31/12/15.
//  Copyright © 2015 Martin Richter. All rights reserved.
//

import Argo
import ReactiveCocoa
import ReactiveSwift
import Result

class LocalStore: StoreType {

    fileprivate var matches = [Match]()
    fileprivate var players = [Player]()

    fileprivate let rankingEngine = RankingEngine()

    fileprivate let matchesKey = "matches"
    fileprivate let playersKey = "players"
    fileprivate let archiveFileName = "LocalStore"

    // MARK: Matches

    func fetchMatches() -> SignalProducer<[Match], AnyError> {
        return SignalProducer(value: matches)
    }

    func createMatch(_ parameters: MatchParameters) -> SignalProducer<Bool, AnyError> {
        let identifier = randomIdentifier()
        let match = matchFromParameters(parameters, withIdentifier: identifier)
        matches.append(match)

        return SignalProducer(value: true)
    }

    func updateMatch(_ match: Match, parameters: MatchParameters) -> SignalProducer<Bool, AnyError> {
        if let oldMatchIndex = matches.index(of: match) {
            let newMatch = matchFromParameters(parameters, withIdentifier: match.identifier)
            matches.remove(at: oldMatchIndex)
            matches.insert(newMatch, at: oldMatchIndex)
            return SignalProducer(value: true)
        } else {
            return SignalProducer(value: false)
        }
    }

    func deleteMatch(_ match: Match) -> SignalProducer<Bool, AnyError> {
        if let index = matches.index(of: match) {
            matches.remove(at: index)
            return SignalProducer(value: true)
        } else {
            return SignalProducer(value: false)
        }
    }

    // MARK: Players

    func fetchPlayers() -> SignalProducer<[Player], AnyError> {
        return SignalProducer(value: players)
    }

    func createPlayerWithName(_ name: String) -> SignalProducer<Bool, AnyError> {
        let player = Player(identifier: randomIdentifier(), name: name)

        // Keep alphabetical order when inserting player
        let alphabeticalIndex = players.index { existingPlayer in
            existingPlayer.name > player.name
        }
        if let index = alphabeticalIndex {
            players.insert(player, at: index)
        } else {
            players.append(player)
        }

        return SignalProducer(value: true)
    }

    // MARK: Rankings

    func fetchRankings() -> SignalProducer<[Ranking], AnyError> {
      let rankings = rankingEngine.rankingsForPlayers(players, fromMatches: matches)
      return SignalProducer(value: rankings)
    }

    // MARK: Persistence

    func archiveToDisk() {
        let matchesDict = matches.map { $0.encode() }
        let playersDict = players.map { $0.encode() }

        let dataDict = [matchesKey: matchesDict, playersKey: playersDict]

        if let filePath = persistentFilePath() {
            NSKeyedArchiver.archiveRootObject(dataDict, toFile: filePath)
        }
    }

    func unarchiveFromDisk() {
        if let
            path = persistentFilePath(),
            let dataDict = NSKeyedUnarchiver.unarchiveObject(withFile: path) as? [String: AnyObject],
            let matchesDict = dataDict[matchesKey],
            let playersDict = dataDict[playersKey],
            let matches: [Match] = decode(matchesDict),
            let players: [Player] = decode(playersDict)
        {
            self.matches = matches
            self.players = players
        }
    }

    // MARK: Private Helpers

    fileprivate func randomIdentifier() -> String {
        return UUID().uuidString
    }

    fileprivate func matchFromParameters(_ parameters: MatchParameters, withIdentifier identifier: String) -> Match {
        let sortByName: (Player, Player) -> Bool = { player1, player2  in
            player1.name < player2.name
        }

        return Match(
            identifier: identifier,
            homePlayers: parameters.homePlayers.sorted(by: sortByName),
            awayPlayers: parameters.awayPlayers.sorted(by: sortByName),
            homeGoals: parameters.homeGoals,
            awayGoals: parameters.awayGoals
        )
    }

    fileprivate func persistentFilePath() -> String? {
        let basePath = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first as NSString?
        return basePath?.appendingPathComponent(archiveFileName)
    }
}
