import Foundation
import Testing
import UIKit
@testable import Genki

/// The boundary to Apple Vision, exercised for real: text is drawn into an
/// image in memory and recognized on the simulator. No real report images.
struct OCRServiceTests {
    @Test("Printed Chinese text is recognized, one page per image")
    func recognizesPages() async throws {
        let pages = [Self.image(of: "科室：眼科"), Self.image(of: "诊断：轻度近视")]

        let text = try await OCRService.recognize(imageData: pages)

        #expect(text.contains("眼科"))
        #expect(text.contains("轻度近视"))
        #expect(text.contains("下一页"))
    }

    @Test("No images is an error, not an empty result")
    func rejectsNoImages() async {
        await #expect(throws: OCRError.noImages) {
            try await OCRService.recognize(imageData: [])
        }
    }

    private static func image(of text: String) -> Data {
        let size = CGSize(width: 900, height: 220)
        return UIGraphicsImageRenderer(size: size).pngData { context in
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: size))
            (text as NSString).draw(
                at: CGPoint(x: 40, y: 60),
                withAttributes: [.font: UIFont.systemFont(ofSize: 72), .foregroundColor: UIColor.black]
            )
        }
    }
}
