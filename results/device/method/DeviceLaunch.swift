import XCTest
import UIKit
import QuartzCore

// Time to content on a physical device.
// While the main thread runs XCUIApplication.launch(), a background thread grabs screenshots
// (XCUIScreen) as fast as the device allows and keeps a 1/10-scale grayscale copy with a timestamp.
// After the run, the "settled" frame is the last one (taken >= SETTLE_S after launch start);
// time to content = first frame from which every later frame equals the settled frame,
// measured from the moment launch() was called. Status bar and home indicator rows are ignored.
// Same rule as harness/coldstart_analyze.py, but on-device (no USB video capture needed).

private let GW = 118, GH = 256          // 1/10 of 1179x2556 (iPhone 16)
private let SETTLE_S = 4.0
private let THRESH = 1.0

private struct Frame { let t: Double; let dt: Double; let px: [UInt8] }

private func gray(_ img: UIImage) -> [UInt8] {
    var buf = [UInt8](repeating: 0, count: GW * GH)
    guard let cg = img.cgImage else { return buf }
    let cs = CGColorSpaceCreateDeviceGray()
    buf.withUnsafeMutableBytes { p in
        let ctx = CGContext(data: p.baseAddress, width: GW, height: GH, bitsPerComponent: 8, bytesPerRow: GW,
                            space: cs, bitmapInfo: CGImageAlphaInfo.none.rawValue)!
        ctx.interpolationQuality = .low
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: GW, height: GH))
    }
    return buf
}

private func diff(_ a: [UInt8], _ b: [UInt8]) -> Double {
    // rows 7..<GH-4 : skip status bar (~top 6%) and home indicator
    var s = 0, n = 0
    for y in 16..<(GH - 8) { for x in 0..<GW { let i = y * GW + x; s += abs(Int(a[i]) - Int(b[i])); n += 1 } }
    return Double(s) / Double(n)
}

final class DeviceLaunch: Base {
    func testTimeToContent() {
        let runs = Int(env["RUNS"] ?? "10") ?? 10
        var results: [Double] = []
        for i in 0...runs {               // run 0 = warm-up after install, discarded
            app.terminate()
            Thread.sleep(forTimeInterval: 3)
            var frames: [Frame] = []
            let lock = NSLock()
            var stop = false
            let t0Box = UnsafeMutablePointer<Double>.allocate(capacity: 1); t0Box.pointee = 0
            let done = DispatchSemaphore(value: 0)
            // baseline (home screen)
            let home = gray(XCUIScreen.main.screenshot().image)
            Thread.detachNewThread {
                while true {
                    lock.lock(); let s = stop; lock.unlock()
                    if s { break }
                    let a = CACurrentMediaTime()
                    let img = XCUIScreen.main.screenshot().image
                    let b = CACurrentMediaTime()
                    let g = gray(img)
                    lock.lock(); frames.append(Frame(t: (a + b) / 2, dt: b - a, px: g)); lock.unlock()
                }
                done.signal()
            }
            let t0 = CACurrentMediaTime()
            t0Box.pointee = t0
            app.launch()
            let launchReturned = CACurrentMediaTime() - t0
            while CACurrentMediaTime() - t0 < SETTLE_S { Thread.sleep(forTimeInterval: 0.05) }
            lock.lock(); stop = true; lock.unlock()
            done.wait()
            let hasCards = el("note-card").waitForExistence(timeout: 5)
            let fs = frames.filter { $0.t >= t0 }
            guard let last = fs.last else { XCTFail("no frames"); return }
            var end = fs.count - 1
            while end > 0 && diff(fs[end - 1].px, last.px) <= THRESH { end -= 1 }
            let firstChange = fs.firstIndex { diff($0.px, home) > THRESH }
            let ttc = (fs[end].t - t0) * 1000
            let fc = firstChange.map { (fs[$0].t - t0) * 1000 } ?? -1
            let gaps = zip(fs.dropFirst(), fs).map { ($0.t - $1.t) * 1000 }
            let medGap = gaps.sorted()[gaps.count / 2]
            let prevGap = end > 0 ? (fs[end].t - fs[end - 1].t) * 1000 : 0
            print(String(format: "TTC %@ run=%d ttc_ms=%.0f first_change_ms=%.0f launch_call_ms=%.0f frames=%d median_frame_gap_ms=%.0f gap_before_content_ms=%.0f cards=%@",
                         bundleId, i, ttc, fc, launchReturned * 1000, fs.count, medGap, prevGap, hasCards ? "yes" : "NO"))
            XCTAssertTrue(hasCards, "notes list not shown")
            if i > 0 { results.append(ttc) }
            t0Box.deallocate()
        }
        app.terminate()
        let s = results.sorted()
        print("TTC_SUMMARY \(bundleId) median_ms=\(Int(s[s.count / 2])) min_ms=\(Int(s.first!)) max_ms=\(Int(s.last!)) values=\(results.map { Int($0) })")
    }
}

// Content in the accessibility tree: a background thread polls for the first seed note title
// while launch() runs on the main thread. Independent of the system launch zoom animation.
final class DeviceContentTree: Base {
    func testContentInTree() {
        let runs = Int(env["RUNS"] ?? "10") ?? 10
        var results: [Double] = []
        for i in 0...runs {
            app.terminate()
            Thread.sleep(forTimeInterval: 3)
            let probe = XCUIApplication(bundleIdentifier: bundleId)
            let lock = NSLock()
            var found = -1.0, polls = 0, stop = false
            var t0 = 0.0
            let done = DispatchSemaphore(value: 0)
            Thread.detachNewThread {
                while true {
                    lock.lock(); let s = stop; lock.unlock(); if s { break }
                    let a = CACurrentMediaTime()
                    let ok = probe.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS %@", seedTitles[0])).firstMatch.exists
                    let b = CACurrentMediaTime()
                    lock.lock(); polls += 1; if ok && found < 0 && t0 > 0 { found = b }; lock.unlock()
                    if ok && found > 0 { break }
                    _ = a
                }
                done.signal()
            }
            lock.lock(); t0 = CACurrentMediaTime(); lock.unlock()
            app.launch()
            let deadline = CACurrentMediaTime() + 6
            while CACurrentMediaTime() < deadline { lock.lock(); let f = found; lock.unlock(); if f > 0 { break }; Thread.sleep(forTimeInterval: 0.05) }
            lock.lock(); stop = true; lock.unlock(); done.wait()
            let ms = found > 0 ? (found - t0) * 1000 : -1
            print(String(format: "TREE %@ run=%d content_in_tree_ms=%.0f polls=%d", bundleId, i, ms, polls))
            if i > 0 && ms > 0 { results.append(ms) }
        }
        app.terminate()
        print("TREE_SUMMARY \(bundleId) values=\(results.map { Int($0) })")
    }
}
