import Foundation
import SwiftUI

final class BibleRouter: ObservableObject {
    enum Command {
        case goToBooksRoot
        case goToChapter(book: BibleBook, chapter: Int)
    }

    @Published private(set) var lastCommandId: Int = 0
    private(set) var lastCommand: Command? = nil

    @MainActor
    func goToBooksRoot() {
        lastCommand = .goToBooksRoot
        lastCommandId &+= 1
    }

    @MainActor
    func goToChapter(book: BibleBook, chapter: Int) {
        lastCommand = .goToChapter(book: book, chapter: chapter)
        lastCommandId &+= 1
    }
}


