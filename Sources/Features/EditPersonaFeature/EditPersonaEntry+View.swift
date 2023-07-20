import FeaturePrelude

// MARK: - EntryWrapperView
struct EditPersonaEntryWrapperView<ContentView>: View where ContentView: View {
	public struct ViewState: Equatable {
		let name: String
		let isRequestedByDapp: Bool
		var canBeDeleted: Bool {
			!isRequestedByDapp
		}
	}

	let viewState: ViewState
	let contentView: () -> ContentView

	var body: some View {
		VStack {
			HStack {
				VStack {
					Text(viewState.name)
					if viewState.isRequestedByDapp {
						Text(L10n.EditPersona.requiredByDapp)
							.textStyle(.body2Regular)
							.foregroundColor(.app.gray2)
							.multilineTextAlignment(.trailing)
					}
				}
				Button(action: {}) {
					Image(asset: AssetResource.trash)
						.offset(x: .small3)
						.frame(.verySmall, alignment: .trailing)
				}
				.modifier {
					if viewState.canBeDeleted { $0 } else { $0.hidden() }
				}
			}

			contentView()
		}
	}
}
