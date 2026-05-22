import SwiftUI

struct MagicRightView: View {
    private let scriptsPath = "~/Library/Application Scripts/local.elidev.MagicRight.FinderSync"
    private let menuItems = [
        "生成字幕",
        "新建文本文件",
        "新建 Markdown 文件",
        "新建 Word 文档",
        "用 Ghostty 打开",
        "用 VS Code 打开",
        "提交并推送当前仓库",
        "复制路径",
        "剪切",
        "粘贴"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            header
            Divider()
            statusSection
            actionsSection
            Spacer(minLength: 0)
        }
        .padding(28)
        .frame(minWidth: 620, minHeight: 460)
    }

    private var header: some View {
        HStack(spacing: 16) {
            Image(systemName: "pointer.arrow.ipad.rays")
                .font(.system(size: 42, weight: .semibold))
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 6) {
                Text("MagicRight")
                    .font(.largeTitle.weight(.semibold))
                Text("Finder 右键扩展宿主")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Finder Sync 扩展已随应用打包", systemImage: "checkmark.seal.fill")
            Label("菜单脚本会在启动时同步到 Application Scripts", systemImage: "folder.badge.gearshape")
            Text(scriptsPath)
                .font(.system(.callout, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
        .font(.body)
    }

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("当前右键菜单")
                .font(.title3.weight(.semibold))

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 180), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(menuItems, id: \.self) { item in
                    Label(item, systemImage: "contextualmenu.and.cursorarrow")
                        .font(.callout)
                        .lineLimit(1)
                }
            }
        }
    }
}
