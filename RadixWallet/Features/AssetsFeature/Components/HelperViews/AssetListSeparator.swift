struct AssetListSeparator: View {
	var body: some View {
		Divider()
			.frame(height: .assetDividerHeight)
			.overlay(.secondaryBackground)
	}
}
