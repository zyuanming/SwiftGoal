//
//  ManagePlayersViewController.swift
//  SwiftGoal
//
//  Created by Martin Richter on 30/06/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa
import Result
import ReactiveSwift
import UIKit

class ManagePlayersViewController: UITableViewController {

    fileprivate let playerCellIdentifier = "PlayerCell"
    fileprivate let viewModel: ManagePlayersViewModel

    // MARK: Lifecycle

    init(viewModel: ManagePlayersViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.rowHeight = 60
        tableView.tableFooterView = UIView() // Prevent empty rows at bottom

        tableView.register(PlayerCell.self, forCellReuseIdentifier: playerCellIdentifier)

        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self,
            action: #selector(refreshControlTriggered),
            for: .valueChanged
        )

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addPlayerButtonTapped)
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

    func addPlayerButtonTapped() {
        let newPlayerViewController = self.newPlayerViewController()
        present(newPlayerViewController, animated: true, completion: nil)
    }

    func refreshControlTriggered() {
        viewModel.refreshObserver.send(value: ())
    }

    // MARK: UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfPlayersInSection(section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: playerCellIdentifier, for: indexPath) as! PlayerCell

        cell.nameLabel.isEnabled = viewModel.canSelectPlayerAtIndexPath(indexPath)
        cell.nameLabel.text = viewModel.playerNameAtIndexPath(indexPath)
        cell.accessoryType = viewModel.isPlayerSelectedAtIndexPath(indexPath) ? .checkmark : .none

        return cell
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        return viewModel.canSelectPlayerAtIndexPath(indexPath) ? indexPath : nil
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let cell = tableView.cellForRow(at: indexPath)

        if viewModel.isPlayerSelectedAtIndexPath(indexPath) {
            viewModel.deselectPlayerAtIndexPath(indexPath)
            cell?.accessoryType = .none
        } else {
            viewModel.selectPlayerAtIndexPath(indexPath)
            cell?.accessoryType = .checkmark
        }
    }

    // MARK: Private Helpers

    fileprivate func newPlayerViewController() -> UIViewController {
        let newPlayerViewController = UIAlertController(
            title: "New Player",
            message: nil,
            preferredStyle: .alert
        )

        // Add user actions
        newPlayerViewController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        let saveAction = UIAlertAction(title: "Save", style: .default, handler: { [weak self] _ in
            self?.viewModel.saveAction.apply().start()
        })
        newPlayerViewController.addAction(saveAction)

        // Allow saving only with valid input
        viewModel.inputIsValid.producer.startWithValues({ isValid in
            saveAction.isEnabled = isValid
        })

        // Add user input fields
        newPlayerViewController.addTextField { textField in
            textField.placeholder = "Player name"
        }

        // Forward text input to view model
        if let nameField = newPlayerViewController.textFields?.first {
            viewModel.playerName <~ nameField.signalProducer()
        }

        return newPlayerViewController
    }
}
