//  Copyright © 2025 Christian Tietze. All rights reserved. Distributed under the MIT License.

import AppKit
import TextKitAutoCompletion

class TextViewController: NSViewController, NSTextViewDelegate {
    @IBOutlet weak var textView: TypeToCompleteTextView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}
