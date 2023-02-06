import FeaturePrelude

// MARK: - Permission.View
extension Permission {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString
		let numberOfAccounts: String

		init(state: Permission.State) {
			switch state.permissionKind {
			case .accounts:
				title = "Account Permission"
			case .personalData:
				title = "Personal Data Permission"
			}

			let normalColor = Color.app.gray2
			let highlightColor = Color.app.gray1
			subtitle = AttributedString(state.dappMetadata.name, foregroundColor: highlightColor) + {
				let always = AttributedString("always", foregroundColor: highlightColor)
				switch state.permissionKind {
				case .accounts:
					return AttributedString(
						" is requesting permission to ",
						foregroundColor: normalColor
					)
						+ always
						+ AttributedString(
							" be able to view account information when you login with this Persona.",
							foregroundColor: normalColor
						)
				case .personalData:
					return AttributedString(
						" is requesting permission to ",
						foregroundColor: normalColor
					)
						+ always
						+ AttributedString(
							" be able to view the following personal data when you login with this Persona.",
							foregroundColor: normalColor
						)
				}
			}()

			switch state.permissionKind {
			case let .accounts(numberOfAccounts):
				switch (numberOfAccounts.quantifier, numberOfAccounts.quantity) {
				case (.atLeast, 0):
					self.numberOfAccounts = "Any accounts"
				case let (.atLeast, number):
					self.numberOfAccounts = "\(number) or more accounts"
				case (.exactly, 1):
					self.numberOfAccounts = "1 account"
				case let (.exactly, number):
					self.numberOfAccounts = "\(number) accounts"
				}
			case .personalData:
				self.numberOfAccounts = ""
			}
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<Permission>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: Permission.ViewState.init,
				send: { .view($0) }
			) { viewStore in
				ForceFullScreen {
					ScrollView {
						VStack(spacing: .medium2) {
							VStack(spacing: .medium2) {
								dappImage

								Text(viewStore.title)
									.foregroundColor(.app.gray1)
									.textStyle(.sheetTitle)

								Text(viewStore.subtitle)
									.textStyle(.secondaryHeader)
									.multilineTextAlignment(.center)
							}
							.padding(.bottom, .medium2)

							VStack {
								HStack {
									Text("• " + viewStore.numberOfAccounts)
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
					.safeAreaInset(edge: .bottom) {
						ConfirmationFooter(
							title: L10n.DApp.LoginRequest.continueButtonTitle,
							isEnabled: true,
							action: { viewStore.send(.continueButtonTapped) }
						)
					}
				}
			}
		}
	}
}

private extension Permission.View {
	// NB: will most likely belong in ViewState
	var dappImage: some SwiftUI.View {
		// NOTE: using placeholder until API is available
		Color.app.gray4
			.frame(.medium)
			.cornerRadius(.medium3)
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Permission_Preview
struct Permission_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		Permission.View(
			store: .init(
				initialState: .previewValue,
				reducer: Permission()
			)
		)
	}
}
#endif
