import ComposableArchitecture
import SwiftUI

extension NewConnectionApproval.State {
	var viewState: NewConnectionApproval.ViewState {
		.init(
			screenState: isConnecting ? .loading(.global(text: L10n.LinkedConnectors.NewConnection.linking)) : .enabled,
			continueButtonControlState: isConnecting ? .loading(.local) : .enabled,
			title: title,
			message: message,
			dismissButtonTitle: dismissButtonTitle
		)
	}

	private var title: String {
		switch purpose {
		case .approveNewConnection:
			L10n.LinkedConnectors.ApproveNewConnector.title
		case .approveExisitingConnection:
			L10n.LinkedConnectors.ApproveExistingConnector.title
		case .approveRelinkAfterProfileRestore, .approveRelinkAfterUpdate:
			L10n.LinkedConnectors.RelinkConnectors.title
		}
	}

	private var message: String {
		switch purpose {
		case .approveNewConnection:
			L10n.LinkedConnectors.ApproveNewConnector.message
		case .approveExisitingConnection:
			L10n.LinkedConnectors.ApproveExistingConnector.message
		case .approveRelinkAfterProfileRestore:
			L10n.LinkedConnectors.RelinkConnectors.afterProfileRestoreMessage
		case .approveRelinkAfterUpdate:
			L10n.LinkedConnectors.RelinkConnectors.afterUpdateMessage
		}
	}

	private var dismissButtonTitle: String {
		switch purpose {
		case .approveNewConnection, .approveExisitingConnection:
			L10n.Common.cancel
		case .approveRelinkAfterProfileRestore, .approveRelinkAfterUpdate:
			L10n.LinkedConnectors.RelinkConnectors.laterButton
		}
	}
}

// MARK: - NewConnectionApproval.View
extension NewConnectionApproval {
	struct ViewState: Equatable {
		let screenState: ControlState
		let continueButtonControlState: ControlState
		let title: String
		let message: String
		let dismissButtonTitle: String
	}

	@MainActor
	struct View: SwiftUI.View {
		private let store: StoreOf<NewConnectionApproval>

		init(store: StoreOf<NewConnectionApproval>) {
			self.store = store
		}

		var body: some SwiftUI.View {
			WithViewStore(store, observe: \.viewState, send: { .view($0) }) { viewStore in
				VStack(spacing: 0) {
					Image(.desktopLinkConnector)
						.padding(.bottom, .large1)

					Text(viewStore.title)
						.foregroundColor(.primaryText)
						.textStyle(.sheetTitle)
						.padding(.bottom, .medium1)

					Text(LocalizedStringKey(viewStore.message))
						.textStyle(.body1Regular)
						.multilineTextAlignment(.center)
						.padding(.horizontal, .large1)

					Spacer()

					HStack {
						Button(viewStore.dismissButtonTitle) {
							viewStore.send(.dismissButtonTapped)
						}
						.buttonStyle(.secondaryRectangular)

						Button(L10n.Common.continue) {
							viewStore.send(.continueButtonTapped)
						}
						.controlState(viewStore.continueButtonControlState)
						.buttonStyle(.primaryRectangular)
					}
					.padding([.horizontal, .bottom], .medium1)
				}
				.padding(.top, .large2)
				.controlState(viewStore.screenState)
			}
		}
	}
}
