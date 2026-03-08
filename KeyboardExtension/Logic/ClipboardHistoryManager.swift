// DEPRECATED: 모든 클립보드 데이터는 HistoryManager를 통해 관리됩니다.
// 이 파일은 향후 정리 시 삭제 예정입니다.
// See: Fix_Data_Sync_And_Realtime_v1.md, Deprecate_ClipboardHistoryManager_v1.md

import Foundation

@available(*, deprecated, message: "Use HistoryManager instead")
final class ClipboardHistoryManager {
    static let shared = ClipboardHistoryManager()
    private init() {}
}
