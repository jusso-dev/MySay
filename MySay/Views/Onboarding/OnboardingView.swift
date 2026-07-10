import SwiftUI

/// Four quick welcome pages — designed to take well under a minute.
struct OnboardingView: View {
    @Environment(SettingsStore.self) private var settings

    @State private var page = 0
    @ScaledMetric(relativeTo: .largeTitle) private var symbolSize = 88

    private struct Page {
        let symbolName: String
        let color: TileColor
        let title: String
        let message: String
    }

    private let pages: [Page] = [
        Page(
            symbolName: "hand.tap.fill",
            color: .sky,
            title: "Tap pictures to speak",
            message: "Tap any picture and MySay says the word out loud. Try “Drink” — the iPad speaks for you."
        ),
        Page(
            symbolName: "star.fill",
            color: .butter,
            title: "Favourite the words you use most",
            message: "Touch and hold a picture, then Add to Favourites. Favourites stay on the Home screen, always one tap away."
        ),
        Page(
            symbolName: "text.bubble.fill",
            color: .sage,
            title: "Build sentences",
            message: "In Phrases, tap pictures in order — like “I” + “want” + “drink” — then press Speak Phrase to hear the whole sentence."
        ),
        Page(
            symbolName: "lock.shield.fill",
            color: .lavender,
            title: "Parents and carers",
            message: "Parent Mode (in Settings) lets you add your own photos as words, organise categories, and back everything up. Everything stays on this iPad."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $page) {
                ForEach(pages.indices, id: \.self) { index in
                    pageView(pages[index])
                        .tag(index)
                        .padding(.bottom, 60)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            HStack(spacing: 16) {
                if page < pages.count - 1 {
                    Button("Skip") {
                        finish()
                    }
                    .font(.title3)
                    .frame(minWidth: 120, minHeight: 56)
                    .accessibilityHint("Skips the introduction")
                }

                Button {
                    if page < pages.count - 1 {
                        page += 1
                    } else {
                        finish()
                    }
                } label: {
                    Text(page < pages.count - 1 ? "Next" : "Start Talking")
                        .font(.title3.weight(.semibold))
                        .frame(maxWidth: 320, minHeight: 56)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.bottom, 40)
            .padding(.horizontal)
        }
    }

    private func pageView(_ page: Page) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Image(systemName: page.symbolName)
                .font(.system(size: symbolSize))
                .foregroundStyle(page.color.accent)
                .padding(44)
                .background(Circle().fill(page.color.fill))
                .accessibilityHidden(true)
            Text(page.title)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            Text(page.message)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 560)
            Spacer()
        }
        .padding(.horizontal, 40)
    }

    private func finish() {
        settings.hasCompletedOnboarding = true
    }
}
