import SwiftUI

struct CleanerView: View {
    @ObservedObject private var loc = LocalizationManager.shared
    @Binding var cacheEntries: [CacheEntry]
    @Binding var selectedCacheIDs: Set<UUID>
    @Binding var isScanning: Bool
    @Binding var isConfirmingCleanup: Bool
    let trashSize: Int64
    let downloadsSize: Int64
    let mailDownloadsSize: Int64
    let onScan: () -> Void
    let onClean: () -> Void

    private var selectedEntries: [CacheEntry] {
        cacheEntries.filter { selectedCacheIDs.contains($0.id) }
    }

    private var selectedSize: Int64 {
        selectedEntries.reduce(0) { $0 + $1.size }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(loc.tr(.macCleaner))
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .tracking(-0.6)
                    }
                    Text(loc.tr(.cleanerSubtitle))
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(action: onScan) {
                    Label(isScanning ? loc.tr(.scanning) : loc.tr(.scan), systemImage: "magnifyingglass")
                        .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.bordered)
                .disabled(isScanning)
            }

            // Category Summary Cards
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                categoryCard(
                    title: loc.tr(.userCaches),
                    icon: "folder.fill",
                    color: Color(red: 0.96, green: 0.67, blue: 0.25),
                    size: cacheEntries.filter { $0.area == .userCache || $0.area == .systemCache }.reduce(0) { $0 + $1.size },
                    count: cacheEntries.filter { $0.area == .userCache || $0.area == .systemCache }.count
                )
                categoryCard(
                    title: loc.tr(.systemLogs),
                    icon: "doc.text.fill",
                    color: Color.primary.opacity(0.85),
                    size: cacheEntries.filter { $0.area == .userLogs || $0.area == .systemLogs || $0.area == .systemVarLogs }.reduce(0) { $0 + $1.size },
                    count: cacheEntries.filter { $0.area == .userLogs || $0.area == .systemLogs || $0.area == .systemVarLogs }.count
                )
                categoryCard(
                    title: loc.tr(.xcodeDerived),
                    icon: "hammer.fill",
                    color: Color(red: 0.20, green: 0.54, blue: 0.83),
                    size: cacheEntries.filter { $0.area == .xcodeDerived || $0.area == .xcodeArchives }.reduce(0) { $0 + $1.size },
                    count: cacheEntries.filter { $0.area == .xcodeDerived || $0.area == .xcodeArchives }.count
                )
                categoryCard(
                    title: loc.tr(.homebrewCache),
                    icon: "mug.fill",
                    color: Color(red: 0.15, green: 0.68, blue: 0.45),
                    size: cacheEntries.filter { $0.area == .homebrewCache }.reduce(0) { $0 + $1.size },
                    count: cacheEntries.filter { $0.area == .homebrewCache }.count
                )
            }

            // Quick Info Cards (Trash, Downloads, Mail)
            HStack(spacing: 12) {
                quickInfoCard(loc.tr(.trash), icon: "trash.fill", color: .orange, size: trashSize)
                quickInfoCard(loc.tr(.downloads), icon: "arrow.down.circle.fill", color: .blue, size: downloadsSize)
                quickInfoCard(loc.tr(.mailDownloads), icon: "envelope.fill", color: .purple, size: mailDownloadsSize)
            }

            // Cleanable Items Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(loc.tr(.cleanableItems))
                            .font(.system(size: 15, weight: .bold))
                        Text(loc.tr(.cleanableItemsSub))
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if !cacheEntries.isEmpty {
                        Button(selectedCacheIDs.count == cacheEntries.count ? loc.tr(.deselectAll) : loc.tr(.selectAll)) {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedCacheIDs = selectedCacheIDs.count == cacheEntries.count ? [] : Set(cacheEntries.map(\.id))
                            }
                        }
                        .buttonStyle(.plain)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(Color.accentColor)
                    }
                }

                VStack(spacing: 0) {
                    if isScanning && cacheEntries.isEmpty {
                        VStack(spacing: 10) {
                            ProgressView()
                                .scaleEffect(0.85)
                            Text(loc.tr(.scanning))
                                .font(.system(size: 12))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 110)
                    } else if cacheEntries.isEmpty {
                        ContentUnavailableView(
                            loc.tr(.noItemsToClean),
                            systemImage: "checkmark.circle",
                            description: Text(loc.tr(.noItemsToCleanDesc))
                        )
                        .frame(minHeight: 120)
                    } else {
                        ForEach(Array(cacheEntries.enumerated()), id: \.element.id) { index, entry in
                            cacheRow(entry)
                            if index < cacheEntries.count - 1 {
                                Divider().padding(.leading, 46)
                            }
                        }
                    }
                }
                .padding(.horizontal, 14)
                .modernCard()

                // Bottom Action Bar
                HStack {
                    Text("\(cacheEntries.count) \(loc.tr(.items)) · \(loc.tr(.total)): \(SystemInfoHelper.formatBytes(cacheEntries.reduce(0) { $0 + $1.size }))")
                        .font(.system(size: 11))
                        .foregroundStyle(.secondary)

                    Spacer()

                    Button {
                        isConfirmingCleanup = true
                    } label: {
                        Label(loc.tr(.cleanSelected, SystemInfoHelper.formatBytes(selectedSize)), systemImage: "trash")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(selectedEntries.isEmpty || isScanning)
                }
            }

            // Safety Note
            Label {
                Text(loc.tr(.safetyNote))
            } icon: {
                Image(systemName: "info.circle.fill")
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 2)
        }
    }

    private func categoryCard(title: String, icon: String, color: Color, size: Int64, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
            Text(title)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
            Text(SystemInfoHelper.formatBytes(size))
                .font(.system(size: 15, weight: .bold, design: .rounded))
            Text("\(count) \(loc.tr(.items))")
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .modernCard()
    }

    private func quickInfoCard(_ title: String, icon: String, color: Color, size: Int64) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                Text(SystemInfoHelper.formatBytes(size))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
            }
            Spacer()
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .modernCard()
    }

    private func cacheRow(_ entry: CacheEntry) -> some View {
        Button {
            withAnimation(.easeOut(duration: 0.15)) {
                if selectedCacheIDs.contains(entry.id) {
                    selectedCacheIDs.remove(entry.id)
                } else {
                    selectedCacheIDs.insert(entry.id)
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: selectedCacheIDs.contains(entry.id) ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 18))
                    .foregroundStyle(selectedCacheIDs.contains(entry.id) ? Color.accentColor : Color.secondary.opacity(0.45))

                Image(systemName: entry.area.iconName)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.primary.opacity(0.75))

                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.name)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    Text("\(entry.area.title(isTurkish: loc.language == .turkish)) · \(entry.fileCount) \(loc.tr(.items))")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(SystemInfoHelper.formatBytes(entry.size))
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
