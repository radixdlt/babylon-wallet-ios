import ComposableArchitecture
import SwiftUI

// MARK: - EditPersonaName.View
extension EditPersonaName {
	typealias ViewState = State

	struct View: SwiftUI.View {
		let store: StoreOf<EditPersonaName>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium2) {
					variantPicker(viewStore)

					VStack(spacing: .medium2) {
						switch viewStore.variant {
						case .eastern:
							familyNameRow

							givenNameRow
						case .western:
							givenNameRow

							familyNameRow
						}
					}
				}
				.padding(.top, .small1)
			}
		}

		// FIXME: Probably worth having as a kind of EditPersonaField
		@ViewBuilder
		func variantPicker(_ viewStore: ViewStoreOf<EditPersonaName>) -> some SwiftUI.View {
			Menu {
				Picker(
					selection: viewStore.binding(
						get: \.variant,
						send: ViewAction.variantPick
					),
					label: EmptyView()
				) {
					ForEach(PersonaDataEntryName.Variant.allCases, id: \.self) {
						Text($0.text)
							.textStyle(.body1Regular)
							.foregroundColor(.primaryText)
					}
				}
			} label: {
				VStack(alignment: .leading, spacing: .small3) {
					Text(L10n.AuthorizedDapps.PersonaDetails.nameVariant)
						.textStyle(.body1HighImportance)
						.foregroundColor(.primaryText)
						.multilineTextAlignment(.leading)

					HStack(spacing: .small2) {
						Text(viewStore.variant.text)
							.foregroundColor(.primaryText)
							.textStyle(.body1Regular)

						Spacer()
						Image(asset: AssetResource.chevronDown)
							.foregroundColor(.primaryText)
							.frame(.smallest)
					}
					.padding([.top, .bottom])
					.padding([.leading, .trailing], 6)
					.frame(height: .standardButtonHeight)
					.background(.textFieldBackground)
					.cornerRadius(.small2)
					.overlay(
						RoundedRectangle(cornerRadius: .small2)
							.stroke(.border, lineWidth: 1)
					)
				}
			}
		}

		private var givenNameRow: some SwiftUI.View {
			HStack(alignment: .top, spacing: .medium2) {
				EditPersonaField.View(
					store: store.scope(
						state: \.given,
						action: { .child(.given($0)) }
					)
				)

				EditPersonaField.View(
					store: store.scope(
						state: \.nickname,
						action: { .child(.nickname($0)) }
					)
				)
			}
		}

		private var familyNameRow: some SwiftUI.View {
			EditPersonaField.View(
				store: store.scope(
					state: \.family,
					action: { .child(.family($0)) }
				)
			)
		}
	}
}

extension PersonaDataEntryName.Variant {
	var text: String {
		switch self {
		case .western:
			L10n.AuthorizedDapps.PersonaDetails.nameVariantWestern
		case .eastern:
			L10n.AuthorizedDapps.PersonaDetails.nameVariantEastern
		}
	}
}
