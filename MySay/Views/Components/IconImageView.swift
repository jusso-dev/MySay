import SwiftUI

/// Renders an icon's artwork: the parent's photo when present, otherwise
/// the SF Symbol placeholder (with a safe fallback for unknown names).
struct IconImageView: View {
    let imageName: String
    let customImageData: Data?
    var accent: Color = .primary

    var body: some View {
        if let customImageData, let uiImage = UIImage(data: customImageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
                .clipShape(RoundedRectangle(cornerRadius: 12))
        } else {
            Image(systemName: validatedSymbolName)
                .resizable()
                .scaledToFit()
                .foregroundStyle(accent)
        }
    }

    private var validatedSymbolName: String {
        UIImage(systemName: imageName) != nil ? imageName : "questionmark.square.dashed"
    }
}
