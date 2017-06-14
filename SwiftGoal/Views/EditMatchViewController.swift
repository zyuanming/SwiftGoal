//
//  EditMatchViewController.swift
//  SwiftGoal
//
//  Created by Martin Richter on 22/06/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import UIKit
import ReactiveCocoa
import SnapKit
import ReactiveSwift

class EditMatchViewController: UIViewController {

    fileprivate let viewModel: EditMatchViewModel

    fileprivate weak var homeGoalsLabel: UILabel!
    fileprivate weak var goalSeparatorLabel: UILabel!
    fileprivate weak var awayGoalsLabel: UILabel!
    fileprivate weak var homeGoalsStepper: UIStepper!
    fileprivate weak var awayGoalsStepper: UIStepper!
    fileprivate weak var homePlayersButton: UIButton!
    fileprivate weak var awayPlayersButton: UIButton!

    fileprivate var saveAction: CocoaAction<Any>
    fileprivate let saveButtonItem: UIBarButtonItem

    // MARK: Lifecycle

    init(viewModel: EditMatchViewModel) {
        self.viewModel = viewModel
        self.saveAction = CocoaAction(viewModel.saveAction, { _ in return () })
        self.saveButtonItem = UIBarButtonItem(
            barButtonSystemItem: .save,
            target: self.saveAction,
            action: CocoaAction<Any>.selector as Selector
        )

        super.init(nibName: nil, bundle: nil)

        // Set up navigation item
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .cancel,
            target: self,
            action: #selector(cancelButtonTapped)
        )
        navigationItem.rightBarButtonItem = self.saveButtonItem
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: View Lifecycle

    override func loadView() {
        let view = UIView()

        view.backgroundColor = UIColor.white

        let labelFont = UIFont(name: "OpenSans-Semibold", size: 70)

        let homeGoalsLabel = UILabel()
        homeGoalsLabel.font = labelFont
        view.addSubview(homeGoalsLabel)
        self.homeGoalsLabel = homeGoalsLabel

        let goalSeparatorLabel = UILabel()
        goalSeparatorLabel.font = labelFont
        goalSeparatorLabel.text = ":"
        view.addSubview(goalSeparatorLabel)
        self.goalSeparatorLabel = goalSeparatorLabel

        let awayGoalsLabel = UILabel()
        awayGoalsLabel.font = labelFont
        view.addSubview(awayGoalsLabel)
        self.awayGoalsLabel = awayGoalsLabel

        let homeGoalsStepper = UIStepper()
        view.addSubview(homeGoalsStepper)
        self.homeGoalsStepper = homeGoalsStepper

        let awayGoalsStepper = UIStepper()
        view.addSubview(awayGoalsStepper)
        self.awayGoalsStepper = awayGoalsStepper

        let homePlayersButton = UIButton(type: .system)
        homePlayersButton.titleLabel?.font = UIFont(name: "OpenSans", size: 15)
        homePlayersButton.addTarget(self,
            action: #selector(homePlayersButtonTapped),
            for: .touchUpInside
        )
        view.addSubview(homePlayersButton)
        self.homePlayersButton = homePlayersButton

        let awayPlayersButton = UIButton(type: .system)
        awayPlayersButton.titleLabel?.font = UIFont(name: "OpenSans", size: 15)
        awayPlayersButton.addTarget(self,
            action: #selector(awayPlayersButtonTapped),
            for: .touchUpInside
        )
        view.addSubview(awayPlayersButton)
        self.awayPlayersButton = awayPlayersButton

        self.view = view
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        bindViewModel()
        makeConstraints()
    }

    // MARK: Bindings

