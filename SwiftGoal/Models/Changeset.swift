//
//  Changeset.swift
//  SwiftGoal
//
//  Created by Martin Richter on 01/06/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import Foundation

struct Changeset<T: Equatable> {

    var deletions: [IndexPath]
    var modifications: [IndexPath]
    var insertions: [IndexPath]

    typealias ContentMatches = (T, T) -> Bool

    init(oldItems: [T], newItems: [T], contentMatches: @escaping ContentMatches) {

        deletions = oldItems.difference(newItems).map { item in
            return Changeset.indexPathForIndex(oldItems.index(of: item)!)
        }

        modifications = oldItems.intersection(newItems)
            .filter({ item in
                let newItem = newItems[newItems.index(of: item)!]
                return !contentMatches(item, newItem)
            })
            .map({ item in
                return Changeset.indexPathForIndex(oldItems.index(of: item)!)
            })

        insertions = newItems.difference(oldItems).map { item in
            return IndexPath(row: newItems.index(of: item)!, section: 0)
        }
    }

    fileprivate static func indexPathForIndex(_ index: Int) -> IndexPath {
        return IndexPath(row: index, section: 0)
    }
}
