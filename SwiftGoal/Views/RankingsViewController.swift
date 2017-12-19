//
//  RankingsViewController.swift
//  SwiftGoal
//
//  Created by Martin Richter on 23/07/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa
import Result
import UIKit
import ReactiveSwift

class RankingsViewController: UITableViewController {

    fileprivate let rankingCellIdentifier = "RankingCell"
    fileprivate let viewModel: RankingsViewModel

    // MARK: Lifecycle

    init(viewModel: RankingsViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelection = false
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView() // Prevent empty rows at bottom

        tableView.register(RankingCell.self, forCellReuseIdentifier: rankingCellIdentifier)

        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self,
            action: #selector(refreshControlTriggered),
            for: .valueChanged
        )

        bindViewModel()
    }

    // MARK: Bindings

    fileprivate func bindViewModel() {
        self.title = viewModel.title

        viewModel.active <~ isActive()

        viewModel.contentChangesSignal
            .observe(on: UIScheduler())
            .observeValues({ [weak self] changeset in
                guard let tableView = self?.tableView else { return }

                tableView.beginUpdates()
                tableView.deleteRows(at: changeset.deletions, with: .automatic)
                tableView.reloadRows(at: changeset.modifications, with: .automatic)
                tableView.insertRows(at: changeset.insertions, with: .automatic)
                tableView.endUpdates()
            })

        viewModel.isLoading.producer
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] isLoading in
                if !isLoading {
                    self?.refreshControl?.endRefreshing()
                }
            })

        viewModel.alertMessageSignal
            .observe(on: UIScheduler())
            .observeValues({ [weak self] alertMessage in
                let alertController = UIAlertController(
                    title: "Oops!",
                    message: alertMessage,
                    preferredStyle: .alert
                )
                alertController.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
                self?.present(alertController, animated: true, completion: nil)
            })
    }

    // MARK: User Interaction

    @objc func refreshControlTriggered() {
        viewModel.refreshObserver.send(value: ())
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRankingsInSection(section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: rankingCellIdentifier, for: indexPath) as! RankingCell

        cell.playerNameLabel.text = viewModel.playerNameAtIndexPath(indexPath)
        cell.ratingLabel.text = viewModel.ratingAtIndexPath(indexPath)

        return cell
    }
}
