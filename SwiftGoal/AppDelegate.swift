//
//  AppDelegate.swift
//  SwiftGoal
//
//  Created by Martin Richter on 10/05/15.
//  Copyright (c) 2015 Martin Richter. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var store: StoreType?
    let tabBarController = UITabBarController()

    // Keys and default values for Settings
    fileprivate let useRemoteStoreSettingKey = "use_remote_store_setting"
    fileprivate let useRemoteStoreSettingDefault = false
    fileprivate let baseURLSettingKey = "base_url_setting"
    fileprivate let baseURLSettingDefault = "http://localhost:3000/api/v1/"

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {

        window = UIWindow(frame: UIScreen.main.bounds)
        customizeAppAppearance()

        let userDefaults = UserDefaults.standard
        registerInitialSettings(userDefaults)

        // Set tab-level view controllers with appropriate store
        store = storeForUserDefaults(userDefaults)
        tabBarController.viewControllers = tabViewControllersForStore(store)

        // Register for settings changes as store might have changed
        NotificationCenter.default.addObserver(self,
            selector: #selector(userDefaultsDidChange(_:)),
            name: UserDefaults.didChangeNotification,
            object: nil)

        window?.rootViewController = tabBarController
        window?.makeKeyAndVisible()

        return true
    }

    func applicationWillTerminate(_ application: UIApplication) {
        archiveStoreIfLocal()
    }

    // MARK: Notifications

    @objc func userDefaultsDidChange(_ notification: Notification) {
        if let userDefaults = notification.object as? UserDefaults {
            archiveStoreIfLocal()
            store = storeForUserDefaults(userDefaults)
            tabBarController.viewControllers = tabViewControllersForStore(store)
        }
    }

    // MARK: Private Helpers

    fileprivate func customizeAppAppearance() {
        UIApplication.shared.statusBarStyle = .lightContent
        let tintColor = Color.primaryColor
        window?.tintColor = tintColor
        UINavigationBar.appearance().barTintColor = tintColor
        UINavigationBar.appearance().tintColor = UIColor.white
        UINavigationBar.appearance().titleTextAttributes = [
            NSAttributedStringKey.font: UIFont(name: "OpenSans-Semibold", size: 20)!,
            NSAttributedStringKey.foregroundColor: UIColor.white
        ]
        UINavigationBar.appearance().isTranslucent = false
        UIBarButtonItem.appearance().setTitleTextAttributes(
            [NSAttributedStringKey.font: UIFont(name: "OpenSans", size: 17)!],
            for: UIControlState()
        )
    }

    fileprivate func registerInitialSettings(_ userDefaults: UserDefaults) {
        if userDefaults.object(forKey: useRemoteStoreSettingKey) == nil {
            userDefaults.set(useRemoteStoreSettingDefault, forKey: useRemoteStoreSettingKey)
        }
        if userDefaults.string(forKey: baseURLSettingKey) == nil {
            userDefaults.set(baseURLSettingDefault, forKey: baseURLSettingKey)
        }
    }

    /// Archives the current store to disk if it's a local store.
    fileprivate func archiveStoreIfLocal() {
        if let localStore = store as? LocalStore {
            localStore.archiveToDisk()
        }
    }

    fileprivate func storeForUserDefaults(_ userDefaults: UserDefaults) -> StoreType {
        if userDefaults.bool(forKey: useRemoteStoreSettingKey) == true {
            // Create remote store
            let baseURLString = userDefaults.string(forKey: baseURLSettingKey) ?? baseURLSettingDefault
            let baseURL = baseURLFromString(baseURLString)
            return RemoteStore(baseURL: baseURL)
        } else {
            // Create local store
            let store = LocalStore()
            store.unarchiveFromDisk()
            return store
        }
    }

    fileprivate func baseURLFromString(_ string: String) -> URL {
        var baseURLString = string

        // Append forward slash if needed to ensure proper relative URL behavior
        let forwardSlash: Character = "/"
        if !baseURLString.hasSuffix(String(forwardSlash)) {
            baseURLString.append(forwardSlash)
        }

        return URL(string: baseURLString) ?? URL(string: baseURLSettingDefault)!
    }

    fileprivate func tabViewControllersForStore(_ store: StoreType?) -> [UIViewController] {
        guard let store = store else { return [] }

        let matchesViewModel = MatchesViewModel(store: store)
        let matchesViewController = MatchesViewController(viewModel: matchesViewModel)
        let matchesNavigationController = UINavigationController(rootViewController: matchesViewController)
        matchesNavigationController.tabBarItem = UITabBarItem(
            title: matchesViewModel.title,
            image: UIImage(named: "FootballFilled"),
            selectedImage: UIImage(named: "FootballFilled")
        )

        let rankingsViewModel = RankingsViewModel(store: store)
        let rankingsViewController = RankingsViewController(viewModel: rankingsViewModel)
        let rankingsNavigationController = UINavigationController(rootViewController: rankingsViewController)
        rankingsNavigationController.tabBarItem = UITabBarItem(
            title: rankingsViewModel.title,
            image: UIImage(named: "Crown"),
            selectedImage: UIImage(named: "CrownFilled")
        )

        return [matchesNavigationController, rankingsNavigationController]
    }
}