    fileprivate func bindViewModel() {
        self.title = viewModel.title

        // Initial values
        homeGoalsStepper.value = Double(viewModel.homeGoals.value)
        awayGoalsStepper.value = Double(viewModel.awayGoals.value)

        viewModel.homeGoals <~ homeGoalsStepper.signalProducer()
        viewModel.awayGoals <~ awayGoalsStepper.signalProducer()

        viewModel.formattedHomeGoals.producer
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] formattedHomeGoals in
                self?.homeGoalsLabel.text = formattedHomeGoals
            })

        viewModel.formattedAwayGoals.producer
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] formattedAwayGoals in
                self?.awayGoalsLabel.text = formattedAwayGoals
            })

        viewModel.homePlayersString.producer
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] homePlayersString in
                self?.homePlayersButton.setTitle(homePlayersString, for: UIControlState())
            })

        viewModel.awayPlayersString.producer
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] awayPlayersString in
                self?.awayPlayersButton.setTitle(awayPlayersString, for: UIControlState())
            })

        viewModel.inputIsValid.producer
            .observe(on: UIScheduler())
            .startWithValues({ [weak self] inputIsValid in
                self?.saveButtonItem.isEnabled = inputIsValid
            })

        viewModel.saveAction.events.observeValues({ [weak self] event in
            switch event {
            case let .value(success):
                if success {
                    self?.dismiss(animated: true, completion: nil)
                } else {
                    self?.presentErrorMessage("The match could not be saved.")
                }
            case let .failed(error):
                self?.presentErrorMessage(error.localizedDescription)
            default:
                return
            }
        })
    }

    // MARK: Layout

    fileprivate func makeConstraints() {
        guard let superview = self.view else { return }

        homeGoalsLabel.snp_makeConstraints { make in
            make.trailing.equalTo(goalSeparatorLabel.snp_leading).offset(-10)
            make.baseline.equalTo(goalSeparatorLabel.snp_baseline)
        }

        goalSeparatorLabel.snp_makeConstraints { make in
            make.centerX.equalTo(superview.snp_centerX)
            make.centerY.equalTo(superview.snp_centerY).offset(-50)
        }

        awayGoalsLabel.snp_makeConstraints { make in
            make.leading.equalTo(goalSeparatorLabel.snp_trailing).offset(10)
            make.baseline.equalTo(goalSeparatorLabel.snp_baseline)
        }

        homeGoalsStepper.snp_makeConstraints { make in
            make.top.equalTo(goalSeparatorLabel.snp_bottom).offset(10)
            make.trailing.equalTo(homeGoalsLabel.snp_trailing)
        }

        awayGoalsStepper.snp_makeConstraints { make in
            make.top.equalTo(goalSeparatorLabel.snp_bottom).offset(10)
            make.leading.equalTo(awayGoalsLabel.snp_leading)
        }

        homePlayersButton.snp_makeConstraints { make in
            make.top.equalTo(homeGoalsStepper.snp_bottom).offset(30)
            make.leading.greaterThanOrEqualTo(superview.snp_leadingMargin)
            make.trailing.equalTo(homeGoalsLabel.snp_trailing)
        }

        awayPlayersButton.snp_makeConstraints { make in
            make.top.equalTo(awayGoalsStepper.snp_bottom).offset(30)
            make.leading.equalTo(awayGoalsLabel.snp_leading)
            make.trailing.lessThanOrEqualTo(superview.snp_trailingMargin)
        }
    }

    // MARK: User Interaction

    func cancelButtonTapped() {
        dismiss(animated: true, completion: nil)
    }

    func homePlayersButtonTapped() {
        let homePlayersViewModel = viewModel.manageHomePlayersViewModel()
        let homePlayersViewController = ManagePlayersViewController(viewModel: homePlayersViewModel)
        self.navigationController?.pushViewController(homePlayersViewController, animated: true)
    }

    func awayPlayersButtonTapped() {
        let awayPlayersViewModel = viewModel.manageAwayPlayersViewModel()
        let awayPlayersViewController = ManagePlayersViewController(viewModel: awayPlayersViewModel)
        self.navigationController?.pushViewController(awayPlayersViewController, animated: true)
    }

    // MARK: Private Helpers

    func presentErrorMessage(_ message: String) {
        let alertController = UIAlertController(
            title: "Oops!",
            message: message,
            preferredStyle: .alert
        )
        let cancelAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)

        self.present(alertController, animated: true, completion: nil)
    }
}
