//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

/// Collection of hard-coded hashtags to test the system.
struct HashtagRepository {
    static let shared = HashtagRepository()

    let hashtags = [
        "###art",
        "####work",
        "##workflow",
        "##photography",
        "##drawing",
        "##sketching",
        "##design",
        "##programming",
        "#landscape",
        "#nature",
        "#sunset",
        "#travel",
        "#clouds",
        "#monochrome",
        "#macro",
        "#wildlife",
        "#forest",
        "#mountains",
        "#cityscape",
        "#seascape",
        "#portrait",
        "#streetphotography",
        "#architecture",
        "#notetaking",
        "#journaling",
        "#bulletjournal",
        "#stationery",
        "#productivity",
        "#mindmap",
        "#Zettelkasten",
        "#studygram",
        "#writing",
        "#writerscommunity",
        "#editing",
        "#creativewriting",
        "#handwriting",
        "#lettering",
        "#conceptart",
        "#typography",
        "#aesthetic",
        "#technology",
        "#coding",
        "#javascript",
        "#webdevelopment",
        "#developer",
        "#tech",
        "#innovation",
        "#future",
        "#minimalism",
        "#organization",
        "#efficiency",
        "#focus",
        "#selfimprovement",
        "#motivation",
        "#goals",
        "#habits",
        "#learning",
        "#studytips",
        "#education",
        "#studying",
        "#creativity",
        "#mindfulness",
        "#inspiration",
        "#quotes",
        "#ideas",
        "#perspective",
        "#goexplore",
        "#discover",
        "#momentsoflife",
        "#wanderlust",
        "#adventure",
        "#instagood",
        "#photographylovers",
        "#snapshot",
        "#blackandwhite",
        "#visualstorytelling",
        "#analogphotography",
        "#filmphotography",
        "#everydaymoments"
    ]
}

extension HashtagRepository: Collection {
    typealias Index = Int
    typealias Element = String

    subscript(position: Int) -> String {
        hashtags[position]
    }

    var startIndex: Int { hashtags.startIndex }
    var endIndex: Int { hashtags.endIndex }

    func index(after i: Int) -> Int {
        hashtags.index(after: i)
    }
}
