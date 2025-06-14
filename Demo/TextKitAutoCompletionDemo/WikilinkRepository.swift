//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Collection of hard-coded titles for wiki links to test the system.
struct WikilinkRepository {
    static let shared = WikilinkRepository()

    let wikilinks = [
        "(Dis-)Advantages of Bilingual Education",
        "Benefits of Regular Physical Activity",
        "Effect of Social Media on Mental Health",
        "Exploring the Human Microbiome",
        "Fostering Creative Thinking Techniques",
        "Importance of Open Source Software",
        "Influence of Music on Emotion",
        "Metaphysics of Time Travel",
        "Mindfulness Meditation",
        "Neural Networks Explained",
        "The Effect of Extremely Long Titles on Long-Term Memory Loss and the Movie Memento",
        "No Advances in Virtual Reality",
        "Quantum Computing",
        "Renewable Energy Innovations",
        "Sustainable Agriculture Practices",
        "The Impact of E-commerce on Retail",
        "Trends in Mobile App Development",
        "Video Game Design Evolution",
        "Zettelkasten Method Basics"
    ]
}

extension WikilinkRepository: Collection {
    typealias Index = Int
    typealias Element = String

    subscript(position: Int) -> String {
        wikilinks[position]
    }

    var startIndex: Int { wikilinks.startIndex }
    var endIndex: Int { wikilinks.endIndex }

    func index(after i: Int) -> Int {
        wikilinks.index(after: i)
    }
}
