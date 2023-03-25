import FeaturePrelude

// MARK: - Permission.View
extension PersonaDataPermission {
	struct ViewState: Equatable {
		let title: String
		let subtitle: AttributedString

		init(state: PersonaDataPermission.State) {
			title = L10n.DApp.AccountPermission.title
			subtitle = {
				let normalColor = Color.app.gray2
				let highlightColor = Color.app.gray1

				let dappName = AttributedString(state.dappMetadata.name.rawValue, foregroundColor: highlightColor)

				let explanation: AttributedString = {
					let always = AttributedString(L10n.DApp.PersonaDataPermission.Subtitle.always, foregroundColor: highlightColor)

					return AttributedString(
						L10n.DApp.PersonaDataPermission.Subtitle.Explanation.first,
						foregroundColor: normalColor
					)
						+ always
						+ AttributedString(
							L10n.DApp.PersonaDataPermission.Subtitle.Explanation.second,
							foregroundColor: normalColor
						)
				}()

				return dappName + explanation
			}()
		}
	}

	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<PersonaDataPermission>

		var body: some SwiftUI.View {
			WithViewStore(
				store,
				observe: ViewState.init,
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

							//                            VStack {
							//                                HStack {
							//                                    Text(viewStore.numberOfAccounts)
							//                                        .foregroundColor(.app.gray1)
							//                                        .textStyle(.body1Regular)
							//                                        .padding([.horizontal, .vertical], .medium1)
//
							//                                    Spacer()
							//                                }
							//                                .background(Color.app.gray5)
							//                                .cornerRadius(.medium3)
//
							//                                Spacer()
							//                                    .frame(height: .large1 * 1.5)
//
							//                                Text(L10n.DApp.Permission.updateInSettingsExplanation)
							//                                    .foregroundColor(.app.gray2)
							//                                    .textStyle(.body1Regular)
							//                                    .multilineTextAlignment(.center)
							//                                    .padding(.horizontal, .medium3)
							//                            }
							//                            .padding(.horizontal, .medium3)

							Spacer()
								.frame(height: .large1 * 1.5)
						}
						.padding(.horizontal, .medium1)
					}
					.footer {
						Button(L10n.DApp.Login.continueButtonTitle) {
							viewStore.send(.continueButtonTapped)
						}
						.buttonStyle(.primaryRectangular)
					}
				}
			}
		}

		var dappImage: some SwiftUI.View {
			// NOTE: using placeholder until API is available
			Color.app.gray4
				.frame(.medium)
				.cornerRadius(.medium3)
		}
	}
}

#if DEBUG
import SwiftUI // NB: necessary for previews to appear

// MARK: - Permission_Preview
struct PersonaDataPermission_Preview: PreviewProvider {
	static var previews: some SwiftUI.View {
		PersonaDataPermission.View(
			store: .init(
				initialState: .previewValue,
				reducer: PersonaDataPermission()
			)
		)
	}
}

extension PersonaDataPermission.State {
	static let previewValue: Self = .init(
		dappMetadata: .previewValue,
		numberOfAccounts: .exactly(1)
	)
}
#endif
