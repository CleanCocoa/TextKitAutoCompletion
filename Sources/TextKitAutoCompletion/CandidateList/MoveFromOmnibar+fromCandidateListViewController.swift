//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import Omnibar

extension MoveFromOmnibar {
    init(wrapping candidateListViewController: CandidateListViewController) {
        self.init { [candidateListViewController] event in
            switch event.movement {
            case .top:
                candidateListViewController.selectFirst()
            case .bottom:
                candidateListViewController.selectLast()
            case .up:
                candidateListViewController.selectPrevious()
            case .down:
                candidateListViewController.selectNext()
            }
        }
    }
}
