import FeaturePrelude

// MARK: - Permission.View
extension Permission {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<Permission>
	}
}

extension Permission.View {
	var body: some View {
		WithViewStore(
			store,
			observe: ViewState.init(state:),
			send: { .view($0) }
		) { viewStore in
			ForceFullScreen {
				VStack(spacing: .zero) {
					NavigationBar(
						leadingItem: CloseButton {
//							viewStore.send(.dismissButtonTapped)
						}
					)
					.foregroundColor(.app.gray1)
					.padding([.horizontal, .top], .medium3)

					Spacer()
						.frame(height: .small2)

					ScrollView {
						VStack(spacing: .medium2) {
							VStack(spacing: .medium2) {
								dappImage

								Text(titleText(with: viewStore))
									.foregroundColor(.app.gray1)
									.textStyle(.sheetTitle)

								subtitle(
									dappName: viewStore.dappName,
									message: subtitleText(with: viewStore)
								)
								.textStyle(.secondaryHeader)
								.multilineTextAlignment(.center)
							}
							.padding(.bottom, .medium2)

							VStack {
								HStack {
									Text("• 2 or more accounts")
										.foregroundColor(.app.gray1)
										.textStyle(.body1Regular)
										.padding([.horizontal, .vertical], .medium1)

									Spacer()
								}
								.background(Color.app.gray5)
								.cornerRadius(.medium3)

								Spacer()
									.frame(height: .large1 * 1.5)

								Text("You can update this permission in your settings at any time.")
									.foregroundColor(.app.gray2)
									.textStyle(.body1Regular)
									.multilineTextAlignment(.center)
									.padding(.horizontal, .medium3)
							}
							.padding(.horizontal, .medium3)

							Spacer()
								.frame(height: .large1 * 1.5)
						}
						.padding(.horizontal, .medium1)
					}

					ConfirmationFooter(
						title: L10n.DApp.LoginRequest.continueButtonTitle,
						isEnabled: true,
						action: {}
					)
				}
			}
		}
	}
}

// MARK: - Permission.View.PermissionViewStore
private extension Permission.View {
	typealias PermissionViewStore = ComposableArchitecture.ViewStore<Permission.View.ViewState, Permission.ViewAction>
}

private extension Permission.View {
	var dappImage: some View {
		// NOTE: using placeholder until API is available
		Color.app.gray4
			.frame(.medium)
			.cornerRadius(.medium3)
	}

	func titleText(with viewStore: PermissionViewStore) -> String {
		switch viewStore.permissionKind {
		case .account:
			return "Account Permission"
		case .personalData:
			return "Personal Data Permission"
		}
	}

	func subtitle(dappName: String, message: String) -> some View {
		var component1 = AttributedString(dappName)
		component1.foregroundColor = .app.gray1

		var component2 = AttributedString(message)
		component2.foregroundColor = .app.gray2

		return Text(component1 + component2)
	}

	func subtitleText(with viewStore: PermissionViewStore) -> String {
		switch viewStore.permissionKind {
		case .account:
			return " is requesting permission to always be able to view account information when you login with this Persona."
		case .personalData:
			return " is requesting permission to always be able to view the following personal data when you login with this Persona."
		}
	}
}

// MARK: - Permission.View.ViewState
extension Permission.View {
	struct ViewState: Equatable {
		let permissionKind: Permission.Kind
		let dappName: String

		init(state: Permission.State) {
			permissionKind = state.permissionKind
			dappName = state.dappMetadata.name
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Permission_Preview
struct Permission_Preview: PreviewProvider {
	static var previews: some View {
		Permission.View(
			store: .init(
				initialState: .previewValue,
				reducer: Permission()
			)
		)
	}
}
#endif
