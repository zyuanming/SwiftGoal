//
//  Extensions.swift
//  SwiftGoal
//
//  Created by Martin Richter on 23/06/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import ReactiveCocoa
import Result
import UIKit
import ReactiveSwift

extension Array {
    func difference<T: Equatable>(_ otherArray: [T]) -> [T] {
        var result = [T]()

        for e in self {
            if let element = e as? T {
                if !otherArray.contains(element) {
                    result.append(element)
                }
            }
        }

        return result
    }

    func intersection<T: Equatable>(_ otherArray: [T]) -> [T] {
        var result = [T]()

        for e in self {
            if let element = e as? T {
                if otherArray.contains(element) {
                    result.append(element)
                }
            }
        }

        return result
    }
}

extension UIStepper {
    func signalProducer() -> Signal<Int, NoError> {
//        return self.rac_newValueChannel(withNilValue: 0).toSignalProducer()
//            .map { $0 as! Int }
//            .flatMapError { _ in return SignalProducer<Int, NoError>.empty }
        return self.reactive.values.map { Int($0) }.flatMapError { _ in return SignalProducer<Int, NoError>.empty }
    }
}

extension UITextField {
    func signalProducer() -> Signal<String, NoError> {
//        return self.rac_textSignal().toSignalProducer()
//            .map { $0 as! String }
//            .flatMapError { _ in return SignalProducer<String, NoError>.empty }
        return self.reactive.textValues.map { $0! }.flatMapError { _ in return SignalProducer<String, NoError>.empty }
    }
}

extension UIViewController {
    func isActive() -> Signal<Bool, NoError> {

        // Track whether view is visible

        let viewWillAppear = reactive.trigger(for: #selector(UIViewController.viewWillAppear(_:)))
        let viewWillDisappear = reactive.trigger(for: #selector(UIViewController.viewWillDisappear(_:)))


//        let viewIsVisible = Signal<Bool, NoError>([
//            viewWillAppear.map { _ in true },
//            viewWillDisappear.map { _ in false }
//        ]).flatten(.merge)

        let viewIsVisible = Signal.merge(viewWillAppear.map { _ in true }, viewWillDisappear.map { _ in false })

        // Track whether app is in foreground

        let notificationCenter = NotificationCenter.default

        let didBecomeActive = notificationCenter.reactive.notifications(forName: NSNotification.Name.UIApplicationDidBecomeActive)

        let willBecomeInactive = notificationCenter.reactive.notifications(forName: NSNotification.Name.UIApplicationWillResignActive)

//        let appIsActive = Signal<Signal<Bool, AnyError>, NoError>([
//            Signal<Bool, NoError>(value: true), // Account for app being initially active without notification
//            didBecomeActive.map { _ in true },
//            willBecomeInactive.map { _ in false }
//        ]).flatten(.merge)

        let appIsActive = Signal.merge(didBecomeActive.map { _ in true },
                                       willBecomeInactive.map { _ in false })

        // View controller is active iff both are true:

        return Signal.combineLatest(viewIsVisible, appIsActive)
            .map { $0 && $1 }
            .flatMapError { _ in SignalProducer.empty }
    }
}
