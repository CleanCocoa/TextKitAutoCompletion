//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

extension MovementAction {
    init(wrapping candidateListViewController: CandidateListViewController) {
        self.init { [candidateListViewController] movement in
            switch movement {
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
