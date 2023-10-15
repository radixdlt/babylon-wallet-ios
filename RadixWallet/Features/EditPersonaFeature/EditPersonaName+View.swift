import ComposableArchitecture
import SwiftUI

// MARK: - EditPersonaName.View
extension EditPersonaName {
	public typealias ViewState = State

	public struct View: SwiftUI.View {
		let store: StoreOf<EditPersonaName>

		public var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }, send: { .view($0) }) { viewStore in
				VStack(spacing: .medium2) {
					variantPicker(viewStore)

					VStack(spacing: .medium2) {
						if viewStore.variant == .eastern {
							easternOrder()
						} else {
							westernOrder()
						}
					}
				}
			}
		}

		// FIXME: Probably worth having as a kind of EditPersonaField
		@ViewBuilder
		func variantPicker(_ viewStore: ViewStoreOf<EditPersonaName>) -> some SwiftUI.View {
			Menu {
				Picker(selection: viewStore.binding(
					get: \.variant,
					send: ViewAction.variantPick
				), label: EmptyView()) {
					ForEach(PersonaData.Name.Variant.allCases, id: \.self) {
						Text($0.text)
							.textStyle(.body1Regular)
							.foregroundColor(.app.gray1)
					}
				}
			} label: {
				VStack(alignment: .leading, spacing: .small3) {
					Text(L10n.AuthorizedDapps.PersonaDetails.nameVariant)
						.textStyle(.body1HighImportance)
						.foregroundColor(.app.gray1)
						.multilineTextAlignment(.leading)

					HStack(spacing: .small2) {
						Text(viewStore.variant.text)
							.foregroundColor(.app.gray1)
							.textStyle(.body1Regular)

						Spacer()
						Image(asset: AssetResource.chevronDown)
							.foregroundColor(.app.gray1)
							.frame(.smallest)
					}
					.padding([.top, .bottom])
					.padding([.leading, .trailing], 6)
					.frame(height: .standardButtonHeight)
					.background(Color.app.gray5)
					.cornerRadius(.small2)
					.overlay(
						RoundedRectangle(cornerRadius: .small2)
							.stroke(.app.gray4, lineWidth: 1)
					)
				}
			}
		}

		// FIXME: Reordering could probably be done nicer by using a Grid probably
		@ViewBuilder
		func westernOrder() -> some SwiftUI.View {
			HStack(alignment: .top, spacing: .medium3) {
				EditPersonaField.View(
					store: store.scope(
						state: \.given,
						action: (/Action.child
							.. EditPersonaName.ChildAction.given
						).embed
					)
				)

				EditPersonaField.View(
					store: store.scope(
						state: \.nickName,
						action: (/Action.child
							.. EditPersonaName.ChildAction.nickname
						).embed
					)
				)
			}

			EditPersonaField.View(
				store: store.scope(
					state: \.family,
					action: (/Action.child
						.. EditPersonaName.ChildAction.family
					).embed
				)
			)
		}

		@ViewBuilder
		func easternOrder() -> some SwiftUI.View {
			EditPersonaField.View(
				store: store.scope(
					state: \.family,
					action: (/Action.child
						.. EditPersonaName.ChildAction.family
					).embed
				)
			)

			HStack(alignment: .top, spacing: .medium3) {
				EditPersonaField.View(
					store: store.scope(
						state: \.given,
						action: (/Action.child
							.. EditPersonaName.ChildAction.given
						).embed
					)
				)

				EditPersonaField.View(
					store: store.scope(
						state: \.nickName,
						action: (/Action.child
							.. EditPersonaName.ChildAction.nickname
						).embed
					)
				)
			}
		}
	}
}

extension PersonaData.Name.Variant {
	var text: String {
		switch self {
		case .western:
			L10n.AuthorizedDapps.PersonaDetails.nameVariantWestern
		case .eastern:
			L10n.AuthorizedDapps.PersonaDetails.nameVariantEastern
		}
	}
}
