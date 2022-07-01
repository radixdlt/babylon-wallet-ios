//
//  WalletApp.swift
//  Shared
//
//  Created by Alexander Cyon on 2022-06-30.
//

import AppFeature
import ComposableArchitecture
import SwiftUI

typealias App = AppFeature.App

public extension App.Environment {
	static let live = Self(
		backgroundQueue: DispatchQueue(label: "background-queue").eraseToAnyScheduler(),
		mainQueue: .main
	)
}

// MARK: - WalletApp
@main
struct WalletApp: SwiftUI.App {
	let store: Store

	init() {
		store = Store(
			initialState: .init(),
			reducer: App.reducer,
			environment: .live
		)
	}

	var body: some Scene {
		WindowGroup {
			App.Coordinator(store: store)
			#if os(macOS)
				.frame(minWidth: 1020, maxWidth: .infinity, minHeight: 512, maxHeight: .infinity)
			#endif
			Text("Version: \(Bundle.main.appVersionLong) build #\(Bundle.main.appBuild)")
				.padding()
		}
	}
}

extension WalletApp {
	typealias Store = ComposableArchitecture.Store<App.State, App.Action>
}
