//
//  MatchesViewController.swift
//  SwiftGoal
//
//  Created by Martin Richter on 10/05/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import DZNEmptyDataSet
import ReactiveCocoa
import Result
import ReactiveSwift

class MatchesViewController: UITableViewController, DZNEmptyDataSetDelegate, DZNEmptyDataSetSource {

    fileprivate let matchCellIdentifier = "MatchCell"
    fileprivate let viewModel: MatchesViewModel

    // MARK: - Lifecycle

    init(viewModel: MatchesViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("NSCoding is not supported")
    }

    // MARK: - View Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.allowsSelection = false
        tableView.allowsSelectionDuringEditing = true
        tableView.rowHeight = 60
        tableView.tableFooterView = UIView() // Prevent empty rows at bottom

        tableView.emptyDataSetDelegate = self
        tableView.emptyDataSetSource = self

        self.refreshControl = UIRefreshControl()
        self.refreshControl?.addTarget(self,
            action: #selector(refreshControlTriggered),
            for: .valueChanged
        )

        tableView.register(MatchCell.self, forCellReuseIdentifier: matchCellIdentifier)

        self.navigationItem.leftBarButtonItem = self.editButtonItem

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addMatchButtonTapped)
        )

        bindViewModel()
    }

    // MARK: - Bindings

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

    func addMatchButtonTapped() {
        let newMatchViewModel = viewModel.editViewModelForNewMatch()
        let newMatchViewController = EditMatchViewController(viewModel: newMatchViewModel)
        let newMatchNavigationController = UINavigationController(rootViewController: newMatchViewController)
        self.present(newMatchNavigationController, animated: true, completion: nil)
    }

    func refreshControlTriggered() {
        viewModel.refreshObserver.send(value: ())
    }

    // MARK: DZNEmptyDataSetDelegate

    func emptyDataSetDidTapButton(_ scrollView: UIScrollView!) {
        if let settingsURL = URL(string: UIApplicationOpenSettingsURLString) {
            UIApplication.shared.openURL(settingsURL)
        }
    }

    // MARK: DZNEmptyDataSetSource

    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "No matches yet!"
        let attributes = [
            NSFontAttributeName: UIFont(name: "OpenSans-Semibold", size: 30)!
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }

    func description(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let text = "Check your storage settings, then tap the “+” button to get started."
        let attributes = [
            NSFontAttributeName: UIFont(name: "OpenSans", size: 20)!,
            NSForegroundColorAttributeName: UIColor.lightGray
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }

    func buttonTitle(forEmptyDataSet scrollView: UIScrollView!, for state: UIControlState) -> NSAttributedString! {
        let text = "Open App Settings"
        let attributes = [
            NSFontAttributeName: UIFont(name: "OpenSans", size: 20)!,
            NSForegroundColorAttributeName: (state == UIControlState()
                ? Color.primaryColor
                : Color.lighterPrimaryColor)
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }

    // MARK: - UITableViewDataSource

    override func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfMatchesInSection(section)
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: matchCellIdentifier, for: indexPath) as! MatchCell

        cell.homePlayersLabel.text = viewModel.homePlayersAtIndexPath(indexPath)
        cell.resultLabel.text = viewModel.resultAtIndexPath(indexPath)
        cell.awayPlayersLabel.text = viewModel.awayPlayersAtIndexPath(indexPath)

        return cell
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            viewModel.deleteAction.apply(indexPath).start()
        }
    }

    // MARK: UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let editMatchViewModel = viewModel.editViewModelForMatchAtIndexPath(indexPath)
        let editMatchViewController = EditMatchViewController(viewModel: editMatchViewModel)
        let editMatchNavigationController = UINavigationController(rootViewController: editMatchViewController)
        self.present(editMatchNavigationController, animated: true, completion: nil)
    }
}
