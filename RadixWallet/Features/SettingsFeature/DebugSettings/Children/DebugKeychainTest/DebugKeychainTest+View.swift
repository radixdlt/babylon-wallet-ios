#if DEBUG

import ComposableArchitecture
import SwiftUI

extension DebugKeychainTest.State {
	var viewState: DebugKeychainTest.ViewState {
		.init(
			status: status,
			containsDataForAuth: containsDataForAuth,
			containsDataForNoAuth: containsDataForNoAuth,
			serviceAndAccessGroup: serviceAndAccessGroup
		)
	}
}

// MARK: - DebugKeychainTest.View
extension DebugKeychainTest {
	struct ViewState: Equatable {
		let status: DebugKeychainTest.Status
		let containsDataForAuth: Bool
		let containsDataForNoAuth: Bool
		var serviceAndAccessGroup: KeychainClient.KeychainServiceAndAccessGroup?
		var canTest: Bool { status.canTest }
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<DebugKeychainTest>

		init(store: StoreOf<DebugKeychainTest>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(alignment: .center) {
					Text("This demo will create 10 Tasks run in parallel, each trying to load-else-generate-and-save some data for two different keys, one key for `auth` and one for `no auth`.\n\nThe test succeeds if only **one single** data was produced by the tasks, asserting that the operation is *atomic* and *data race free*.\n\nThe `Auth Test` also tests that the operation is **not** performed on the main thread, which it must not be.")
						.font(.app.body1Regular)

					Separator()

					StatusView(status: viewStore.status)

					VStack {
						if let serviceAndAccessGroup = viewStore.serviceAndAccessGroup {
							Text("Keychain service: `\(serviceAndAccessGroup.service)`")
							Text("Keychain accessGroup: `\(serviceAndAccessGroup.accessGroup ?? "NONE")`")
						}
						Text("Contains data for `\(authRandomKey.rawValue.rawValue)`: \(viewStore.containsDataForAuth.description)")
						Text("Contains data for `\(noAuthRandomKey.rawValue.rawValue)`: \(viewStore.containsDataForNoAuth.description)")
					}.font(.app.body3HighImportance)

					Separator()

					if viewStore.canTest {
						VStack {
							Button("`Auth Test`") {
								viewStore.send(.testAuth)
							}
							Text("**Should** prompted for biometrics *many* times.")
								.font(.app.resourceLabel)
						}
						Separator()
						VStack {
							Button("`No Auth Test`") {
								viewStore.send(.testNoAuth)
							}
							Text("Should **not** prompt for biometrics.")
								.font(.app.resourceLabel)
						}
					} else {
						Button("Restart") {
							viewStore.send(.reset)
						}
					}

					Spacer(minLength: 0)
				}
				.buttonStyle(.primaryRectangular)
				.font(.title)
				.padding()
				.onAppear { viewStore.send(.appeared) }
			}
		}
	}
}

// MARK: - StatusView
struct StatusView: View {
	let status: DebugKeychainTest.Status
	var body: some View {
		HStack {
			Circle().fill(status.color)
				.frame(width: 30, height: 30)
			Text("`\(status.description)`")
			Spacer(minLength: 0)
		}
	}
}

extension DebugKeychainTest.Status {
	var canTest: Bool {
		switch self {
		case .initialized: true
		default: false
		}
	}

	var description: String {
		switch self {
		case .new: "New"
		case .initializing: "Initializing"
		case let .failedToInitialize(error): "Failed to initialize \(error)"
		case .initialized: "Initialized"
		case let .error(error): "Error: \(error)"
		case .finishedSuccessfully: "Success"
		case let .finishedWithFailure(failure): "Failed: \(failure)"
		}
	}

	var color: Color {
		switch self {
		case .new: .gray
		case .initializing: .yellow
		case .failedToInitialize: .red
		case .initialized: .blue
		case .error: .red
		case .finishedSuccessfully: .green
		case .finishedWithFailure: .orange
		}
	}
}

#endif
