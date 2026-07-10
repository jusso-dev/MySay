import Foundation

/// The bundled starter vocabulary: 13 categories, 140 icons.
///
/// Artwork is SF Symbols only — development placeholders that ship free of
/// licensing constraints. The architecture supports replacing them with
/// ARASAAC / OpenSymbols imports or parent photos (see `SymbolProviders`).
nonisolated enum SeedData {
    struct CategoryDefinition: Sendable {
        let name: String
        let symbolName: String
        let color: TileColor
        let sortOrder: Int
    }

    static let categories: [CategoryDefinition] = [
        .init(name: "Quick Phrases", symbolName: "bolt.fill", color: .butter, sortOrder: -1),
        .init(name: "Core Words", symbolName: "quote.bubble.fill", color: .slate, sortOrder: 0),
        .init(name: "People", symbolName: "person.2.fill", color: .coral, sortOrder: 1),
        .init(name: "Food", symbolName: "fork.knife", color: .peach, sortOrder: 2),
        .init(name: "Drinks", symbolName: "cup.and.saucer.fill", color: .sky, sortOrder: 3),
        .init(name: "Feelings", symbolName: "face.smiling.fill", color: .lavender, sortOrder: 4),
        .init(name: "Needs", symbolName: "hand.raised.fill", color: .rose, sortOrder: 5),
        .init(name: "Activities", symbolName: "balloon.2.fill", color: .sage, sortOrder: 6),
        .init(name: "Places", symbolName: "house.fill", color: .teal, sortOrder: 7),
        .init(name: "Body", symbolName: "figure.stand", color: .sand, sortOrder: 8),
        .init(name: "Clothes", symbolName: "tshirt.fill", color: .butter, sortOrder: 9),
        .init(name: "Animals", symbolName: "pawprint.fill", color: .sage, sortOrder: 10),
        .init(name: "School", symbolName: "graduationcap.fill", color: .lavender, sortOrder: 11),
        .init(name: "Weather", symbolName: "cloud.sun.fill", color: .sky, sortOrder: 12),
    ]

    static let icons: [CommunicationIcon] = quickPhrases + coreWords + people
        + food + drinks + feelings + needs + activities + places + body
        + clothes + animals + school + weather

    // MARK: - Quick Phrases
    // Whole pre-stored sentences for urgent or frequent messages — one tap
    // speaks the full phrase.

    static let quickPhrases: [CommunicationIcon] = [
        .init(title: "Help", imageName: "exclamationmark.bubble.fill", category: "Quick Phrases", phraseText: "I need help please"),
        .init(title: "Toilet", imageName: "toilet.fill", category: "Quick Phrases", phraseText: "I need the toilet"),
        .init(title: "Hungry", imageName: "fork.knife", category: "Quick Phrases", phraseText: "I'm hungry"),
        .init(title: "Thirsty", imageName: "drop.fill", category: "Quick Phrases", phraseText: "I'm thirsty"),
        .init(title: "Break", imageName: "pause.circle.fill", category: "Quick Phrases", phraseText: "I want a break"),
        .init(title: "Space", imageName: "person.slash.fill", category: "Quick Phrases", phraseText: "Please give me some space"),
        .init(title: "Play With Me", imageName: "balloon.2.fill", category: "Quick Phrases", phraseText: "Come and play with me"),
        .init(title: "Feel Sick", imageName: "thermometer.medium", category: "Quick Phrases", phraseText: "I don't feel well"),
        .init(title: "It Hurts", imageName: "bandage.fill", category: "Quick Phrases", phraseText: "It hurts"),
        .init(title: "Wait", imageName: "clock.fill", category: "Quick Phrases", phraseText: "Please wait for me"),
        .init(title: "Love You", imageName: "heart.fill", category: "Quick Phrases", phraseText: "I love you"),
        .init(title: "All Done", imageName: "checkmark.seal.fill", category: "Quick Phrases", phraseText: "I'm all done"),
    ]

    // MARK: - Core Words

    static let coreWords: [CommunicationIcon] = [
        .init(title: "I", imageName: "person.fill", category: "Core Words", phraseText: "I"),
        .init(title: "You", imageName: "person.wave.2.fill", category: "Core Words"),
        .init(title: "Want", imageName: "hand.point.up.left.fill", category: "Core Words"),
        .init(title: "Like", imageName: "hand.thumbsup.fill", category: "Core Words"),
        .init(title: "Don't Like", imageName: "hand.thumbsdown.fill", category: "Core Words", phraseText: "don't like"),
        .init(title: "Yes", imageName: "checkmark.circle.fill", category: "Core Words"),
        .init(title: "No", imageName: "xmark.circle.fill", category: "Core Words"),
        .init(title: "More", imageName: "plus.circle.fill", category: "Core Words"),
        .init(title: "All Done", imageName: "checkmark.seal.fill", category: "Core Words", phraseText: "all done"),
        .init(title: "Go", imageName: "arrow.right.circle.fill", category: "Core Words"),
        .init(title: "Stop", imageName: "hand.raised.fill", category: "Core Words"),
        .init(title: "Come", imageName: "arrow.left.circle.fill", category: "Core Words"),
        .init(title: "Look", imageName: "eye.fill", category: "Core Words"),
        .init(title: "Give", imageName: "gift.fill", category: "Core Words"),
        .init(title: "Open", imageName: "lock.open.fill", category: "Core Words"),
        .init(title: "Wait", imageName: "clock.fill", category: "Core Words"),
        .init(title: "Please", imageName: "hands.clap.fill", category: "Core Words"),
        .init(title: "Thank You", imageName: "heart.fill", category: "Core Words", phraseText: "thank you"),
        .init(title: "My Turn", imageName: "arrow.triangle.2.circlepath", category: "Core Words", phraseText: "my turn"),
    ]

    // MARK: - People

    static let people: [CommunicationIcon] = [
        .init(title: "Mum", imageName: "figure.stand.dress", category: "People"),
        .init(title: "Dad", imageName: "figure.stand", category: "People"),
        .init(title: "Brother", imageName: "figure.child", category: "People"),
        .init(title: "Sister", imageName: "figure.child", category: "People"),
        .init(title: "Friend", imageName: "figure.2.arms.open", category: "People"),
        .init(title: "Grandma", imageName: "figure.walk", category: "People"),
        .init(title: "Grandpa", imageName: "figure.walk", category: "People"),
        .init(title: "Baby", imageName: "figure.and.child.holdinghands", category: "People"),
        .init(title: "Teacher", imageName: "graduationcap.fill", category: "People"),
        .init(title: "Doctor", imageName: "stethoscope", category: "People"),
    ]

    // MARK: - Food

    static let food: [CommunicationIcon] = [
        .init(title: "Apple", imageName: "apple.logo", category: "Food"),
        .init(title: "Banana", imageName: "moon.fill", category: "Food"),
        .init(title: "Sandwich", imageName: "rectangle.stack.fill", category: "Food"),
        .init(title: "Bread", imageName: "rectangle.fill", category: "Food"),
        .init(title: "Cheese", imageName: "triangle.fill", category: "Food"),
        .init(title: "Egg", imageName: "oval.portrait.fill", category: "Food"),
        .init(title: "Pizza", imageName: "chart.pie.fill", category: "Food"),
        .init(title: "Carrot", imageName: "carrot.fill", category: "Food"),
        .init(title: "Fish", imageName: "fish.fill", category: "Food"),
        .init(title: "Popcorn", imageName: "popcorn.fill", category: "Food"),
        .init(title: "Cake", imageName: "birthday.cake.fill", category: "Food"),
        .init(title: "Ice Cream", imageName: "snowflake", category: "Food", phraseText: "ice cream"),
        .init(title: "Dinner", imageName: "fork.knife", category: "Food"),
        .init(title: "Snack", imageName: "takeoutbag.and.cup.and.straw.fill", category: "Food"),
        .init(title: "Lolly", imageName: "circle.hexagongrid.fill", category: "Food"),
    ]

    // MARK: - Drinks

    static let drinks: [CommunicationIcon] = [
        .init(title: "Drink", imageName: "cup.and.saucer.fill", category: "Drinks"),
        .init(title: "Water", imageName: "drop.fill", category: "Drinks"),
        .init(title: "Juice", imageName: "takeoutbag.and.cup.and.straw.fill", category: "Drinks"),
        .init(title: "Milk", imageName: "waterbottle.fill", category: "Drinks"),
        .init(title: "Tea", imageName: "mug.fill", category: "Drinks"),
        .init(title: "Hot Chocolate", imageName: "mug.fill", category: "Drinks", phraseText: "hot chocolate"),
    ]

    // MARK: - Feelings

    static let feelings: [CommunicationIcon] = [
        .init(title: "Happy", imageName: "face.smiling.fill", category: "Feelings"),
        .init(title: "Sad", imageName: "cloud.rain.fill", category: "Feelings"),
        .init(title: "Angry", imageName: "flame.fill", category: "Feelings"),
        .init(title: "Tired", imageName: "moon.zzz.fill", category: "Feelings"),
        .init(title: "Excited", imageName: "star.fill", category: "Feelings"),
        .init(title: "Scared", imageName: "exclamationmark.triangle.fill", category: "Feelings"),
        .init(title: "Sick", imageName: "thermometer.medium", category: "Feelings"),
        .init(title: "Calm", imageName: "leaf.fill", category: "Feelings"),
        .init(title: "Love", imageName: "heart.fill", category: "Feelings"),
        .init(title: "Silly", imageName: "face.smiling.inverse", category: "Feelings"),
    ]

    // MARK: - Needs

    static let needs: [CommunicationIcon] = [
        .init(title: "Toilet", imageName: "toilet.fill", category: "Needs"),
        .init(title: "Help", imageName: "questionmark.circle.fill", category: "Needs"),
        .init(title: "Stop", imageName: "hand.raised.fill", category: "Needs"),
        .init(title: "More", imageName: "plus.circle.fill", category: "Needs"),
        .init(title: "Finished", imageName: "checkmark.circle.fill", category: "Needs"),
        .init(title: "Hungry", imageName: "fork.knife", category: "Needs"),
        .init(title: "Thirsty", imageName: "drop.fill", category: "Needs"),
        .init(title: "Hurt", imageName: "bandage.fill", category: "Needs"),
        .init(title: "Break", imageName: "pause.circle.fill", category: "Needs"),
        .init(title: "Hug", imageName: "heart.circle.fill", category: "Needs"),
        .init(title: "Quiet", imageName: "speaker.slash.fill", category: "Needs"),
        .init(title: "Wash Hands", imageName: "sparkles", category: "Needs", phraseText: "wash hands"),
    ]

    // MARK: - Activities

    static let activities: [CommunicationIcon] = [
        .init(title: "Play", imageName: "balloon.2.fill", category: "Activities"),
        .init(title: "Read", imageName: "book.fill", category: "Activities"),
        .init(title: "Sleep", imageName: "bed.double.fill", category: "Activities"),
        .init(title: "Outside", imageName: "sun.max.fill", category: "Activities"),
        .init(title: "iPad", imageName: "ipad", category: "Activities"),
        .init(title: "Draw", imageName: "paintbrush.fill", category: "Activities"),
        .init(title: "Music", imageName: "music.note", category: "Activities"),
        .init(title: "Swim", imageName: "figure.pool.swim", category: "Activities"),
        .init(title: "Run", imageName: "figure.run", category: "Activities"),
        .init(title: "Walk", imageName: "figure.walk", category: "Activities"),
        .init(title: "Dance", imageName: "figure.dance", category: "Activities"),
        .init(title: "TV", imageName: "tv.fill", category: "Activities"),
        .init(title: "Bath", imageName: "bathtub.fill", category: "Activities"),
        .init(title: "Ball", imageName: "soccerball", category: "Activities"),
        .init(title: "Blocks", imageName: "square.stack.3d.up.fill", category: "Activities"),
        .init(title: "Puzzle", imageName: "puzzlepiece.fill", category: "Activities"),
    ]

    // MARK: - Places

    static let places: [CommunicationIcon] = [
        .init(title: "Home", imageName: "house.fill", category: "Places"),
        .init(title: "School", imageName: "graduationcap.fill", category: "Places"),
        .init(title: "Park", imageName: "tree.fill", category: "Places"),
        .init(title: "Car", imageName: "car.fill", category: "Places"),
        .init(title: "Shops", imageName: "cart.fill", category: "Places"),
        .init(title: "Beach", imageName: "beach.umbrella.fill", category: "Places"),
        .init(title: "Pool", imageName: "figure.pool.swim", category: "Places"),
        .init(title: "Library", imageName: "books.vertical.fill", category: "Places"),
        .init(title: "Playground", imageName: "figure.gymnastics", category: "Places"),
        .init(title: "Doctor", imageName: "cross.case.fill", category: "Places"),
    ]

    // MARK: - Body

    static let body: [CommunicationIcon] = [
        .init(title: "Eyes", imageName: "eye.fill", category: "Body"),
        .init(title: "Ears", imageName: "ear.fill", category: "Body"),
        .init(title: "Nose", imageName: "nose.fill", category: "Body"),
        .init(title: "Mouth", imageName: "mouth.fill", category: "Body"),
        .init(title: "Hands", imageName: "hand.raised.fill", category: "Body"),
        .init(title: "Feet", imageName: "shoeprints.fill", category: "Body"),
        .init(title: "Head", imageName: "brain.head.profile", category: "Body"),
        .init(title: "Hair", imageName: "comb.fill", category: "Body"),
    ]

    // MARK: - Clothes

    static let clothes: [CommunicationIcon] = [
        .init(title: "Shirt", imageName: "tshirt.fill", category: "Clothes"),
        .init(title: "Shoes", imageName: "shoe.fill", category: "Clothes"),
        .init(title: "Hat", imageName: "hat.cap.fill", category: "Clothes"),
        .init(title: "Jacket", imageName: "jacket", category: "Clothes"),
        .init(title: "Backpack", imageName: "backpack.fill", category: "Clothes"),
        .init(title: "Glasses", imageName: "eyeglasses", category: "Clothes"),
        .init(title: "Pyjamas", imageName: "moon.zzz.fill", category: "Clothes"),
        .init(title: "Socks", imageName: "shoeprints.fill", category: "Clothes"),
    ]

    // MARK: - Animals

    static let animals: [CommunicationIcon] = [
        .init(title: "Dog", imageName: "dog.fill", category: "Animals"),
        .init(title: "Cat", imageName: "cat.fill", category: "Animals"),
        .init(title: "Bird", imageName: "bird.fill", category: "Animals"),
        .init(title: "Fish", imageName: "fish.fill", category: "Animals"),
        .init(title: "Rabbit", imageName: "hare.fill", category: "Animals"),
        .init(title: "Turtle", imageName: "tortoise.fill", category: "Animals"),
        .init(title: "Lizard", imageName: "lizard.fill", category: "Animals"),
        .init(title: "Ladybug", imageName: "ladybug.fill", category: "Animals"),
        .init(title: "Ant", imageName: "ant.fill", category: "Animals"),
        .init(title: "Horse", imageName: "figure.equestrian.sports", category: "Animals"),
    ]

    // MARK: - School

    static let school: [CommunicationIcon] = [
        .init(title: "Pencil", imageName: "pencil", category: "School"),
        .init(title: "Book", imageName: "book.fill", category: "School"),
        .init(title: "Paint", imageName: "paintpalette.fill", category: "School"),
        .init(title: "Scissors", imageName: "scissors", category: "School"),
        .init(title: "Ruler", imageName: "ruler.fill", category: "School"),
        .init(title: "Computer", imageName: "laptopcomputer", category: "School"),
        .init(title: "Friends", imageName: "person.3.fill", category: "School"),
        .init(title: "Bag", imageName: "backpack.fill", category: "School"),
    ]

    // MARK: - Weather

    static let weather: [CommunicationIcon] = [
        .init(title: "Sunny", imageName: "sun.max.fill", category: "Weather"),
        .init(title: "Rainy", imageName: "cloud.rain.fill", category: "Weather"),
        .init(title: "Cloudy", imageName: "cloud.fill", category: "Weather"),
        .init(title: "Windy", imageName: "wind", category: "Weather"),
        .init(title: "Snow", imageName: "snowflake", category: "Weather"),
        .init(title: "Storm", imageName: "cloud.bolt.fill", category: "Weather"),
        .init(title: "Rainbow", imageName: "rainbow", category: "Weather"),
        .init(title: "Hot", imageName: "thermometer.sun.fill", category: "Weather"),
    ]
}
