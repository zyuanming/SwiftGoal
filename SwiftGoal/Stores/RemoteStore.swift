//
//  Store.swift
//  SwiftGoal
//
//  Created by Martin Richter on 10/05/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import Argo
import ReactiveCocoa
import ReactiveSwift
import Result

class RemoteStore: StoreType {

    enum RequestMethod {
        case get
        case post
        case put
        case delete
    }

    fileprivate let baseURL: URL
    fileprivate let matchesURL: URL
    fileprivate let playersURL: URL
    fileprivate let rankingsURL: URL

    // MARK: Lifecycle

    init(baseURL: URL) {
        self.baseURL = baseURL
        self.matchesURL = URL(string: "matches", relativeTo: baseURL)!
        self.playersURL = URL(string: "players", relativeTo: baseURL)!
        self.rankingsURL = URL(string: "rankings", relativeTo: baseURL)!
    }

    // MARK: - Matches

    func fetchMatches() -> SignalProducer<[Match], AnyError> {
        let request = mutableRequestWithURL(matchesURL, method: .get)

        return URLSession.shared.reactive.data(with: request)
            .map { data, response in
                if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                  let matches: [Match] = decode(json) {
                    return matches
                } else {
                    return []
                }
            }
    }

    func createMatch(_ parameters: MatchParameters) -> SignalProducer<Bool, AnyError> {

        var request = mutableRequestWithURL(matchesURL, method: .post)
        request.httpBody = httpBodyForMatchParameters(parameters)

        return URLSession.shared.reactive.data(with: request)
            .map { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    return httpResponse.statusCode == 201
                } else {
                    return false
                }
            }
    }

    func updateMatch(_ match: Match, parameters: MatchParameters) -> SignalProducer<Bool, AnyError> {

        var request = mutableRequestWithURL(urlForMatch(match), method: .put)
        request.httpBody = httpBodyForMatchParameters(parameters)

        return URLSession.shared.reactive.data(with: request)
            .map { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    return httpResponse.statusCode == 200
                } else {
                    return false
                }
            }
    }

    func deleteMatch(_ match: Match) -> SignalProducer<Bool, AnyError> {
        let request = mutableRequestWithURL(urlForMatch(match), method: .delete)

        return URLSession.shared.reactive.data(with: request)
            .map { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    return httpResponse.statusCode == 200
                } else {
                    return false
                }
            }
    }

    // MARK: Players

    func fetchPlayers() -> SignalProducer<[Player], AnyError> {
        let request = URLRequest(url: playersURL)
        return URLSession.shared.reactive.data(with: request)
            .map { data, response in
                if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                    let players: [Player] = decode(json) {
                    return players
                } else {
                    return []
                }
            }
    }

    func createPlayerWithName(_ name: String) -> SignalProducer<Bool, AnyError> {
        var request = mutableRequestWithURL(playersURL, method: .post)
        request.httpBody = httpBodyForPlayerName(name)

        return URLSession.shared.reactive.data(with: request)
            .map { data, response in
                if let httpResponse = response as? HTTPURLResponse {
                    return httpResponse.statusCode == 201
                } else {
                    return false
                }
            }
    }

    // MARK: Rankings

    func fetchRankings() -> SignalProducer<[Ranking], AnyError> {
        let request = URLRequest(url: rankingsURL)
        return URLSession.shared.reactive.data(with: request)
            .map { data, response in
                if let json = try? JSONSerialization.jsonObject(with: data, options: []),
                    let rankings: [Ranking] = decode(json) {
                    return rankings
                } else {
                    return []
                }
        }
    }

    // MARK: Private Helpers

    fileprivate func httpBodyForMatchParameters(_ parameters: MatchParameters) -> Data? {
        let jsonObject = [
            "home_player_ids": Array(parameters.homePlayers).map { $0.identifier },
            "away_player_ids": Array(parameters.awayPlayers).map { $0.identifier },
            "home_goals": parameters.homeGoals,
            "away_goals": parameters.awayGoals
        ] as [String : Any]

        return try? JSONSerialization.data(withJSONObject: jsonObject, options: [])
    }

    fileprivate func httpBodyForPlayerName(_ name: String) -> Data? {
        let jsonObject = [
            "name": name
        ]

        return try? JSONSerialization.data(withJSONObject: jsonObject, options: [])
    }

    fileprivate func urlForMatch(_ match: Match) -> URL {
        return matchesURL.appendingPathComponent(match.identifier)
    }

    fileprivate func mutableRequestWithURL(_ url: URL, method: RequestMethod) -> URLRequest {
        var request = URLRequest(url: url)

        switch method {
            case .get:
                request.httpMethod = "GET"
            case .post:
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            case .put:
                request.httpMethod = "PUT"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            case .delete:
                request.httpMethod = "DELETE"
        }

        return request
    }
}
