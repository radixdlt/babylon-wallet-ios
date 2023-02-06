import FeaturePrelude

// MARK: - Permission.View
extension Permission {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString

		init(state: Permission.State) {
			switch state.permissionKind {
			case .accounts:
				title = "Account Permission"
			case .personaData:
				title = "Personal Data Permission"
			}

			var dappName = AttributedString(state.dappMetadata.name)
			dappName.foregroundColor = Color.app.gray1
			var keywordAlways = AttributedString("always")
			keywordAlways.foregroundColor = Color.app.gray1

			let descriptionFirst: String
			let descriptionSecond: String

			switch state.permissionKind {
			case .accounts:
				descriptionFirst = " is requesting permission to "
				descriptionSecond = " be able to view account information when you login with this Persona."

			case .personaData:
				descriptionFirst = " is requesting permission to "
				descriptionSecond = " be able to view the following personal data when you login with this Persona."
			}

			var temp1 = AttributedString(descriptionFirst)
			temp1.foregroundColor = Color.app.gray2
			var temp2 = AttributedString(descriptionSecond)
			temp2.foregroundColor = Color.app.gray2
			subtitle = dappName + temp1 + keywordAlways + temp2
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
					.safeAreaInset(edge: .bottom) {
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
